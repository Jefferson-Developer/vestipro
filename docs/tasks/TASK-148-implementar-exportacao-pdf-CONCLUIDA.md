# TASK-148 — Implementar exportação PDF (CONCLUÍDA)

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ✅ Concluída
**Agentes:** Flutter Senior Architect + Flutter UI Design Specialist (revisão de UX da pré-visualização)

## Resumo

Implementada a exportação de relatórios para PDF a partir do construtor de relatórios
(TASK-144), seguindo exatamente o mesmo padrão arquitetural já estabelecido pelas exportações
CSV (TASK-146) e XLSX (TASK-147): roteamento local/nuvem pelo mesmo limiar de linhas
(`FeatureFlagRegistry.configReportExportMaxLocalRows`), mesmo RBAC (`Capability.reportExport` /
`assertCanExportReports`), mesmo isolamento de tenant e mesmo nome de arquivo determinístico
(`ReportExportFileNameBuilder`). A diferença específica do PDF, exigida pela task, é a
**pré-visualização obrigatória com opção de cancelar antes de persistir o arquivo** e a
**aplicação do branding da organização (logo + cor)**, só quando explicitamente configurado.

## Decisões técnicas

- **Fluxo em duas etapas (preview → confirm), só para PDF.** Diferente de CSV/XLSX (que
  codificam e salvam em um único passo), o PDF primeiro gera os bytes em memória
  (`ExportReportToPdf.call`, retornando `LocalReportPdfPreview` ou, para volume grande,
  `RemoteReportPdfPreview` direto — sem pré-visualização client-side nesse caso) e só persiste
  quando o usuário confirma (`ExportReportToPdf.confirm`), reaproveitando os mesmos bytes já
  gerados — nunca recodifica nem busca o branding de novo.
- **Branding da organização.** Adicionados os campos opcionais `OrganizationSettings
  .brandingLogoUrl`/`brandingPrimaryColorHex` (nulo = não configurado, nunca inferido). O
  `ReportBrandingDataSource` (Flutter) resolve `Organization.getById` + baixa o logo via `Dio`
  (dependência já reservada no `pubspec.yaml` para integrações REST externas, agora registrada
  em `AppInjectionModule`); qualquer falha de rede degrada silenciosamente para "sem logo"
  (nunca bloqueia a exportação). O mesmo fallback existe no lado servidor
  (`resolveReportPdfBranding`, lendo o documento `organizations/{id}` via Admin SDK e usando
  `fetch` nativo do Node 20).
- **Pacotes escolhidos:**
  - Flutter: `pdf` (gerador puro Dart, mesma lógica de "sem dependência nativa/licença
    comercial" já documentada para `excel`) + `printing` (só na camada de apresentação, para o
    widget `PdfPreview` da tela de pré-visualização — `PdfReportEncoder` nunca importa
    `printing`).
  - Cloud Functions: `pdfkit` (gerador puro Node, mesmo raciocínio do `exceljs` já usado em
    TASK-147).
- **Caracteres Unicode no `pdf` (Dart).** A fonte padrão (Helvetica base-14) do pacote `pdf` não
  tem glifo para "—" (em-dash) nem "•" (bullet) — descoberto rodando os testes do encoder, que
  emitiam avisos de "Unable to find a font to draw". Substituídos por hífen simples (`-`) em
  todos os textos gerados (`PdfReportEncoder`), evitando caracteres "quebrados" no PDF final.
  Português acentuado (á, ç, ã, é, etc.) funciona normalmente com a fonte padrão.
- **Cloud Function `exportReportToPdf`** replica exatamente `exportReportToXlsx`
  (RBAC, `MAX_EXPORTABLE_ROWS`, `EXPORT_LINK_TTL_MS`, nome de arquivo), reexecutando a agregação
  server-side (nunca confiando em `ReportQueryResult` do cliente) e resolvendo o branding
  independentemente do que o cliente informar.
- **`storage.rules`** já era agnóstico de formato (path `organizations/{id}/exports/{uid}/
  {fileName}`, sem checagem de `contentType`), então nenhuma alteração foi necessária ali.

## Arquivos criados

- `lib/features/reports/domain/entities/report_branding.dart`
- `lib/features/reports/domain/services/pdf_report_encoder.dart`
- `lib/features/reports/domain/usecases/export_report_to_pdf.dart`
- `lib/features/reports/data/datasources/pdf_isolate_encoder.dart`
- `lib/features/reports/data/datasources/report_branding_data_source.dart`
- `lib/features/reports/presentation/pages/report_pdf_preview_page.dart`
- `functions/src/reports/export-report-to-pdf.ts`
- `functions/test/reports/export-report-to-pdf.test.ts`
- `test/features/reports/domain/services/pdf_report_encoder_test.dart`
- `docs/tasks/TASK-148-implementar-exportacao-pdf-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `pubspec.yaml` (dependências `pdf`, `printing`) / `pubspec.lock`
- `functions/package.json` / `functions/package-lock.json` (dependências `pdfkit`,
  `@types/pdfkit`)
- `lib/app/injection_module.dart` (registro de `Dio`)
- `lib/app/injection.config.dart` (regenerado via `build_runner`)
- `lib/features/organizations/domain/value_objects/organization_settings.dart` (+
  `.freezed.dart`, regenerado) — campos `brandingLogoUrl`/`brandingPrimaryColorHex`
- `lib/features/organizations/data/dtos/organization_settings_dto.dart`
- `lib/features/organizations/data/mappers/organization_mapper.dart`
- `lib/features/reports/domain/entities/report_export_result.dart` (formato `pdf`,
  `ReportPdfPreviewResult`/`LocalReportPdfPreview`/`RemoteReportPdfPreview`)
- `lib/features/reports/domain/repositories/report_export_repository.dart`
  (`encodePdf`/`loadBranding`/`requestCloudPdfExport`)
- `lib/features/reports/data/repositories/report_export_repository_impl.dart`
- `lib/features/reports/data/datasources/report_export_remote_data_source.dart` +
  `cloud_functions_report_export_remote_data_source.dart` (`exportPdf`)
- `lib/features/reports/data/datasources/report_file_saver_data_source.dart` (mime `.pdf`)
- `lib/features/reports/presentation/bloc/report_builder_event.dart`/`_state.dart`/`_bloc.dart`
  (eventos/estados `ReportPdfPreviewRequested`/`Cancelled`, `ReportPdfExportConfirmed`,
  `ReportPdfPreviewStatus`)
- `lib/features/reports/presentation/pages/report_builder_page.dart` (botão "Exportar PDF" +
  navegação para a pré-visualização)
- `lib/features/reports/reports.dart` (barrel exports)
- `functions/src/reports/index.ts` / `functions/src/index.ts` (registro de `exportReportToPdf`)
- `test/features/reports/domain/usecases/export_report_to_csv_test.dart` /
  `export_report_to_xlsx_test.dart` (fakes atualizados com os novos métodos do contrato)
- `test/features/reports/presentation/bloc/report_builder_bloc_test.dart` (injeção do novo use
  case + 6 novos cenários de PDF: preview local, confirmação, cancelamento, delegação remota,
  falha de geração)
- `test/features/reports/presentation/pages/report_builder_page_test.dart` (fakes atualizados)
- `test/features/organizations/domain/value_objects/organization_settings_test.dart` (4 novos
  casos de branding)
- `docs/tasks/TASKS.md` (checkbox TASK-148 + progresso 147→148)

## Validações executadas

- `flutter analyze` — sem erros (apenas infos pré-existentes não relacionados).
- `dart format --output=none --set-exit-if-changed` nos diretórios tocados — sem divergências.
- `flutter test` (suíte completa do projeto) — **2807 testes, todos passando**.
- `npm run build` (tsc) em `functions/` — sem erros.
- `npx eslint` nos arquivos novos/alterados de `functions/` — sem apontamentos.
- `npx jest test/reports` em `functions/` — **36 testes, todos passando** (10 novos específicos
  de PDF). A suíte completa de `functions/` tem falhas pré-existentes e não relacionadas
  (dependem do Firestore Emulator, que não está rodando neste ambiente).

## Pendências / riscos residuais

- **Teste de widget da tela de pré-visualização** (`ReportPdfPreviewPage`, usando o widget
  `PdfPreview` do pacote `printing`) não foi criado: esse widget depende de um `MethodChannel`
  nativo (`net.nfet.printing`) para rasterizar o PDF, o que tornaria o teste frágil/dependente de
  mocks de canal de plataforma sem benefício claro. Em vez disso, o ciclo de vida completo da
  pré-visualização (loading → ready/failure, confirmação, cancelamento, delegação remota sem
  preview) está coberto no nível do `ReportBuilderBloc`
  (`test/features/reports/presentation/bloc/report_builder_bloc_test.dart`).
- **Download do logo via `Dio`** ainda não tem teste de datasource dedicado
  (`ReportBrandingDataSource`) — a fidelidade do fallback (sem organização, sem URL, URL
  quebrada) está coberta indiretamente pelos testes do use case/bloc (branding sempre
  `ReportBranding.none()` nos fakes), mas não há teste unitário isolado do datasource real.
- Push não realizado nesta rodada (não autorizado).
