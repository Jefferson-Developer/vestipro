# TASK-133 — Criar camada de agregação server-side

**Epic:** EPIC-17 — Dashboards e BI
**Status:** ⬜ Pendente
**Depende de:** TASK-095 (Order e OrderItem modelados — origem do faturamento e quantidade vendida), TASK-048 (Customer modelado — origem dos dados de carteira/segmento), TASK-064 (Product modelado — origem de categoria/coleção/cor/tamanho)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar a camada de agregações/snapshots pré-calculados server-side que alimenta todos os dashboards do EPIC-17 e todas as regras de insight do EPIC-16 (seção 12 de `tasks.md`). Dashboards e engine de insights nunca devem executar centenas de queries do cliente — este é o alicerce de performance e escalabilidade do BI do VestiPro.

## Escopo técnico

- Criar Cloud Functions de agregação (agendadas via Cloud Scheduler e/ou triggers de escrita, conforme a métrica) que pré-calculam: faturamento por período (dia/semana/mês) por organização/empresa, por cliente, por produto/categoria/coleção, por vendedor/equipe e por região.
- Modelar coleções de snapshot no Firestore dimensionadas para leitura direta pelos dashboards (ex.: `organizations/{orgId}/aggregates/salesDaily/{date}`, `.../aggregates/customerMonthly/{customerId_period}`, `.../aggregates/productMonthly/{productId_period}`, `.../aggregates/sellerMonthly/{sellerId_period}`, `.../aggregates/regionMonthly/{region_period}`), evitando fan-out de queries no cliente.
- Definir e documentar a estratégia de atualização por métrica: near-real-time via trigger de escrita (ex.: contadores simples de pedidos do dia) vs. batch periódico agendado (ex.: giro de estoque, mix por cliente, rankings — recalculados a cada N horas), com o trade-off de cada abordagem explicitado.
- Implementar idempotência em todas as Cloud Functions de agregação: reprocessar o mesmo período não duplica nem corrompe o snapshot (upsert determinístico por chave de período).
- Criar `AggregationRepository` no app para consumir exclusivamente os snapshots já prontos, com cache local e TTL — nenhum dashboard calcula agregação pesada no cliente.
- Instrumentar cada função de agregação com logging estruturado e observabilidade (tempo de execução, quantidade de documentos processados, falhas) via Crashlytics/Performance Monitoring.

## Regras de negócio e restrições

- Nenhum dashboard deve executar centenas de queries client-side; todo dado exibido vem de um snapshot pré-calculado ou de uma consulta pontual e limitada (ex.: drill-down para um único pedido).
- Todo snapshot carrega `organizationId`/`companyId` e nunca mistura dados de tenants diferentes.
- Falha em uma função de agregação não pode travar as demais — isolamento por métrica/job.
- Reprocessamento manual de um período (ex.: correção de dados históricos) deve ser possível de forma controlada e idempotente, sem duplicar registros.

## Testes obrigatórios

- Teste (Firebase Emulator Suite) de cada função de agregação cobrindo: primeira execução, reexecução idempotente do mesmo período, período sem dados (zero), dados de múltiplos tenants (isolamento garantido).
- Teste de performance/tempo de execução com volume representativo simulado.
- Teste do `AggregationRepository` cobrindo cache local, TTL e fallback quando o snapshot ainda não existe para o período consultado.
- Teste de Security Rules garantindo que um usuário não consegue ler snapshot de agregação de outra organização.

## Critérios de aceite

- Todas as métricas necessárias aos dashboards das TASK-134 a TASK-143 possuem snapshot correspondente definido e documentado.
- Nenhuma consulta de dashboard varre coleções brutas de pedidos/clientes/produtos em tempo real no cliente.
- Estratégia de atualização (near-real-time vs. batch) documentada explicitamente por métrica.
- Testes no Firebase Emulator Suite cobrindo idempotência e isolamento multi-tenant aprovados.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
