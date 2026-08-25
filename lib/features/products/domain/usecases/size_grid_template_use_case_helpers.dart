import '../../../../core/errors/errors.dart';
import '../entities/size_grid_template.dart';

typedef SizeGridValidationResult = ({
  List<SizeGridSize> sizes,
  Map<String, String> fieldErrors,
});

String normalizeSizeGridTemplateName(String value) => value.trim();

List<SizeGridSize> normalizeSizeGridSizes(List<SizeGridSize> sizes) {
  final ordered = List<SizeGridSize>.of(sizes)
    ..sort((a, b) {
      final byScore = a.orderScore.compareTo(b.orderScore);
      if (byScore != 0) return byScore;
      return a.label.compareTo(b.label);
    });

  return List<SizeGridSize>.unmodifiable(
    ordered.indexed.map((entry) {
      final (index, size) = entry;
      return SizeGridSize(
        id: size.id.trim(),
        organizationId: size.organizationId.trim(),
        label: size.label.trim(),
        orderScore: index + 1,
      );
    }),
  );
}

SizeGridValidationResult validateSizeGridTemplatePayload({
  required String organizationId,
  required String name,
  required List<SizeGridSize> sizes,
}) {
  final fieldErrors = <String, String>{};
  final trimmedOrganizationId = organizationId.trim();
  final trimmedName = normalizeSizeGridTemplateName(name);
  if (trimmedOrganizationId.isEmpty) {
    fieldErrors['organizationId'] = 'OrganizationId is required.';
  }
  if (trimmedName.isEmpty) {
    fieldErrors['name'] = 'Informe o nome do template de grade.';
  }
  if (sizes.isEmpty) {
    fieldErrors['sizes'] = 'Informe ao menos um tamanho.';
  }

  final normalizedSizes = normalizeSizeGridSizes(sizes);
  final labels = <String>{};
  for (final size in normalizedSizes) {
    if (size.id.isEmpty) {
      fieldErrors['sizes'] = 'Cada tamanho precisa de um id.';
    }
    if (size.organizationId != trimmedOrganizationId) {
      fieldErrors['sizes'] =
          'Todos os tamanhos precisam pertencer à organização ativa.';
    }
    if (size.label.isEmpty) {
      fieldErrors['sizes'] = 'Tamanho não pode ficar vazio.';
    }
    final normalizedLabel = size.label.toLowerCase();
    if (!labels.add(normalizedLabel)) {
      fieldErrors['sizes'] = 'Não repita tamanhos no mesmo template.';
    }
  }

  return (sizes: normalizedSizes, fieldErrors: fieldErrors);
}

ValidationFailure sizeGridTemplateValidationFailure(
  Map<String, String> fieldErrors, {
  required String code,
}) {
  return ValidationFailure(
    'Invalid size grid template payload.',
    fieldErrors: fieldErrors,
    code: code,
  );
}
