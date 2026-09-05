import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

/// Hands exported bytes (CSV, TASK-146; XLSX, TASK-147) to the platform's
/// native "save file" dialog. Deliberately kept as its own tiny datasource
/// (instead of, say, `dart:io.File`) because `file_picker` is the one
/// dependency already in `pubspec.yaml` (used for uploads elsewhere,
/// TASK-068) whose `saveFile` API works uniformly across mobile/desktop/web
/// — writing raw bytes straight through `dart:io` would not compile on web.
abstract interface class ReportFileSaverDataSource {
  /// Returns the URI/path the platform reports back, or `null` when the user
  /// cancels the native save dialog — never throws for a cancellation, only
  /// for a genuine I/O failure.
  Future<String?> save({required List<int> bytes, required String fileName});
}

/// Mime-type/allowed-extension known to this datasource, keyed by the
/// export file's own extension (`ReportExportFileNameBuilder`'s `.csv`/
/// `.xlsx`/`.pdf`) — kept as a small lookup instead of a format parameter so
/// a future export format only needs a new map entry, never a signature
/// change on [ReportFileSaverDataSource.save].
const Map<String, String> _mimeTypeByExtension = <String, String>{
  'csv': 'text/csv',
  'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'pdf': 'application/pdf',
};

@LazySingleton(as: ReportFileSaverDataSource)
final class FilePickerReportFileSaverDataSource
    implements ReportFileSaverDataSource {
  const FilePickerReportFileSaverDataSource();

  @override
  Future<String?> save({
    required List<int> bytes,
    required String fileName,
  }) async {
    final dotIndex = fileName.lastIndexOf('.');
    final extension = dotIndex == -1
        ? 'csv'
        : fileName.substring(dotIndex + 1).toLowerCase();
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
      mimeType: _mimeTypeByExtension[extension] ?? 'application/octet-stream',
      dialogTitle: 'Salvar exportação de relatório',
      type: FileType.custom,
      allowedExtensions: <String>[extension],
    );
    return uri?.toString();
  }
}
