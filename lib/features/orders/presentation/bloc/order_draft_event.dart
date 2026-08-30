import '../../../customers/domain/entities/customer.dart';

/// Events `OrderDraftBloc` reacts to (EPIC-13, TASK-096).
sealed class OrderDraftEvent {
  const OrderDraftEvent();
}

/// Starts the "novo pedido" flow, scoped to [organizationId]/[companyId]/
/// [sellerId]. When [draftId] is provided, the bloc tries to resume that
/// exact draft from the local Drift cache instead of starting empty — the
/// "sobrevive ao fechamento do app" requirement.
final class OrderDraftStarted extends OrderDraftEvent {
  const OrderDraftStarted({
    required this.organizationId,
    required this.companyId,
    required this.sellerId,
    this.draftId,
  });

  final String organizationId;
  final String companyId;
  final String sellerId;
  final String? draftId;
}

/// The seller picked a customer from their carteira (or resumed picking one
/// after a previous failed attempt) — starts (or restarts) the `Order`
/// draft for that customer.
final class OrderDraftCustomerSelected extends OrderDraftEvent {
  const OrderDraftCustomerSelected(this.customer);

  final Customer customer;
}

/// The seller edited the draft's observação/notes field. Triggers a
/// debounced autosave, mirroring `CustomerPortfolioSearchDebounced`'s
/// token-based debounce inside the bloc itself (never in a widget Timer).
final class OrderDraftNotesChanged extends OrderDraftEvent {
  const OrderDraftNotesChanged(this.notes);

  final String notes;
}

/// Internal event the bloc's own debounce `Timer` adds once
/// [OrderDraftBloc.autoSaveDebounce] elapses after the last relevant change.
/// [token] lets `OrderDraftBloc` ignore a stale timer that fired after a
/// newer edit already rescheduled it.
final class OrderDraftAutoSaved extends OrderDraftEvent {
  const OrderDraftAutoSaved(this.token);

  final int token;
}

/// Manually retries persisting the current in-memory draft after a failed
/// autosave — the "falha de autosave local deve ser tratada como erro
/// recuperável, nunca silenciosa" requirement: the UI must offer this,
/// never just swallow the failure.
final class OrderDraftAutoSaveRetried extends OrderDraftEvent {
  const OrderDraftAutoSaveRetried();
}

/// The seller changed a typed quantity for an item already on the draft
/// (TASK-097), directly from the items list — e.g. via `AppQuantityStepper`.
/// [quantity] of zero or less removes the line, same "0 means gone"
/// convention `ProductDetailQuantityChanged` already sets. Triggers the same
/// debounced autosave as [OrderDraftNotesChanged].
final class OrderDraftItemQuantityChanged extends OrderDraftEvent {
  const OrderDraftItemQuantityChanged({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final int quantity;
}

/// The seller removed an item already on the draft (TASK-097) directly from
/// the items list. Triggers the same debounced autosave as
/// [OrderDraftNotesChanged].
final class OrderDraftItemRemoved extends OrderDraftEvent {
  const OrderDraftItemRemoved(this.itemId);

  final String itemId;
}
