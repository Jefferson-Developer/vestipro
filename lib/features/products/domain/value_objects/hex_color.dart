import '../../../../core/errors/errors.dart';

final class HexColor {
  const HexColor._(this.value);

  factory HexColor.parse(String value) {
    final normalized = value.trim().replaceFirst('#', '').toUpperCase();
    if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(normalized)) {
      throw ValidationException(
        'Invalid color hex.',
        code: 'invalid_color_hex',
        fieldErrors: const <String, String>{
          'hex': 'Informe uma cor hexadecimal válida, ex.: #1F3A5F.',
        },
        cause: value,
      );
    }
    return HexColor._('#$normalized');
  }

  final String value;

  int get red => int.parse(value.substring(1, 3), radix: 16);
  int get green => int.parse(value.substring(3, 5), radix: 16);
  int get blue => int.parse(value.substring(5, 7), radix: 16);

  int distanceTo(HexColor other) {
    final dr = red - other.red;
    final dg = green - other.green;
    final db = blue - other.blue;
    return dr * dr + dg * dg + db * db;
  }

  @override
  bool operator ==(Object other) => other is HexColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
