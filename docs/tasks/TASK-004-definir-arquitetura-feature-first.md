# TASK-004 — Definir arquitetura feature-first + Clean Architecture

**Epic:** EPIC-00 — Fundação e Arquitetura
**Status:** ⬜ Pendente
**Depende de:** TASK-001 (projeto Flutter criado, pastas `lib/core`/`lib/features` existentes), TASK-003 (dependências de arquitetura como `freezed`, `get_it`, `injectable`, `flutter_bloc` já resolvidas no pubspec)

## Agentes obrigatórios

- `flutter-senior-architect`

## Objetivo

Materializar a arquitetura feature-first + Clean Architecture descrita na seção 4.1 de `tasks.md` como estrutura de pastas real e como um módulo de exemplo funcional, para que todas as ~200 tasks seguintes de feature tenham um padrão concreto para copiar em vez de reinterpretar a especificação a cada task.

## Escopo técnico

- Criar as subpastas de `lib/core/`: `analytics/`, `auth/`, `database/`, `design_system/`, `errors/`, `extensions/`, `navigation/`, `network/`, `offline/`, `permissions/`, `services/`, `sync/`, `utils/` (vazias ou com um arquivo `barrel`/README mínimo indicando o propósito de cada uma — o conteúdo real de cada uma é populado pelas tasks específicas: erros nesta task, navegação na TASK-007, sync no EPIC-14 etc.).
- Escolher uma feature simples e de baixo risco para servir de módulo de referência (recomendado: `lib/features/settings/` com uma única tela de "Sobre o app" ou `lib/features/onboarding/` com uma tela estática) e implementá-la completa com as quatro camadas: `presentation/` (`bloc/`, `pages/`, `widgets/`), `domain/` (`entities/`, `repositories/`, `usecases/`, `value_objects/`), `data/` (`datasources/`, `dtos/`, `mappers/`, `models/`, `repositories/`) — mesmo que o datasource seja um mock em memória, sem Firebase ainda.
- Criar `lib/core/errors/` com a hierarquia `AppException`/`Failure` completa descrita pelo agente Flutter Senior (`NetworkException`, `TimeoutException`, `UnauthorizedException`, `ForbiddenException`, `NotFoundException`, `ValidationException`, `ConflictException`, `ServerException`, `CacheException`, `SyncException`, `UnknownException` no lado de exceções; `ConnectivityFailure`, `AuthenticationFailure`, `PermissionFailure`, `ValidationFailure`, `NotFoundFailure`, `ConflictFailure`, `ServerFailure`, `UnexpectedFailure` no lado de domínio).
- Documentar em um arquivo (`docs/architecture/README.md` ou similar dentro de `docs/`) o fluxo obrigatório de dados: Página → Evento do BLoC → BLoC → Caso de uso → Contrato do repositório → Implementação → Datasource, e o fluxo de retorno inverso com DTO → Mapper → Entidade → Estado do BLoC → Interface.
- Garantir que a camada `domain/` do módulo de exemplo não importa `flutter`, `firebase_core`, `drift` ou qualquer pacote de UI/infra — validar isso manualmente ou via regra de lint/import (ex.: `import_lint` ou revisão de imports) como precedente para as próximas features.

## Regras de negócio e restrições

- `presentation/` nunca acessa datasource ou repositório diretamente — sempre via BLoC + caso de uso.
- `domain/` não conhece Firestore, Drift, Dio, nem qualquer detalhe de infraestrutura.
- Entidades são imutáveis (usar `freezed`) e distintas de DTOs; DTOs residem exclusivamente em `data/dtos/`.
- Nenhuma regra de negócio real (preço, RBAC, sincronização) é implementada aqui — o módulo de exemplo deve ser propositalmente simples para não antecipar decisões de outras tasks.

## Testes obrigatórios

- Teste unitário do caso de uso do módulo de exemplo, cobrindo sucesso e uma falha esperada (retorno de `Failure`).
- Teste unitário do mapper DTO → Entidade do módulo de exemplo.
- Teste de widget mínimo validando que a página do módulo de exemplo renderiza os estados de loading/sucesso/erro do BLoC.
- Teste garantindo que a hierarquia de `AppException`/`Failure` está corretamente exportada e instanciável.

## Critérios de aceite

- Estrutura completa de `lib/core/` (subpastas) e de `lib/features/` (com o módulo de exemplo) presente no repositório, seguindo exatamente a árvore da seção 4.1 de `tasks.md`.
- Módulo de exemplo funcional com as quatro camadas implementadas e testadas.
- Hierarquia de exceções e failures criada em `lib/core/errors/`.
- Documento de arquitetura descrevendo o fluxo obrigatório de dados criado em `docs/`.
- `flutter analyze` e `flutter test` passam sem erros.

## Arquivos prováveis

- A definir pelo agente executor no início da task, com base no estado real do repositório no momento da execução (este backlog foi escrito antes da implementação; não presuma que a estrutura de pastas do plano já existe).

## Referências

- Especificação funcional completa: `tasks.md` (raiz do projeto)
- Agente Flutter Senior: `.claude/agents/flutter-senior-architect.md`
- Agente Front-end: `.claude/agents/flutter-ui-design-specialist.md` (quando aplicável)
- Fluxo obrigatório de execução, testes, documentação e commit: `AGENTS.md` (raiz do projeto)
