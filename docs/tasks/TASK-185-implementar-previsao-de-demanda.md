# TASK-185 — Implementar modelo de previsão de demanda

**Epic:** EPIC-27 — Reposição e Previsão de Demanda
**Status:** ⬜ Pendente
**Depende de:** TASK-184 (sugestão de replenishment automático, base de dados de giro/estoque a ser estendida para uma projeção prospectiva)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Implementar um modelo de previsão de demanda por produto/coleção/região a partir do histórico de vendas, evoluindo a base de replenishment (TASK-184) para uma projeção futura, sempre exibindo intervalo de confiança e documentando as limitações do modelo — nunca como número absoluto e infalível.

## Escopo técnico

- Pipeline server-side (Cloud Function agendada ou job em BigQuery/Functions) que treina/atualiza um modelo estatístico simples (ex.: média móvel ponderada, suavização exponencial ou regressão sazonal) por produto/coleção/região, a partir do histórico de pedidos.
- Modelar `DemandForecast` (escopo: produto/coleção/região, período previsto, valor previsto, intervalo de confiança inferior/superior, versão do modelo, data de geração).
- Tela de previsão (gestor/planejamento): gráfico com histórico real + projeção + faixa de confiança, filtro por produto/coleção/região/período.
- Documentar (em documentação técnica do módulo) o método estatístico usado, premissas e limitações (ex.: não considera eventos externos, sensível a poucos dados).
- Reaproveitar a camada de agregação server-side (padrão de TASK-133) para não recalcular históricos já agregados.
- Job de reavaliação periódica do erro do modelo (ex.: MAPE), comparando previsão passada vs. realizado, exposto internamente para calibração.

## Regras de negócio e restrições

- Previsão nunca é apresentada sem o intervalo de confiança correspondente.
- Modelo nunca gera número para combinação produto/coleção/região com histórico insuficiente — deve indicar explicitamente "previsão não disponível".
- Cálculo e retreinamento sempre server-side; o cliente apenas consome o resultado já calculado.
- Isolamento por organização: o modelo de uma organização nunca usa dados de outra para treinar ou inferir.
- Toda previsão registra a versão do modelo usada, permitindo auditar por que um número foi gerado em determinada data.

## Testes obrigatórios

- Testes unitários do algoritmo de previsão: série com tendência, série sazonal, série com poucos pontos, série vazia.
- Teste do cálculo de intervalo de confiança em cenários com alta e baixa variância.
- Testes de isolamento multi-tenant do pipeline de treinamento.
- Testes de widget do gráfico de previsão: com dados suficientes, com "previsão não disponível", erro de carregamento.

## Critérios de aceite

- Toda previsão exibida inclui intervalo de confiança e data/versão do modelo.
- Combinações sem histórico suficiente mostram estado explícito de indisponibilidade, nunca um número fabricado.
- Previsão de uma organização nunca é influenciada por dados de outra.
- Documentação do método e das limitações do modelo está acessível à equipe.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
