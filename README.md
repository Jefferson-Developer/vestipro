# VestiPro

Plataforma omnichannel de força de vendas para o mercado de moda B2B (Flutter + Firebase): CRM,
catálogo de produtos por cor/grade, tabelas de preço, pedidos, operação offline real, inteligência
comercial e BI — multi-tenant desde a fundação, com foco em ser **o sistema de força de vendas
mobile mais completo do mercado de moda**.

Este projeto segue um protocolo único de execução de backlog, descrito em [`AGENTS.md`](AGENTS.md).
O backlog técnico e o status de progresso ficam em [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md);
cada task individual está documentada em `docs/tasks/TASK-XXX-*.md`. A especificação funcional
completa do produto está em [`tasks.md`](tasks.md).

## Versão do Flutter

Este projeto foi inicializado e validado com:

- Flutter 3.44.7 stable
- Dart 3.12.2

A versão recomendada também está registrada em [`.fvmrc`](.fvmrc), para reprodutibilidade entre
máquinas de desenvolvimento e CI.

## Como rodar

```bash
flutter pub get
flutter run
```

Para Web:

```bash
flutter run -d chrome
```

## Qualidade estática

Antes de concluir uma task com código Dart/Flutter, execute:

```powershell
.\scripts\check.ps1
```

O script valida `dart format --set-exit-if-changed .`, `flutter analyze` e comentários `TODO`/`FIXME`
sem referência de task, issue ou URL. As regras e limites de revisão ficam em
[`docs/architecture/static-quality.md`](docs/architecture/static-quality.md).

## Ambientes

O VestiPro possui três ambientes isolados, com nomes visuais e identifiers distintos:

- `development` / `dev`: VestiPro Dev
- `staging`: VestiPro Staging
- `production` / `prod`: VestiPro

`flutter run` sem flags usa o ambiente `development`.

### Android

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

flutter build apk --debug --flavor dev -t lib/main_dev.dart
flutter build apk --debug --flavor staging -t lib/main_staging.dart
flutter build apk --release --flavor prod -t lib/main_prod.dart
```

### iOS

Os schemes compartilhados são `dev`, `staging` e `prod`, com `.xcconfig` próprios em `ios/Flutter/`.

```bash
flutter run --flavor dev -t lib/main_dev.dart
flutter run --flavor staging -t lib/main_staging.dart
flutter run --flavor prod -t lib/main_prod.dart

flutter build ipa --flavor staging -t lib/main_staging.dart
flutter build ipa --flavor prod -t lib/main_prod.dart
```

Builds iOS exigem macOS com Xcode.

### Web

Flutter Web não usa flavors nativos; o ambiente é escolhido por `--dart-define`.

```bash
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=development
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=staging
flutter run -d chrome -t lib/main_web.dart --dart-define=ENVIRONMENT=production

flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=staging
flutter build web -t lib/main_web.dart --dart-define=ENVIRONMENT=production
```

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

`core/` possui apenas a configuração mínima de ambiente criada na TASK-002; `features/` ainda não
possui feature real. A arquitetura completa (Clean Architecture por feature, BLoC, injeção de
dependência, navegação com `go_router`, offline-first com Drift) está descrita em
`.claude/agents/flutter-senior-architect.md` e será adicionada progressivamente pelas próximas tasks.

## Backend

Firebase: Authentication, Cloud Firestore, Storage, Cloud Functions, Analytics, Crashlytics,
Performance Monitoring, Cloud Messaging, Remote Config, App Check. Nenhum SDK Firebase está
integrado ainda — a configuração começa em `docs/tasks/TASK-010-criar-projetos-firebase.md`
(EPIC-01).

## Documentação

- Protocolo de execução do backlog: [`AGENTS.md`](AGENTS.md)
- Backlog e status: [`docs/tasks/TASKS.md`](docs/tasks/TASKS.md)
- Especificação funcional completa: [`tasks.md`](tasks.md)
