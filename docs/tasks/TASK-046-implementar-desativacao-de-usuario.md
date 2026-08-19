# TASK-046 — Implementar desativação de usuário

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-042 (lista de usuários — ponto de entrada da ação de desativar)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que `ADMIN`/`OWNER` desativem o acesso de um usuário à organização, preservando integralmente o histórico de pedidos, atividades e demais dados já gerados por ele, e impedindo login enquanto estiver desativado.

## Escopo técnico

- Adicionar ação "Desativar usuário" na `UserListPage`/tela de detalhe, com diálogo de confirmação explicando que o histórico do usuário será preservado.
- Criar Cloud Function/caso de uso `deactivateUser` que marca o vínculo `user_organization` como inativo — nunca deletando o documento do usuário nem qualquer registro associado (pedidos, atividades de CRM, entradas de auditoria permanecem íntegros e atribuídos a ele).
- Bloquear login de usuário desativado no backend (verificação do vínculo ativo/custom claims), exibindo mensagem clara ("Seu acesso foi desativado. Entre em contato com o administrador da sua organização.") — nunca apenas ocultar a tela no client.
- Integrar com TASK-041: sessão já aberta de um usuário desativado deve ser revogada de forma efetiva no próximo request autenticado.
- Implementar reativação como ação simétrica, também auditada.
- Toda desativação/reativação gera entrada de auditoria correspondente (integrada à TASK-033).

## Regras de negócio e restrições

- Nunca deletar em cascata pedidos, atividades de CRM, vínculos de carteira ou entradas de auditoria de um usuário desativado.
- Usuário desativado não pode autenticar nem executar nenhuma ação autorizada, mesmo que ainda possua um token tecnicamente válido no momento da desativação.
- Não permitir desativar o último `OWNER` ativo da organização, com a mesma proteção aplicada na TASK-043.

## Testes obrigatórios

- Testes de Cloud Function: desativação bloqueando login subsequente, preservação do histórico (pedidos/atividades continuam consultáveis normalmente), reativação bem-sucedida, bloqueio de desativação do último `OWNER`.
- Teste de sessão: usuário com sessão já aberta é desconectado no próximo request após ser desativado.
- Testes de widget: diálogo de confirmação, atualização do status na listagem após a ação.

## Critérios de aceite

- Usuário desativado é impedido de autenticar, com validação garantida no backend.
- Nenhum dado histórico é perdido ou removido em cascata na desativação.
- Auditoria registrada corretamente para desativação e reativação.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
