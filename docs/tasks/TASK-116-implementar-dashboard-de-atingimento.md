# TASK-116 — Implementar dashboard de atingimento

**Epic:** EPIC-15 — Metas e Performance Comercial
**Status:** ⬜ Pendente
**Depende de:** TASK-115 (metas cadastradas — o dashboard consome os Targets existentes)

## Agentes obrigatórios

- `flutter-senior-architect`
- `flutter-ui-design-specialist`

## Objetivo

Criar o dashboard que acompanha o progresso de cada meta em tempo real: valor realizado, meta, gap restante e uma projeção simples de fechamento, permitindo ao vendedor e ao gestor entender rapidamente onde estão.

## Escopo técnico

- Criar agregação server-side (Cloud Function ou snapshot pré-calculado, alinhado à seção 22 de `tasks.md`) que calcula o "realizado" por dimensão/período a partir de pedidos faturados/aprovados — nunca centenas de queries do cliente para somar pedidos.
- Criar `TargetProgressViewModel` (realizado, meta, gap absoluto, gap percentual, percentual de tempo decorrido do período, projeção simples linear com base no ritmo atual).
- Criar a página/seção de dashboard com cards KPI (meta, realizado, gap, atingimento %) e gráfico de evolução acumulada no período comparado à linha de meta.
- Implementar filtros por período e dimensão (próprio vendedor, equipe, empresa) respeitando RBAC (um `SALES_REP` só vê a própria meta e a de sua equipe se explicitamente permitido; gestor vê sua equipe/empresa).
- Reaproveitar componentes de gráfico/KPI do Design System (TASK-023) — nenhum gráfico sem explicar a pergunta de negócio respondida.
- Atualização em tempo real (ou near real-time) via stream/subscription na agregação, refletindo pedidos recém-sincronizados.

## Regras de negócio e restrições

- O cálculo de atingimento nunca é feito só no cliente somando documentos brutos — usa agregação server-side para evitar centenas de reads e garantir consistência entre este dashboard e o dashboard executivo.
- Um vendedor nunca visualiza a meta/realizado de outro vendedor sem permissão explícita (RBAC).
- Gap e atingimento % devem sempre refletir a mesma fonte de dados usada no ranking (TASK-118) e na projeção (TASK-119), para não haver números divergentes entre telas.
- O dashboard deve indicar claramente o período de referência e a data/hora do último cálculo (o dado pode não ser 100% real-time se vier de snapshot).

## Testes obrigatórios

- Teste do cálculo do ViewModel (realizado, gap, percentual, projeção linear simples) cobrindo casos: meta zerada, realizado maior que a meta, período ainda não iniciado, período já encerrado.
- Teste de RBAC garantindo que um `SALES_REP` não acessa dados de atingimento de outro vendedor via este dashboard.
- Teste de widget cobrindo: loading, dados carregados, meta inexistente para o período (estado vazio), erro ao carregar a agregação.
- Teste de integração validando que o dashboard reflete a atualização após um novo pedido ser sincronizado (mock da agregação).

## Critérios de aceite

- Dashboard exibe meta, realizado, gap e projeção simples de forma clara e correta.
- RBAC impede a visualização indevida de dados de outros vendedores/equipes.
- Cálculo baseado em agregação server-side, não em somatório client-side de documentos brutos.
- `flutter analyze`, `dart format --set-exit-if-changed .` e os testes passam.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
