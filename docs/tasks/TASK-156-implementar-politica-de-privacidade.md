# TASK-156 — Implementar política de privacidade e termos

**Epic:** EPIC-20 — LGPD e Privacidade
**Status:** ⬜ Pendente
**Depende de:** TASK-020 (foundations do Design System, para o layout de texto longo da tela)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar a tela de Política de Privacidade e Termos de Uso com aceite versionado — publicar uma
nova versão exige novo aceite explícito — e garantir que o conteúdo seja acessível ao usuário a
qualquer momento, base para toda a gestão de consentimentos (TASK-157) do MVP.

## Escopo técnico

- Tela de Política de Privacidade e Termos de Uso acessível pelo menu de configurações/perfil, usando
  os tokens de tipografia e espaçamento do Design System (TASK-020) para texto longo.
- Modelar `PolicyDocument` versionado (`tipo`: `privacy_policy` | `terms_of_use`, `versão`,
  conteúdo/URL, `publicadoEm`) — versionamento explícito, nunca sobrescrever versão anterior.
- Registrar `UserPolicyAcceptance` (usuário, tipo, versão aceita, data/hora, dispositivo quando
  aplicável) em subcollection própria.
- Ao publicar nova versão, bloquear o uso do app até o novo aceite: usuário com aceite de versão
  anterior vê tela de bloqueio simples, sem necessidade de logout.
- Fluxo de aceite no onboarding (primeiro acesso) e no bloqueio por nova versão publicada.

## Regras de negócio e restrições

- Nunca assumir aceite implícito; ação explícita (checkbox/botão "Aceitar") é obrigatória e
  registrada.
- Aceite de versão antiga não é retroativamente considerado válido para uma versão nova.
- Texto da política/termos é acessível mesmo sem aceitar (usuário pode ler antes de decidir) e a
  qualquer momento depois, pelo menu de configurações.
- Registro de aceite é dado de conformidade sensível: nunca excluído em rotinas normais de limpeza
  (ver política de retenção em TASK-160).

## Testes obrigatórios

- Teste de caso de uso: primeiro acesso exige aceite antes de liberar o uso do app.
- Teste de nova versão publicada bloqueando usuário com aceite desatualizado até o novo aceite.
- Teste de registro de `UserPolicyAcceptance` com todos os campos exigidos (usuário, versão, data).
- Teste de acesso à política a qualquer momento pelo menu de configurações, fora do fluxo de
  bloqueio.
- Teste de isolamento por usuário: aceite registrado por usuário, não por organização.

## Critérios de aceite

- Nenhum usuário acessa funcionalidades do app sem ter aceitado a versão vigente da política/termos.
- Nova versão publicada exige novo aceite explícito, sem depender de aceite anterior.
- Usuário consegue reler política/termos a qualquer momento pelo menu, independentemente de já ter
  aceitado.
- Todo aceite fica registrado de forma auditável (quem, quando, qual versão).

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
