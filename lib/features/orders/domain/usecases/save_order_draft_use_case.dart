// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../repositories/order_draft_repository.dart';

/// Persists an in-progress `Order` draft edit (TASK-096 autosave — notes,
/// item/quantity changes in later EPIC-13 tasks) fully offline. Mirrors
/// `SaveCustomerFormDraftUseCase`'s thin-delegation shape, but backed by
/// [OrderDraftRepository] (Drift) instead of a `SharedPreferences`-backed
/// form draft: unlike a customer form draft, an `Order` draft is itself the
/// same aggregate every later EPIC-13 task keeps building on, not a
/// throwaway staging document.
///
/// Deliberately not `final`, mirroring `ListCustomerPortfolioUseCase`'s own
/// precedent for a thin use case a BLoC calls directly: `OrderDraftBloc`'s
/// own tests fake this class outright (`implements SaveOrderDraftUseCase`)
/// instead of composing it with a fake `OrderDraftRepository` every time.
@injectable
class SaveOrderDraftUseCase {
  const SaveOrderDraftUseCase(this._repository);

  final OrderDraftRepository _repository;

  Future<AppResult<void>> call({required Order order}) {
    return _repository.saveDraft(order: order);
  }
}
