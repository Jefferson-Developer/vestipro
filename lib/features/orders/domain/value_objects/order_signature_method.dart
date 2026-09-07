/// How an `OrderSignature` was captured (TASK-180).
///
/// [canvasDrawn] — a manuscript signature drawn on a touchscreen canvas
/// (`OrderSignaturePad`) — is the only method actually implemented today: it
/// requires no external provider/credentials and works fully offline.
///
/// [externalProvider] is the extension point the task's own "avaliar e
/// documentar a necessidade de integração com um provedor externo de
/// assinatura eletrônica avançada/qualificada" requirement asks for — no
/// concrete flow produces this value yet (see
/// `ExternalESignatureProviderGateway`'s own docs for why), it only reserves
/// the code so a future provider integration does not need a new enum value
/// released alongside every historical `OrderSignature` already persisted
/// with [canvasDrawn].
///
/// Code<->enum conversion is centralized in `OrderSignatureCodec`
/// (`data/mappers/order_signature_codec.dart`), same "one place decides the
/// wire codes" precedent `OrderMapper` already sets for `Order` itself — not
/// duplicated here as a per-enum extension.
enum OrderSignatureMethod { canvasDrawn, externalProvider }
