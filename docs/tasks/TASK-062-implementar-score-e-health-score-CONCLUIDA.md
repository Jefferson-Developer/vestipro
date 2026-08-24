# TASK-062 - Concluida (2026-08-24)

## Resumo
Implementado score comercial e health score do cliente com formula v1 versionada, persistencia denormalizada no `Customer`, exibicao no detalhe 360 e recalc definitivo por Cloud Function agendada diaria.

## Agentes utilizados
- flutter-senior-architect
- Subagente Averroes em modo somente leitura para checklist da TASK-062

## Arquivos criados
- `lib/features/customers/domain/services/customer_scoring_service.dart`
- `lib/features/customers/domain/value_objects/customer_health_score_band.dart`
- `lib/features/customers/domain/value_objects/customer_score_data_coverage.dart`
- `test/features/customers/domain/services/customer_scoring_service_test.dart`
- `functions/src/customers/customer-scoring-service.ts`
- `functions/src/customers/recalculate-customer-scores.ts`
- `functions/src/customers/index.ts`
- `functions/test/customers/customer-scoring-service.test.ts`
- `docs/tasks/TASK-062-implementar-score-e-health-score-CONCLUIDA.md`

## Arquivos alterados
- `functions/src/index.ts`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/tables/customers_table.dart`
- `lib/features/customers/customers.dart`
- `lib/features/customers/data/dtos/customer_dto.dart`
- `lib/features/customers/data/mappers/customer_local_mapper.dart`
- `lib/features/customers/data/mappers/customer_mapper.dart`
- `lib/features/customers/data/repositories/shared_preferences_customer_repository.dart`
- `lib/features/customers/domain/entities/customer.dart`
- `lib/features/customers/domain/entities/customer.freezed.dart`
- `lib/features/customers/presentation/pages/customer_detail_page.dart`
- `test/core/database/app_database_test.dart`
- `test/features/customers/data/mappers/customer_local_mapper_test.dart`
- `test/features/customers/data/mappers/customer_mapper_test.dart`
- `test/features/customers/data/repositories/shared_preferences_customer_repository_test.dart`
- `test/features/customers/presentation/pages/customer_detail_page_test.dart`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Clean Architecture feature-first: formula pura em servico de dominio, value objects para faixa/cobertura, DTO/mappers na camada data, UI apenas consumindo campos denormalizados e Cloud Function como fonte definitiva server-side.

## Regras de negocio implementadas
- Formula v1 versionada como `customer_score_v1_2026_08_24`.
- Score comercial com sinais de pedido usa RFV simplificado: 40% recencia, 30% frequencia 12m e 30% valor 12m.
- Sem sinais de pedido, o score comercial usa recencia CRM/cadastro, frequencia CRM 90d e frescor cadastral, com teto 60.
- Health score combina recencia, tendencia de receita, recencia CRM e follow-ups vencidos quando dados existem.
- Sem pedido/faturamento, o health score redistribui peso para CRM/cadastro e marca cobertura degradada.
- Health score classifica em `healthy`, `attention` e `risk`.
- Campos persistidos/consumidos: `commercialScore`, `healthScore`, `healthScoreBand`, `scoreUpdatedAt`, `scoreFormulaVersion` e `scoreDataCoverage`.

## Regras Firebase implementadas
- Criada Cloud Function agendada `recalculateCustomerScores`, diaria as 03:00 em `America/Sao_Paulo`.
- A Function percorre `organizations/{organizationId}`, le somente `customers` e `crmActivities` da subcolecao da propria organizacao e ignora documentos cujo `organizationId` nao corresponda.
- Escrita feita por `update` parcial apenas nos campos de score, preservando o restante do documento.
- Nao houve alteracao em Firestore Rules ou Storage Rules.

## Analytics implementado
Nao houve evento novo de analytics nesta task.

## Crashlytics implementado
Nao houve integracao nova com Crashlytics.

## Impacto offline
O `Customer` local preserva os scores em SharedPreferences e na carga offline Drift. O schema Drift subiu para versao 2 com migracao nullable para os campos denormalizados.

## Impacto multi-tenant
O calculo filtra sinais por `organizationId` e `customerId`. A Function evita `collectionGroup`, processa organizacao por organizacao e nao mistura acumuladores entre tenants.

## Testes criados
- Formula Dart cobrindo cliente sem atividade, cliente recente, fallback sem pedidos, RFV com pedidos, faixas de health e isolamento de tenant.
- Formula TypeScript/Functions cobrindo os mesmos limites e update parcial de Firestore.

## Comandos executados
- `dart run build_runner build --delete-conflicting-outputs`
- `dart format --set-exit-if-changed .`
- `flutter analyze`
- `flutter test test/features/customers/domain/services/customer_scoring_service_test.dart test/features/customers/data/mappers/customer_mapper_test.dart test/features/customers/data/mappers/customer_local_mapper_test.dart test/features/customers/data/repositories/shared_preferences_customer_repository_test.dart test/features/customers/presentation/pages/customer_detail_page_test.dart test/core/database/app_database_test.dart`
- `npm run build` em `functions`
- `npm run lint` em `functions`
- `npm test` em `functions`
- `npm test -- test/customers/customer-scoring-service.test.ts` em `functions`
- `flutter test`

## Resultado do formatter
Primeira execucao de `dart format --set-exit-if-changed .` formatou 4 arquivos e retornou exit code 1, como esperado quando ha alteracoes. Execucao final passou: 933 arquivos, 0 alterados.

## Resultado do analyzer
Primeira execucao apontou import ausente/`!` desnecessario na pagina de detalhe, corrigidos. Execucao final: `flutter analyze` sem issues.

## Resultado dos testes
- Suite focada Flutter passou: 25 testes.
- Suite completa Flutter passou: 1311 testes.
- `npm run build` passou.
- `npm run lint` passou.
- Suite nova Functions passou isolada: 7 testes.
- `npm test` completo das Functions falhou em suites antigas que acessam Firestore sem credenciais/emulador local (`Could not load the default credentials`); a suite nova de score passou antes da falha global e tambem isolada.

## Decisoes tecnicas
- `scoreDataCoverage` foi persistido para a TASK-063 diferenciar score com pedidos/CRM de score degradado por ausencia de pedidos.
- O teto de 60 no fallback sem pedidos evita que CRM/cadastro recente pareca evidencia forte de valor comercial.
- A UI 360 exibe badges e metadados, mas nao recalcula formula no cliente.
- A Function usa subcolecoes da organizacao e update parcial para preservar o contrato de tenant e nao sobrescrever campos do cliente.

## Riscos conhecidos
- Enquanto pedidos/faturamento remotos ainda nao existirem, a maior parte dos clientes tera cobertura `crmOnly` ou `registrationOnly`.
- As atividades CRM atuais ainda sao majoritariamente locais; ate a sincronizacao remota, a Function pode nao refletir todas as interacoes criadas offline no app.
- O anchor de receita BRL 50k e provisorio; deve evoluir para percentis por organizacao quando houver volume historico.

## Pendencias
- Integrar sinais reais de pedidos/faturamento quando EPIC-13 estiver disponivel.
- Adicionar testes de emulator para a Function agendada quando o ambiente de Firestore Emulator/credenciais estiver padronizado.

## Evidencias
- Formatter final sem alteracoes pendentes.
- Analyzer final sem issues.
- Suite focada Flutter passou.
- Suite completa Flutter passou com 1311 testes.
- Functions build/lint passaram e a suite nova de score passou isolada.

## Commit
Pendente ate a criacao do commit local desta task.

## Push
Nao autorizado pelo usuario nesta rodada (`sem push`).

## Hash do commit
Pendente ate a criacao do commit local desta task.

## Branch
`main`
