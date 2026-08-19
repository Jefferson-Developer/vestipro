# TASK-043 — Implementar gestão de perfis e permissões

**Epic:** EPIC-05 — Usuários e Equipes
**Status:** ⬜ Pendente
**Depende de:** TASK-029 (RBAC — define a matriz de quem pode atribuir quais roles); TASK-042 (lista de usuários — ponto de entrada para a ação de alterar perfil)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela que permite a `ADMIN`/`OWNER` alterar a role de usuários autorizados da organização, com toda alteração gerando entrada de auditoria e com bloqueio absoluto de qualquer operação que deixe a organização sem nenhum `OWNER`.

## Escopo técnico

- Criar `UserRoleEditPage`/bottom sheet com seletor de role limitado às roles que o usuário logado tem permissão de atribuir, conforme a matriz de RBAC da TASK-029.
- Criar Cloud Function/caso de uso `updateUserRole` validando no backend: permissão do solicitante para a alteração, validade da role de destino, e se a alteração deixaria a organização sem nenhum `OWNER` ativo (nesse caso, bloquear).
- Toda alteração de role bem-sucedida gera uma entrada no audit log central (ator, usuário alvo, role anterior, role nova, timestamp), integrada diretamente à TASK-033.
- Exibir diálogo de confirmação para alterações sensíveis (ex.: rebaixar um `OWNER`, promover a `ADMIN`).
- Exibir mensagem de erro clara e específica quando a operação é bloqueada por ser a última alteração de `OWNER` da organização.

## Regras de negócio e restrições

- Nunca permitir, sob nenhuma condição, que a organização fique sem nenhum `OWNER` — validação obrigatoriamente no backend, não apenas na UI.
- Um usuário não pode alterar a própria role para um nível de permissão acima do que possui atualmente.
- Toda validação de permissão ocorre no backend; a ocultação de opções na UI é apenas conveniência de UX.

## Testes obrigatórios

- Testes de Cloud Function/caso de uso: alteração válida, tentativa de rebaixar o último `OWNER` (bloqueada), alteração feita por usuário sem permissão (bloqueada), tentativa de auto-promoção indevida (bloqueada).
- Teste garantindo que cada alteração bem-sucedida gera exatamente uma entrada de auditoria com os dados corretos (ator, alvo, role anterior, role nova).
- Testes de widget: seletor de role restrito às opções permitidas, diálogo de confirmação para alterações sensíveis, mensagem de bloqueio do último `OWNER`.

## Critérios de aceite

- Alteração de role validada corretamente no backend e sempre auditada.
- Impossível remover o último `OWNER` da organização, comprovado por teste.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
