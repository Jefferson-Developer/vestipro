import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/utils/utils.dart';
import '../../../organizations/domain/entities/organization.dart';
import '../../../organizations/domain/repositories/organization_repository.dart';
import '../../domain/entities/report_branding.dart';

/// Resolves the calling organization's configured PDF branding (TASK-148) —
/// `OrganizationSettings.brandingLogoUrl`/`brandingPrimaryColorHex` — into a
/// [ReportBranding] with the logo image already downloaded as bytes, ready
/// for the pure-Dart `PdfReportEncoder` to embed without performing any I/O
/// of its own.
///
/// Never throws: the organization lookup and the logo download each degrade
/// independently — an organization that fails to load falls back to
/// [ReportBranding.none], and a configured-but-unreachable/broken logo URL
/// falls back to a color-only [ReportBranding] instead of blocking the PDF
/// export entirely (TASK-148's own fallback rule).
abstract interface class ReportBrandingDataSource {
  Future<ReportBranding> resolve(String organizationId);
}

@LazySingleton(as: ReportBrandingDataSource)
final class OrganizationReportBrandingDataSource
    implements ReportBrandingDataSource {
  const OrganizationReportBrandingDataSource(this._organizations, this._dio);

  final OrganizationRepository _organizations;
  final Dio _dio;

  @override
  Future<ReportBranding> resolve(String organizationId) async {
    final result = await _organizations.getById(organizationId);
    if (result is! AppSuccess<Organization>) return const ReportBranding.none();

    final settings = result.value.settings;
    final colorHex = settings.brandingPrimaryColorHex;
    final logoUrl = settings.brandingLogoUrl;
    if (logoUrl == null) return ReportBranding(primaryColorHex: colorHex);

    try {
      final response = await _dio.get<List<int>>(
        logoUrl,
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null) return ReportBranding(primaryColorHex: colorHex);
      return ReportBranding(
        primaryColorHex: colorHex,
        logoBytes: Uint8List.fromList(bytes),
      );
    } catch (_) {
      // A broken/unreachable logo URL never blocks the export — falls back
      // to the organization's configured color (or VestiPro's own default
      // when that is not configured either).
      return ReportBranding(primaryColorHex: colorHex);
    }
  }
}
