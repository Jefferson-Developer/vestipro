import '../../../../core/errors/errors.dart';

/// Brazilian postal code value object with normalization and display format.
final class Cep {
  const Cep._(this.digits);

  factory Cep.parse(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw ValidationException(
        'Invalid CEP length.',
        code: 'invalid_cep_length',
        fieldErrors: const <String, String>{
          'zipCode': 'CEP must have 8 digits.',
        },
        cause: digits.length,
      );
    }

    if (RegExp(r'^(\d)\1{7}$').hasMatch(digits)) {
      throw ValidationException(
        'Invalid CEP digits.',
        code: 'invalid_cep_digits',
        fieldErrors: const <String, String>{
          'zipCode': 'CEP cannot use only repeated digits.',
        },
        cause: digits,
      );
    }

    return Cep._(digits);
  }

  final String digits;

  String get formatted => '${digits.substring(0, 5)}-${digits.substring(5)}';

  @override
  bool operator ==(Object other) => other is Cep && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => formatted;
}
