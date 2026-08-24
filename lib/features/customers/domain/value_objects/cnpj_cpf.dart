import '../../../../core/errors/errors.dart';

enum CnpjCpfType { cpf, cnpj }

/// Brazilian CPF/CNPJ value object with normalization, check-digit validation
/// and display formatting.
final class CnpjCpf {
  const CnpjCpf._({required this.digits, required this.type});

  factory CnpjCpf.parse(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return switch (digits.length) {
      11 => _parseCpf(digits),
      14 => _parseCnpj(digits),
      _ => throw ValidationException(
        'Invalid CPF/CNPJ length.',
        code: 'invalid_cnpj_cpf_length',
        fieldErrors: const <String, String>{
          'document': 'Document must have 11 CPF digits or 14 CNPJ digits.',
        },
        cause: digits.length,
      ),
    };
  }

  final String digits;
  final CnpjCpfType type;

  bool get isCpf => type == CnpjCpfType.cpf;

  bool get isCnpj => type == CnpjCpfType.cnpj;

  String get formatted {
    return switch (type) {
      CnpjCpfType.cpf =>
        '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
            '${digits.substring(6, 9)}-${digits.substring(9, 11)}',
      CnpjCpfType.cnpj =>
        '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
            '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
            '${digits.substring(12, 14)}',
    };
  }

  static CnpjCpf _parseCpf(String digits) {
    if (_hasOnlyRepeatedDigits(digits) || !_hasValidCpfDigits(digits)) {
      throw ValidationException(
        'Invalid CPF check digits.',
        code: 'invalid_cpf_check_digits',
        fieldErrors: const <String, String>{
          'document': 'CPF check digits are invalid.',
        },
        cause: digits,
      );
    }

    return CnpjCpf._(digits: digits, type: CnpjCpfType.cpf);
  }

  static CnpjCpf _parseCnpj(String digits) {
    if (_hasOnlyRepeatedDigits(digits) || !_hasValidCnpjDigits(digits)) {
      throw ValidationException(
        'Invalid CNPJ check digits.',
        code: 'invalid_cnpj_check_digits',
        fieldErrors: const <String, String>{
          'document': 'CNPJ check digits are invalid.',
        },
        cause: digits,
      );
    }

    return CnpjCpf._(digits: digits, type: CnpjCpfType.cnpj);
  }

  static bool _hasOnlyRepeatedDigits(String digits) {
    final first = digits.codeUnitAt(0);
    return digits.codeUnits.every((digit) => digit == first);
  }

  static bool _hasValidCpfDigits(String digits) {
    final firstDigit = _cpfCheckDigit(digits, length: 9);
    final secondDigit = _cpfCheckDigit(digits, length: 10);
    return _digitAt(digits, 9) == firstDigit &&
        _digitAt(digits, 10) == secondDigit;
  }

  static int _cpfCheckDigit(String digits, {required int length}) {
    var sum = 0;
    for (var index = 0; index < length; index += 1) {
      sum += _digitAt(digits, index) * (length + 1 - index);
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  static bool _hasValidCnpjDigits(String digits) {
    const firstWeights = <int>[5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const secondWeights = <int>[6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    final firstDigit = _cnpjCheckDigit(digits, firstWeights);
    final secondDigit = _cnpjCheckDigit(digits, secondWeights);
    return _digitAt(digits, 12) == firstDigit &&
        _digitAt(digits, 13) == secondDigit;
  }

  static int _cnpjCheckDigit(String digits, List<int> weights) {
    var sum = 0;
    for (var index = 0; index < weights.length; index += 1) {
      sum += _digitAt(digits, index) * weights[index];
    }
    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }

  static int _digitAt(String digits, int index) {
    return digits.codeUnitAt(index) - 48;
  }

  @override
  bool operator ==(Object other) {
    return other is CnpjCpf && other.digits == digits;
  }

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => formatted;
}
