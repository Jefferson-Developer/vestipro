# TASK-146 — Implementar exportação CSV (CONCLUÍDA)

**Epic:** EPIC-18 — Relatórios Customizados e Exportações

## Resumo

Implementada a exportação de resultados do construtor de relatórios (TASK-144) para CSV, com duas
rotas conforme o volume de linhas:

- **Volume pequeno/médio (≤ limite configurável):** codificação inteiramente no dispositivo, em um
  isolate (`compute`), e gravação através do fluxo nativo de "salvar arquivo" (`file_picker`, já
  presente no `pubspec.yaml` — nenhuma dependência nova adicionada).
- **Volume grande (acima do limite):** delegado à nova Cloud Function `exportReportToCsv`, que
  **re-executa** a agregação do relatório inteiramente no servidor (nunca confia num resultado que o
  cliente já tenha calculado), grava o CSV em um objeto do Storage restrito ao usuário solicitante e
  devolve um link assinado com expiração de 24h.

O limite que decide qual rota é usada é o feature flag/Remote Config
`config_report_export_max_local_rows` (padrão `5000`), lido pelo `ReportBuilderBloc` — nunca
hardcoded no use case, e nunca, por si só, um limite de segurança (a Cloud Function aplica seu
próprio teto independente de 200.000 linhas).

## RBAC

- `Capability.reportExport` (`lib/core/permissions/capability.dart`) já existia e já era concedida
  apenas a OWNER/ADMIN/SALES_MANAGER/FINANCE (nunca SALES_REP) — reaproveitada, não recriada.
- A Cloud Function `exportReportToCsv` replica esse boundary com seu próprio guard,
  `assertCanExportReports` (`REPORT_EXPORT_ROLES`), que falha fechado (`permission-denied`) para
  qualquer papel fora desse conjunto — testado isoladamente (`functions/test/reports/export-report-to-csv.test.ts`).
  A checagem de papel do cliente (botão "Exportar CSV" oculto/visível) usa `PermissionBuilder` com a
  mesma capability, mas é só UX: a autorização real está na callable e no `storage.rules`.
- `storage.rules` ganhou o path `organizations/{organizationId}/exports/{userId}/{fileName}`: leitura
  restrita ao próprio usuário que gerou o export e à capability `report.export`; escrita sempre negada
  para qualquer SDK cliente (só o Admin SDK da própria Cloud Function grava ali). Testes
  positivos/negativos adicionados em `storage-tests/storage.rules.test.js` seguindo o padrão já
  existente (TASK-031) — **não foi possível executá-los nesta sessão** porque o Firebase Emulator
  Suite (Firestore + Storage) exige um runtime Java que não está disponível neste ambiente; ver
  "Pendências" abaixo.
- O export de baixo volume nunca refaz a consulta: ele serializa exatamente o `ReportQueryResult` que
  `ExecuteReportQuery` já retornou sob o escopo RBAC/tenant do usuário. O export de alto volume nunca
  confia nesse resultado do cliente — a Cloud Function chama `runReportAggregation` (extraída de
  `execute-report-query.ts`, reaproveitada por `executeReportQuery` e `exportReportToCsv`) de novo,
  sob a Membership real do chamador.

## Arquitetura (Flutter)

Domain (sem Flutter/Firebase):
- `domain/entities/report_export_result.dart` — `ReportExportLocale` (pt-BR/en-US, delimitador e
  separador decimal sempre pareados, nunca combináveis de forma ambígua),
  `ReportExportLocation`/`LocalReportExportLocation`/`RemoteReportExportLocation`,
  `ReportExportSummary`.
- `domain/services/csv_report_encoder.dart` — `CsvReportEncoder`, encoder CSV puro (BOM UTF-8,
  `\r\n`, escaping RFC4180-like, formatação de decimal por locale).
- `domain/services/report_export_file_name_builder.dart` — nome determinístico
  `<slug-do-relatorio>_<organizacao>_<timestamp>.csv`, espelhado no lado servidor
  (`buildExportFileName` em `export-report-to-csv.ts`).
- `domain/repositories/report_export_repository.dart` — contrato com 3 métodos: `encodeCsv`
  (isolate), `saveLocalFile` (I/O nativo) e `requestCloudCsvExport` (Cloud Function).
- `domain/usecases/export_report_to_csv.dart` — `ExportReportToCsv`, decide a rota por
  `maxLocalRows` e nunca falha silenciosamente (captura exceção de encoding como `AppFailure`).

Data:
- `data/datasources/csv_isolate_encoder.dart` — único ponto que importa `package:flutter/foundation.dart`
  (`compute`) nesta feature, mantendo o domínio livre de Flutter.
- `data/datasources/report_file_saver_data_source.dart` — `FilePickerReportFileSaverDataSource`
  (`FilePicker.saveFile`, já em `pubspec.yaml`), cross-platform (mobile/desktop/web).
- `data/datasources/report_export_remote_data_source.dart` +
  `cloud_functions_report_export_remote_data_source.dart` — chama `exportReportToCsv` via
  `CloudFunctionsService`, mesmo padrão de `CloudFunctionsReportRemoteDataSource`.
- `data/repositories/report_export_repository_impl.dart` — converte exceções em `Failure` seguindo
  exatamente o padrão de `ReportRepositoryImpl`.

Presentation:
- `presentation/bloc/report_builder_event.dart` — novo evento `ReportExportRequested`.
- `presentation/bloc/report_builder_state.dart` — novo `ReportExportStatus`
  (`idle/exporting/success/failure`) e `exportSummary`/`exportFailure`, independentes do
  `ReportBuilderStatus` de preview/execução.
- `presentation/bloc/report_builder_bloc.dart` — injeta `ExportReportToCsv` e `FeatureFlagService`;
  lê `FeatureFlagRegistry.configReportExportMaxLocalRows` no momento do export (mesmo padrão já usado
  por `ProductMediaBloc`); loga `AnalyticsEvents.reportExported` (evento que já existia na taxonomia,
  reaproveitado) com `formato=csv`, `row_count` e `delegated_to_cloud`.
- `presentation/pages/report_builder_page.dart` — botão "Exportar CSV" na prévia, com indicador de
  progresso durante a exportação, `SnackBar` de sucesso/erro, e gate de RBAC via `PermissionBuilder`
  (`Capability.reportExport`) quando `permissionService` é informado (mesmo padrão já usado para
  "Salvar visualização"/TASK-145).

Feature flag:
- `lib/core/feature_flags/feature_flag_registry.dart` — novo
  `configReportExportMaxLocalRows` (integer, default `5000`), documentado em
  `docs/architecture/feature-flags.md`.

## Cloud Functions

- `functions/src/reports/execute-report-query.ts` — refatorado sem mudar comportamento: a lógica de
  agregação foi extraída para `runReportAggregation` (exportada), reaproveitada tanto por
  `executeReportQuery` quanto pela nova `exportReportToCsv`. `mergeComparison`/`comparisonMonth`
  continuam exportadas e os testes existentes (`execute-report-query.test.ts`) continuam passando sem
  alteração.
- `functions/src/reports/export-report-to-csv.ts` (novo) — callable `exportReportToCsv`: valida
  auth/Membership/empresa exatamente como `executeReportQuery`, aplica `assertCanExportReports`,
  roda `runReportAggregation`, aplica um teto duro de 200.000 linhas, gera o CSV
  (`rowsToCsv`, BOM + `;`/`,` conforme locale) e grava em
  `organizations/{organizationId}/exports/{uid}/{fileName}` via Admin SDK, devolvendo um
  `getSignedUrl` de 24h.
- `functions/src/reports/index.ts` / `functions/src/index.ts` — `exportReportToCsv` registrada e
  exportada.
- `functions/test/reports/export-report-to-csv.test.ts` (novo) — testes unitários puros (sem
  emulador, mesmo padrão de `report-catalog.test.ts`/`execute-report-query.test.ts`): RBAC
  (`assertCanExportReports`), encoding CSV (BOM, delimitador/decimal por locale, escaping de aspas/
  ponto-e-vírgula/quebra de linha, valores nulos/inteiros, acentuação) e nome de arquivo determinístico.

## Testes executados

- `cd functions && npm run build` — TypeScript compila sem erros.
- `cd functions && npm run lint` — ESLint sem apontamentos.
- `cd functions && npm test -- reports` — 15/15 testes passando (`report-catalog`,
  `execute-report-query`, `export-report-to-csv`).
- `flutter analyze` (projeto inteiro) — 0 erros; apenas *infos* de depreciação pré-existentes,
  não relacionadas a esta task.
- `flutter test test/features/reports test/core/feature_flags` — 76/76 testes passando, incluindo os
  novos: `csv_report_encoder_test.dart`, `report_export_file_name_builder_test.dart`,
  `export_report_to_csv_test.dart` e os novos casos em `report_builder_bloc_test.dart`/
  `report_builder_page_test.dart` (os dois últimos foram atualizados apenas para adaptar a assinatura
  do construtor de `ReportBuilderBloc`, que ganhou dois parâmetros).
- `dart format --output=none --set-exit-if-changed <arquivos tocados>` — 0 arquivos precisando de
  formatação.
- `dart run build_runner build` — regenerou `lib/app/injection.config.dart` com o registro das 5
  novas classes injetáveis; nenhuma outra mudança nesse arquivo gerado.

## Pendências / riscos conhecidos

- **Testes de `storage.rules` não executados**: o Firebase Emulator Suite (Firestore + Storage)
  exige um runtime Java, indisponível neste ambiente (`java: command not found`). Os testes
  positivos/negativos para o novo path `organizations/{organizationId}/exports/...` foram escritos em
  `storage-tests/storage.rules.test.js` seguindo exatamente o padrão da TASK-031, mas precisam ser
  rodados (`firebase emulators:exec --only "firestore,storage" "npm --prefix storage-tests test"`) em
  um ambiente com Java antes do próximo deploy de `storage.rules`.
- **`exportReportToCsv` ainda não foi implantada** (`firebase deploy --only functions`) nem testada
  contra o Firestore/Storage reais — apenas compilada e coberta por testes unitários puros.
- A notificação mencionada no escopo original da task ("com notificação (TASK-151) quando o arquivo
  estiver pronto") não foi implementada porque TASK-151 (central de notificações) ainda não existe no
  backlog — o fluxo de exportação grande hoje devolve o link assinado diretamente na resposta da
  callable (a mesma chamada que o app já aguarda), sem depender de uma central de notificações futura.
  Quando TASK-151 for implementada, valeria complementar com uma notificação assíncrona para o caso de
  o app ser fechado antes da resposta da callable retornar.
- O botão "Exportar CSV" mostra apenas uma mensagem textual (`SnackBar`) para o caso remoto — não abre
  automaticamente o link de download nem baixa o arquivo (não há `url_launcher` no projeto). Abrir o
  link fica para quando uma tela dedicada de "exportações"/central de downloads existir.
