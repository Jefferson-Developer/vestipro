# TASK-061 — Implementar motivos de perda e ganho

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-057 (Modelar Opportunity) — os motivos passam a ser exigidos pelas transições `MarkOpportunityWon`/`MarkOpportunityLost` já modeladas; TASK-058 (Implementar funil de vendas configurável) — o motivo é coletado no momento da movimentação para estágio terminal no funil.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar um catálogo configurável de motivos de perda e ganho por organização, obrigatório ao mover uma oportunidade para "perdida"/"ganha", formando a base de um relatório de motivos mais frequentes.

## Escopo técnico

- Entidade `OpportunityOutcomeReason` (id, organizationId, tipo: ganho/perdido, descrição, ativo/inativo), administrável em tela de configurações (criar/editar/desativar motivo — nunca excluir motivo já usado historicamente, apenas desativar).
- Atualizar `MarkOpportunityWon`/`MarkOpportunityLost` (TASK-057) para exigir um `reasonId` válido e ativo do tipo correspondente.
- Tela/modal de seleção de motivo ao mover oportunidade para estágio terminal no funil (TASK-058), com campo de observação livre opcional complementar.
- Consulta agregada simples de motivos mais frequentes (contagem por motivo, por período), preparando terreno para dashboards futuros (EPIC-16/17).

## Regras de negócio e restrições

- Motivo desativado não pode ser selecionado em novas movimentações, mas motivos históricos já registrados permanecem legíveis — nunca apagar um motivo em uso.
- Motivo deve ser específico ao tipo de desfecho: motivo de "perda" não pode ser usado para marcar "ganho" e vice-versa.
- Apenas perfis administrativos (`ADMIN`/`OWNER`/`SALES_MANAGER` conforme política) podem gerenciar o catálogo de motivos.
- `organizationId` sempre resolvido pela sessão; catálogo nunca compartilhado entre organizações.

## Testes obrigatórios

- Teste de caso de uso: marcar oportunidade como ganha/perdida sem motivo é bloqueado.
- Teste de validação de tipo (motivo de perda usado em "ganho" é rejeitado).
- Teste de desativação de motivo: motivo desativado não aparece na seleção, mas permanece em registros históricos.
- Teste da consulta agregada de motivos mais frequentes com dados de exemplo.

## Critérios de aceite

- Catálogo de motivos configurável por organização, com tipo ganho/perdido.
- Movimentação de oportunidade para estágio terminal exige motivo válido e ativo do tipo correspondente.
- `flutter analyze`, `dart format` e testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
