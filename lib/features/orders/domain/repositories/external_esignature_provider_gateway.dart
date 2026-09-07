import '../../../../core/utils/utils.dart';
import '../entities/order.dart';

/// Extension point for a future external, advanced/qualified electronic
/// signature provider (EPIC-13, TASK-180's own "avaliar e documentar a
/// necessidade de integração com um provedor externo... implementar ao
/// menos o ponto de extensão" requirement).
///
/// **No concrete implementation exists yet** — this interface is
/// deliberately unregistered in DI (no `@Injectable`/`@LazySingleton`
/// binding) and nothing in this codebase calls it. It exists so a future
/// task can plug in a provider such as DocuSign/Clicksign/ZapSign (ICP-Brasil
/// certificate-backed, "assinatura eletrônica qualificada") without having
/// to redesign `OrderSignature`/`signOrder`'s own shape: that future
/// implementation would still persist an `OrderSignature` with
/// `method: OrderSignatureMethod.externalProvider`, still going through
/// `signOrder` for the actual write (never a client-side Firestore/Storage
/// write, same rule every other signature method already follows) — only
/// the *how the signer actually signs* step changes (an external provider's
/// own hosted signing flow/webhook instead of the in-app canvas), typically
/// requiring:
/// - [requestSignature] to kick off the provider's own hosted signing flow
///   (usually returns a redirect URL/envelope id, not a finished signature —
///   the actual signed evidence normally arrives later, asynchronously, via
///   the provider's own webhook);
/// - a new Cloud Function (mirroring `signOrder`) receiving that webhook,
///   validating the provider's own signature/authenticity token, and only
///   then persisting the `OrderSignature` the exact same way `signOrder`
///   does today for a canvas capture.
///
/// See `docs/tasks/TASK-180-implementar-assinatura-eletronica-de-pedido-CONCLUIDA.md`
/// ("Decisões técnicas"/"Regras de negócio implementadas") for the full
/// analysis of why the canvas-drawn signature (already implemented) is
/// sufficient for VestiPro's own commercial process today, and in which
/// scenarios a qualified provider like this one would actually be required
/// instead.
abstract interface class ExternalESignatureProviderGateway {
  /// Starts an external signing flow for [order], to be completed by
  /// [signerEmail] outside of this app (email/SMS/hosted page) — returns a
  /// provider-specific reference (e.g. "envelope id") the caller can use to
  /// track status, never the finished signature itself.
  Future<AppResult<String>> requestSignature({
    required Order order,
    required String signerEmail,
  });
}
