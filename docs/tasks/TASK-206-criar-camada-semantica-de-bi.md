# TASK-206 — Criar camada semântica de BI

**Epic:** EPIC-31 — Administração Avançada e Data Platform
**Status:** ⬜ Pendente
**Depende de:** TASK-133 (camada de agregação server-side, um dos dois caminhos de cálculo a unificar), TASK-205 (pipeline Data Warehouse/BigQuery, o outro caminho de cálculo a unificar)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar uma camada semântica centralizada com a definição única de métricas de negócio (ex.: "faturamento", "cliente ativo", "atingimento de meta"), reutilizada tanto pelos dashboards do app (TASK-133) quanto pelas consultas do Data Warehouse (TASK-205), eliminando divergência de números entre telas diferentes.

## Escopo técnico

- Inventariar as métricas já calculadas de forma dispersa (dashboards de EPIC-17, relatórios de EPIC-18, insights de EPIC-16) e consolidar cada uma em uma definição única: nome, fórmula exata, filtros implícitos (ex.: pedidos cancelados entram ou não no faturamento), granularidade (organização/vendedor/produto/período).
- Criar um módulo/camada de definição de métricas (ex.: serviço de domínio compartilhado ou arquivo de configuração central), consumido tanto pela camada de agregação server-side (TASK-133, que alimenta os dashboards do app) quanto pelas views/queries do BigQuery (TASK-205) — a mesma fórmula, expressa de forma equivalente nos dois lugares, nunca duas fórmulas divergentes para o mesmo nome de métrica.
- Processo de revisão obrigatório: qualquer métrica nova ou alteração de fórmula existente passa por essa camada central antes de ser usada em qualquer dashboard/relatório novo — proibido calcular uma métrica já definida "na mão" direto em uma tela ou query pontual.
- Documentação viva do dicionário de métricas (nome, fórmula, granularidade, dono/responsável, última revisão), acessível à equipe de produto/dados.
- Rotina de auditoria de divergência: comparação do valor de uma métrica-chave (ex.: faturamento do mês) calculado pelo caminho do app (TASK-133) e pelo caminho do Data Warehouse (TASK-205) para o mesmo período, alertando se divergirem.

## Regras de negócio e restrições

- Uma métrica de negócio possui exatamente uma definição de fórmula em todo o sistema; qualquer tela/relatório que precisar dela deve consumir essa definição central, nunca recalcular com lógica própria.
- Alteração na fórmula de uma métrica existente deve ser versionada e comunicada, afetando todos os dashboards/relatórios que a usam simultaneamente, de forma consistente.
- A camada semântica não introduz um terceiro motor de cálculo paralelo ao motor de precificação (TASK-088) nem à camada de agregação (TASK-133) — ela organiza e reutiliza o que já existe, não duplica.
- Toda métrica-chave exposta a gestores/executivos deve ter dono definido e data da última revisão registrada.

## Testes obrigatórios

- Teste de consistência: mesma métrica (ex.: faturamento do mês para uma organização) calculada pelo caminho do app e pelo caminho do Data Warehouse produz o mesmo valor para o mesmo conjunto de dados de teste.
- Testes unitários das fórmulas centralizadas: casos de borda (pedido cancelado, período sem dados, cliente sem atividade) conforme a definição documentada de cada métrica.
- Teste de regressão nos dashboards existentes (EPIC-17) após migrarem para consumir a definição central, garantindo que os números não mudaram silenciosamente sem justificativa.
- Teste do processo de auditoria de divergência (alerta disparado quando os dois caminhos produzem valores diferentes).

## Critérios de aceite

- Toda métrica de negócio relevante possui uma única definição de fórmula, documentada e versionada.
- Dashboards do app e consultas do Data Warehouse para a mesma métrica produzem o mesmo número para o mesmo período/escopo.
- Nenhum dashboard/relatório novo recalcula uma métrica já definida com lógica própria e divergente.
- Divergências entre os dois caminhos de cálculo são detectadas por rotina de auditoria, não descobertas manualmente pelo usuário.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
