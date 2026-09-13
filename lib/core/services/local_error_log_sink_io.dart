import 'dart:io';

final class LocalErrorLogSink {
  const LocalErrorLogSink();

  static const fileName = 'vestipro-login-errors.log';

  Future<String?> appendLine(String line) async {
    final file = await _resolveWritableFile();
    await file.writeAsString('$line\n', mode: FileMode.append, flush: true);
    return file.path;
  }

  Future<File> _resolveWritableFile() async {
    final candidates = <Directory>[Directory.current, Directory.systemTemp];

    for (final directory in candidates) {
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      try {
        await file.writeAsString('', mode: FileMode.append, flush: true);
        return file;
      } catch (_) {
        // Try the next writable location.
      }
    }

    return File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
    );
  }
}
