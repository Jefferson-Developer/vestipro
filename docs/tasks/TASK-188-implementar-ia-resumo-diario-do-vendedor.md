# TASK-188 — Implementar IA generativa: resumo diário do vendedor

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-116 (dashboard de atingimento, fonte do dado de meta), TASK-132 (central de oportunidades, fonte de insights e follow-ups do dia)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Entregar diariamente (ex.: pela manhã) um resumo em linguagem natural consolidando meta, pendências, insights prioritários e follow-ups do vendedor, como notificação e card na home, gerado exclusivamente a partir de dados já calculados pelas camadas de metas, insights e CRM.

## Escopo técnico

- Cloud Function agendada `generateDailyRepSummary` (scheduler diário por organização/fuso horário) monta payload: atingimento de meta (TASK-116), follow-ups do dia, insights prioritários (engine de insights), pedidos com problema.
- Geração do texto via LLM com prompt fixo e a mesma validação anti-alucinação numérica das TASK-186/TASK-187 (todo número citado deve existir no payload).
- Entrega como notificação (reaproveitando a central de notificações, TASK-151) e como card fixo no topo da home do vendedor, com deep link direto para cada item citado (follow-up, insight, pedido).
- Respeitar preferências de comunicação e quiet hours do usuário ao disparar a notificação.
- Persistir o resumo gerado (histórico) para consulta posterior no mesmo dia.

## Regras de negócio e restrições

- O resumo é gerado uma vez por vendedor/dia (idempotente); reexecução no mesmo dia não duplica notificação.
- Nenhum item citado no resumo pode ser fabricado — cada item deve linkar para um registro real (follow-up, insight, pedido).
- Geração sempre server-side; o cliente nunca monta o prompt nem envia dados livres para o modelo.
- Falha na geração não deve travar a home — a ausência do resumo é um estado tratado, não um erro fatal do app.

## Testes obrigatórios

- Testes da Cloud Function agendada: geração para vendedor com pendências, sem pendências, com erro de payload.
- Teste de idempotência (não duplicar notificação no mesmo dia).
- Teste de rejeição de texto com item não presente no payload.
- Testes de widget: card na home com resumo disponível, indisponível, erro, link para cada item citado.

## Critérios de aceite

- Vendedor recebe resumo diário consolidado com links funcionais para cada item citado.
- Nenhum item do resumo é fabricado; todos existem nos dados reais do dia.
- Resumo respeita quiet hours/preferências de notificação do usuário.
- Falha de geração não compromete o uso normal da home.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
