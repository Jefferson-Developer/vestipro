import 'dart:typed_data';

import '../../../organizations/domain/value_objects/organization_settings.dart';

/// Branding applied to a PDF report export's cover page/footer (TASK-148).
///
/// Deliberately carries already-resolved [logoBytes] instead of a URL: the
/// PDF encoder (`PdfReportEncoder`) is pure Dart and must never perform I/O
/// itself, so fetching the logo image from `OrganizationSettings
/// .brandingLogoUrl` is a data-layer concern (`ReportBrandingDataSource`).
///
/// Both fields are independently optional — an organization can configure
/// only a color, only a logo, both, or neither — and a `null` field always
/// means "not configured", never inferred from anything else. When neither
/// is set ([isConfigured] is `false`), `PdfReportEncoder` applies VestiPro's
/// own default identity instead (never a blank/broken cover page).
final class ReportBranding {
  const ReportBranding({this.logoBytes, this.primaryColorHex});

  /// No organization branding at all — the encoder's default fallback.
  const ReportBranding.none() : this();

  final Uint8List? logoBytes;
  final String? primaryColorHex;

  bool get isConfigured => logoBytes != null || primaryColorHex != null;

  /// Reads only the *configuration* (never fetches [logoBytes] — that is
  /// `ReportBrandingDataSource`'s job) out of [settings], so a caller that
  /// already has bytes in hand (e.g. a cache) can still combine them with
  /// the organization's configured color via [copyWith].
  factory ReportBranding.fromSettings(OrganizationSettings settings) =>
      ReportBranding(primaryColorHex: settings.brandingPrimaryColorHex);

  ReportBranding copyWith({Uint8List? logoBytes, String? primaryColorHex}) =>
      ReportBranding(
        logoBytes: logoBytes ?? this.logoBytes,
        primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      );
}
