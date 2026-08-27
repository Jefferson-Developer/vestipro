# TASK-088 — Concluída (2026-08-27)

## Resumo

A TASK-088 foi implementada em `functions/src/pricing` com um motor central de composição reutilizável, callable idempotente `calculatePricing`, tolerância explícita de divergência client/server, cache por `idempotencyKey` e logs estruturados para auditoria do cálculo.

## Agentes utilizados

- `flutter-senior-architect`

## Arquivos criados

- `functions/src/pricing/pricing-engine.ts`
- `functions/src/pricing/calculate-pricing.ts`
- `functions/test/pricing/pricing-engine.test.ts`
- `functions/test/pricing/calculate-pricing.test.ts`
- `docs/tasks/TASK-088-implementar-motor-de-precificacao-CONCLUIDA.md`

## Arquivos alterados

- `functions/src/index.ts`
- `functions/src/pricing/index.ts`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada

Cloud Functions v2 com separação entre composição pura (`pricing-engine.ts`) e orquestração Firebase (`calculate-pricing.ts`). A Cloud Function apenas valida contexto/autorização, carrega documentos do tenant, invoca o motor compartilhado e persiste a resposta idempotente.

## Regras de negócio implementadas

- Ordem determinística de composição: preço-base por produto/variante → campanhas promocionais elegíveis → desconto manual validado por política do perfil → etapa de condição de pagamento → total final com frete.
- Campanhas não empilháveis competem por maior prioridade; empate usa `id`.
- Desconto manual acima do limite é bloqueado; acima do limiar de aprovação e dentro do máximo retorna `approvalRequired`.
- A condição de pagamento é validada quanto a status ativo e compatibilidade com a tabela de preço; como a modelagem atual não define ajuste monetário, a etapa permanece explícita com ajuste `0`.
- Divergência entre total informado pelo cliente e total recalculado no servidor fica disponível via `clientTotalDiverged`, usando tolerância de `0.01`.
- Reuso do mesmo `idempotencyKey` com payload diferente retorna erro tipado `already-exists`.

## Regras Firebase implementadas

- Callable `calculatePricing` exige autenticação e membership do usuário em `organizations/{organizationId}/members/{uid}`.
- Price List, Payment Term, itens da tabela, políticas e campanhas são validados no escopo da mesma `companyId` quando esse campo está presente no documento.
- Respostas idempotentes são persistidas em `organizations/{organizationId}/pricingCalculations/{idempotencyKey}`.

## Analytics implementado

Nenhum evento novo de Analytics nesta task.

## Crashlytics implementado

Nenhuma instrumentação nova de Crashlytics nesta task.

## Impacto offline

Nenhum impacto offline direto. O motor server-side consolida a fonte de verdade para submissão futura sem alterar o cálculo local de feedback imediato da UI.

## Impacto multi-tenant

O cálculo lê apenas documentos do tenant solicitado e valida compatibilidade de `companyId`, reduzindo risco de composição cruzada entre empresas da mesma organização.

## Testes criados

- `functions/test/pricing/pricing-engine.test.ts`
- `functions/test/pricing/calculate-pricing.test.ts`

## Comandos executados

```bash
Get-Content functions/src/pricing/index.ts
Get-Content functions/src/pricing/pricing-engine.ts
Get-Content functions/src/pricing/calculate-pricing.ts
npm run build
npx jest test/pricing/pricing-engine.test.ts test/pricing/calculate-pricing.test.ts --runInBand
npm run lint
```

## Resultado do formatter

Não aplicável nesta task TypeScript.

## Resultado do analyzer

`npm run lint` executado com sucesso em `functions`.

## Resultado dos testes

`npm run build` e as 12 asserções das suítes `pricing-engine.test.ts` e `calculate-pricing.test.ts` passaram com sucesso.

## Decisões técnicas

- O motor puro foi mantido desacoplado do Firebase para evitar duas fontes de verdade entre callable e testes.
- A idempotência foi reforçada para corrida concorrente: se outro processo criar o mesmo cache primeiro, a função relê o documento e reutiliza a resposta quando o hash coincide.
- A suíte do callable usa Firestore em memória para ficar executável localmente sem depender de credenciais GCP ou do Emulator Suite já iniciado.
- A checagem de divergência ficou implementada como contrato reutilizável para a submissão de pedido da TASK-101, onde a rejeição no envio será conectada ao fluxo real.

## Riscos conhecidos

- A submissão de pedido ainda não chama `calculatePricing`, porque o fluxo correspondente pertence à TASK-101 e ainda não existe na `functions`.
- A etapa de condição de pagamento hoje apenas valida compatibilidade/status; não há ajuste financeiro porque esse atributo ainda não faz parte da modelagem do domínio.
- Não foi executado teste end-to-end com Firebase Emulator Suite nesta task.

## Pendências

- Integrar `calculatePricing` à função de submissão de pedidos na TASK-101.
- Evoluir a etapa de condição de pagamento caso o domínio passe a modelar juros, desconto financeiro ou acréscimo por prazo.

## Evidências

- Motor compartilhado: `functions/src/pricing/pricing-engine.ts`
- Callable idempotente: `functions/src/pricing/calculate-pricing.ts`
- Export público: `functions/src/pricing/index.ts` e `functions/src/index.ts`
- Cobertura de composição e idempotência: `functions/test/pricing/pricing-engine.test.ts` e `functions/test/pricing/calculate-pricing.test.ts`

## Commit

Pendente nesta etapa da documentação; será preenchido após o commit local.

## Push

Não autorizado nesta conversa.

## Hash do commit

Pendente nesta etapa da documentação.

## Branch

`main`
