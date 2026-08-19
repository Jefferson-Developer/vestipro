# TASK-017 — Configurar Firebase Analytics

**Epic:** EPIC-01 — Firebase e Observabilidade
**Status:** ⬜ Pendente
**Depende de:** TASK-011 (Firebase Core inicializado — Analytics é um serviço Firebase que depende da inicialização básica)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Criar a abstração central `AnalyticsService` e a taxonomia inicial de eventos comerciais/produto do VestiPro (login, criação de organização, criação de cliente/produto, ações de catálogo e pedido), garantindo que toda feature futura registre eventos de forma consistente e testável, em vez de cada uma inventar seu próprio nome de evento.

## Escopo técnico

- Criar em `lib/core/analytics/` a abstração `AnalyticsService` com uma interface testável/mockável (ex.: `abstract class AnalyticsService { Future<void> logEvent(String name, {Map<String, Object?>? parameters}); Future<void> setUserProperty(...); }`), implementada por `FirebaseAnalyticsService` usando `firebase_analytics`.
- Centralizar os nomes de eventos em uma classe/enum única (`AnalyticsEvents`) para evitar strings mágicas espalhadas pelo código, iniciando com a taxonomia mínima da seção 14 de `tasks.md`: `login_completed`, `organization_created`, `customer_created`, `product_viewed`, `catalog_filtered`, `order_created`, `order_submitted`, `order_sync_failed`, `crm_activity_created`, `insight_opened`, `insight_action_clicked`, `report_exported`, `offline_pack_downloaded`, `product_added_to_order`.
- Configurar `setUserId`/`setUserProperty` para associar `organizationId` (ou um identificador anonimizado equivalente) e papel do usuário (role RBAC) aos eventos, permitindo segmentação de analytics por tenant sem expor dados pessoais desnecessários.
- Implementar um `FakeAnalyticsService`/mock para uso em testes, permitindo que BLoCs e casos de uso que disparam eventos de analytics sejam testados sem depender do SDK real.
- Filtrar eventos de contas de teste/QA e de builds `dev` do fluxo real de Analytics (ex.: via propriedade de usuário `is_test_account` ou projeto Firebase separado, conforme decisão da TASK-010), evitando poluir métricas de produto.
- Documentar em `docs/architecture/analytics.md` a convenção de nomenclatura de eventos (snake_case, verbo no particípio passado, ex.: `_created`, `_completed`, `_viewed`) para orientar a adição de novos eventos nas tasks futuras.

## Regras de negócio e restrições

- Nomes de eventos e parâmetros nunca devem ser strings soltas no código de feature — sempre referenciados a partir de `AnalyticsEvents`.
- Nunca registrar dados pessoais sensíveis (nome completo, e-mail, telefone, CPF/CNPJ) como parâmetro de evento — usar identificadores técnicos.
- Métricas administrativas (auditoria, RBAC) não devem se misturar com métricas comerciais no mesmo fluxo de evento — manter taxonomias separadas se necessário.
- Todo evento definido nesta task deve ser efetivamente disparado apenas quando a feature correspondente existir; nesta task, criar a infraestrutura e, no máximo, instrumentar eventos que já têm uma feature real disponível (ex.: nenhum ainda, já que login/organização/etc. vêm em tasks futuras) — não simular disparo de eventos sem o fluxo de origem existir.

## Testes obrigatórios

- Teste unitário do `AnalyticsService` (via `FakeAnalyticsService`) validando que `logEvent` é chamado com o nome e parâmetros corretos a partir de um ponto de disparo de exemplo.
- Teste garantindo que `AnalyticsEvents` expõe exatamente os nomes definidos na taxonomia inicial, sem duplicidade.
- Teste (unitário) validando que `setUserProperty`/`setUserId` são chamados corretamente ao simular login/logout no `FakeAnalyticsService`.

## Critérios de aceite

- `AnalyticsService` implementado com versão real (`firebase_analytics`) e versão fake/testável.
- Taxonomia inicial de eventos centralizada em `AnalyticsEvents`, documentada em `docs/architecture/analytics.md`.
- Associação de `organizationId`/role de usuário aos eventos implementada.
- Decisão sobre filtragem de eventos de teste/QA documentada e implementada.
- Testes unitários passando.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
