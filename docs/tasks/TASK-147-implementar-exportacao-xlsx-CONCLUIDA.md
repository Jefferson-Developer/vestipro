# TASK-147 — Implementar exportação XLSX (CONCLUÍDA)

**Epic:** EPIC-18 — Relatórios Customizados e Exportações

## Resumo

Implementada a exportação de resultados do construtor de relatórios (TASK-144) para XLSX,
reaproveitando integralmente a arquitetura e a estratégia de roteamento por volume já criadas na
TASK-146 (CSV) — mesmas duas rotas, mesmo `Capability.reportExport`, mesmo feature flag, mesmo path
de Storage:

- **Volume pequeno/médio (≤ limite configurável):** planilha gerada inteiramente no dispositivo, em
  um isolate (`compute`), e gravada através do fluxo nativo de "salvar arquivo" (`file_picker`, já
  usado pela TASK-146 — generalizado para inferir mime-type/extensão do próprio nome do arquivo em
  vez de assumir CSV).
- **Volume grande (acima do limite):** delegado à nova Cloud Function `exportReportToXlsx`, que
  **re-executa** a agregação do relatório inteiramente no servidor (nunca confia num resultado ou
  catálogo que o cliente já tenha calculado), gera a planilha, grava no mesmo path de Storage já
  restrito ao usuário solicitante (`organizations/{organizationId}/exports/{uid}/{fileName}`,
  já genérico a qualquer extensão — nenhuma mudança em `storage.rules` foi necessária) e devolve um
  link assinado com expiração de 24h.

## Decisão técnica: geração client-side com `excel` + pós-processamento de XML

Antes de codar, avaliei pacotes de planilha Dart disponíveis pelos critérios do agente sênior
(manutenção recente, suporte às três plataformas, necessidade real):

- **`excel` (^4.0.6, escolhido):** pacote Dart puro, sem dependência nativa — funciona em
  mobile/desktop/web sem qualquer configuração extra; é a única opção séria sem exigência de licença
  comercial (ao contrário de `syncfusion_flutter_xlsio`, que exige licença para uso comercial).
  **Limitação encontrada:** a API pública do `excel` não expõe cabeçalho congelado (`freeze pane`)
  nem `AutoFilter` nativo — nenhum dos dois é sequer mencionado no código-fonte do pacote.
- Diante disso, `XlsxReportEncoder` (`lib/features/reports/domain/services/xlsx_report_encoder.dart`)
  gera a planilha normalmente via `excel` e, em seguida, **pós-processa o XML da planilha diretamente
  dentro do arquivo `.xlsx` já gerado** (que é um `.zip` de XMLs OOXML): descompacta com `archive`
  (`ZipDecoder`/`ZipEncoder`, já dependência transitiva do `excel`, declarada aqui como direta por ser
  usada diretamente), injeta os elementos `<pane .../>` (cabeçalho congelado) e `<autoFilter ref="..."/>`
  no `xl/worksheets/sheet1.xml` usando `package:xml` (idem, já transitiva, declarada direta), e
  recompacta. Essa decisão evita adicionar uma segunda dependência mais pesada/com licença comercial
  só para dois recursos pontuais, mantendo o resto da geração (tipos de célula, estilo, formato
  numérico) inteiramente a cargo do `excel`.
- No lado servidor (Cloud Function), o Node tem uma opção mais completa e sem essa lacuna:
  **`exceljs` (^4.4.0)**, que já suporta `views: [{ state: 'frozen', ySplit: 1 }]` e
  `worksheet.autoFilter` nativamente — nenhum pós-processamento de XML foi necessário nesse lado.
  `exceljs` acrescentou uma vulnerabilidade `moderate` transitiva (`uuid`, buffer bounds check) ao
  `npm audit`; a mesma advisory já aparecia em várias outras dependências pré-existentes da árvore
  (`gaxios`, `google-gax`, `retry-request`, `teeny-request`, todas vindas do `firebase-admin`), então
  não é uma classe de risco nova introduzida só pelo `exceljs` — registrado aqui como risco conhecido,
  não corrigido nesta task (corrigir exigiria `npm audit fix --force`, fora do escopo).

## Tipos de célula (nunca texto genérico)

Data/moeda/percentual nunca são exportados como string — o tipo real da célula vem do catálogo do
relatório (`ReportCatalog`/`ReportFieldConfig.valueType`), nunca é adivinhado a partir do valor bruto:

- **`ReportColumnValueTypeResolver`** (Dart, `domain/services/report_column_value_type_resolver.dart`)
  e **`resolveColumnValueType`** (TypeScript, `functions/src/reports/export-report-to-xlsx.ts`) —
  implementações espelhadas: resolvem o tipo de uma coluna pelo id direto no catálogo, com dois casos
  especiais para colunas de comparação sintetizadas por `runReportAggregation`
  (`mergeComparison`): `<metrica>ChangePercent` é sempre percentual, `<metrica>Comparison` herda o
  tipo da métrica-base.
- **Data** (`period`, formato `AAAA-MM`): convertida para uma data Excel real (dia 1 do mês), com
  formato `yyyy-mm` — nunca dependente do idioma do Excel de quem abre o arquivo (evita nomes de mês
  localizados ambíguos), mas ainda assim um tipo de data de verdade (serial number), nunca uma string.
- **Moeda** (`revenueNet`, `revenueGross`, `averageTicket`): número real, formatado como `"R$" #,##0.00`
  (pt-BR) ou `"$" #,##0.00` (en-US) conforme a localidade escolhida.
- **Percentual** (`averageDiscount`, `<metrica>ChangePercent`): a agregação já devolve um percentual em
  unidade "humana" (ex.: `12,34` significando 12,34%) — convertido para a fração `0,1234` antes de
  escrever a célula, porque o formato `%` do Excel multiplica por 100 na exibição; sem essa conversão o
  valor apareceria como `1234,00%`.
- **Número** (`orderCount`, `itemQuantity`, `piecesPerOrder`): inteiro ou decimal reais, nunca texto.
- **Texto** (`customer`, `product`, `seller`, etc.): mantido como está.

## RBAC e volume

- Idênticos à TASK-146 — nenhuma lógica nova de autorização foi criada: `Capability.reportExport`
  (Dart) e `assertCanExportReports`/`REPORT_EXPORT_ROLES` (Cloud Function) foram **extraídos para
  `functions/src/reports/export-shared.ts`** e reaproveitados por `exportReportToCsv` e
  `exportReportToXlsx` — a task pedia explicitamente para "reaproveitar... não duplicar lógica de
  exportação assíncrona". O mesmo módulo compartilhado também reúne `MAX_EXPORTABLE_ROWS` (teto duro de
  200.000 linhas), `EXPORT_LINK_TTL_MS` (24h) e `buildExportFileName` (agora parametrizado por
  `extension`, em vez de fixo em `.csv`).
- `exportReportToXlsx` nunca recebe nem confia num resultado ou catálogo computado pelo cliente: chama
  `runReportAggregation` de novo (a mesma função já reaproveitada por `executeReportQuery` e
  `exportReportToCsv`) e resolve seu próprio catálogo via `catalogForRole(member.roleName)`.
- `storage.rules` não precisou de nenhuma alteração: o path
  `organizations/{organizationId}/exports/{userId}/{fileName}` já era genérico a qualquer extensão de
  arquivo (confirmado lendo a regra e os testes existentes em `storage-tests/storage.rules.test.js`,
  que já cobrem esse path independentemente do nome do arquivo).

## Arquitetura (Flutter)

Domain (sem Flutter/Firebase):
- `domain/entities/report_export_result.dart` — novo `ReportExportFormat` (csv/xlsx), usado pelo
  evento `ReportExportRequested` para escolher qual caso de uso a BLoC dispara.
- `domain/services/report_column_value_type_resolver.dart` — `ReportColumnValueTypeResolver` (ver
  acima).
- `domain/services/xlsx_report_encoder.dart` — `XlsxReportEncoder`, encoder XLSX puro (usa `excel` +
  pós-processamento `archive`/`xml` para congelar cabeçalho e aplicar AutoFilter — ver decisão técnica
  acima). Produz uma planilha válida mesmo sem linhas (apenas cabeçalho).
- `domain/repositories/report_export_repository.dart` — ganhou `encodeXlsx` e
  `requestCloudXlsxExport`, ao lado dos métodos de CSV já existentes (mesma interface, não uma nova).
- `domain/usecases/export_report_to_xlsx.dart` — `ExportReportToXlsx`, mesma estrutura de
  `ExportReportToCsv`: decide a rota por `maxLocalRows`, nunca falha silenciosamente.

Data:
- `data/datasources/xlsx_isolate_encoder.dart` — `XlsxIsolateEncoder`/`FlutterXlsxIsolateEncoder`,
  único ponto que importa `package:flutter/foundation.dart` (`compute`) para XLSX, espelhando
  `CsvIsolateEncoder`.
- `data/datasources/report_file_saver_data_source.dart` — generalizado: `mimeType`/`allowedExtensions`
  agora são inferidos da extensão do próprio `fileName` (mapa `csv -> text/csv`,
  `xlsx -> application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`), em vez de assumir CSV
  fixo — pronto também para a TASK-148 (PDF) só precisar de uma nova entrada no mapa.
- `data/datasources/report_export_remote_data_source.dart` +
  `cloud_functions_report_export_remote_data_source.dart` — ganharam `exportXlsx`, chamando a nova
  Cloud Function `exportReportToXlsx`.
- `data/repositories/report_export_repository_impl.dart` — implementa os dois métodos novos da
  interface, injetando `XlsxIsolateEncoder` ao lado do `CsvIsolateEncoder` já existente.

Presentation:
- `presentation/bloc/report_builder_event.dart` — `ReportExportRequested` ganhou `format`
  (`ReportExportFormat`, default `csv` — nenhum call site existente quebrou).
- `presentation/bloc/report_builder_bloc.dart` — injeta `ExportReportToXlsx`; `_onExport` escolhe o
  caso de uso pelo `event.format` e loga `AnalyticsEvents.reportExported` com
  `formato: event.format.name` (`'csv'` ou `'xlsx'`).
- `presentation/pages/report_builder_page.dart` — novo botão "Exportar XLSX"
  (`Key('export-report-xlsx')`) ao lado do "Exportar CSV" existente, mesmo gate de RBAC via
  `PermissionBuilder`/`Capability.reportExport`.

## Cloud Functions

- `functions/src/reports/export-shared.ts` (novo) — RBAC (`REPORT_EXPORT_ROLES`/
  `assertCanExportReports`), `MAX_EXPORTABLE_ROWS`, `EXPORT_LINK_TTL_MS`, `ExportLocale`/
  `parseExportLocale` e `buildExportFileName` (agora com `extension` explícito) — extraídos de
  `export-report-to-csv.ts` para serem reaproveitados por `export-report-to-xlsx.ts` sem duplicação.
  `export-report-to-csv.ts` reexporta `assertCanExportReports`/`buildExportFileName` para não quebrar
  o teste já existente.
- `functions/src/reports/export-report-to-xlsx.ts` (novo) — callable `exportReportToXlsx`: valida
  auth/Membership/empresa exatamente como `executeReportQuery`/`exportReportToCsv`, aplica
  `assertCanExportReports`, roda `runReportAggregation`, aplica o mesmo teto de 200.000 linhas, resolve
  o catálogo do papel (`catalogForRole`), gera o XLSX (`rowsToXlsxBuffer`, via `exceljs`: cabeçalho em
  negrito, congelado, `AutoFilter`, tipos de célula reais) e grava em
  `organizations/{organizationId}/exports/{uid}/{fileName}` via Admin SDK, devolvendo um
  `getSignedUrl` de 24h.
- `functions/src/reports/index.ts` / `functions/src/index.ts` — `exportReportToXlsx` registrada e
  exportada.
- `functions/test/reports/export-report-to-xlsx.test.ts` (novo) — testes unitários puros (sem
  emulador): RBAC, `resolveColumnValueType` (direto/`Comparison`/`ChangePercent`/fallback), geração
  XLSX (tipos de célula reais via releitura com `exceljs`, planilha válida sem linhas, valor nulo,
  cabeçalho congelado + `AutoFilter`).
- `functions/test/reports/export-report-to-csv.test.ts` — ajustado para o novo parâmetro obrigatório
  `extension` de `buildExportFileName`; adicionado um teste confirmando que CSV e XLSX produzem o
  mesmo nome-base variando apenas a extensão.
- `functions/package.json` — nova dependência `exceljs: ^4.4.0`.

## Testes executados

- `cd functions && npm run build` — TypeScript compila sem erros.
- `cd functions && npm run lint` — ESLint sem apontamentos.
- `cd functions && npm test -- reports` — 26/26 testes passando (`report-catalog`,
  `execute-report-query`, `export-report-to-csv`, `export-report-to-xlsx`).
- `cd functions && npm test` (suíte completa) — os testes de `reports/*` passam integralmente; as
  falhas observadas (`invites/*`, `orders/*`, `catalog/*`, `admin/*`, `create-organization`,
  `aggregations/*.emulator.test.ts`) são pré-existentes e dependem do Firebase Emulator Suite
  (Firestore/Auth), indisponível neste ambiente — mesma limitação já registrada na conclusão da
  TASK-146.
- `flutter analyze` (projeto inteiro) — 0 erros; apenas *infos* de depreciação pré-existentes (Radio
  deprecado em `report_builder_page.dart`, já mencionadas na TASK-146) e de outras features, não
  relacionadas a esta task.
- `flutter test test/features/reports` — 69/69 testes passando, incluindo os novos:
  `report_column_value_type_resolver_test.dart`, `xlsx_report_encoder_test.dart`,
  `export_report_to_xlsx_test.dart`, e os novos casos em `report_builder_bloc_test.dart`/
  `report_builder_page_test.dart`.
- `flutter test` (suíte completa do projeto) — **2789/2789 testes passando**, confirmando que nenhuma
  outra feature quebrou com a adição das dependências `excel`/`archive`/`xml` ou com a extensão da
  interface `ReportExportRepository`.
- `dart format --output=none --set-exit-if-changed` nos arquivos tocados — 0 arquivos precisando de
  formatação.
- `dart run build_runner build` — regenerou `lib/app/injection.config.dart` com o registro das novas
  classes injetáveis (`ExportReportToXlsx`, `FlutterXlsxIsolateEncoder`) e o novo parâmetro do
  `ReportExportRepositoryImpl`; nenhuma outra mudança funcional nesse arquivo gerado. Quatro arquivos
  `*.freezed.dart` de features não relacionadas (`settings`, `users`) foram regenerados como efeito
  colateral do build global (apenas diferenças cosméticas de BOM/espaço em branco, sem mudança de
  código) — **revertidos** para manter o diff desta task restrito ao escopo de TASK-147.

## Pendências / riscos conhecidos

- `exportReportToXlsx` ainda não foi implantada (`firebase deploy --only functions`) nem testada
  contra o Firestore/Storage reais — apenas compilada e coberta por testes unitários puros, mesma
  situação já registrada para `exportReportToCsv` na TASK-146.
- O botão "Exportar XLSX" mostra apenas uma mensagem textual (`SnackBar`) para o caso remoto — mesma
  limitação já registrada na TASK-146 (não há tela dedicada de "central de exportações"/`url_launcher`
  no projeto ainda).
- `npm audit` aponta uma vulnerabilidade `moderate` transitiva trazida por `exceljs` (`uuid`); como
  documentado na seção de decisão técnica acima, a mesma advisory já existe em múltiplas outras
  dependências da árvore vindas do `firebase-admin`, então não foi tratada nesta task.
- O formato numérico de "número" no XLSX (`#,##0.##` no lado servidor, `NumFormat.standard_3`/`_4` no
  lado cliente) não é byte-a-byte idêntico entre as duas rotas (local vs. Cloud Function) — ambos
  ainda assim satisfazem o critério de aceite de "tipo de célula correto, nunca texto"; uma eventual
  unificação exata do formato de exibição fica para uma iteração futura, se algum usuário reportar
  inconsistência visual entre os dois caminhos.
