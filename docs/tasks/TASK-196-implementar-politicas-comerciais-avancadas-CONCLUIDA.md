# TASK-196 — Concluida (2026-09-09)

## Resumo
Implementado motor de politicas comerciais avancadas dentro da pipeline unica de precificacao server-side. A entrega modela `CommercialRule`, aplica regras por cliente/segmento/produto/categoria/colecao/canal/vigencia/volume/combo, resolve prioridade deterministica, retorna trilha auditavel por regra e inclui callable de simulacao administrativa sem persistir efeitos em pedidos, clientes, cache de precificacao ou regras reais.

## Agentes utilizados
- flutter-senior-architect
- vestipro-commercial-ops-strategist
- flutter-ui-design-specialist, como checklist, porque a spec exige simulacao administrativa

## Arquivos criados
- `docs/tasks/TASK-196-implementar-politicas-comerciais-avancadas-CONCLUIDA.md`

## Arquivos alterados
- `functions/src/pricing/pricing-engine.ts`
- `functions/src/pricing/calculate-pricing.ts`
- `functions/src/pricing/index.ts`
- `functions/src/index.ts`
- `functions/src/orders/submit-order.ts`
- `functions/test/pricing/pricing-engine.test.ts`
- `functions/test/pricing/calculate-pricing.test.ts`
- `firestore.rules`
- `docs/tasks/TASKS.md`

## Arquitetura utilizada
Foi preservada a fonte unica de verdade no `calculatePricingEngine`. `calculatePricing`, `simulateCommercialRule` e `submitOrder` chamam o mesmo engine, sem criar motor paralelo. A simulacao usa a mesma funcao pura, mas nao grava cache idempotente nem documentos reais.

## Regras de negocio implementadas
- `CommercialRule` generica com tipo, status, prioridade, escopo de empresa, vigencia, condicoes e efeito.
- Condicoes por cliente, segmento, produto, colecao, categoria, canal, quantidade minima e combo de produtos.
- Efeitos de percentual, valor fixo e condicao de pagamento.
- Precedencia deterministica: preco-base, campanhas promocionais, regras comerciais avancadas por prioridade/ID, desconto manual validado por politica, condicao de pagamento e frete.
- Regra expirada ou inativa nao e aplicada.
- Regra de canal diferente nao e aplicada.
- Regra nao empilhavel de maior prioridade vence regras sobrepostas.
- Desconto total do pedido passa a incluir campanhas, regras comerciais avancadas e desconto manual.

## Regras Firebase implementadas
- Nova colecao `organizations/{organizationId}/commercialRules/{ruleId}` em `firestore.rules`.
- Leitura restrita a OWNER/ADMIN, SALES_MANAGER ou `finance.manage`.
- Escrita direta pelo cliente negada; aplicacao e simulacao ficam em Cloud Functions com Admin SDK e RBAC server-side.

## Analytics implementado
Nao houve novo evento de Analytics no app Flutter. As Cloud Functions registram logs estruturados com totais de regras comerciais no fluxo de precificacao.

## Crashlytics implementado
Nao aplicavel; alteracao concentrada em Cloud Functions e rules.

## Impacto offline
Sem impacto offline direto. O cliente continua exibindo estimativas/resultado vindo do motor de precificacao; regras avancadas definitivas sao server-side.

## Impacto multi-tenant
Toda regra carregada e validada no escopo `organizations/{organizationId}` e `companyId`. `ensureCompanyScope` foi reutilizado para impedir regra de outra empresa.

## Testes criados
- Testes unitarios de engine para regra unica, sobreposicao por prioridade, regra expirada, canal incompatvel e regressao de campanhas/desconto manual sem regras avancadas.
- Testes callable para carregamento de `commercialRules` reais em `calculatePricing`.
- Teste de simulacao garantindo ausencia de persistencia em `pricingCalculations` e `commercialRules`.

## Comandos executados
- `npm run build`
- `npm test -- --runTestsByPath test/pricing/pricing-engine.test.ts test/pricing/calculate-pricing.test.ts`
- `npm run lint`
- `npm test -- --runTestsByPath test/orders/submit-order.test.ts`
- `git status --short`

## Resultado do formatter
Nao executado; nao houve alteracao Dart/Flutter nesta entrega.

## Resultado do analyzer
Nao executado; nao houve alteracao Dart/Flutter nesta entrega.

## Resultado dos testes
- Build TypeScript: passou.
- Testes focados de pricing: passaram, 2 suites e 19 testes.
- Lint Functions: passou sem erros, com 10 warnings preexistentes fora do escopo.
- `submit-order.test.ts`: nao executavel neste ambiente por falta de credenciais/emulador Firestore (`Could not load the default credentials`) e timeouts decorrentes nos hooks.

## Decisoes tecnicas
- A simulacao administrativa foi implementada como callable `simulateCommercialRule`, usando o mesmo engine server-side e sem persistencia, para preservar a fonte unica de calculo.
- A ordem de precedencia foi mantida compativel com TASK-088 e estendida com uma etapa explicita de regras comerciais avancadas entre campanhas e desconto manual.
- `submitOrder` grava `pricingCommercialRuleTrace`, `commercialRuleDiscountAmount` e `pricingAppliedPaymentTermRuleId` no snapshot do pedido.

## Riscos conhecidos
- A tela administrativa completa de cadastro/operacao de regras comerciais pode ser evoluida em uma task posterior; esta entrega fornece a simulacao callable segura e a base server-side auditavel.
- Testes de `submitOrder` dependem de ambiente Firestore com credenciais/emulador configurado.

## Pendencias
- Integrar uma rota/tela Flutter completa para operadores simularem regras pela UI quando a navegacao administrativa correspondente for priorizada.
- Criar testes de Rules no Emulator para `commercialRules` quando Java/Emulator estiver disponivel.

## Evidencias
- `npm run build`: sucesso.
- `npm test -- --runTestsByPath test/pricing/pricing-engine.test.ts test/pricing/calculate-pricing.test.ts`: sucesso, 19 testes.
- `npm run lint`: sucesso sem erros.

## Commit
Pendente neste momento da criacao do documento; preenchido no commit local da task.

## Push
Nao autorizado.

## Hash do commit
Pendente neste momento da criacao do documento; preenchido apos o commit local.

## Branch
main
