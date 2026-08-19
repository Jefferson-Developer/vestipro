# TASK-059 — Implementar atividades CRM (timeline)

**Epic:** EPIC-07 — CRM
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Modelar Customer) — a atividade se vincula a cliente (e opcionalmente a lead/oportunidade), reaproveitando a entidade já definida.

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o registro de atividades CRM (ligação, visita, reunião, mensagem, nota) vinculadas a cliente, lead ou oportunidade, exibidas em uma timeline cronológica completa no detalhe do cliente 360º (TASK-052).

## Escopo técnico

- Entidade `CrmActivity` (id, organizationId, tipo: ligação/visita/reunião/mensagem/nota, vínculo polimórfico opcional a `customerId`/`leadId`/`opportunityId`, autor (`userId`), data/hora, descrição/notas, duração quando aplicável, anexos opcionais).
- Casos de uso: `RegisterCrmActivity`, `ListCrmActivitiesForCustomer`/`ForLead`/`ForOpportunity`.
- Componente de timeline no Design System (ou reaproveitado) com ícone por tipo de atividade e destaque visual para follow-ups vencidos (integração futura com TASK-060).
- Registro rápido de atividade acessível a partir do detalhe do cliente (botão de ação rápida da TASK-052).
- Suporte a registro offline: atividade criada em campo sem conexão é persistida localmente e marcada como pendente (entra na Outbox quando o motor de EPIC-14 existir).

## Regras de negócio e restrições

- Toda atividade deve ter ao menos um vínculo (cliente, lead ou oportunidade) — nunca uma atividade "solta".
- Autor da atividade é sempre o usuário autenticado no momento do registro, nunca escolhido livremente no formulário.
- Timeline deve ser ordenada cronologicamente (mais recente primeiro, com opção de ordenação) e paginada quando o histórico for extenso.
- Edição de atividade já registrada, se permitida, deve preservar histórico de quem criou/alterou (auditoria básica).

## Testes obrigatórios

- Teste de caso de uso: registrar atividade exige vínculo válido (cliente/lead/oportunidade); falha sem nenhum vínculo.
- Teste de listagem/timeline: ordenação cronológica, paginação de histórico extenso.
- Teste de widget: ícone correto por tipo de atividade, destaque de follow-up vencido (placeholder até TASK-060 existir).
- Teste de comportamento offline: atividade registrada sem conexão fica marcada como pendente e não se perde.

## Critérios de aceite

- Atividade CRM pode ser registrada com os cinco tipos previstos e vínculo obrigatório a cliente/lead/oportunidade.
- Timeline cronológica exibida corretamente no detalhe do cliente (TASK-052).
- `flutter analyze`, `dart format` e testes passam; comportamento offline não perde dados do usuário.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
