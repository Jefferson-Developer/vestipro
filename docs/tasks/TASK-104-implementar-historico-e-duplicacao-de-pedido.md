# TASK-104 — Implementar histórico e duplicação de pedido

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-101 — Implementar submissão do pedido (histórico e duplicação operam sobre pedidos já submetidos)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir visualizar o histórico completo de um pedido (mudanças de status) e "repetir pedido anterior", pré-preenchendo um novo rascunho com os mesmos itens, sempre revalidando preço e disponibilidade atuais.

## Escopo técnico

- Criar tela de histórico do pedido exibindo a linha do tempo de `OrderStatusHistoryEntry` (status anterior, novo status, autor, timestamp, motivo quando houver) de forma cronológica e clara.
- Implementar a ação "Repetir pedido", que cria um novo rascunho (`draft`) pré-preenchido com cliente e itens (produto + variante + quantidade) do pedido de origem.
- Ao duplicar, revalidar o preço vigente (nova consulta ao motor de precificação, TASK-088) e a disponibilidade atual (TASK-090/TASK-091) para cada item — nunca copiar preço/estoque antigos como se ainda fossem válidos.
- Sinalizar claramente ao vendedor quando um item do pedido antigo não está mais disponível ou teve o preço alterado, permitindo ajuste antes de prosseguir.
- Vincular o novo rascunho ao pedido de origem apenas como referência informativa (ex.: "duplicado de #12345"), sem herdar status ou histórico do pedido original.

## Regras de negócio e restrições

- Novo rascunho criado por duplicação começa sempre em `draft`, nunca herda o status do pedido original.
- Item descontinuado ou sem variante equivalente não pode ser copiado silenciosamente — o vendedor deve ser avisado explicitamente.
- Histórico de status é somente leitura — não pode ser editado ou removido pela interface.

## Testes obrigatórios

- Teste de widget da timeline de histórico cobrindo múltiplas transições, incluindo aprovação/rejeição quando aplicável.
- Teste de caso de uso de duplicação cobrindo revalidação de preço (preço mudou) e de disponibilidade (item sem estoque/descontinuado).
- Teste garantindo que o pedido duplicado inicia em `draft` e não referencia incorretamente o status do original.
- Teste de estado vazio/erro na consulta de histórico (ex.: pedido sem nenhuma transição além da criação).

## Critérios de aceite

- Histórico completo e cronológico do pedido disponível e somente leitura.
- "Repetir pedido" gera novo rascunho com preço e disponibilidade revalidados, nunca copiados cegamente.
- Itens não disponíveis/desatualizados são sinalizados claramente ao vendedor antes de prosseguir.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
