# TASK-099 — Implementar resumo comercial do pedido

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-096 — Implementar pedido em rascunho (resumo exibe os totais do rascunho atual); TASK-088 — Implementar motor de precificação server-side (fonte única de verdade dos valores exibidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Exibir subtotal, desconto, acréscimo, frete e total do pedido em elaboração, sempre refletindo exatamente o que o motor de precificação (TASK-088) retorna — nunca um cálculo divergente feito apenas na interface.

## Escopo técnico

- Criar caso de uso `GetOrderPricingSummary` que invoca o motor de precificação server-side (Cloud Function idempotente da TASK-088) com os itens atuais do rascunho, retornando subtotal, descontos aplicados (com origem/motivo), acréscimos, frete, impostos quando aplicável e total.
- Criar (ou reaproveitar, se já existir) o componente de resumo comercial no Design System, exibindo cada linha (subtotal, desconto, acréscimo, frete, total) sempre alinhada ao retorno do backend.
- Tratar o estado de "recalculando" (enquanto aguarda resposta do motor de precificação) sem travar a interação do vendedor com o restante do pedido.
- Tratar falha de comunicação com o motor de precificação (offline): exibir claramente que o total apresentado é uma estimativa local pendente de confirmação, nunca como valor definitivo.

## Regras de negócio e restrições

- A UI nunca calcula desconto/acréscimo/frete/total por conta própria — sempre exibe exatamente o que a Cloud Function de precificação retornou.
- Quando offline, o resumo deve deixar explícito que o valor exibido ainda não foi confirmado pelo motor de precificação (rascunho ainda não sincronizado).
- Qualquer desconto acima do limite do perfil do vendedor deve ser sinalizado no resumo (indicando que exigirá aprovação — ver TASK-103), nunca escondido.

## Testes obrigatórios

- Teste de caso de uso cobrindo resposta bem-sucedida, erro de rede e resposta com desconto acima do limite do perfil.
- Teste de widget garantindo que a UI reflete exatamente os valores retornados pelo mock do motor de precificação, sem divergência de arredondamento/cálculo local.
- Teste de estado offline exibindo o aviso de valor não confirmado.
- Teste de acessibilidade garantindo que valores e status (ex.: "recalculando") sejam anunciados por leitor de tela.

## Critérios de aceite

- Resumo comercial sempre reflete exatamente o retorno do motor de precificação, sem cálculo divergente na UI.
- Estados de recalculando, sucesso, offline e erro tratados de forma clara para o vendedor.
- Descontos acima do limite do perfil sinalizados visualmente no resumo.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
