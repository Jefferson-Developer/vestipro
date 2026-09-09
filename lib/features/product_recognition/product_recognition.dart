/// Public surface of `lib/features/product_recognition/`.
library;

export 'data/repositories/cloud_functions_product_recognition_repository.dart';
export 'domain/entities/product_recognition_candidate.dart';
export 'domain/entities/product_recognition_result.dart';
export 'domain/repositories/product_recognition_repository.dart';
export 'domain/usecases/recognize_product_image_use_case.dart';
export 'domain/usecases/submit_product_recognition_feedback_use_case.dart';
export 'domain/value_objects/product_recognition_feedback_outcome.dart';
export 'presentation/cubit/product_recognition_cubit.dart';
export 'presentation/cubit/product_recognition_state.dart';
export 'presentation/pages/product_recognition_page.dart';
