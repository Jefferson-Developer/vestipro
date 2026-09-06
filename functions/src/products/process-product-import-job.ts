import { Readable } from 'node:stream';

import { logger } from 'firebase-functions/v2';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import {
  Timestamp,
  type DocumentReference,
  type Firestore,
  type WriteBatch,
} from 'firebase-admin/firestore';
import { getFirestore } from 'firebase-admin/firestore';
import { getStorage } from 'firebase-admin/storage';
import ExcelJS from 'exceljs';

import {
  MAX_IMPORT_ROWS,
  buildProductDocumentFromFields,
  buildProductVariantDocumentFromFields,
  deriveVariantSku,
  extractRawValues,
  validateProductImportRow,
  type ProductImportLookupInput,
} from './product-import-shared';

interface ProductImportJobDoc {
  organizationId: string;
  companyId: string;
  fileName: string;
  storagePath: string;
  imagesFolderPath: string | null;
  mapping: {
    hasHeaderRow: boolean;
    columnByField: Record<string, number>;
    sizeGridTemplateId: string;
  };
  lookup: ProductImportLookupInput;
  status: string;
  createdBy: string;
}

interface RowReportEntry {
  rowNumber: number;
  outcome: 'created' | 'rejected';
  reason?: string;
  sku?: string;
  createdProductId?: string;
  createdVariantId?: string;
  imageAssociated: boolean;
  rawValues: Record<string, string>;
}

interface RegisteredProduct {
  id: string;
  ref: DocumentReference;
  variantKeys: Set<string>;
  rowNumbers: number[];
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
  const normalizedBytes = Buffer.from(bytes);
  const workbook = new ExcelJS.Workbook();
  if (fileName.toLowerCase().endsWith('.xlsx')) {
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
  return values.slice(1).map((cell) => (cell === null || cell === undefined ? '' : String(cell).trim()));
}

/** Loads every non-deleted Product's sku/reference for [organizationId] once
 * up front — used to detect a conflict with an already-existing product
 * without a per-row Firestore read, same known scaling limitation
 * documented for `loadExistingCustomerIndex` (TASK-167). */
async function loadExistingProductIndex(
  db: Firestore,
  organizationId: string,
): Promise<{ bySku: Set<string>; byReference: Set<string> }> {
  const snapshot = await db
    .collection('organizations')
    .doc(organizationId)
    .collection('products')
    .get();
  const bySku = new Set<string>();
  const byReference = new Set<string>();
  snapshot.forEach((doc) => {
    const data = doc.data();
    if (data.deletedAt != null) return;
    if (typeof data.sku === 'string') bySku.add(data.sku);
    if (typeof data.reference === 'string') byReference.add(data.reference);
  });
  return { bySku, byReference };
}

function baseNameWithoutExtension(fileName: string): string {
  const slashIndex = Math.max(fileName.lastIndexOf('/'), fileName.lastIndexOf('\\'));
  const name = slashIndex >= 0 ? fileName.slice(slashIndex + 1) : fileName;
  const dotIndex = name.lastIndexOf('.');
  return (dotIndex > 0 ? name.slice(0, dotIndex) : name).trim().toUpperCase();
}

/**
 * Processes a queued `ProductImportJob` (TASK-168) — triggered by its own
 * Firestore document creation, mirroring `processCustomerImportJob`
 * (TASK-167). Never interrupts on a single bad row: every row of the source
 * file gets exactly one outcome recorded in the report, and the loop always
 * continues.
 */
export const processProductImportJob = onDocumentCreated(
  'organizations/{organizationId}/productImportJobs/{jobId}',
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;
    const job = snapshot.data() as ProductImportJobDoc;
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

      const { bySku: existingSkus, byReference: existingReferences } =
        await loadExistingProductIndex(db, job.organizationId);

      const productsCollection = db
        .collection('organizations')
        .doc(job.organizationId)
        .collection('products');
      const variantsCollection = db
        .collection('organizations')
        .doc(job.organizationId)
        .collection('productVariants');

      const registeredBySku = new Map<string, RegisteredProduct>();
      const rowsReport: RowReportEntry[] = [];
      let createdProductsCount = 0;
      let createdVariantsCount = 0;
      let rejectedCount = 0;
      let processedRows = 0;

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

        const validation = validateProductImportRow(rawValues, job.lookup);
        if (!validation.ok) {
          rejectedCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'rejected',
            reason: validation.reason,
            sku: rawValues.sku || undefined,
            imageAssociated: false,
            rawValues,
          });
          processedRows += 1;
          continue;
        }

        const { fields } = validation;
        let registered = registeredBySku.get(fields.sku);

        if (!registered) {
          if (existingSkus.has(fields.sku) || existingReferences.has(fields.reference)) {
            rejectedCount += 1;
            rowsReport.push({
              rowNumber,
              outcome: 'rejected',
              reason: existingSkus.has(fields.sku)
                ? 'Já existe um produto com este SKU nesta organização.'
                : 'Já existe um produto com esta referência nesta organização.',
              sku: fields.sku,
              imageAssociated: false,
              rawValues,
            });
            processedRows += 1;
            continue;
          }

          const productRef = productsCollection.doc();
          batch.set(
            productRef,
            buildProductDocumentFromFields({
              organizationId: job.organizationId,
              companyId: job.companyId,
              fields,
              categoryId: fields.categoryName
                ? job.lookup.categoryIdByName[fields.categoryName.toLowerCase()]
                : null,
              subcategoryId: fields.subcategoryName
                ? job.lookup.categoryIdByName[fields.subcategoryName.toLowerCase()]
                : null,
              collectionId: fields.collectionName
                ? job.lookup.collectionIdByName[fields.collectionName.toLowerCase()]
                : null,
              sizeGridTemplateId: job.mapping.sizeGridTemplateId,
              createdBy: job.createdBy,
              now,
            }),
          );
          pendingWrites += 1;
          createdProductsCount += 1;
          existingSkus.add(fields.sku);
          existingReferences.add(fields.reference);
          registered = {
            id: productRef.id,
            ref: productRef,
            variantKeys: new Set<string>(),
            rowNumbers: [],
          };
          registeredBySku.set(fields.sku, registered);
        }

        const variantKey = `${fields.colorId}|${fields.sizeId}`;
        if (registered.variantKeys.has(variantKey)) {
          rejectedCount += 1;
          rowsReport.push({
            rowNumber,
            outcome: 'rejected',
            reason: 'Combinação de cor e tamanho já importada para este produto nesta planilha.',
            sku: fields.sku,
            createdProductId: registered.id,
            imageAssociated: false,
            rawValues,
          });
          processedRows += 1;
          continue;
        }

        const variantSku = deriveVariantSku({
          productSku: fields.sku,
          colorCode: fields.colorRaw,
          colorId: fields.colorId,
          sizeLabel: fields.sizeLabelRaw,
          sizeId: fields.sizeId,
        });
        const variantRef = variantsCollection.doc();
        batch.set(
          variantRef,
          buildProductVariantDocumentFromFields({
            organizationId: job.organizationId,
            productId: registered.id,
            fields,
            variantSku,
            sizeGridTemplateId: job.mapping.sizeGridTemplateId,
            createdBy: job.createdBy,
            now,
          }),
        );
        pendingWrites += 1;
        createdVariantsCount += 1;
        registered.variantKeys.add(variantKey);
        registered.rowNumbers.push(rowNumber);

        rowsReport.push({
          rowNumber,
          outcome: 'created',
          sku: fields.sku,
          createdProductId: registered.id,
          createdVariantId: variantRef.id,
          imageAssociated: false,
          rawValues,
        });

        await commitIfNeeded();
        processedRows += 1;
        if (processedRows % PROGRESS_UPDATE_EVERY === 0) {
          await jobRef.update({
            processedRows,
            createdProductsCount,
            createdVariantsCount,
            rejectedCount,
          });
        }
      }

      await commitIfNeeded(true);

      // ---------------------------------------------------------------
      // Image association (TASK-168): matches every file uploaded under
      // `imagesFolderPath` to a registered product by SKU/referência (file
      // name without extension, case-insensitive) — an unmatched image is
      // reported as orphan, never blocking the products already created.
      // ---------------------------------------------------------------
      let imagesAssociatedCount = 0;
      let imagesOrphanCount = 0;
      const orphanImageFileNames: string[] = [];

      if (job.imagesFolderPath) {
        const nameIndex = new Map<string, RegisteredProduct>();
        for (const [sku, registered] of registeredBySku.entries()) {
          nameIndex.set(sku.toUpperCase(), registered);
        }
        // Also index by reference: read back the just-created products'
        // `reference` field is unnecessary — `fields.reference` was already
        // known per row, but only `sku` is the registeredBySku key. A second
        // pass over rowsReport recovers the reference->product association
        // without an extra Firestore read.
        for (const row of rowsReport) {
          if (row.outcome !== 'created' || !row.sku) continue;
          const reference = row.rawValues.reference;
          const registered = registeredBySku.get(row.sku);
          if (reference && registered) {
            nameIndex.set(reference.trim().toUpperCase(), registered);
          }
        }

        const [files] = await bucket.getFiles({ prefix: job.imagesFolderPath });
        let order = 0;
        for (const file of files) {
          const key = baseNameWithoutExtension(file.name);
          if (key.length === 0) continue;
          const registered = nameIndex.get(key);
          if (!registered) {
            imagesOrphanCount += 1;
            orphanImageFileNames.push(file.name.split('/').pop() ?? file.name);
            continue;
          }

          const [url] = await file.getSignedUrl({
            action: 'read',
            expires: '2500-01-01',
          });
          await registered.ref.update({
            media: [
              {
                id: variantsCollection.doc().id,
                type: 'photo',
                url,
                thumbnailUrl: null,
                order: order++,
                principal: true,
                colorId: null,
              },
            ],
          });
          imagesAssociatedCount += 1;
          for (const rowNumber of registered.rowNumbers) {
            const reportRow = rowsReport.find((row) => row.rowNumber === rowNumber);
            if (reportRow) reportRow.imageAssociated = true;
          }
        }
      }

      const reportStoragePath = `organizations/${job.organizationId}/productImports/${jobRef.id}/report.json`;
      await bucket.file(reportStoragePath).save(
        Buffer.from(
          JSON.stringify({
            totalRows,
            createdProductsCount,
            createdVariantsCount,
            imagesAssociatedCount,
            imagesOrphanCount,
            rejectedCount,
            rows: rowsReport,
            orphanImageFileNames,
          }),
        ),
        { contentType: 'application/json' },
      );

      const completedAt = Timestamp.now();
      await jobRef.update({
        status: 'completed',
        processedRows,
        createdProductsCount,
        createdVariantsCount,
        imagesAssociatedCount,
        imagesOrphanCount,
        rejectedCount,
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
          action: 'productImport.completed',
          entityType: 'productImportJob',
          entityId: jobRef.id,
          previousValue: null,
          newValue: {
            fileName: job.fileName,
            totalRows,
            createdProductsCount,
            createdVariantsCount,
            imagesAssociatedCount,
            imagesOrphanCount,
            rejectedCount,
          },
          timestamp: completedAt,
        });

      logger.info('processProductImportJob succeeded', {
        organizationId: job.organizationId,
        jobId: jobRef.id,
        totalRows,
        createdProductsCount,
        createdVariantsCount,
        imagesAssociatedCount,
        imagesOrphanCount,
        rejectedCount,
      });
    } catch (error) {
      logger.error('processProductImportJob failed', {
        organizationId: job.organizationId,
        jobId: jobRef.id,
        error: error instanceof Error ? error.message : String(error),
      });
      await jobRef.update({
        status: 'failed',
        errorMessage:
          error instanceof Error ? error.message : 'Erro inesperado ao processar a importação.',
        completedAt: Timestamp.now(),
      });
    }
  },
);
