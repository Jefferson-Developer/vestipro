# TASK-190 — Implementar recomendação de produtos baseada em comportamento

**Epic:** EPIC-28 — Inteligência Artificial Generativa
**Status:** ⬜ Pendente
**Depende de:** TASK-069 (busca global de produtos, ponto de exibição da recomendação no catálogo), TASK-125 (insight de cross-sell, sinais e lógica de base a serem reaproveitados/estendidos)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Recomendar produtos com base em comportamento de navegação e compra (produtos vistos, adicionados ao pedido, comprados por clientes semelhantes), evoluindo os sinais já usados no insight de cross-sell (TASK-125), documentando claramente quais sinais alimentam o modelo e a frequência de retraining.

## Escopo técnico

- Pipeline server-side (Cloud Function agendada) que consome eventos de comportamento já coletados (`product_viewed`, `product_added_to_order`, `order_submitted` — ver seção 23 de `tasks.md`) e calcula recomendações por cliente/segmento (ex.: co-ocorrência de produtos comprados, similaridade entre clientes).
- Modelar `ProductRecommendation` (customerId ou segmentId, lista de productIds recomendados, sinais usados, data de geração, versão do modelo).
- Expor recomendações via repositório consumido pelo catálogo (grid/detalhe de produto) e pela tela do cliente, sem recalcular nada no cliente.
- Documentar (arquivo técnico do módulo) os sinais usados e a cadência de retraining (ex.: diário/semanal), para auditoria e explicabilidade.
- Fallback claro quando não há dado suficiente (cliente novo): recomendação vazia ou baseada em mais vendidos gerais, nunca inventada.

## Regras de negócio e restrições

- Cálculo sempre server-side; o cliente apenas consome a lista já pronta.
- Nenhum dado de comportamento de uma organização alimenta recomendação de outra.
- A recomendação deve poder ser explicada minimamente (ex.: "clientes que compraram X também compraram Y") — nunca uma lista sem justificativa alguma.
- Dados de comportamento usados no cálculo não incluem dados pessoais sensíveis (conforme seção 23 de `tasks.md`).

## Testes obrigatórios

- Testes unitários do algoritmo de co-ocorrência/similaridade: histórico rico, esparso, cliente novo sem histórico.
- Teste de isolamento multi-tenant do cálculo e do resultado.
- Teste de fallback para cliente sem dado suficiente.
- Testes de integração da exibição da recomendação no catálogo/detalhe do cliente.

## Critérios de aceite

- Recomendações aparecem no catálogo/tela do cliente com justificativa mínima visível.
- Cliente sem histórico suficiente recebe fallback definido, nunca lista vazia sem explicação nem dado fabricado.
- Nenhum dado de comportamento vaza entre organizações.
- Documentação de sinais e cadência de retraining está disponível para a equipe.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no
  momento da execução (este backlog foi escrito antes da implementação; não presuma que a
  estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
