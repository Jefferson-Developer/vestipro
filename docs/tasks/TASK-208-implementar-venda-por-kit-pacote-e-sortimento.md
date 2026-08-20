# TASK-208 — Implementar venda por kit, pacote e sortimento no pedido

**Epic:** EPIC-32 — Operações Comerciais Avançadas de Moda B2B
**Status:** ⬜ Pendente
**Depende de:** TASK-207 (kits/pacotes/sortimentos), TASK-088 (motor de precificação), TASK-090 (saldo por variante), TASK-095 (Order/OrderItem), TASK-097 (adição de produtos ao pedido), TASK-101 (submissão do pedido)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`
- `vestipro-sales-representative-specialist`
- `vestipro-commercial-ops-strategist`

## Objetivo

Permitir que o vendedor adicione kits, pacotes e sortimentos ao pedido com poucos toques, mantendo
explicação clara de composição, preço, desconto, estoque e restrições. O objetivo comercial é aumentar
ticket médio, reduzir erro de grade e acelerar compra recorrente por perfil de loja.

## Escopo técnico

- Exibir pacotes elegíveis no catálogo, detalhe do produto, line sheet e pedido, filtrados por cliente,
  coleção, campanha, tabela de preço e disponibilidade.
- Ao adicionar um pacote, expandir a composição para `OrderItem`s vinculados por `packGroupId`,
  preservando o nome/versão do pacote no snapshot do pedido.
- Integrar ao motor de precificação server-side: preço fechado, desconto de pacote e bonificação são
  sempre calculados/revalidados no servidor.
- Integrar ao estoque: disponibilidade de pacote é a disponibilidade mínima das variantes componentes
  ou o saldo de pacote pré-montado, conforme política modelada na TASK-207.
- Criar UI para visualizar composição, ajustar quantidades quando permitido, desfazer pacote e explicar
  por que um pacote está indisponível.
- Suportar rascunho offline com aviso de que preço/estoque definitivos serão revalidados ao sincronizar.

## Regras de negócio e restrições

- A UI nunca calcula preço final do pacote como fonte de verdade; todo total definitivo vem do motor
  server-side.
- Pacote fixo não pode ter componentes removidos pelo vendedor; pacote flexível só permite ajustes
  dentro dos limites configurados.
- Pedido não pode ser submetido se a versão do pacote usada no rascunho estiver expirada sem revalidação.
- A remoção de um pacote remove todos os itens vinculados, preservando histórico no rascunho/audit log.

## Testes obrigatórios

- Teste unitário/use case de expansão de pacote em itens de pedido, incluindo composição fixa e flexível.
- Teste do motor de precificação com pacote de preço fechado, desconto e item bonificado.
- Teste de validação de estoque para pacote com múltiplas variantes e disponibilidade parcial.
- Teste de widget do fluxo de adicionar, editar quando permitido e remover pacote.
- Teste offline: rascunho com pacote criado sem conexão e revalidação ao sincronizar.

## Critérios de aceite

- Vendedor consegue adicionar pacotes/sortimentos ao pedido sem digitar grade item a item.
- O pedido mantém rastreabilidade de qual pacote/versão originou cada item.
- Preço, desconto e estoque de pacote são revalidados no servidor antes da submissão.

## Arquivos prováveis

- A definir pelo agente executor no início da task.

## Referências

- Especificação funcional completa: `tasks.md`
- Agentes: `.claude/agents/flutter-senior-architect.md`, `.claude/agents/flutter-ui-design-specialist.md`,
  `.claude/agents/vestipro-sales-representative-specialist.md`,
  `.claude/agents/vestipro-commercial-ops-strategist.md`
- Fluxo obrigatório: `AGENTS.md`
