# TASK-149 — Implementar agendamento de relatórios

**Epic:** EPIC-18 — Relatórios Customizados e Exportações
**Status:** ⬜ Pendente
**Depende de:** TASK-144 (construtor de relatórios, definição executada periodicamente), TASK-015
(Cloud Functions for Firebase, base de execução do agendamento)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Permitir o envio periódico automatizado de relatórios (visualizações salvas) via Cloud Functions e
Cloud Scheduler, respeitando as permissões de quem pode agendar e de quem pode receber cada
relatório.

## Escopo técnico

- Modelar `ReportSchedule` em `organizations/{organizationId}/reportSchedules/{scheduleId}`
  (savedReportId, frequência, destinatários, formato de exportação, próxima execução).
- Cloud Function agendada via Cloud Scheduler (cron) que executa a `ReportDefinition` salva
  (TASK-144/TASK-145), gera a exportação no formato configurado (TASK-146/TASK-147/TASK-148) e
  envia por e-mail e/ou notificação interna (TASK-151).
- Casos de uso: `CreateReportSchedule`, `PauseReportSchedule`, `DeleteReportSchedule`,
  `ListReportSchedules`.
- Garantir idempotência: retry do Cloud Scheduler não pode duplicar o envio do mesmo ciclo agendado.
- Expor tela mínima de gestão de agendamentos (criar, pausar, excluir); componente visual reaproveita
  o Design System existente.

## Regras de negócio e restrições

- Apenas perfis com permissão adequada (`SALES_MANAGER`, `ADMIN`, `OWNER`) podem criar agendamento;
  destinatários devem pertencer à mesma organização do agendamento.
- Agendamento com dado financeiro sensível respeita o RBAC do destinatário no momento do envio, não
  o RBAC de quem criou o agendamento.
- Excluir a visualização salva referenciada (TASK-145) pausa ou alerta explicitamente os
  agendamentos dependentes — nunca falha silenciosa.
- Falha de geração/envio é registrada e visível ao criador do agendamento, nunca silenciosa.

## Testes obrigatórios

- Teste da Cloud Function no Emulator Suite: execução agendada gera exportação e realiza o envio
  (mock de e-mail/notificação).
- Teste de idempotência: retry do Cloud Scheduler não duplica o envio.
- Teste de RBAC: usuário sem permissão não cria agendamento; destinatário sem permissão não recebe
  dado fora do próprio escopo.
- Teste de pausar/excluir agendamento e efeito sobre execuções futuras.
- Teste do vínculo quebrado quando a visualização salva referenciada é excluída.

## Critérios de aceite

- Relatório agendado é gerado e entregue automaticamente na frequência configurada, sem intervenção
  manual.
- Apenas usuários autorizados criam e gerenciam agendamentos.
- Falhas de execução são visíveis ao responsável pelo agendamento, nunca silenciosas.
- Nenhum agendamento duplica envios em caso de retry do Cloud Scheduler.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura
  de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
