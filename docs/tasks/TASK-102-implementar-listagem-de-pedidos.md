# TASK-102 — Implementar listagem e acompanhamento de pedidos

**Epic:** EPIC-13 — Pedidos
**Status:** ⬜ Pendente
**Depende de:** TASK-101 — Implementar submissão do pedido (listagem exibe pedidos já submetidos e seus status)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a listagem e o acompanhamento de pedidos com filtros por status, período, cliente e vendedor, com indicação clara de pedidos pendentes de sincronização (offline) versus já confirmados no servidor.

## Escopo técnico

- Criar tela de listagem de pedidos com filtros por status (usando os status da seção 9.1 de `tasks.md`), período, cliente e vendedor (visível apenas para perfis com permissão de ver pedidos de outros vendedores).
- Implementar paginação por cursor, nunca carregando todo o histórico de pedidos de uma vez.
- Exibir badge de status claro por pedido, diferenciando visualmente pedidos com `syncStatus` pendente/falhou (ainda no dispositivo, offline) dos já confirmados no servidor (`submitted` em diante) — sem depender só de cor.
- Adicionar busca rápida (por número de pedido, cliente) com debounce.
- Converter para cards em mobile e tabela densa em desktop/Web, seguindo os padrões de responsividade do Design System.

## Regras de negócio e restrições

- Vendedor vê por padrão apenas os próprios pedidos; gestores/perfis com permissão veem pedidos da equipe/organização conforme RBAC.
- Pedido pendente de sincronização deve permitir edição/cancelamento local; pedido já confirmado no servidor segue a máquina de estados oficial (TASK-095) e não pode ser editado livremente pelo client.
- Filtros aplicados devem ser preserváveis na URL no Flutter Web (deep link).

## Testes obrigatórios

- Teste de BLoC cobrindo filtros combinados (status + período + cliente + vendedor) e paginação preservando itens já carregados.
- Teste de widget diferenciando visualmente pedido pendente de sincronização vs. confirmado, verificando que não depende só de cor.
- Teste de RBAC garantindo que vendedor sem permissão não visualiza pedidos de outros vendedores.
- Teste de busca com debounce e cancelamento de requisição anterior.

## Critérios de aceite

- Listagem funcional com todos os filtros especificados e paginação por cursor.
- Diferenciação clara e acessível entre pedido pendente de sincronização e pedido confirmado no servidor.
- RBAC aplicado corretamente na visibilidade de pedidos de terceiros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
