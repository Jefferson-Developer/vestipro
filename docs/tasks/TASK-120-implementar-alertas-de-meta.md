# TASK-120 — Implementar alertas de meta

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-116 (dashboard de atingimento — os alertas derivam do gap/ritmo já calculado ali)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Sinalizar proativamente risco (vendedor abaixo do ritmo necessário para bater a meta) ou oportunidade (meta prestes a ser atingida/superada), com thresholds configuráveis por organização e sem gerar excesso de notificações.

## Escopo técnico

- Criar uma regra de avaliação (`TargetAlertEvaluator`, domain) que compara o ritmo atual (realizado / tempo decorrido) com o ritmo necessário (meta / tempo total do período) e classifica em: risco alto, risco moderado, no ritmo, oportunidade (acima do ritmo, meta prestes a bater).
- Tornar os thresholds configuráveis por organização (ex.: "risco alto" = ritmo abaixo de X% do necessário; "oportunidade" = acima de Y% da meta faltando menos de Z dias) — nunca thresholds fixos no código.
- Implementar agrupamento/limite de frequência de notificação (ex.: no máximo uma notificação de risco por meta por dia/semana, mesmo que a condição continue verdadeira em avaliações subsequentes), para evitar excesso de notificações ao vendedor.
- Integrar com a infraestrutura de notificações (Firebase Cloud Messaging, quando disponível, ou notificação interna do app) e com a central de notificações do app, incluindo deep link direto para o dashboard de atingimento (TASK-116) da meta correspondente.
- Exibir também um indicador visual (badge/banner) no próprio dashboard de metas, além da notificação push, para o caso de o usuário não abrir a notificação.
- Adicionar evento de Analytics (`target_alert_triggered`) incluindo o tipo de alerta (risco/oportunidade), sem dados pessoais sensíveis.

## Regras de negócio e restrições

- Thresholds de risco/oportunidade são configuráveis por organização, nunca fixos.
- Nunca disparar mais de um alerta da mesma condição para a mesma meta dentro da janela de frequência configurada (agrupar, não repetir).
- Alertas nunca podem ser a única forma de o vendedor saber que está em risco — o dashboard de metas deve refletir a mesma informação de forma persistente.
- Alerta de risco nunca deve usar tom alarmista/culpabilizador — mensagem objetiva e orientada à ação (ex.: "Faltam X para a meta; ritmo atual sugere Y — considere priorizar Z clientes").

## Testes obrigatórios

- Teste do `TargetAlertEvaluator` cobrindo as quatro classificações (risco alto, risco moderado, no ritmo, oportunidade) com thresholds configuráveis distintos por organização.
- Teste de limite de frequência: a mesma condição de risco avaliada múltiplas vezes no período não gera notificação duplicada dentro da janela configurada.
- Teste de integração garantindo que o alerta contém deep link correto para a meta/dashboard correspondente.
- Teste de widget do indicador visual no dashboard de metas.

## Critérios de aceite

- Alertas de risco e oportunidade disparados corretamente conforme thresholds configuráveis por organização.
- Nenhum excesso de notificações para a mesma condição (agrupamento/limite de frequência funcionando).
- Indicador visual persistente no dashboard de metas complementa a notificação.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
