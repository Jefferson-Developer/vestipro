# TASK-007 — Configurar navegação principal

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-004 (estrutura feature-first para localizar `lib/core/navigation/` e as páginas do módulo de exemplo), TASK-005 (BLoC/Cubit configurado, pois os guards de rota reagirão a estados de autenticação/sessão futuros via BLoC)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Estabelecer `go_router` como sistema único de navegação do VestiPro, com rotas tipadas e guards centralizados preparados desde já para autenticação e organização ativa — mesmo antes de o módulo de autenticação existir (EPIC-04) — para que nenhuma feature futura precise inventar seu próprio mecanismo de navegação ou proteção de rota.

## Escopo técnico

- Criar `lib/core/navigation/app_router.dart` configurando `GoRouter` com rotas tipadas (usar `go_router_builder` ou classes de rota nomeadas explicitamente, nunca strings soltas espalhadas pelo código de features).
- Definir o padrão de rota com escopo de organização já embutido na convenção, mesmo que ainda não haja dado real: `/org/:orgId/...` como prefixo para rotas autenticadas, replicando os exemplos de `tasks.md`/agente Flutter Senior (`/org/:orgId/customers/:customerId`, `/org/:orgId/catalog/:collectionSlug`, `/org/:orgId/orders/:orderId`, `/org/:orgId/dashboards/executive`, `/org/:orgId/reports/:reportId`).
- Implementar um guard de autenticação (`redirect` do `GoRouter`) preparado como interface/abstração (`AuthGuard`) que hoje sempre libera a navegação (stub), mas que será conectado ao estado real de sessão na TASK-041 sem exigir refatoração de rotas.
- Implementar guard de organização ativa (`ActiveOrganizationGuard`) como stub análogo, a ser conectado quando o modelo de Organization existir (TASK-026/TASK-037).
- Implementar rota de fallback "não encontrada" (404) e rota "sem permissão" (403), cada uma com uma página simples e reutilizável do design system (mesmo que ainda genérica, antes do EPIC-02 completo).
- Preparar suporte a deep links: habilitar `GoRouter.routerConfig` com suporte a URLs diretas no Flutter Web preservando parâmetros de rota, e configurar `AndroidManifest.xml`/`Info.plist` com esqueleto de intent-filters/associated domains comentado/documentado para ativação futura (a ativação completa de deep link universal pode ficar como pendência documentada se depender de domínio próprio ainda não definido).
- Integrar a navegação do módulo de exemplo (TASK-004) como primeira rota real usando este router, substituindo qualquer navegação ad-hoc.

## Regras de negócio e restrições

- Nenhuma string de rota deve ser escrita diretamente dentro de widgets de feature — sempre via método/rota tipada exposta por `app_router.dart`.
- Guards de autenticação/organização nunca devem ser reimplementados localmente por uma feature; toda feature que precisar de proteção declara isso na configuração central de rotas.
- Preferir passar IDs (não objetos grandes) como parâmetro de rota, para manter deep links e refresh de página (Web) funcionando corretamente.
- Filtros relevantes de listagem devem poder ser preservados na URL no Flutter Web (ex.: via query parameters), mesmo que a feature real de filtros venha em tasks futuras — deixar a capacidade prevista na configuração do router.

## Testes obrigatórios

- Teste de navegação validando que a rota 404 é exibida para um caminho inexistente.
- Teste de navegação validando que a rota "sem permissão" é acessível e renderiza corretamente quando o guard nega acesso (usando o stub configurado nesta task).
- Teste garantindo que a rota do módulo de exemplo resolve parâmetros de path corretamente (ex.: um ID passado na URL chega ao BLoC/página esperado).
- Teste (ou verificação manual documentada) de que o Flutter Web preserva a rota após reload (deep link básico).

## Critérios de aceite

- `go_router` configurado como único mecanismo de navegação do projeto, com rotas tipadas.
- Guards de autenticação e organização ativa implementados como stubs plugáveis, documentados como ponto de extensão para TASK-041 e TASK-037.
- Rotas 404 e "sem permissão" implementadas e navegáveis.
- Convenção `/org/:orgId/...` documentada em `docs/architecture/` para uso por todas as features futuras.
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
