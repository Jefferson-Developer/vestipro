/// Public surface of `lib/features/customers/`.
library;

export 'domain/entities/customer.dart';
export 'domain/repositories/customer_repository.dart';
export 'domain/usecases/create_customer_use_case.dart';
export 'domain/usecases/deactivate_customer_use_case.dart';
export 'domain/usecases/get_customer_by_id_use_case.dart';
export 'domain/usecases/update_customer_use_case.dart';
export 'domain/value_objects/cnpj_cpf.dart';
export 'domain/value_objects/customer_sensitive_field.dart';
export 'domain/value_objects/customer_status.dart';
export 'domain/value_objects/customer_sync_status.dart';
export 'domain/value_objects/customer_type.dart';
