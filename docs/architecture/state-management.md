# State Management

VestiPro uses `flutter_bloc`/`bloc` as the default state management pattern for presentation flows.
Each feature keeps BLoC/Cubit code in `lib/features/<feature>/presentation/bloc/`.

## Naming

- Prefer one BLoC per functional flow, not one large BLoC for an entire feature.
- Name events as user or system intent, for example `OrderDraftItemAdded`,
  `OrderGridQuantityChanged`, `AboutAppSearchQueryChanged`.
- Name states as complete situations, for example `OrderDraftInitial`, `OrderDraftLoading`,
  `OrderDraftReady`, `OrderSubmitting`, `OrderSubmitFailure`.
- Use Cubit only for flows with no meaningful event concurrency. Use BLoC when events can overlap,
  be cancelled, dropped, or ordered.

## State Rules

- States are immutable and compare by value. New states must use `freezed` unless there is a clear
  reason not to.
- Do not emit partially valid states. Every state represents a complete UI situation.
- Preserve already loaded data when a pagination or refresh operation fails.
- Include data origin when it affects the UI, such as local cache versus remote synchronized data.
- BLoCs never receive `BuildContext`, navigate, show dialogs, or instantiate repositories directly.
  They receive use cases through constructors.

## Event Concurrency

Use `bloc_concurrency` transformers explicitly when event overlap matters:

- `sequential()` for operations that must stay ordered, such as submissions or writes.
- `restartable()` for user input where the latest intent wins, such as search and filters.
- `droppable()` for load-more or bootstrap events where duplicate in-flight requests should be
  ignored.

The reference implementation is `AboutAppBloc` in `lib/features/settings/presentation/bloc/`.
It uses:

- `droppable()` for initial loading and next-page requests.
- `restartable()` for architecture note search.
- `sequential()` for diagnostics submission.

## Pagination

Paginated states must keep the currently loaded items while a new page is requested. On success,
append the next page to the existing list. On failure, emit a failure state that still contains the
previous items, current page, query, `hasMore`, and data origin.

## Observer

`VestiProBlocObserver` is registered in `lib/app/bootstrap.dart`. In debug mode it logs structured
BLoC changes and transitions through `dart:developer`, recording only runtime types and event names.
This is a temporary lightweight logger until the dedicated AppLogger/Crashlytics setup is completed
in the observability tasks.
