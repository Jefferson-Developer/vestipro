// `injectable` also exports an `Order` annotation (unrelated to this
// feature's `Order` entity) — hidden here to avoid an ambiguous import, same
// precedent `OrderLocalMapper` already follows.
import 'package:injectable/injectable.dart' hide Order;

import '../../../../core/utils/utils.dart';
import '../entities/order.dart';
import '../repositories/order_draft_repository.dart';

/// Loads a locally stored `Order` by id (TASK-096) — used to resume a draft
/// after the app was closed/restarted, entirely offline.
///
/// Deliberately not `final`, mirroring `ListCustomerPortfolioUseCase`'s own
/// precedent for a thin use case a BLoC calls directly: `OrderDraftBloc`'s
/// own tests fake this class outright (`implements GetOrderDraftUseCase`)
/// instead of composing it with a fake `OrderDraftRepository` every time.
@injectable
class GetOrderDraftUseCase {
  const GetOrderDraftUseCase(this._repository);

  final OrderDraftRepository _repository;

  Future<AppResult<Order?>> call({
    required String organizationId,
    required String companyId,
    required String id,
  }) {
    return _repository.getDraftById(
      organizationId: organizationId,
      companyId: companyId,
      id: id,
    );
  }
}
