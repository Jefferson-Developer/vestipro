# TASK-121 — Criar engine base de insights

**Epic:** EPIC-16 — Insights e Recomendação
**Status:** ⬜ Pendente
**Depende de:** TASK-048 (Customer modelado — fonte de dados de cliente para as regras), TASK-064 (Product modelado — fonte de dados de produto/categoria), TASK-095 (Order e OrderItem modelados — fonte de dados de faturamento e pedidos)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar o framework extensível de regras que sustenta toda a Inteligência Comercial do VestiPro (seção 11 de `tasks.md`): cada regra é uma função pura que recebe dados já agregados e retorna zero ou mais insights, sempre acompanhados de evidência, impacto estimado, recomendação e ação rápida. Nenhuma regra individual de insight (TASK-122 a TASK-131) pode ser implementada antes desta engine existir.

## Escopo técnico

- Criar contrato `InsightRule` (feature `insights/domain/`) com método `evaluate(InsightContext context) -> List<Insight>`, exigindo que cada regra seja pura (sem I/O, sem chamadas a rede/banco diretamente).
- Modelar entidade `Insight` (freezed) com: `id`, `type` (enum `InsightType`), `title`, `description`, `evidence` (lista estruturada de fatos/números que sustentam o insight), `estimatedImpact` (valor monetário e/ou percentual), `severity`/confiança, `recommendation`, `quickAction` (`InsightAction` tipado: abrir cliente, iniciar pedido, agendar contato, ver categoria, etc.), `organizationId`, `companyId`, entidade relacionada (`customerId`/`productId`/`sellerId`), `generatedAt`, `expiresAt`, `status` (novo/visualizado/em ação/descartado/resolvido).
- Criar `InsightContext`/`InsightDataset` como estrutura de dados já pré-calculados (snapshots de TASK-133), desacoplando as regras da fonte real (Firestore bruto nunca é consumido diretamente pela regra).
- Criar `InsightEngine` (serviço de domínio) que registra regras via injeção (`get_it`/`injectable`), executa todas sobre o mesmo contexto, agrega resultados, aplica deduplicação por (tipo + entidade relacionada) e ordena por impacto estimado.
- Criar `InsightRepository` (contrato + implementação Firestore) persistindo insights em `organizations/{orgId}/insights`, com consulta paginada por destinatário, tipo e status.
- Criar Cloud Function agendada `generateInsightsScheduled` que executa a `InsightEngine` sobre os dados agregados de TASK-133 e grava os insights resultantes — a engine nunca roda no cliente para o volume completo da carteira.
- Implementar validação estrutural: insight sem `evidence`, `estimatedImpact` ou `recommendation` preenchidos é rejeitado antes da persistência.

## Regras de negócio e restrições

- Toda regra deve ser pura (mesma entrada produz sempre a mesma saída), testável isoladamente sem mocks de rede.
- Insight sem evidência explícita nunca deve ser exibido ao usuário — é a regra central da explicabilidade da engine.
- Insights possuem expiração (`expiresAt`) e são recalculados no próximo ciclo agendado; não devem se acumular indefinidamente.
- Cálculo de impacto estimado deve ser auditável: dado um insight, deve ser possível reconstruir os números que originaram o valor exibido.
- Regras de insight vivem na camada domain/Functions, nunca hardcoded na UI.

## Testes obrigatórios

- Teste unitário do `InsightEngine` com regras fake: nenhuma regra dispara, múltiplas regras disparam, deduplicação por tipo+entidade, ordenação por impacto.
- Teste garantindo rejeição de insight sem evidência, impacto ou recomendação.
- Teste do `InsightRepository`: persistência, consulta paginada, filtro por tipo/status.
- Teste de expiração e recálculo de insights entre ciclos.
- Teste de idempotência da Cloud Function agendada (executar duas vezes sobre o mesmo período não duplica insights).

## Critérios de aceite

- Nova regra de insight pode ser adicionada sem alterar o código da `InsightEngine` (aberto para extensão, fechado para modificação).
- Todo insight persistido possui evidência, impacto estimado, recomendação e ação rápida preenchidos.
- Engine consome exclusivamente dados agregados pré-calculados (TASK-133), nunca centenas de queries client-side.
- `flutter analyze`, `dart format --set-exit-if-changed .` e `flutter test` sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
