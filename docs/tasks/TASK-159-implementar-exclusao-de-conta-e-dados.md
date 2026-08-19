# TASK-159 — Implementar exclusão de conta e dados

**Epic:** EPIC-20 — LGPD e Privacidade
**Status:** ⬜ Pendente
**Depende de:** TASK-013 (Configurar Cloud Firestore, onde residem os dados a excluir/anonimizar),
TASK-029 (RBAC, para remover vínculos de perfil/permissão do usuário excluído)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Permitir a exclusão de conta e dados pessoais conforme obrigação legal, preservando apenas o que
precisa ser retido por obrigação fiscal/contratual (documentado explicitamente) e sem jamais excluir
em cascata dados de terceiros vinculados ao usuário excluído.

## Escopo técnico

- Caso de uso `RequestAccountDeletion` com fluxo de confirmação explícita (dupla confirmação/senha)
  antes de iniciar.
- Cloud Function que executa a exclusão/anonimização dos dados pessoais do usuário, preservando
  exclusivamente o que houver obrigação legal de reter (ex.: registros fiscais de pedidos aprovados,
  trilha de auditoria administrativa) — documentar explicitamente quais dados são retidos e por quê.
- Anonimizar (em vez de excluir fisicamente) registros que precisam ser mantidos para o histórico de
  terceiros — ex.: um pedido de um cliente permanece com "vendedor removido" em vez de o pedido ser
  apagado.
- Nunca deletar em cascata dados de terceiros vinculados (clientes, pedidos, oportunidades de outros
  usuários) apenas porque referenciam o usuário excluído.
- Remover vínculos ativos de RBAC/roles/teams (TASK-029), tokens de push (TASK-150), sessões e dados
  locais (Drift/secure storage) do dispositivo.

## Regras de negócio e restrições

- Exclusão de conta do único `OWNER` de uma organização exige tratamento especial (transferência de
  titularidade ou bloqueio da exclusão até resolver) — nunca deixar a organização órfã.
- Dados retidos por obrigação fiscal/contratual são claramente documentados (quais, por quanto
  tempo, base legal) e nunca expostos como "dado pessoal ativo" no app após a exclusão.
- Todo o fluxo passa por confirmação explícita e não pode ser acionado por engano em um único toque.
- Processo é auditável: quem solicitou, quando, o que foi excluído/anonimizado e o que foi retido.

## Testes obrigatórios

- Teste de caso de uso: exclusão remove dados pessoais do usuário mas preserva pedidos/registros de
  terceiros com o vendedor anonimizado.
- Teste garantindo que a exclusão nunca apaga em cascata clientes/pedidos/oportunidades de outros
  usuários.
- Teste de bloqueio/tratamento especial quando o usuário é o único `OWNER` da organização.
- Teste de remoção de vínculos RBAC, tokens de push e dados locais do dispositivo.
- Teste de auditoria completa do processo de exclusão (dados retidos documentados no registro).

## Critérios de aceite

- Usuário consegue solicitar a exclusão da própria conta com confirmação explícita e segura.
- Dados de terceiros vinculados nunca são apagados como efeito colateral da exclusão.
- Dados retidos por obrigação legal estão explicitamente documentados e não são tratados como dado
  pessoal ativo.
- Todo o processo de exclusão é auditável e rastreável.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
