/// Who physically signed an `OrderSignature` (TASK-180): the [customer]
/// closing the pedido, or the [seller] themselves when the commercial
/// process calls for the representative's own signature instead (e.g. an
/// internal/sample order). Independent from [signedByUserId] (always the
/// authenticated seller operating the device the canvas was drawn on) —
/// [OrderSignature.signedByName] is the free-text name of whoever this role
/// says actually signed.
enum OrderSignerRole { customer, seller }
