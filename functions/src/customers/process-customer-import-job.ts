import { Readable } from 'node:stream';

import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import {
  Timestamp,
  type Firestore,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import ExcelJS from 'exceljs';

import {
  MAX_IMPORT_ROWS,
  buildCustomerDocumentFromFields,
  extractRawValues,
  isValidEmail,
  validateCustomerImportRow,
} from './customer-import-shared';

interface CustomerImportJobDoc {
  organizationId: string;
  companyId: string;
  fileName: string;
  storagePath: string;
  templateId: string | null;
  mapping: { hasHeaderRow: boolean; columnByField: Record<string, number> };
  status: string;
  createdBy: string;
}

interface RowReportEntry {
  rowNumber: number;
  outcome: 'imported' | 'rejected' | 'duplicateInFile' | 'duplicateExisting';
  reason?: string;
  createdCustomerId?: string;
  matchedExistingCustomerId?: string;
  matchedByEmailOnly?: boolean;
  resolution?: string;
  rawValues: Record<string, string>;
}

const PROGRESS_UPDATE_EVERY = 200;
const BATCH_COMMIT_THRESHOLD = 400;

function detectCsvDelimiter(buffer: Buffer): string {
  const firstLine = buffer.toString('utf8').split(/\r?\n/, 1)[0] ?? '';
  const commaCount = (firstLine.match(/,/g) ?? []).length;
  const semicolonCount = (firstLine.match(/;/g) ?? []).length;
  return semicolonCount > commaCount ? ';' : ',';
}

async function loadWorksheet(
  bytes: Buffer,
  fileName: string,
): Promise<ExcelJS.Worksheet> {
  // `Buffer.from(bytes)` re-wraps whatever concrete `Buffer` subtype
  // `bucket.file().download()` returned (its `@types/node` structural type
  // does not always line up with the one `exceljs`'s own typings expect) —
  // a cheap, always-safe normalization, not a data copy semantics change.
  const normalizedBytes = Buffer.from(bytes);
  const workbook = new ExcelJS.Workbook();
  if (fileName.toLowerCase().endsWith('.xlsx')) {
    // `exceljs`'s own bundled `@types/node`-derived `Buffer` type does not
    // structurally line up with this project's — same root cause
    // `export-report-to-xlsx.ts` (TASK-147) already works around (there, on
    // the write side, via `as unknown as Buffer`, which is not enough here
    // since the mismatch is on the *parameter* type itself) — `as any` is
    // the only cast that reliably sidesteps it on this read side.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    await workbook.xlsx.load(normalizedBytes as any);
    const sheet = workbook.worksheets[0];
    if (!sheet) throw new Error('Planilha XLSX sem nenhuma aba.');
    return sheet;
  }
  const delimiter = detectCsvDelimiter(normalizedBytes);
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  return workbook.csv.read(Readable.from(normalizedBytes) as any, {
    parserOptions: { delimiter, ignoreEmpty: true },
  });
}

function rowToStrings(row: ExcelJS.Row): string[] {
  const values = row.values as ExcelJS.CellValue[];
  // `row.values` is 1-indexed (index 0 is always empty) — sliced to match
  // the 0-based column indexes `CustomerImportMapping` (Flutter) uses.
  return values.slice(1).map((cell) => (cell === null || cell === undefined ? '' : String(cell).trim()));
}

/** Loads every non-deleted `Customer`'s document/e-mail for [organizationId]
 * once, up front — used to detect `duplicateExisting` rows without a
 * per-row Firestore read. Acceptable for typical organization sizes (base
 * import target, `tasks.md`); a very large existing base (tens of
 * thousands of customers) would need a paginated/indexed lookup instead —
 * documented as a known scaling limitation, not attempted here (see
 * TASK-167-...-CONCLUIDA.md). */
async function loadExistingCustomerIndex(
  db: Firestore,
  organizationId: string,
): Promise<{ byDocument: Map<string, string>; byEmail: Map<string, string> }> {
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('customers')
    .get();
  const byDocument = new Map<string, string>();
  const byEmail = new Map<string, string>();
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.deletedAt != null) return;
    if (typeof data.document === 'string') byDocument.set(data.document, doc.id);
    if (typeof data.primaryEmail === 'string' && isValidEmail(data.primaryEmail)) {
      byEmail.set(data.primaryEmail.toLowerCase(), doc.id);
    }
  });
  return { byDocument, byEmail };
}

/**
 * Processes a queued `CustomerImportJob` (TASK-167) — triggered by its own
 * Firestore document creation instead of running inside
 * `startCustomerImportJob`'s callable request/response cycle, so a large
 * spreadsheet's parse/validate/write work never risks a callable timeout
 * nor blocks the client waiting for a response.
 *
 * Never interrupts on a single bad row ("Nenhuma linha inválida pode
 * interromper o processamento das demais", AGENTS.md): every row gets
 * exactly one outcome recorded in the report, and the loop always
 * continues. Any *unexpected* exception (corrupt file, Storage/Firestore
 * failure) instead fails the whole job with `status: 'failed'` and
 * `errorMessage` — that is the one case processing legitimately cannot
 * continue.
 */
export const processCustomerImportJob = onDocumentCreated(
  'organizations/{organizationId}/customerImportJobs/{jobId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const job = snapshot.data() as CustomerImportJobDoc;
    if (job.status !== 'queued') return;

    const db = getFirestore();
    const jobRef = snapshot.ref;
    const now = Timestamp.now();

    try {
      await jobRef.update({ status: 'processing', startedAt: now });

      const bucket = getStorage().bucket();
      const [bytes] = await bucket.file(job.storagePath).download();
      const worksheet = await loadWorksheet(bytes, job.fileName);

      const hasHeaderRow = job.mapping.hasHeaderRow;
      const firstDataRow = hasHeaderRow ? 2 : 1;
      const totalRows = Math.max(0, worksheet.rowCount - (hasHeaderRow ? 1 : 0));

      if (totalRows > MAX_IMPORT_ROWS) {
        await jobRef.update({
          status: 'failed',
          errorMessage: `A planilha tem ${totalRows} linhas, acima do limite de ${MAX_IMPORT_ROWS}. Divida o arquivo em partes menores.`,
          completedAt: Timestamp.now(),
        });
        return;
      }

      await jobRef.update({ totalRows });

      const { byDocument: existingByDocument, byEmail: existingByEmail } =
        await loadExistingCustomerIndex(db, job.organizationId);
      const documentSeenAtRow = new Map<string, number>();
      const emailSeenAtRow = new Map<string, number>();

      const rowsReport: RowReportEntry[] = [];
      let importedCount = 0;
      let rejectedCount = 0;
      let duplicateCount = 0;
      let processedRows = 0;

      const customersCollection = db
        .collection('organizations')
        .doc(job.organizationId)
        .collection('customers');

      let batch: WriteBatch = db.batch();
      let pendingWrites = 0;
      const commitIfNeeded = async (force = false): Promise<void> => {
        if (pendingWrites === 0 || (!force && pendingWrites < BATCH_COMMIT_THRESHOLD)) {
          return;
        }
        await batch.commit();
        batch = db.batch();
        pendingWrites = 0;
      };

      for (let excelRowNumber = firstDataRow; excelRowNumber <= worksheet.rowCount; excelRowNumber += 1) {
        const rowNumber = excelRowNumber - (hasHeaderRow ? 1 : 0);
        const excelRow = worksheet.getRow(excelRowNumber);
        const rawValues = extractRawValues(rowToStrings(excelRow), job.mapping.columnByField);

        const isEntirelyBlank = Object.values(rawValues).every((value) => value.length === 0);
        if (isEntirelyBlank) {
          processedRows += 1;
          continue;
        }

        const validation = validateCustomerImportRow(rawValues);
        if (!validation.ok) {
          rejectedCount += 1;
          rowsReport.push({ rowNumber, outcome: 'rejected', reason: validation.reason, rawValues });
          processedRows += 1;
          continue;
        }

        const { fields } = validation;
        const normalizedEmail = fields.primaryEmail?.toLowerCase() ?? null;

        const duplicateInFileRow = documentSeenAtRow.get(fields.documentDigits);
        const duplicateInFileByEmail = normalizedEmail
          ? emailSeenAtRow.get(normalizedEmail)
          : undefined;
        if (duplicateInFileRow !== undefined) {
          duplicateCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'duplicateInFile',
            reason: `Mesmo CNPJ/CPF já importado na linha ${duplicateInFileRow}.`,
            rawValues,
          });
          processedRows += 1;
          continue;
        }
        if (duplicateInFileByEmail !== undefined) {
          duplicateCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'duplicateInFile',
            reason: `Mesmo e-mail já importado na linha ${duplicateInFileByEmail}.`,
            rawValues,
          });
          processedRows += 1;
          continue;
        }

        const existingByDoc = existingByDocument.get(fields.documentDigits);
        const existingByMail = normalizedEmail ? existingByEmail.get(normalizedEmail) : undefined;
        if (existingByDoc) {
          duplicateCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'duplicateExisting',
            reason: 'Já existe um cliente com este CNPJ/CPF nesta organização.',
            matchedExistingCustomerId: existingByDoc,
            matchedByEmailOnly: false,
            rawValues,
          });
          processedRows += 1;
          continue;
        }
        if (existingByMail) {
          duplicateCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'duplicateExisting',
            reason: 'Já existe um cliente com este e-mail nesta organização.',
            matchedExistingCustomerId: existingByMail,
            matchedByEmailOnly: true,
            rawValues,
          });
          processedRows += 1;
          continue;
        }

        const customerRef = customersCollection.doc();
        batch.set(
          customerRef,
          buildCustomerDocumentFromFields({
            organizationId: job.organizationId,
            companyId: job.companyId,
            fields,
            createdBy: job.createdBy,
            now,
          }),
        );
        pendingWrites += 1;
        importedCount += 1;
        documentSeenAtRow.set(fields.documentDigits, rowNumber);
        if (normalizedEmail) emailSeenAtRow.set(normalizedEmail, rowNumber);
        rowsReport.push({ rowNumber, outcome: 'imported', createdCustomerId: customerRef.id, rawValues });

        await commitIfNeeded();
        processedRows += 1;
        if (processedRows % PROGRESS_UPDATE_EVERY === 0) {
          await jobRef.update({ processedRows, importedCount, rejectedCount, duplicateCount });
        }
      }

      await commitIfNeeded(true);

      const reportStoragePath = `organizations/${job.organizationId}/customerImports/${jobRef.id}/report.json`;
      await bucket.file(reportStoragePath).save(
        Buffer.from(
          JSON.stringify({ totalRows, importedCount, rejectedCount, duplicateCount, rows: rowsReport }),
        ),
        { contentType: 'application/json' },
      );

      const completedAt = Timestamp.now();
      await jobRef.update({
        status: 'completed',
        processedRows,
        importedCount,
        rejectedCount,
        duplicateCount,
        reportStoragePath,
        completedAt,
      });

      await db
        .collection('organizations')
        .doc(job.organizationId)
        .collection('auditLogs')
        .doc()
        .set({
          organizationId: job.organizationId,
          actorUserId: job.createdBy,
          actorName: job.createdBy,
          action: 'customerImport.completed',
          entityType: 'customerImportJob',
          entityId: jobRef.id,
          previousValue: null,
          newValue: { fileName: job.fileName, totalRows, importedCount, rejectedCount, duplicateCount },
          timestamp: completedAt,
        });

      logger.info('processCustomerImportJob succeeded', {
        organizationId: job.organizationId,
        jobId: jobRef.id,
        totalRows,
        importedCount,
        rejectedCount,
        duplicateCount,
      });
    } catch (error) {
      logger.error('processCustomerImportJob failed', {
        organizationId: job.organizationId,
        jobId: jobRef.id,
        error: error instanceof Error ? error.message : String(error),
      });
      await jobRef.update({
        status: 'failed',
        errorMessage: error instanceof Error ? error.message : 'Erro inesperado ao processar a importação.',
        completedAt: Timestamp.now(),
      });
    }
  },
);
