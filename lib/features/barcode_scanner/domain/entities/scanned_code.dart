import '../value_objects/scanned_code_format.dart';

/// One decoded read — from the camera or the manual fallback field — before
/// it is resolved against the catalog (TASK-216).
final class ScannedCode {
  const ScannedCode({
    required this.rawValue,
    required this.format,
    required this.scannedAt,
  });

  final String rawValue;
  final ScannedCodeFormat format;
  final DateTime scannedAt;
}
