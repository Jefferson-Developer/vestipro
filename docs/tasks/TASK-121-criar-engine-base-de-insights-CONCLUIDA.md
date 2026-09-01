# TASK-121 - Criar engine base de insights (CONCLUIDA)

**Epic:** EPIC-16 - Insights e Recomendacao  
**Status:** Concluida  
**Data:** terça-feira, 1 de setembro de 2026  
**Branch:** `main`

## O que foi feito

- Estruturei a nova feature `insights` em `lib/features/insights/` seguindo o padrao feature-first + Clean Architecture, com contratos de dominio, entidades imutaveis, repository, datasource Firestore, mapper e paginacao por destinatario/tipo/status.
- Modelei a entidade `Insight` com evidencia estruturada, impacto estimado, severidade, confianca, recomendacao, acao rapida tipada, expiracao, status e escopo multi-tenant (`organizationId`/`companyId`/`recipientUserId`).
- Criei `InsightContext`, `InsightDataset` e snapshots agregados para desacoplar as regras da fonte de dados bruta, deixando a engine dependente apenas de dados precomputados.
- Implementei `InsightEngine`, `InsightRule` e `InsightStructuralValidator`, com agregacao de regras, validacao obrigatoria de evidencia/impacto/recomendacao, deduplicacao por tipo + entidade relacionada e ordenacao por impacto.
- Adicionei persistencia Firestore em `organizations/{orgId}/insights` com `InsightRepositoryImpl` e `FirestoreInsightDataSource`, incluindo consulta paginada para leitura futura da central de oportunidades.
- Criei a base server-side em `functions/src/insights/`, com engine equivalente em TypeScript e a Cloud Function agendada `generateInsightsScheduled`, preparada para consumir snapshots agregados e regravar insights de forma idempotente.

## Arquivos criados

- `lib/features/insights/` (nova feature completa de dominio e data)
- `functions/src/insights/insight-engine.ts`
- `functions/src/insights/generate-insights-scheduled.ts`
- `functions/src/insights/index.ts`
- `functions/test/insights/generate-insights-scheduled.test.ts`
- `docs/tasks/TASK-121-criar-engine-base-de-insights-CONCLUIDA.md` (este arquivo)

## Arquivos alterados

- `functions/src/index.ts`
- `lib/app/injection.config.dart`
- `docs/tasks/TASKS.md`

## Validacoes executadas

- `flutter pub run build_runner build` - sucesso. O gerador atualizou `lib/app/injection.config.dart`; permaneceram warnings preexistentes de DI em outros modulos fora do escopo desta task.
- `dart format lib/features/insights test/features/insights functions/src/insights functions/test/insights` - sucesso.
- `flutter analyze` - sucesso, sem issues.
- `flutter test test/features/insights` - sucesso, com 10 testes verdes cobrindo engine, validacao estrutural, regras e repositorio.
- `npm test -- --runInBand insights` em `functions/` - sucesso, cobrindo geracao deterministica e idempotente da rotina agendada.

## Decisoes e riscos conhecidos

- A Cloud Function foi preparada para ler snapshots agregados (`insightCustomerSnapshots` e `insightRevenueComparisons`) em vez de consultar Firestore bruto; a camada de agregacao completa do backlog continua sendo responsabilidade da TASK-133.
- A rotina agendada usa ids deterministas por insight para evitar duplicacao entre ciclos. Isso garante idempotencia e evita acumulo indefinido para as regras atuais.
- A leitura por RBAC no cliente ainda nao foi conectada a UI porque a central de oportunidades so chega na TASK-132; nesta task ficou pronta a fundacao de dominio, persistencia e backend.

## Commit

- Commit local desta task: `feat(insights): cria engine base de insights`

## Push

- Nenhum push foi realizado nesta sessao, conforme solicitado.
