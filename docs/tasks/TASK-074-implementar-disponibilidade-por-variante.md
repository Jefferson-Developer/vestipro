# TASK-074 — Implementar disponibilidade por variante

**Epic:** EPIC-09 — Cores, Grades e Variantes
**Status:** ⬜ Pendente
**Depende de:** TASK-072 (Implementar geração de variantes produto-cor-tamanho) — disponibilidade é sempre exibida por variante já gerada.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Exibir estoque por cor/tamanho diferenciando pronta entrega, estoque futuro e indisponível. Esta task consumirá o saldo real de estoque quando o EPIC-12 (TASK-090 — Implementar saldo por variante) existir; até lá, modelar o contrato de disponibilidade de forma estável mesmo com fonte de dado inicial simplificada, para não exigir retrabalho de UI depois.

## Escopo técnico

- Definir contrato de domínio `VariantAvailability` (`variantId`, status `prontaEntrega`/`estoqueFuturo`/`indisponivel`, quantidade disponível opcional, data prevista quando estoque futuro), independente da fonte concreta de dado.
- Implementar fonte inicial simplificada (ex.: campo de disponibilidade manual no cadastro de variante) documentando explicitamente que será substituída pelo saldo real de estoque quando TASK-090 existir.
- Criar `GetVariantAvailabilityUseCase` consumido tanto pela grade comercial (TASK-073) quanto pelo catálogo (EPIC-10), com uma única fonte de verdade de contrato.
- Implementar UI exibindo os três estados (pronta entrega, futuro com data prevista, indisponível) de forma visualmente consistente entre catálogo e grade comercial.

## Regras de negócio e restrições

- Nenhuma tela deve calcular disponibilidade por conta própria — sempre consumir o caso de uso/contrato central `GetVariantAvailabilityUseCase`.
- Enquanto a fonte de dado real (TASK-090) não existir, o contrato `VariantAvailability` deve permanecer estável, para não exigir retrabalho de UI ao trocar a fonte no futuro.
- O estado "indisponível" nunca deve ser omitido silenciosamente — a variante continua visível, apenas marcada como indisponível.

## Testes obrigatórios

- Testes unitários do contrato `VariantAvailability` e do mapeamento dos três estados.
- Testes do caso de uso com a fonte simplificada, cobrindo os três estados e ausência de dado (fallback seguro).
- Teste de widget garantindo que catálogo e grade comercial exibem o mesmo estado para a mesma variante.
- Teste de regressão documentando o ponto de substituição futuro por TASK-090 (teste de contrato, não implementação de estoque real).

## Critérios de aceite

- Contrato de disponibilidade modelado e estável, pronto para receber a fonte real de estoque no futuro sem retrabalho de UI.
- Três estados (pronta entrega, futuro, indisponível) exibidos de forma consistente entre grade comercial e catálogo.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
