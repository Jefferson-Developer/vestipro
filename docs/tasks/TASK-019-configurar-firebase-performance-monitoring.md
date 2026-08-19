# TASK-019 — Configurar Firebase Performance Monitoring

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Performance Monitoring é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar a abstração `PerformanceMonitor` sobre Firebase Performance Monitoring e instrumentar traces customizados para as operações mais críticas do VestiPro (sincronização offline, submissão de pedido, carregamento de catálogo), para que o time consiga identificar regressões de performance em campo antes que se tornem reclamações de vendedores usando o app em conexões instáveis.

## Escopo técnico

- Criar em `lib/core/services/` a abstração `PerformanceMonitor` com métodos como `startTrace(String name)`/`stopTrace(String name)` e `wrapAsync<T>(String name, Future<T> Function() action)`, implementada sobre `firebase_performance`, permitindo instrumentar qualquer operação assíncrona com poucas linhas de código.
- Habilitar as traces automáticas nativas do SDK (rede HTTP/HTTPS, quando aplicável a chamadas REST via `dio`) e documentar que chamadas Firebase (Firestore/Functions) usam trace manual via `PerformanceMonitor`, já que o SDK automático cobre principalmente tráfego HTTP genérico.
- Instrumentar (criar os pontos de trace, mesmo que os fluxos completos ainda não existam) as operações identificadas como críticas pelo backlog: `sync_incremental_duration` (preparado para o motor de sincronização do EPIC-14), `order_submit_duration` (preparado para TASK-101), `catalog_load_duration` (preparado para o EPIC-10) — nesta task, criar os nomes de trace centralizados e, quando possível, aplicar a um ponto real já existente (ex.: tempo de resolução de dependências no bootstrap, ou tempo de carregamento do módulo de exemplo) para validar o mecanismo ponta a ponta.
- Centralizar os nomes de trace em uma classe (`PerformanceTraces`) similar ao padrão já usado para `AnalyticsEvents`, evitando strings soltas.
- Adicionar atributos customizados a cada trace quando relevante (ex.: `organizationId` truncado/anonimizado, tamanho do payload, plataforma) para permitir segmentação da análise de performance.
- Documentar em `docs/architecture/performance.md` a lista de traces planejadas e o ponto do backlog onde cada uma será efetivamente conectada a um fluxo real.

## Regras de negócio e restrições

- Traces não devem registrar dados pessoais sensíveis como atributo; usar identificadores técnicos ou agregados.
- A instrumentação de performance nunca deve adicionar overhead perceptível ao fluxo medido (evitar operações síncronas custosas dentro do wrapper de trace).
- Toda trace criada deve ter um nome estável e documentado — nomes de trace não devem ser alterados livremente depois de já existirem dados históricos coletados.

## Testes obrigatórios

- Teste unitário do `PerformanceMonitor` validando que `wrapAsync` inicia e finaliza a trace corretamente mesmo quando a operação lança exceção (a trace deve ser finalizada, não vazar).
- Teste garantindo que `PerformanceTraces` expõe os nomes planejados sem duplicidade, coerentes com a documentação criada.
- Verificação manual/documentada de que ao menos uma trace real aparece no console Firebase de Performance após execução do app em modo debug/profile.

## Critérios de aceite

- `PerformanceMonitor` implementado como abstração central sobre `firebase_performance`.
- Nomes de trace centralizados em `PerformanceTraces`, cobrindo ao menos sincronização, submissão de pedido e carregamento de catálogo como traces planejadas.
- Pelo menos uma trace real instrumentada e validada no console Firebase.
- Documento `docs/architecture/performance.md` criado, listando traces planejadas e seu ponto de conexão futuro no backlog.
- Testes unitários passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
