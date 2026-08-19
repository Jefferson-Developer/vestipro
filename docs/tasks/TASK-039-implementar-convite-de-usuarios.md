# TASK-039 — Implementar convite de usuários

**Epic:** EPIC-04 — Autenticação e Onboarding
**Status:** ⬜ Pendente
**Depende de:** TASK-026 (modelagem de Organization — convite pertence a uma Organization); TASK-029 (RBAC — define quem pode convidar e atribuir quais roles); TASK-037 (criação da primeira Organization — precisa existir uma Organization para convidar alguém para ela)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir que usuários com role `OWNER` ou `ADMIN` convidem colaboradores por e-mail para a Organization, definindo a role de destino, com convite expirável e token seguro gerado exclusivamente via Cloud Function.

## Escopo técnico

- Criar `InviteUserPage` acessível apenas a `OWNER`/`ADMIN`, com campos: e-mail do convidado, role de destino (restrita às roles que o usuário logado tem permissão de atribuir), organização/empresa de destino quando aplicável, mensagem opcional.
- Criar Cloud Function callable `createInvite` que gera um token único, seguro e não previsível, cria o documento `Invite` (status `pending`/`accepted`/`expired`/`revoked`) com expiração configurável por organização (padrão sugerido: 7 dias).
- Validar no backend, dentro da Function, que quem está convidando tem permissão RBAC para atribuir a role solicitada (ex.: `ADMIN` não pode convidar outro `OWNER`).
- Criar `InviteListPage` com convites pendentes, permitindo reenviar (gera novo token, invalida o anterior) ou revogar (marca como `revoked`, invalidando o token) — ambas ações via Cloud Function.
- Disparar o envio do convite por e-mail via integração de e-mail transacional (Cloud Function/Firebase Extension — decisão técnica a documentar na conclusão da task).
- Disparar evento de analytics `invite_sent`.

## Regras de negócio e restrições

- O token de convite nunca deve ser adivinhável nem reaproveitável após aceite, expiração ou revogação.
- Apenas `OWNER`/`ADMIN` podem convidar; a UI oculta a ação para os demais perfis, mas a restrição real é sempre validada no backend.
- Toda criação, reenvio ou revogação de convite gera uma entrada de auditoria (ator, ação, e-mail convidado, role atribuída, timestamp), integrada à TASK-033.

## Testes obrigatórios

- Testes de Cloud Function com Firebase Emulator: geração de token, expiração após o prazo configurado, revogação efetiva do token, tentativa de convite por usuário sem permissão (deve ser rejeitada), tentativa de `ADMIN` convidar como `OWNER` (deve ser rejeitada).
- Testes de unidade do `Cubit`/`Bloc` de convite: sucesso, e-mail inválido, role não permitida para o convidador, falha de rede.
- Testes de widget: listagem de convites pendentes, ação de revogar/reenviar, estado vazio quando não há convites.

## Critérios de aceite

- Convite gerado apenas por `OWNER`/`ADMIN` autorizados, com validação real no backend.
- Token seguro, expirável e revogável, comprovado por teste.
- Cada ação de convite gera exatamente uma entrada de auditoria correspondente.
- `dart format`, `flutter analyze` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
