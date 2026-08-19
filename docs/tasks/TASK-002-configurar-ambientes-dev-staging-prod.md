# TASK-002 — Configurar ambientes dev, staging e prod

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-001 (inicializar projeto Flutter multiplataforma) — precisa do projeto criado e das pastas de plataforma (Android/iOS/Web) existentes para configurar flavors e entrypoints sobre elas

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Estabelecer três ambientes isolados (`development`, `staging`, `production`) para que o VestiPro nunca misture dados de desenvolvimento com dados reais de clientes, e para que builds de cada ambiente sejam gerados de forma reprodutível nas três plataformas. Esta configuração é pré-requisito direto de TASK-010 (projetos Firebase por ambiente).

## Escopo técnico

- Configurar flavors no Android (`android/app/build.gradle`) para `dev`, `staging` e `prod`, cada um com `applicationIdSuffix` próprio (ex.: `.dev`, `.staging`) e `versionNameSuffix` quando útil, mantendo `prod` com o `applicationId` final sem sufixo.
- Configurar xcconfig por flavor no iOS (`ios/Flutter/Dev.xcconfig`, `Staging.xcconfig`, `Prod.xcconfig` incluídos a partir de `Debug.xcconfig`/`Release.xcconfig`), com bundle identifiers e display names distintos, e schemes correspondentes no Xcode.
- Criar entrypoints `lib/main_dev.dart`, `lib/main_staging.dart`, `lib/main_prod.dart`, cada um configurando um objeto de ambiente (`AppEnvironment`) antes de chamar a função de bootstrap comum em `lib/app/`; manter `lib/main.dart` como delegação simples para `main_dev.dart` (ambiente padrão para `flutter run` sem flags).
- Para Flutter Web (que não possui flavors nativos), diferenciar ambiente via `--dart-define=ENVIRONMENT=development|staging|production` lido em tempo de build por uma classe `Environment`/`AppConfig` central em `lib/core/` (ainda que o `core/` completo só seja estruturado na TASK-004, criar aqui o mínimo necessário: um único arquivo de configuração de ambiente).
- Documentar no README os comandos exatos para rodar/buildar cada ambiente em cada plataforma (ex.: `flutter run --flavor dev -t lib/main_dev.dart`, `flutter build web --dart-define=ENVIRONMENT=staging`).
- Definir e documentar nomes visuais distintos do app por ambiente (ex.: "VestiPro Dev", "VestiPro Staging", "VestiPro") para evitar confusão entre instalações no mesmo dispositivo.

## Regras de negócio e restrições

- Nunca usar configuração/dados de produção durante desenvolvimento local, conforme regra do agente Flutter Senior.
- Cada ambiente deve poder coexistir instalado no mesmo dispositivo físico (bundle id/applicationId distintos) para permitir teste comparativo.
- Nenhuma credencial real de produção deve ser referenciada nesta task (Firebase entra na TASK-010); aqui apenas a estrutura de diferenciação de ambiente é criada.

## Testes obrigatórios

- Validar `flutter run --flavor dev -t lib/main_dev.dart` (ou build equivalente) inicia sem erro no Android.
- Validar build/scheme `staging` e `prod` no iOS constrói sem erro de configuração (quando ambiente macOS disponível; documentar impedimento caso contrário).
- Validar `flutter build web --dart-define=ENVIRONMENT=staging` gera build distinto do `production` (ex.: nome/label visível na tela inicial de debug).
- Teste unitário simples validando que `AppEnvironment`/`AppConfig` resolve corretamente os três valores esperados a partir do `dart-define`/flavor.

## Critérios de aceite

- Três flavors Android configurados e funcionais (`dev`, `staging`, `prod`).
- Três xcconfigs/schemes iOS configurados e documentados.
- Três entrypoints Dart (`main_dev.dart`, `main_staging.dart`, `main_prod.dart`) mais `main.dart` delegando para dev.
- Diferenciação de ambiente Web funcional via `--dart-define=ENVIRONMENT`.
- README atualizado com os comandos de execução/build por ambiente e plataforma.
- `flutter analyze` e `flutter test` continuam passando após a mudança.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
