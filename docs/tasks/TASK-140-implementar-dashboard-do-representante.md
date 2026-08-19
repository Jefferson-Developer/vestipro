# TASK-140 — Implementar dashboard do representante

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side), TASK-051 (carteira de clientes — escopo individual do vendedor)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Implementar o Representative Dashboard (seção 12.1 de `tasks.md`): visão individual do vendedor com venda do dia/mês, atingimento de meta, carteira e follow-ups, pensado para consulta rápida em campo (mobile) antes/durante uma visita.

## Escopo técnico

- Criar `RepresentativeDashboardBloc` consumindo os snapshots de vendedor/período (TASK-133) via `AggregationRepository`, escopado sempre ao próprio vendedor autenticado (ou, para gestor, a um vendedor específico da equipe).
- Exibir KPIs (seção 12.2): venda do dia, venda do mês, atingimento de meta (TASK-115), positivação da carteira, ranking pessoal dentro da equipe.
- Listar follow-ups pendentes e vencidos (TASK-060), priorizados por vencimento, com atalho direto para a atividade CRM.
- Exibir carteira resumida (TASK-051) com destaque para clientes com insight ativo relevante (ex.: inativo, risco de churn, cross-sell) cruzando com a Central de Oportunidades (TASK-132).
- Priorizar layout mobile-first (uma mão, tela pequena), com versão desktop/tablet reaproveitando os mesmos componentes de KPI card do Design System.
- Registrar evento de analytics `dashboard_viewed` (tipo `representative`).

## Regras de negócio e restrições

- Vendedor só acessa o próprio dashboard por padrão; gestor acessa o de qualquer vendedor da própria equipe (RBAC).
- Dados exibidos devem funcionar em modo offline com indicação clara de "última atualização" quando não houver conectividade (cache local do snapshot mais recente).
- Nenhuma meta ou dado de outro vendedor pode vazar para quem não tem permissão de visão de equipe.

## Testes obrigatórios

- Teste de bloc cobrindo: carregamento completo, ausência de meta cadastrada, follow-ups vazios, uso de cache offline.
- Teste de RBAC (vendedor não acessa dashboard de outro vendedor sem permissão de gestor).
- Teste de widget para layout mobile de uma coluna e desktop/tablet com múltiplas colunas.
- Teste de integração entre a listagem de follow-ups e a timeline de atividades CRM (TASK-059).

## Critérios de aceite

- Dashboard exibe venda do dia/mês, atingimento de meta, positivação da carteira e follow-ups pendentes/vencidos.
- Funciona em modo offline com indicação clara de desatualização dos dados.
- RBAC impede acesso ao dashboard de outro vendedor sem permissão adequada.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
