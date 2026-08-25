/// Public surface of `lib/features/favorites/`.
library;

export 'domain/entities/favorite_catalog_page.dart';
export 'domain/entities/favorite_product.dart';
export 'domain/entities/favorite_product_page.dart';
export 'domain/repositories/favorite_repository.dart';
export 'domain/usecases/add_favorite_product_use_case.dart';
export 'domain/usecases/list_favorite_products_use_case.dart';
export 'domain/usecases/remove_favorite_product_use_case.dart';
export 'domain/usecases/watch_favorite_product_ids_use_case.dart';
export 'domain/value_objects/favorite_sync_status.dart';
export 'presentation/bloc/favorites_bloc.dart';
export 'presentation/bloc/favorites_event.dart';
export 'presentation/bloc/favorites_state.dart';
export 'presentation/cubit/favorite_status_cubit.dart';
export 'presentation/cubit/favorite_status_state.dart';
export 'presentation/pages/favorites_page.dart';
