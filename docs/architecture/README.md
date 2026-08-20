# VestiPro Architecture

This document defines the baseline pattern for feature-first Clean Architecture in the VestiPro app.

## Folder Pattern

Each feature must keep code grouped by business capability:

```text
lib/features/<feature>/
  presentation/
    bloc/
    pages/
    widgets/
  domain/
    entities/
    repositories/
    usecases/
    value_objects/
  data/
    datasources/
    dtos/
    mappers/
    models/
    repositories/
```

The `settings` feature is the reference implementation for this pattern.

State management conventions are documented in [`state-management.md`](state-management.md).
Dependency injection conventions are documented in
[`dependency-injection.md`](dependency-injection.md).
Navigation conventions (routing, guards, deep links) are documented in
[`navigation.md`](navigation.md).
Static quality conventions are documented in [`static-quality.md`](static-quality.md).

## Data Flow

The required request flow is:

```text
Page -> Event/Cubit command -> BLoC/Cubit -> Use case -> Repository contract -> Repository implementation -> Datasource
```

The required response flow is:

```text
Datasource -> DTO -> Mapper -> Entity -> AppResult -> BLoC/Cubit state -> Interface
```

## Layer Rules

- `presentation/` depends on BLoC/Cubit, use cases, states, and widgets. It never calls a datasource or repository implementation directly.
- `domain/` owns entities, value objects, use cases, and repository contracts. It must not import Flutter, Firebase, Drift, widgets, or infrastructure packages.
- `data/` owns DTOs, mappers, datasource contracts/implementations, models, and repository implementations.
- DTOs are not entities. DTOs stay in `data/dtos/`; entities stay in `domain/entities/`.
- External errors are converted to `AppException` in infrastructure and returned to domain/presentation as `Failure` through `AppResult`.
- Dependency wiring lives in `lib/app/injection.dart` and is resolved from the app composition
  boundary.

## Current Reference

`lib/features/settings/` implements an in-memory "About app" module:

- Page renders loading, success, and error states.
- BLoC calls use cases injected through its constructor.
- BLoC events use explicit concurrency transformers for loading, search, pagination, and submission.
- Use case depends only on `AboutAppRepository`.
- Repository implementation calls `AboutAppDataSource`, maps `AboutAppDto` to `AboutApp`, and converts exceptions to failures.
- Paginated architecture notes preserve loaded items and expose data origin in state.
- Domain imports are covered by a boundary test.
