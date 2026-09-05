import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// Hands exported CSV bytes to the platform's native "save file" dialog.
/// Deliberately kept as its own tiny datasource (instead of, say,
/// `dart:io.File`) because `file_picker` is the one dependency already in
/// `pubspec.yaml` (used for uploads elsewhere, TASK-068) whose `saveFile`
/// API works uniformly across mobile/desktop/web — writing raw bytes
/// straight through `dart:io` would not compile on web.
abstract interface class ReportFileSaverDataSource {
  /// Returns the URI/path the platform reports back, or `null` when the user
  /// cancels the native save dialog — never throws for a cancellation, only
  /// for a genuine I/O failure.
  Future<String?> save({required List<int> bytes, required String fileName});
}

@LazySingleton(as: ReportFileSaverDataSource)
final class FilePickerReportFileSaverDataSource
    implements ReportFileSaverDataSource {
  const FilePickerReportFileSaverDataSource();

  @override
  Future<String?> save({
    required List<int> bytes,
    required String fileName,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: 'text/csv',
      dialogTitle: 'Salvar exportação de relatório',
      type: FileType.custom,
      allowedExtensions: const <String>['csv'],
    );
    return uri?.toString();
  }
}
