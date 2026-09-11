/// Public surface of `lib/features/barcode_scanner/` (TASK-216): scan or
/// manually type a code and resolve it to a product/variant, offline-first.
///
/// Every other feature that wants "escanear para localizar/adicionar
/// produto" (busca global, pedido, detalhe do produto, conferência de
/// mostruário) imports this barrel only, never a file inside `domain/`,
/// `data/` or `presentation/` directly.
library;

export 'domain/entities/alternate_product_code.dart';
export 'domain/entities/product_code_match.dart';
export 'domain/entities/product_code_resolution.dart';
export 'domain/entities/scanned_code.dart';
export 'domain/repositories/product_code_lookup_repository.dart';
export 'domain/services/scanned_code_classifier.dart';
export 'domain/usecases/register_unknown_product_code_use_case.dart';
export 'domain/usecases/resolve_product_code_use_case.dart';
export 'domain/value_objects/internal_qr_payload.dart';
export 'domain/value_objects/scanned_code_format.dart';
export 'presentation/cubit/barcode_scan_cubit.dart';
export 'presentation/cubit/barcode_scan_state.dart';
export 'presentation/pages/barcode_scanner_page.dart';
export 'presentation/widgets/manual_code_entry_field.dart';
