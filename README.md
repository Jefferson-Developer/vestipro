# VestiPro

Plataforma omnichannel de força de vendas para o mercado de moda B2B (Flutter + Firebase): CRM,
catálogo de produtos por cor/grade, tabelas de preço, pedidos, operação offline real, inteligência
comercial e BI — multi-tenant desde a fundação, com foco em ser **o sistema de força de vendas
mobile mais completo do mercado de moda**.

Este projeto segue um protocolo único de execução de backlog, descrito em [`AGENTS.md`](AGENTS.md).
O backlog técnico e o status de progresso ficam em [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md);
cada task individual está documentada em `docs/tasks/TASK-XXX-*.md`. A especificação funcional
completa do produto está em [`tasks.md`](tasks.md).

## Como continuar o backlog

```
/proxima-task
```

ou, em qualquer ferramenta (Claude Code ou Codex CLI):

```
Rode a próxima task pendente do backlog em docs/tasks/TASKS.md
```

Isso abre `docs/tasks/TASKS.md`, localiza a primeira task pendente e executa o fluxo obrigatório
completo descrito em `AGENTS.md` (agentes especializados, testes, documentação, commit).

## Agentes especializados

- `.claude/agents/flutter-senior-architect.md` — arquitetura, domain, data, Firebase, multi-tenancy,
  RBAC, offline-first, motor de precificação, engine de insights, agregações de BI, segurança,
  testes, CI/CD.
- `.claude/agents/flutter-ui-design-specialist.md` — interface, Design System, componentes,
  responsividade, acessibilidade, UX premium de moda.

## Estrutura de pastas

```text
lib/
├── app/
├── core/            # analytics, auth, database, design_system, errors, navigation, network,
│                     # offline, permissions, services, sync, utils
├── features/         # authentication, onboarding, organizations, users, crm, customers, products,
│                     # catalog, inventory, pricing, orders, dashboards, reports, insights, targets,
│                     # notifications, settings
└── main.dart
```

`core/`, `design_system/` e `features/` ainda não têm conteúdo além do template padrão do Flutter —
nenhuma feature real foi implementada ainda. A arquitetura completa (Clean Architecture por feature,
BLoC, injeção de dependência, navegação com `go_router`, offline-first com Drift) está descrita em
`.claude/agents/flutter-senior-architect.md` e será adicionada progressivamente pelas tasks do
backlog, começando por `docs/tasks/TASK-001-inicializar-projeto-flutter-multiplataforma.md`.

## Backend

Firebase: Authentication, Cloud Firestore, Storage, Cloud Functions, Analytics, Crashlytics,
Performance Monitoring, Cloud Messaging, Remote Config, App Check. Nenhum SDK Firebase está
integrado ainda — a configuração começa em `docs/tasks/TASK-010-criar-projetos-firebase.md`
(EPIC-01).

## Documentação

- Protocolo de execução do backlog: [`AGENTS.md`](AGENTS.md)
- Backlog e status: [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md)
- Especificação funcional completa: [`tasks.md`](tasks.md)
