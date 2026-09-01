# TASK-122 - Implementar insight de cliente inativo (CONCLUIDA)

**Epic:** EPIC-16 - Insights e Recomendacao  
**Status:** Concluida  
**Data:** terça-feira, 1 de setembro de 2026  
**Branch:** `main`

## O que foi feito

- Implementei `InactiveCustomerInsightRule` no dominio Flutter e sua contraparte server-side em TypeScript, ambas plugadas na engine criada na TASK-121.
- A regra consome apenas snapshots agregados, compara `asOf - lastOrderAt` com threshold configuravel por organizacao e override por segmento, e ignora clientes sem historico de pedido ou desativados administrativamente.
- A evidencia gerada inclui data do ultimo pedido, valor do ultimo pedido, ticket medio historico e dias corridos sem compra.
- O impacto estimado foi modelado como o ticket medio historico do cliente, com severidade graduada pelo tempo acima do threshold.
- Configurei a `quickAction` principal como `scheduleContact` e uma acao secundaria `openCustomer`, ambas tipadas e prontas para consumo pela futura central de oportunidades.
- Cobri a regra com testes de borda para limite exato, abaixo e acima do threshold, alem de cenarios sem historico e cliente inativo.

## Arquivos criados ou alterados

- `lib/features/insights/domain/rules/inactive_customer_insight_rule.dart`
- `functions/src/insights/inactive-customer-insight-rule.ts`
- `test/features/insights/domain/rules/inactive_customer_insight_rule_test.dart`
- `lib/features/insights/insight_module.dart`
- `docs/tasks/TASK-122-implementar-insight-de-cliente-inativo-CONCLUIDA.md` (este arquivo)
- `docs/tasks/TASKS.md`

## Validacoes executadas

- `flutter test test/features/insights` - sucesso, incluindo os cenarios de cliente inativo.
- `npm test -- --runInBand insights` em `functions/` - sucesso.
- `flutter analyze` - sucesso, sem issues.

## Decisoes e riscos conhecidos

- A task pedia acao de contato reaproveitando CRM. Nesta entrega a acao ficou tipada e contextualizada para o fluxo de CRM, sem ainda disparar UI ou persistencia de atividade por si so; essa integracao fica naturalmente para a central de oportunidades/TASK-132.
- O escopo de visibilidade foi resolvido pela atribuicao de `recipientUserId` ao vendedor responsavel no snapshot agregado. A leitura gerencial por equipe depende da futura camada de consulta/central, nao da regra em si.

## Commit

- Commit local desta task: `feat(insights): implementa insight de cliente inativo`

## Push

- Nenhum push foi realizado nesta sessao, conforme solicitado.
