# TASK-085 — Concluída (2026-08-27)

## Resumo

A implementação de condições de pagamento já está presente no workspace do VestiPro, cobrindo domínio, repositórios, casos de uso, persistência offline, tela administrativa e seletor de condição de pagamento. Esta documentação registra a conclusão da TASK-085 com base na inspeção do código e dos testes já existentes.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Arquivos criados

- `lib/core/database/tables/payment_terms_table.dart`
- `lib/features/pricing/domain/entities/payment_installment.dart`
- `lib/features/pricing/domain/entities/payment_term.dart`
- `lib/features/pricing/domain/repositories/payment_term_local_store_repository.dart`
- `lib/features/pricing/domain/repositories/payment_term_repository.dart`
- `lib/features/pricing/domain/usecases/create_payment_term_use_case.dart`
- `lib/features/pricing/domain/usecases/list_active_payment_terms_use_case.dart`
- `lib/features/pricing/domain/usecases/update_payment_term_use_case.dart`
- `lib/features/pricing/domain/value_objects/payment_term_status.dart`
- `lib/features/pricing/domain/value_objects/payment_term_sync_status.dart`
- `lib/features/pricing/data/mappers/payment_term_local_mapper.dart`
- `lib/features/pricing/data/repositories/drift_payment_term_local_store_repository.dart`
- `lib/features/pricing/data/repositories/shared_preferences_payment_term_repository.dart`
- `lib/features/pricing/presentation/cubit/payment_terms_cubit.dart`
- `lib/features/pricing/presentation/cubit/payment_terms_state.dart`
- `lib/features/pricing/presentation/pages/payment_terms_page.dart`
- `lib/features/pricing/presentation/widgets/payment_term_selector.dart`
- `test/features/pricing/data/repositories/drift_payment_term_local_store_repository_test.dart`
- `test/features/pricing/domain/usecases/create_payment_term_use_case_test.dart`
- `test/features/pricing/domain/usecases/list_active_payment_terms_use_case_test.dart`
- `test/features/pricing/domain/usecases/update_payment_term_use_case_test.dart`
- `test/features/pricing/presentation/pages/payment_terms_page_test.dart`
- `docs/tasks/TASK-085-implementar-condicoes-de-pagamento-CONCLUIDA.md`

## Arquivos alterados

- `docs/tasks/TASKS.md`
- `lib/app/injection.config.dart`
- `lib/core/database/app_database.dart`
- `lib/core/database/app_database.g.dart`
- `lib/core/database/database.dart`
- `lib/core/navigation/active_organization_guard.dart`
- `lib/features/audit_log/domain/value_objects/audit_action.dart`
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart`
- `lib/features/pricing/pricing.dart`

## Arquitetura utilizada

Estrutura feature-first com Clean Architecture em `features/pricing`, separando entidade de domínio (`PaymentTerm`, `PaymentInstallment`), contratos de repositório, casos de uso, camada de dados e apresentação com Cubit. A persistência offline foi ligada ao schema Drift e a DI foi registrada em `lib/app/injection.config.dart`.

## Regras de negócio implementadas

- Condição de pagamento possui `organizationId`, `companyId`, nome, parcelas, status, prazo médio e restrições opcionais por `priceListIds`.
- O prazo médio é derivado das parcelas, evitando entrada manual divergente.
- A criação e a edição validam inconsistências como soma de percentuais diferente de 100%, ausência de parcelas e prazos inválidos.
- O seletor para pedido expõe somente condições ativas e compatíveis com a tabela de preço selecionada.
- Condições inativas continuam representáveis para histórico, mas não entram como opção para novos fluxos compatíveis.

## Regras Firebase implementadas

Nenhuma regra Firebase específica foi identificada nesta implementação. O escopo encontrado está concentrado em domínio, UI e persistência local.

## Analytics implementado

Nenhuma instrumentação de Analytics específica foi identificada durante a inspeção.

## Crashlytics implementado

Nenhuma instrumentação de Crashlytics específica foi identificada durante a inspeção.

## Impacto offline

As condições de pagamento foram integradas ao armazenamento local com Drift por meio de `PaymentTermsTable`, `PaymentTermLocalMapper` e `DriftPaymentTermLocalStoreRepository`, permitindo carga offline e atualização incremental no cache local.

## Impacto multi-tenant

O modelo e os repositórios carregam `organizationId` e `companyId`, preservando escopo por tenant e por empresa no armazenamento e na listagem.

## Testes criados

Os seguintes testes já existem no workspace para esta task:

- `test/features/pricing/domain/usecases/create_payment_term_use_case_test.dart`
- `test/features/pricing/domain/usecases/list_active_payment_terms_use_case_test.dart`
- `test/features/pricing/domain/usecases/update_payment_term_use_case_test.dart`
- `test/features/pricing/data/repositories/drift_payment_term_local_store_repository_test.dart`
- `test/features/pricing/presentation/pages/payment_terms_page_test.dart`

## Comandos executados

```bash
rg -n "TASK-085|085" docs/tasks/TASKS.md docs/tasks -g "TASK-085*"
Get-Content -Raw docs/tasks/TASK-085-implementar-condicoes-de-pagamento.md
Get-Content -Raw AGENTS.md
Get-Content -Raw .claude/agents/flutter-senior-architect.md
Get-Content -Raw .claude/agents/flutter-ui-design-specialist.md
rg -n "PaymentTerm|payment term|payment_term|condição de pagamento|paymentTerms|payment_terms" lib test docs/tasks tasks.md
git status --short --branch
Get-ChildItem -Recurse lib/features/pricing/domain
Get-ChildItem -Recurse lib/features/pricing/presentation
Get-ChildItem -Recurse test/features/pricing
rg -n "Progresso:" docs/tasks/TASKS.md
rg -n "payment_terms|PaymentTermsTable|payment term|payment_term" lib/core/database lib/app lib/features/audit_log lib/core/navigation
```

## Resultado do formatter

Não executado nesta rodada de documentação.

## Resultado do analyzer

Não executado nesta rodada de documentação.

## Resultado dos testes

Não executados nesta rodada de documentação. A evidência disponível é a presença dos arquivos de teste ligados ao escopo da TASK-085 no workspace atual.

## Decisões técnicas

- Reuso da feature `pricing` para concentrar tabelas de preço e condições comerciais no mesmo domínio.
- Uso de Cubit para a tela administrativa de CRUD de condições de pagamento.
- Persistência local baseada em Drift para suportar offline e sincronização futura.
- Auditoria administrativa conectada ao módulo de `audit_log` por meio das dependências já presentes no projeto.

## Riscos conhecidos

- A conclusão foi documentada por inspeção do workspace, sem execução retrospectiva de formatter, analyzer ou testes nesta rodada.
- O `git status` atual mostra alterações locais e arquivos ainda não commitados relacionados à implementação de payment terms.
- A integração completa com a tela de pedido da EPIC-13 pode depender de tasks posteriores do fluxo de pedidos.

## Pendências

- Realizar commit da implementação e da documentação quando desejado.
- Executar formatter, analyzer e testes se for necessário validar formalmente o estado atual antes do commit.

## Evidências

- Entidade de domínio presente em `lib/features/pricing/domain/entities/payment_term.dart`.
- Casos de uso presentes em `lib/features/pricing/domain/usecases/create_payment_term_use_case.dart`, `list_active_payment_terms_use_case.dart` e `update_payment_term_use_case.dart`.
- Tela administrativa presente em `lib/features/pricing/presentation/pages/payment_terms_page.dart`.
- Seletor de condição de pagamento presente em `lib/features/pricing/presentation/widgets/payment_term_selector.dart`.
- Persistência offline presente em `lib/core/database/tables/payment_terms_table.dart` e `lib/features/pricing/data/repositories/drift_payment_term_local_store_repository.dart`.
- Cobertura de testes presente em `test/features/pricing/domain/usecases/*payment_term*` e `test/features/pricing/presentation/pages/payment_terms_page_test.dart`.

## Commit

Não executado nesta rodada.

## Push

Não executado nesta rodada.

## Hash do commit

Não há hash para informar nesta rodada.

## Branch

`main`
