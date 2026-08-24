/// Centralizes the "is this Product complete enough to publish" rule
/// (TASK-065's acceptance criteria: "publicação é bloqueada até que nome,
/// SKU, categoria e demais campos mínimos configurados estejam presentes").
///
/// `name`/`sku`/`reference` are already non-nullable on [Product] (TASK-064)
/// — the entity's type system alone cannot guarantee they are non-blank
/// (an empty string is still a valid `String`), so this validator re-checks
/// them defensively alongside two fields a draft is explicitly allowed to
/// skip: `categoryId` and, since TASK-068, a principal photo. Used by
/// `PublishProductUseCase` — never duplicated inline in a BLoC or a widget
/// (`AGENTS.md`: "regra de negócio não fica em widget").
library;

/// Returns a field-keyed map of validation messages; empty when [name],
/// [sku], [reference], [categoryId] and [hasPrincipalPhoto] are all
/// satisfied, matching the `ValidationFailure.fieldErrors` shape every other
/// VestiPro use case returns.
///
/// [hasPrincipalPhoto] (TASK-068) is passed in rather than a `Product`
/// itself so this validator stays a plain function over primitives, exactly
/// like every other field here — the caller (`PublishProductUseCase`) is the
/// one that knows how to derive it from `Product.hasPrincipalPhoto`.
Map<String, String> validateProductCompletenessForPublish({
  required String name,
  required String sku,
  required String reference,
  String? categoryId,
  required bool hasPrincipalPhoto,
}) {
  final errors = <String, String>{};

  if (name.trim().isEmpty) {
    errors['name'] = 'Informe o nome do produto.';
  }
  if (sku.trim().isEmpty) {
    errors['sku'] = 'Informe o SKU do produto.';
  }
  if (reference.trim().isEmpty) {
    errors['reference'] = 'Informe a referência do produto.';
  }
  if (categoryId == null || categoryId.trim().isEmpty) {
    errors['categoryId'] = 'Selecione a categoria do produto.';
  }
  if (!hasPrincipalPhoto) {
    errors['media'] = 'Defina uma foto principal antes de publicar.';
  }

  return errors;
}
