/// Public surface of `lib/features/dashboards/`.
///
/// TASK-133 shipped the read layer (`AggregationRepository` + its
/// Firestore-backed implementation) every dashboard in EPIC-17 reuses.
/// TASK-134 (Executive Dashboard) is the first screen populating
/// `presentation/`.
library;

export 'data/datasources/aggregation_remote_data_source.dart';
export 'data/datasources/firestore_aggregation_data_source.dart';
export 'data/dtos/aggregation_snapshot_dto.dart';
export 'data/mappers/aggregation_snapshot_mapper.dart';
export 'data/repositories/aggregation_repository_impl.dart';
export 'domain/entities/aggregation_snapshot.dart';
export 'domain/entities/executive_dashboard_filters.dart';
export 'domain/entities/executive_dashboard_metric.dart';
export 'domain/entities/executive_dashboard_snapshot.dart';
export 'domain/entities/executive_dashboard_trend_point.dart';
export 'domain/entities/executive_dashboard_visibility_filter.dart';
export 'domain/entities/collection_dashboard_category_mix.dart';
export 'domain/entities/collection_dashboard_entry.dart';
export 'domain/entities/collection_dashboard_filters.dart';
export 'domain/entities/customer_dashboard_filters.dart';
export 'domain/entities/customer_dashboard_ranking_row.dart';
export 'domain/entities/customer_dashboard_snapshot.dart';
export 'domain/entities/inventory_dashboard_filters.dart';
export 'domain/entities/inventory_dashboard_snapshot.dart';
export 'domain/entities/inventory_dashboard_stalled_product_page.dart';
export 'domain/entities/inventory_dashboard_stalled_product_row.dart';
export 'domain/entities/product_dashboard_filters.dart';
export 'domain/entities/product_dashboard_ranking_row.dart';
export 'domain/entities/product_dashboard_snapshot.dart';
export 'domain/entities/sales_dashboard_filters.dart';
export 'domain/entities/sales_dashboard_group_row.dart';
export 'domain/entities/sales_dashboard_kpi.dart';
export 'domain/entities/sales_dashboard_snapshot.dart';
export 'domain/repositories/aggregation_repository.dart';
export 'domain/services/executive_dashboard_visibility_service.dart';
export 'domain/usecases/build_product_dashboard_snapshot_use_case.dart';
export 'domain/usecases/load_collection_dashboard_entries_use_case.dart';
export 'domain/usecases/load_customer_dashboard_ranking_use_case.dart';
export 'domain/usecases/load_customer_dashboard_snapshot_use_case.dart';
export 'domain/usecases/load_executive_dashboard_snapshot_use_case.dart';
export 'domain/usecases/load_inventory_dashboard_snapshot_use_case.dart';
export 'domain/usecases/load_inventory_dashboard_stalled_products_use_case.dart';
export 'domain/usecases/load_product_dashboard_ranking_use_case.dart';
export 'domain/usecases/load_sales_dashboard_group_rows_use_case.dart';
export 'domain/usecases/load_sales_dashboard_snapshot_use_case.dart';
export 'domain/value_objects/aggregation_dimension.dart';
export 'domain/value_objects/customer_dashboard_sort_field.dart';
export 'domain/value_objects/product_dashboard_sort_field.dart';
export 'domain/value_objects/sales_dashboard_comparison_mode.dart';
export 'domain/value_objects/sales_dashboard_group_dimension.dart';
export 'domain/value_objects/sales_dashboard_sort_field.dart';
export 'presentation/bloc/collection_dashboard_bloc.dart';
export 'presentation/bloc/collection_dashboard_event.dart';
export 'presentation/bloc/collection_dashboard_state.dart';
export 'presentation/bloc/customer_dashboard_bloc.dart';
export 'presentation/bloc/customer_dashboard_event.dart';
export 'presentation/bloc/customer_dashboard_state.dart';
export 'presentation/bloc/executive_dashboard_bloc.dart';
export 'presentation/bloc/executive_dashboard_event.dart';
export 'presentation/bloc/executive_dashboard_state.dart';
export 'presentation/bloc/inventory_dashboard_bloc.dart';
export 'presentation/bloc/inventory_dashboard_event.dart';
export 'presentation/bloc/inventory_dashboard_state.dart';
export 'presentation/bloc/product_dashboard_bloc.dart';
export 'presentation/bloc/product_dashboard_event.dart';
export 'presentation/bloc/product_dashboard_state.dart';
export 'presentation/bloc/sales_dashboard_bloc.dart';
export 'presentation/bloc/sales_dashboard_event.dart';
export 'presentation/bloc/sales_dashboard_state.dart';
export 'presentation/pages/collection_dashboard_page.dart';
export 'presentation/pages/customer_dashboard_page.dart';
export 'presentation/pages/executive_dashboard_page.dart';
export 'presentation/pages/inventory_dashboard_page.dart';
export 'presentation/pages/product_dashboard_page.dart';
export 'presentation/pages/sales_dashboard_page.dart';
