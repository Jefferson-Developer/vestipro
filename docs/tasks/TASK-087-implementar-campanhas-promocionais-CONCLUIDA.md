# TASK-087 — Concluída (2026-08-27)

## Resumo

A TASK-087 foi implementada na feature `pricing` com campanhas promocionais por vigência, segmento e escopo de produto, resolução determinística por prioridade/empilhamento, auditoria administrativa e contrato de origem do desconto pronto para o resumo comercial e para o motor server-side da TASK-088.

## Agentes utilizados

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-commercial-ops-strategist`

## Arquivos criados

- `lib/features/pricing/domain/value_objects/promotional_campaign_status.dart`
- `lib/features/pricing/domain/value_objects/promotional_discount_type.dart`
- `lib/features/pricing/domain/entities/promotional_campaign.dart`
- `lib/features/pricing/domain/entities/applied_promotional_campaign.dart`
- `lib/features/pricing/domain/entities/promotional_campaign_resolution.dart`
- `lib/features/pricing/domain/repositories/promotional_campaign_repository.dart`
- `lib/features/pricing/data/repositories/shared_preferences_promotional_campaign_repository.dart`
- `lib/features/pricing/domain/usecases/create_promotional_campaign_use_case.dart`
- `lib/features/pricing/domain/usecases/update_promotional_campaign_use_case.dart`
- `lib/features/pricing/domain/usecases/resolve_applicable_campaigns_use_case.dart`
- `lib/features/pricing/presentation/cubit/promotional_campaign_state.dart`
- `lib/features/pricing/presentation/cubit/promotional_campaign_cubit.dart`
- `lib/features/pricing/presentation/pages/promotional_campaigns_page.dart`
- `lib/features/pricing/presentation/widgets/pricing_adjustment_origin_card.dart`
- `test/features/pricing/domain/usecases/resolve_applicable_campaigns_use_case_test.dart`
- `test/features/pricing/presentation/pages/promotional_campaigns_page_test.dart`
- `test/features/pricing/presentation/widgets/pricing_adjustment_origin_card_test.dart`
- `docs/tasks/TASK-087-implementar-campanhas-promocionais-CONCLUIDA.md`

## Arquivos alterados

- `docs/tasks/TASKS.md`
- `lib/features/audit_log/domain/value_objects/audit_action.dart`
- `lib/features/audit_log/presentation/presenters/audit_log_presenter.dart`
- `lib/features/pricing/pricing.dart`

## Arquitetura utilizada

Estrutura feature-first com Clean Architecture em `features/pricing`, centralizando campanha promocional como conceito de domínio independente do catálogo visual. A resolução de elegibilidade ficou encapsulada em um use case tipado, preparado para reuso pela futura composição server-side.

## Regras de negócio implementadas

- Campanha exige vigência válida, segmento de cliente e ao menos um escopo elegível entre produto, coleção ou categoria.
- Campanhas ativas e vigentes são filtradas por segmento e escopo do produto.
- Quando há campanhas não empilháveis, a maior prioridade vence de forma determinística; empate é desempatado por `id`.
- Quando todas as campanhas elegíveis são empilháveis, todas são preservadas no resultado.
- A decisão adotada nesta task é que desconto de campanha é uma origem separada do desconto manual do vendedor; o limite por perfil continua validando apenas o desconto manual.
- O contrato `AppliedPromotionalCampaign` mantém `campaignId`, nome, tipo, valor e motivo, preparando a rastreabilidade por item no pedido.

## Regras Firebase implementadas

Nenhuma regra Firebase nova nesta task. Os contratos foram preparados para compor o cálculo definitivo da TASK-088.

## Analytics implementado

Nenhum evento novo de Analytics nesta task.

## Crashlytics implementado

Nenhuma instrumentação nova de Crashlytics nesta task.

## Impacto offline

As campanhas promocionais seguem o mesmo padrão local temporário em `SharedPreferences` já usado na feature `pricing`, sem quebrar o comportamento offline atual.

## Impacto multi-tenant

As campanhas permanecem sempre escopadas por `organizationId` e `companyId`, e a resolução busca apenas dados da mesma empresa/tenant.

## Testes criados

- `test/features/pricing/domain/usecases/resolve_applicable_campaigns_use_case_test.dart`
- `test/features/pricing/presentation/pages/promotional_campaigns_page_test.dart`
- `test/features/pricing/presentation/widgets/pricing_adjustment_origin_card_test.dart`

## Comandos executados

```bash
rg -n "TASK-087|TASK-088|Progresso:" docs/tasks/TASKS.md
rg -n "segment|customer segment|segmento|collectionId|categoryId|product scope|productScope" lib/features/customers lib/features/products lib/features/catalog test
Get-Content -Raw lib/features/customers/domain/entities/customer_segment.dart
Get-Content -Raw lib/features/customers/domain/entities/customer_segment_criteria.dart
Get-Content -Raw lib/features/products/domain/entities/product.dart
Get-Content -Raw lib/features/catalog/presentation/pages/campaign_form_page.dart
dart format lib/features/pricing lib/features/audit_log test/features/pricing
flutter test test/features/pricing/domain/usecases/resolve_applicable_campaigns_use_case_test.dart test/features/pricing/presentation/widgets/pricing_adjustment_origin_card_test.dart test/features/pricing/presentation/pages/promotional_campaigns_page_test.dart
```

## Resultado do formatter

`dart format` executado com sucesso nos arquivos afetados.

## Resultado do analyzer

Não executado nesta task.

## Resultado dos testes

Os 8 testes focados executados para a TASK-087 passaram com sucesso.

## Decisões técnicas

- Campanhas promocionais entraram em `pricing`, não em `catalog`, para refletir sua natureza comercial e facilitar o reuso no cálculo server-side.
- O desempate entre campanhas não empilháveis usa prioridade descendente e `id` ascendente para manter reprodutibilidade.
- O resumo comercial futuro ganhou um widget simples de origem dos descontos para explicitar campanha versus desconto manual.
- Foram adicionadas ações de auditoria específicas para criação, edição e encerramento de campanha promocional.

## Riscos conhecidos

- A persistência remota definitiva ainda não existe.
- Não houve `flutter analyze` nesta task.
- A gravação real do `campaignId` no item de pedido dependerá da modelagem de pedidos e da composição final da TASK-088/TASK-095.

## Pendências

- Integrar a resolução de campanhas ao motor definitivo da TASK-088.
- Persistir a origem no item real do pedido quando a estrutura de `OrderItem` estiver implementada.

## Evidências

- Domínio: `promotional_campaign.dart`, `applied_promotional_campaign.dart`, `promotional_campaign_resolution.dart`
- Use cases: `create_promotional_campaign_use_case.dart`, `update_promotional_campaign_use_case.dart`, `resolve_applicable_campaigns_use_case.dart`
- UI administrativa: `promotional_campaigns_page.dart`
- Resumo de origem: `pricing_adjustment_origin_card.dart`
- Auditoria: ações novas em `audit_action.dart` e labels no presenter

## Commit

Pendente nesta etapa da documentação; será preenchido após o commit local.

## Push

Não autorizado nesta conversa.

## Hash do commit

Pendente nesta etapa da documentação.

## Branch

`main`
