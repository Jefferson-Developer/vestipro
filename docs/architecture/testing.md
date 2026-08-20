# Testing

Testing conventions are mandatory for every VestiPro task that touches Dart or Flutter code.
The `settings` feature is the reference implementation for this pattern, mirroring the folder
pattern documented in [`README.md`](README.md).

## Folder Pattern

`test/` mirrors `lib/features/<feature>/` layer by layer:

```text
test/features/<feature>/
  domain/
    usecases/
  data/
    mappers/
    repositories/
  presentation/
    bloc/
    pages/
```

Reference implementation: `test/features/settings/`.

- `test/features/settings/domain/usecases/get_about_app_use_case_test.dart`
- `test/features/settings/domain/domain_import_boundary_test.dart`
- `test/features/settings/data/mappers/about_app_mapper_test.dart`
- `test/features/settings/data/repositories/about_app_repository_impl_test.dart`
- `test/features/settings/presentation/bloc/about_app_bloc_test.dart`
- `test/features/settings/presentation/pages/about_app_page_test.dart`

## File Naming Convention

Every test file ends with `_test.dart` and mirrors the name of the file under test, e.g.
`lib/features/settings/data/repositories/about_app_repository_impl.dart` is covered by
`test/features/settings/data/repositories/about_app_repository_impl_test.dart`.

## Coverage Goals by Layer

| Layer | Target coverage |
| --- | ---: |
| Domain (entities, value objects) | 90% |
| Use cases | 90% |
| BLoCs/Cubits | 85% |
| Repositories (implementation) | 80% |
| Mappers (DTO to entity) | 100% |

These are targets, not automatic build gates. Every task that adds or changes code in a layer above
must add or update tests proportional to the risk of that change.

## Running Tests Locally

```bash
flutter test
```

To measure coverage:

```bash
flutter test --coverage
```

This generates `coverage/lcov.info`. To inspect it as HTML (requires `lcov`/`genhtml`, e.g. via
`choco install lcov` or WSL):

```bash
genhtml coverage/lcov.info -o coverage/html
```

## Test Doubles: `mocktail`

VestiPro uses [`mocktail`](https://pub.dev/packages/mocktail) to mock contracts. `mocktail` does not
require `build_runner`, keeping test doubles independent from code generation.

Rules:

- Mock the `abstract`/`abstract interface class` contract (repository, datasource), never a concrete
  implementation. Mocking a concrete class hides real behavior (mapping, error translation) that the
  test should exercise.
- Declare the mock next to the test that uses it: `class _MockAboutAppDataSource extends Mock
  implements AboutAppDataSource {}`.
- Prefer real collaborators (mappers, value objects) over mocking them when they are pure and
  side-effect free; this keeps mapping/business logic covered instead of assumed.
- Use `setUp` to create a fresh mock and subject under test per test case, avoiding shared mutable
  state between tests.
- Use `registerFallbackValue` only when a matcher like `any()` is used for a non-primitive argument
  type; the example module does not need it because arguments are matched by literal value.

Reference: `test/features/settings/data/repositories/about_app_repository_impl_test.dart` mocks
`AboutAppDataSource` to cover:

- Success: datasource returns a valid DTO, repository maps it to an entity via `AboutAppMapper`.
- Failure: datasource throws an `AppException` (e.g. `NotFoundException`), repository converts it to
  a `Failure` via `mapAppExceptionToFailure`.
- Failure: datasource throws a `FormatException`, repository converts it to a `ValidationFailure`.
- Failure: datasource throws a generic exception, repository converts it to an `UnexpectedFailure`.

For use cases that depend only on a repository contract, a manual stub implementing the interface
(e.g. `_AboutAppRepositoryStub` in `get_about_app_use_case_test.dart`) remains an accepted lightweight
alternative to `mocktail` when the contract is small and no interaction verification (`verify`) is
needed. Prefer `mocktail` when the test needs to verify call arguments/count or when the contract has
many methods that a manual stub would otherwise have to implement with `UnimplementedError()`.

For BLoC/Cubit tests, use `bloc_test` (`blocTest`) together with `mocktail` to mock use cases, as in
`test/features/settings/presentation/bloc/about_app_bloc_test.dart`.

## Golden Tests (`golden_toolkit`)

**Decision: not adopted yet.** `golden_toolkit` is not added to `pubspec.yaml`.

Rationale: golden tests are most valuable once there is a stable Design System (typography, colors,
spacing, shared components) to assert pixel-accurate rendering against. EPIC-02 (Design System) has
not started, so introducing golden tests now would immediately be invalidated by upcoming
Design System changes, adding maintenance cost without a stable baseline.

This decision will be revisited when EPIC-02 (Design System) starts. At that point, add
`golden_toolkit` as a dev dependency, call `loadAppFonts()` in a `setUpAll`, and add a
`testGoldens` example for a simple shared widget before requiring golden coverage on other features.

## Widget Tests

Widget tests render the page with a `BlocProvider` supplying a mocked/stubbed BLoC or an in-memory
fake state stream, and assert on rendered output for loading, success, and error states — never by
reaching into a datasource or repository implementation. See
`test/features/settings/presentation/pages/about_app_page_test.dart`.

## Isolation Rules

- No test depends on real network access, a real Firebase project, or shared global state between
  tests.
- Use `setUp`/`tearDown` to reset mocks and subjects under test for every test case.
- Domain-layer tests must not import `package:flutter/*`; `test/features/settings/domain/domain_import_boundary_test.dart`
  enforces this for the reference feature.
