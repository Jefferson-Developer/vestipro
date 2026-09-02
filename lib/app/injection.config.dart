// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:cloud_functions/cloud_functions.dart' as _i809;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_app_check/firebase_app_check.dart' as _i56;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:firebase_crashlytics/firebase_crashlytics.dart' as _i141;
import 'package:firebase_performance/firebase_performance.dart' as _i346;
import 'package:firebase_remote_config/firebase_remote_config.dart' as _i627;
import 'package:firebase_storage/firebase_storage.dart' as _i457;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:uuid/uuid.dart' as _i706;

import '../core/analytics/analytics.dart' as _i202;
import '../core/analytics/analytics_service.dart' as _i932;
import '../core/analytics/firebase_analytics_service.dart' as _i569;
import '../core/auth/auth.dart' as _i472;
import '../core/auth/data/datasources/auth_data_source.dart' as _i845;
import '../core/auth/data/datasources/firebase_auth_data_source.dart' as _i814;
import '../core/auth/data/datasources/secure_flutter_session_store.dart'
    as _i772;
import '../core/auth/data/datasources/secure_session_store.dart' as _i99;
import '../core/auth/data/mappers/auth_user_mapper.dart' as _i26;
import '../core/auth/data/repositories/auth_repository_impl.dart' as _i961;
import '../core/auth/data/services/session_service_impl.dart' as _i520;
import '../core/auth/domain/repositories/auth_repository.dart' as _i217;
import '../core/auth/domain/services/session_service.dart' as _i885;
import '../core/connectivity/connectivity_plus_service.dart' as _i4;
import '../core/connectivity/connectivity_service.dart' as _i610;
import '../core/database/app_database.dart' as _i935;
import '../core/database/database.dart' as _i658;
import '../core/environment/app_environment.dart' as _i461;
import '../core/feature_flags/feature_flag_service.dart' as _i972;
import '../core/feature_flags/feature_flags.dart' as _i869;
import '../core/feature_flags/firebase_feature_flag_service.dart' as _i845;
import '../core/functions/app_client_metadata.dart' as _i465;
import '../core/functions/cloud_functions_service.dart' as _i147;
import '../core/functions/functions.dart' as _i340;
import '../core/notifications/data/repositories/shared_preferences_notification_inbox_repository.dart'
    as _i393;
import '../core/notifications/domain/repositories/notification_inbox_repository.dart'
    as _i73;
import '../core/notifications/notifications.dart' as _i387;
import '../core/offline/data/repositories/drift_offline_package_status_repository.dart'
    as _i963;
import '../core/offline/domain/download_offline_package_use_case.dart' as _i109;
import '../core/offline/domain/offline_package_entity_loader.dart' as _i84;
import '../core/offline/domain/repositories/offline_package_status_repository.dart'
    as _i799;
import '../core/offline/presentation/cubit/offline_package_download_cubit.dart'
    as _i74;
import '../core/performance/firebase_performance_monitor.dart' as _i387;
import '../core/performance/performance_monitor.dart' as _i1008;
import '../core/permissions/permission_service.dart' as _i315;
import '../core/permissions/permissions.dart' as _i47;
import '../core/services/crash_reporter.dart' as _i349;
import '../core/services/firebase_crash_reporter.dart' as _i559;
import '../core/services/services.dart' as _i113;
import '../core/storage/firebase_storage_data_source.dart' as _i833;
import '../core/storage/image_compressor.dart' as _i611;
import '../core/storage/image_upload_compressor.dart' as _i620;
import '../core/storage/storage.dart' as _i209;
import '../core/storage/storage_data_source.dart' as _i904;
import '../core/sync/data/repositories/drift_conflict_audit_log_repository.dart'
    as _i59;
import '../core/sync/data/repositories/drift_conflict_record_repository.dart'
    as _i566;
import '../core/sync/data/repositories/drift_outbox_repository.dart' as _i170;
import '../core/sync/data/repositories/drift_sync_cursor_repository.dart'
    as _i152;
import '../core/sync/domain/conflict_resolution_service.dart' as _i746;
import '../core/sync/domain/repositories/conflict_audit_log_repository.dart'
    as _i552;
import '../core/sync/domain/repositories/conflict_record_repository.dart'
    as _i814;
import '../core/sync/domain/repositories/outbox_repository.dart' as _i234;
import '../core/sync/domain/repositories/sync_cursor_repository.dart' as _i405;
import '../core/sync/domain/sync_engine.dart' as _i292;
import '../core/sync/domain/sync_pull_source.dart' as _i417;
import '../core/sync/domain/sync_push_handler.dart' as _i17;
import '../core/sync/domain/sync_retry_policy.dart' as _i158;
import '../core/sync/domain/sync_scheduler.dart' as _i970;
import '../core/sync/presentation/cubit/conflict_list_cubit.dart' as _i189;
import '../core/sync/presentation/cubit/conflict_resolution_cubit.dart'
    as _i717;
import '../core/sync/presentation/cubit/outbox_watcher_cubit.dart' as _i866;
import '../core/sync/presentation/cubit/sync_center_cubit.dart' as _i542;
import '../features/audit_log/data/datasources/audit_log_data_source.dart'
    as _i432;
import '../features/audit_log/data/datasources/firestore_audit_log_data_source.dart'
    as _i709;
import '../features/audit_log/data/mappers/audit_log_entry_mapper.dart'
    as _i246;
import '../features/audit_log/data/repositories/audit_log_repository_impl.dart'
    as _i303;
import '../features/audit_log/domain/repositories/audit_log_repository.dart'
    as _i753;
import '../features/audit_log/domain/usecases/list_audit_log_entries_use_case.dart'
    as _i201;
import '../features/audit_log/domain/usecases/record_audit_log_use_case.dart'
    as _i421;
import '../features/authentication/data/datasources/firestore_user_profile_data_source.dart'
    as _i1043;
import '../features/authentication/data/datasources/user_profile_data_source.dart'
    as _i668;
import '../features/authentication/data/mappers/user_profile_mapper.dart'
    as _i756;
import '../features/authentication/data/repositories/user_profile_repository_impl.dart'
    as _i801;
import '../features/authentication/domain/repositories/user_profile_repository.dart'
    as _i488;
import '../features/authentication/domain/usecases/create_account_with_email_and_password_use_case.dart'
    as _i90;
import '../features/authentication/domain/usecases/send_password_reset_email_use_case.dart'
    as _i820;
import '../features/authentication/domain/usecases/sign_in_with_email_and_password_use_case.dart'
    as _i185;
import '../features/authentication/presentation/bloc/forgot_password_bloc.dart'
    as _i1015;
import '../features/authentication/presentation/bloc/login_bloc.dart' as _i776;
import '../features/authentication/presentation/bloc/sign_up_bloc.dart'
    as _i481;
import '../features/catalog/data/repositories/remote_config_catalog_home_config_repository.dart'
    as _i288;
import '../features/catalog/data/repositories/shared_preferences_catalog_campaign_repository.dart'
    as _i565;
import '../features/catalog/data/repositories/shared_preferences_catalog_home_cache_repository.dart'
    as _i26;
import '../features/catalog/data/repositories/shared_preferences_catalog_preferences_repository.dart'
    as _i590;
import '../features/catalog/domain/repositories/catalog_campaign_repository.dart'
    as _i150;
import '../features/catalog/domain/repositories/catalog_home_cache_repository.dart'
    as _i841;
import '../features/catalog/domain/repositories/catalog_home_config_repository.dart'
    as _i1072;
import '../features/catalog/domain/repositories/catalog_preferences_repository.dart'
    as _i1031;
import '../features/catalog/domain/usecases/create_campaign_use_case.dart'
    as _i169;
import '../features/catalog/domain/usecases/delete_campaign_use_case.dart'
    as _i961;
import '../features/catalog/domain/usecases/get_campaign_use_case.dart'
    as _i746;
import '../features/catalog/domain/usecases/get_catalog_campaigns_section_use_case.dart'
    as _i151;
import '../features/catalog/domain/usecases/get_catalog_home_config_use_case.dart'
    as _i316;
import '../features/catalog/domain/usecases/get_featured_collections_section_use_case.dart'
    as _i1042;
import '../features/catalog/domain/usecases/get_new_arrivals_section_use_case.dart'
    as _i76;
import '../features/catalog/domain/usecases/list_campaign_related_products_use_case.dart'
    as _i345;
import '../features/catalog/domain/usecases/list_campaigns_use_case.dart'
    as _i328;
import '../features/catalog/domain/usecases/list_catalog_products_use_case.dart'
    as _i448;
import '../features/catalog/domain/usecases/load_catalog_home_cache_use_case.dart'
    as _i249;
import '../features/catalog/domain/usecases/load_catalog_preferences_use_case.dart'
    as _i700;
import '../features/catalog/domain/usecases/save_catalog_home_cache_use_case.dart'
    as _i64;
import '../features/catalog/domain/usecases/save_catalog_preferences_use_case.dart'
    as _i36;
import '../features/catalog/domain/usecases/update_campaign_use_case.dart'
    as _i598;
import '../features/catalog/presentation/bloc/campaign_form_bloc.dart' as _i419;
import '../features/catalog/presentation/bloc/campaign_list_bloc.dart' as _i59;
import '../features/catalog/presentation/bloc/catalog_filter_bloc.dart'
    as _i186;
import '../features/catalog/presentation/bloc/catalog_home_bloc.dart' as _i420;
import '../features/catalog/presentation/bloc/lookbook_bloc.dart' as _i630;
import '../features/catalog/presentation/bloc/product_detail_bloc.dart'
    as _i578;
import '../features/catalog/presentation/bloc/product_grid_bloc.dart' as _i331;
import '../features/catalog_share/data/datasources/catalog_share_data_source.dart'
    as _i993;
import '../features/catalog_share/data/datasources/catalog_share_lookup_data_source.dart'
    as _i979;
import '../features/catalog_share/data/datasources/cloud_functions_catalog_share_lookup_data_source.dart'
    as _i354;
import '../features/catalog_share/data/datasources/firestore_catalog_share_data_source.dart'
    as _i1002;
import '../features/catalog_share/data/mappers/catalog_share_mapper.dart'
    as _i1010;
import '../features/catalog_share/data/repositories/catalog_share_lookup_repository_impl.dart'
    as _i667;
import '../features/catalog_share/data/repositories/catalog_share_repository_impl.dart'
    as _i54;
import '../features/catalog_share/domain/repositories/catalog_share_lookup_repository.dart'
    as _i344;
import '../features/catalog_share/domain/repositories/catalog_share_repository.dart'
    as _i558;
import '../features/catalog_share/domain/usecases/create_catalog_share_link_use_case.dart'
    as _i990;
import '../features/catalog_share/domain/usecases/get_catalog_share_use_case.dart'
    as _i795;
import '../features/catalog_share/domain/usecases/preview_catalog_share_use_case.dart'
    as _i620;
import '../features/catalog_share/domain/usecases/register_catalog_share_open_use_case.dart'
    as _i298;
import '../features/catalog_share/domain/usecases/revoke_catalog_share_use_case.dart'
    as _i601;
import '../features/catalog_share/presentation/bloc/catalog_share_public_bloc.dart'
    as _i447;
import '../features/catalog_share/presentation/bloc/catalog_share_sheet_bloc.dart'
    as _i511;
import '../features/crm/crm.dart' as _i205;
import '../features/crm/data/mappers/crm_activity_mapper.dart' as _i203;
import '../features/crm/data/mappers/crm_task_mapper.dart' as _i519;
import '../features/crm/data/repositories/shared_preferences_crm_activity_repository.dart'
    as _i699;
import '../features/crm/data/repositories/shared_preferences_crm_task_repository.dart'
    as _i150;
import '../features/crm/domain/repositories/crm_activity_repository.dart'
    as _i558;
import '../features/crm/domain/repositories/crm_task_repository.dart' as _i588;
import '../features/crm/domain/services/next_best_action_service.dart' as _i905;
import '../features/crm/domain/usecases/complete_crm_task_use_case.dart'
    as _i96;
import '../features/crm/domain/usecases/create_crm_task_use_case.dart'
    as _i1039;
import '../features/crm/domain/usecases/list_crm_activities_for_customer_use_case.dart'
    as _i489;
import '../features/crm/domain/usecases/list_crm_activities_for_lead_use_case.dart'
    as _i554;
import '../features/crm/domain/usecases/list_crm_activities_for_opportunity_use_case.dart'
    as _i286;
import '../features/crm/domain/usecases/list_pending_tasks_for_customer_use_case.dart'
    as _i972;
import '../features/crm/domain/usecases/list_pending_tasks_for_today_use_case.dart'
    as _i224;
import '../features/crm/domain/usecases/list_pending_tasks_for_week_use_case.dart'
    as _i874;
import '../features/crm/domain/usecases/register_crm_activity_use_case.dart'
    as _i924;
import '../features/crm/domain/usecases/reschedule_crm_task_use_case.dart'
    as _i711;
import '../features/crm/presentation/bloc/crm_task_list_bloc.dart' as _i634;
import '../features/customers/customers.dart' as _i909;
import '../features/customers/data/datasources/customer_form_draft_data_source.dart'
    as _i1036;
import '../features/customers/data/datasources/customer_segment_data_source.dart'
    as _i659;
import '../features/customers/data/datasources/shared_preferences_customer_form_draft_data_source.dart'
    as _i292;
import '../features/customers/data/datasources/shared_preferences_customer_segment_data_source.dart'
    as _i15;
import '../features/customers/data/mappers/customer_form_draft_mapper.dart'
    as _i258;
import '../features/customers/data/mappers/customer_local_mapper.dart' as _i725;
import '../features/customers/data/mappers/customer_mapper.dart' as _i457;
import '../features/customers/data/mappers/customer_segment_mapper.dart'
    as _i712;
import '../features/customers/data/repositories/customer_form_draft_repository_impl.dart'
    as _i920;
import '../features/customers/data/repositories/customer_segment_repository_impl.dart'
    as _i1052;
import '../features/customers/data/repositories/drift_customer_local_store_repository.dart'
    as _i674;
import '../features/customers/data/repositories/shared_preferences_customer_repository.dart'
    as _i784;
import '../features/customers/domain/repositories/customer_form_draft_repository.dart'
    as _i999;
import '../features/customers/domain/repositories/customer_local_store_repository.dart'
    as _i361;
import '../features/customers/domain/repositories/customer_repository.dart'
    as _i857;
import '../features/customers/domain/repositories/customer_segment_repository.dart'
    as _i748;
import '../features/customers/domain/services/customer_offline_package_entity_loader.dart'
    as _i325;
import '../features/customers/domain/usecases/clear_customer_form_draft_use_case.dart'
    as _i551;
import '../features/customers/domain/usecases/create_customer_segment_use_case.dart'
    as _i806;
import '../features/customers/domain/usecases/create_customer_use_case.dart'
    as _i427;
import '../features/customers/domain/usecases/customer_address_use_cases.dart'
    as _i860;
import '../features/customers/domain/usecases/customer_contact_use_cases.dart'
    as _i442;
import '../features/customers/domain/usecases/delete_customer_segment_use_case.dart'
    as _i869;
import '../features/customers/domain/usecases/get_customer_by_id_use_case.dart'
    as _i356;
import '../features/customers/domain/usecases/get_customer_form_config_use_case.dart'
    as _i825;
import '../features/customers/domain/usecases/get_customer_form_draft_use_case.dart'
    as _i504;
import '../features/customers/domain/usecases/list_customer_portfolio_use_case.dart'
    as _i576;
import '../features/customers/domain/usecases/list_customer_segments_use_case.dart'
    as _i261;
import '../features/customers/domain/usecases/load_initial_customer_offline_data_use_case.dart'
    as _i977;
import '../features/customers/domain/usecases/preview_customer_segment_count_use_case.dart'
    as _i438;
import '../features/customers/domain/usecases/save_customer_form_draft_use_case.dart'
    as _i780;
import '../features/customers/domain/usecases/update_customer_use_case.dart'
    as _i172;
import '../features/customers/presentation/bloc/customer_detail_bloc.dart'
    as _i433;
import '../features/customers/presentation/bloc/customer_form_bloc.dart'
    as _i478;
import '../features/customers/presentation/bloc/customer_portfolio_bloc.dart'
    as _i522;
import '../features/customers/presentation/bloc/customer_segment_bloc.dart'
    as _i901;
import '../features/favorites/data/datasources/favorite_remote_data_source.dart'
    as _i1002;
import '../features/favorites/data/datasources/firestore_favorite_remote_data_source.dart'
    as _i349;
import '../features/favorites/data/mappers/favorite_local_mapper.dart' as _i619;
import '../features/favorites/data/repositories/drift_favorite_repository.dart'
    as _i204;
import '../features/favorites/domain/repositories/favorite_repository.dart'
    as _i761;
import '../features/favorites/domain/usecases/add_favorite_product_use_case.dart'
    as _i1016;
import '../features/favorites/domain/usecases/list_favorite_products_use_case.dart'
    as _i72;
import '../features/favorites/domain/usecases/remove_favorite_product_use_case.dart'
    as _i214;
import '../features/favorites/domain/usecases/watch_favorite_product_ids_use_case.dart'
    as _i487;
import '../features/favorites/presentation/bloc/favorites_bloc.dart' as _i318;
import '../features/favorites/presentation/cubit/favorite_status_cubit.dart'
    as _i249;
import '../features/insights/data/datasources/firestore_insight_data_source.dart'
    as _i837;
import '../features/insights/data/datasources/insight_data_source.dart'
    as _i902;
import '../features/insights/data/mappers/insight_mapper.dart' as _i963;
import '../features/insights/data/repositories/insight_repository_impl.dart'
    as _i666;
import '../features/insights/domain/repositories/insight_repository.dart'
    as _i644;
import '../features/insights/domain/rules/abandoned_order_insight_rule.dart'
    as _i617;
import '../features/insights/domain/rules/churn_risk_insight_rule.dart' as _i47;
import '../features/insights/domain/rules/cross_sell_insight_rule.dart'
    as _i671;
import '../features/insights/domain/rules/growing_customer_insight_rule.dart'
    as _i425;
import '../features/insights/domain/rules/high_stock_low_turnover_insight_rule.dart'
    as _i572;
import '../features/insights/domain/rules/inactive_customer_insight_rule.dart'
    as _i364;
import '../features/insights/domain/rules/insufficient_mix_insight_rule.dart'
    as _i101;
import '../features/insights/domain/rules/replenishment_suggestion_insight_rule.dart'
    as _i104;
import '../features/insights/domain/rules/revenue_drop_insight_rule.dart'
    as _i622;
import '../features/insights/domain/rules/up_sell_insight_rule.dart' as _i810;
import '../features/insights/domain/services/insight_engine.dart' as _i918;
import '../features/insights/domain/services/insight_rule.dart' as _i629;
import '../features/insights/domain/services/insight_structural_validator.dart'
    as _i864;
import '../features/insights/insight_module.dart' as _i676;
import '../features/inventory/data/datasources/firestore_stock_alert_data_source.dart'
    as _i8;
import '../features/inventory/data/datasources/firestore_stock_turnover_data_source.dart'
    as _i605;
import '../features/inventory/data/datasources/firestore_variant_stock_balance_data_source.dart'
    as _i185;
import '../features/inventory/data/datasources/firestore_warehouse_data_source.dart'
    as _i504;
import '../features/inventory/data/datasources/stock_alert_data_source.dart'
    as _i240;
import '../features/inventory/data/datasources/stock_turnover_data_source.dart'
    as _i135;
import '../features/inventory/data/datasources/variant_stock_balance_remote_data_source.dart'
    as _i180;
import '../features/inventory/data/datasources/warehouse_remote_data_source.dart'
    as _i80;
import '../features/inventory/data/mappers/stock_alert_mapper.dart' as _i655;
import '../features/inventory/data/mappers/stock_turnover_metric_snapshot_mapper.dart'
    as _i422;
import '../features/inventory/data/mappers/variant_stock_balance_local_mapper.dart'
    as _i333;
import '../features/inventory/data/mappers/variant_stock_balance_mapper.dart'
    as _i617;
import '../features/inventory/data/mappers/warehouse_local_mapper.dart'
    as _i172;
import '../features/inventory/data/mappers/warehouse_mapper.dart' as _i678;
import '../features/inventory/data/repositories/inventory_variant_availability_repository.dart'
    as _i808;
import '../features/inventory/data/repositories/product_variant_future_stock_repository.dart'
    as _i1008;
import '../features/inventory/data/repositories/stock_alert_repository_impl.dart'
    as _i711;
import '../features/inventory/data/repositories/stock_turnover_repository_impl.dart'
    as _i80;
import '../features/inventory/data/repositories/variant_stock_balance_repository_impl.dart'
    as _i682;
import '../features/inventory/data/repositories/warehouse_repository_impl.dart'
    as _i2;
import '../features/inventory/domain/repositories/future_stock_repository.dart'
    as _i639;
import '../features/inventory/domain/repositories/stock_alert_repository.dart'
    as _i896;
import '../features/inventory/domain/repositories/stock_turnover_repository.dart'
    as _i503;
import '../features/inventory/domain/repositories/variant_stock_balance_repository.dart'
    as _i221;
import '../features/inventory/domain/repositories/warehouse_repository.dart'
    as _i62;
import '../features/inventory/domain/usecases/get_active_warehouses_use_case.dart'
    as _i609;
import '../features/inventory/domain/usecases/get_stock_turnover_metrics_use_case.dart'
    as _i722;
import '../features/inventory/domain/usecases/get_variant_future_stock_summary_use_case.dart'
    as _i349;
import '../features/inventory/domain/usecases/get_variant_inventory_availability_use_case.dart'
    as _i1069;
import '../features/inventory/domain/usecases/get_warehouses_by_company_use_case.dart'
    as _i472;
import '../features/inventory/domain/usecases/list_stock_alerts_use_case.dart'
    as _i684;
import '../features/invites/data/datasources/cloud_functions_invite_acceptance_data_source.dart'
    as _i674;
import '../features/invites/data/datasources/firestore_invite_data_source.dart'
    as _i3;
import '../features/invites/data/datasources/invite_acceptance_data_source.dart'
    as _i336;
import '../features/invites/data/datasources/invite_data_source.dart' as _i814;
import '../features/invites/data/mappers/invite_acceptance_mapper.dart' as _i87;
import '../features/invites/data/mappers/invite_mapper.dart' as _i649;
import '../features/invites/data/repositories/invite_acceptance_repository_impl.dart'
    as _i371;
import '../features/invites/data/repositories/invite_repository_impl.dart'
    as _i90;
import '../features/invites/domain/repositories/invite_acceptance_repository.dart'
    as _i999;
import '../features/invites/domain/repositories/invite_repository.dart' as _i75;
import '../features/invites/domain/usecases/accept_invite_use_case.dart'
    as _i559;
import '../features/invites/domain/usecases/create_invite_use_case.dart'
    as _i461;
import '../features/invites/domain/usecases/list_pending_invites_use_case.dart'
    as _i509;
import '../features/invites/domain/usecases/resend_invite_use_case.dart'
    as _i502;
import '../features/invites/domain/usecases/revoke_invite_use_case.dart'
    as _i334;
import '../features/invites/domain/usecases/validate_invite_use_case.dart'
    as _i409;
import '../features/invites/presentation/bloc/accept_invite_bloc.dart' as _i628;
import '../features/invites/presentation/bloc/invite_form_bloc.dart' as _i193;
import '../features/invites/presentation/bloc/invite_list_bloc.dart' as _i0;
import '../features/leads/data/mappers/lead_mapper.dart' as _i265;
import '../features/leads/data/repositories/shared_preferences_lead_repository.dart'
    as _i185;
import '../features/leads/domain/repositories/lead_repository.dart' as _i472;
import '../features/leads/domain/usecases/create_lead_use_case.dart' as _i770;
import '../features/leads/domain/usecases/disqualify_lead_use_case.dart'
    as _i904;
import '../features/leads/domain/usecases/list_leads_use_case.dart' as _i778;
import '../features/leads/domain/usecases/qualify_lead_use_case.dart' as _i924;
import '../features/leads/presentation/bloc/lead_form_bloc.dart' as _i480;
import '../features/leads/presentation/bloc/lead_list_bloc.dart' as _i581;
import '../features/onboarding/data/datasources/onboarding_progress_data_source.dart'
    as _i924;
import '../features/onboarding/data/datasources/shared_preferences_onboarding_progress_data_source.dart'
    as _i1035;
import '../features/onboarding/data/mappers/onboarding_progress_mapper.dart'
    as _i477;
import '../features/onboarding/data/repositories/onboarding_progress_repository_impl.dart'
    as _i803;
import '../features/onboarding/domain/repositories/onboarding_progress_repository.dart'
    as _i886;
import '../features/onboarding/domain/usecases/clear_onboarding_progress_use_case.dart'
    as _i214;
import '../features/onboarding/domain/usecases/complete_onboarding_use_case.dart'
    as _i675;
import '../features/onboarding/domain/usecases/get_onboarding_progress_use_case.dart'
    as _i206;
import '../features/onboarding/domain/usecases/save_onboarding_progress_use_case.dart'
    as _i81;
import '../features/onboarding/presentation/bloc/onboarding_bloc.dart' as _i593;
import '../features/opportunities/data/mappers/opportunity_mapper.dart'
    as _i449;
import '../features/opportunities/data/mappers/opportunity_outcome_reason_mapper.dart'
    as _i210;
import '../features/opportunities/data/mappers/pipeline_stage_mapper.dart'
    as _i772;
import '../features/opportunities/data/repositories/shared_preferences_opportunity_outcome_reason_repository.dart'
    as _i292;
import '../features/opportunities/data/repositories/shared_preferences_opportunity_repository.dart'
    as _i771;
import '../features/opportunities/data/repositories/shared_preferences_pipeline_stage_repository.dart'
    as _i319;
import '../features/opportunities/domain/repositories/opportunity_outcome_reason_repository.dart'
    as _i527;
import '../features/opportunities/domain/repositories/opportunity_repository.dart'
    as _i43;
import '../features/opportunities/domain/repositories/pipeline_stage_repository.dart'
    as _i385;
import '../features/opportunities/domain/usecases/create_opportunity_outcome_reason_use_case.dart'
    as _i254;
import '../features/opportunities/domain/usecases/create_pipeline_stage_use_case.dart'
    as _i959;
import '../features/opportunities/domain/usecases/deactivate_opportunity_outcome_reason_use_case.dart'
    as _i287;
import '../features/opportunities/domain/usecases/list_opportunity_outcome_reasons_use_case.dart'
    as _i690;
import '../features/opportunities/domain/usecases/list_pipeline_opportunities_use_case.dart'
    as _i891;
import '../features/opportunities/domain/usecases/list_pipeline_stages_use_case.dart'
    as _i879;
import '../features/opportunities/domain/usecases/list_top_opportunity_outcome_reasons_use_case.dart'
    as _i546;
import '../features/opportunities/domain/usecases/mark_opportunity_lost_use_case.dart'
    as _i416;
import '../features/opportunities/domain/usecases/mark_opportunity_won_use_case.dart'
    as _i657;
import '../features/opportunities/domain/usecases/rename_pipeline_stage_use_case.dart'
    as _i266;
import '../features/opportunities/domain/usecases/reorder_pipeline_stages_use_case.dart'
    as _i482;
import '../features/opportunities/domain/usecases/update_opportunity_outcome_reason_use_case.dart'
    as _i552;
import '../features/opportunities/domain/usecases/update_opportunity_stage_use_case.dart'
    as _i942;
import '../features/opportunities/presentation/bloc/opportunity_outcome_reason_admin_bloc.dart'
    as _i683;
import '../features/opportunities/presentation/bloc/pipeline_stage_admin_bloc.dart'
    as _i31;
import '../features/opportunities/presentation/bloc/sales_pipeline_bloc.dart'
    as _i339;
import '../features/orders/data/datasources/cloud_functions_order_approval_data_source.dart'
    as _i725;
import '../features/orders/data/datasources/cloud_functions_order_pricing_data_source.dart'
    as _i708;
import '../features/orders/data/datasources/cloud_functions_order_submission_data_source.dart'
    as _i1058;
import '../features/orders/data/datasources/firestore_order_list_data_source.dart'
    as _i937;
import '../features/orders/data/datasources/order_approval_data_source.dart'
    as _i1039;
import '../features/orders/data/datasources/order_list_data_source.dart'
    as _i726;
import '../features/orders/data/datasources/order_pricing_data_source.dart'
    as _i492;
import '../features/orders/data/datasources/order_submission_data_source.dart'
    as _i1068;
import '../features/orders/data/mappers/order_approval_decision_mapper.dart'
    as _i447;
import '../features/orders/data/mappers/order_local_mapper.dart' as _i431;
import '../features/orders/data/mappers/order_mapper.dart' as _i169;
import '../features/orders/data/mappers/order_pricing_mapper.dart' as _i730;
import '../features/orders/data/mappers/order_submission_mapper.dart' as _i1062;
import '../features/orders/data/repositories/drift_order_draft_repository.dart'
    as _i247;
import '../features/orders/data/repositories/order_approval_repository_impl.dart'
    as _i455;
import '../features/orders/data/repositories/order_list_repository_impl.dart'
    as _i67;
import '../features/orders/data/repositories/order_pricing_repository_impl.dart'
    as _i258;
import '../features/orders/data/repositories/order_submission_repository_impl.dart'
    as _i167;
import '../features/orders/domain/repositories/order_approval_repository.dart'
    as _i592;
import '../features/orders/domain/repositories/order_draft_repository.dart'
    as _i81;
import '../features/orders/domain/repositories/order_list_repository.dart'
    as _i1051;
import '../features/orders/domain/repositories/order_pricing_repository.dart'
    as _i183;
import '../features/orders/domain/repositories/order_submission_repository.dart'
    as _i202;
import '../features/orders/domain/services/order_status_transition_validator.dart'
    as _i753;
import '../features/orders/domain/services/order_submission_validator.dart'
    as _i745;
import '../features/orders/domain/services/order_visibility_service.dart'
    as _i63;
import '../features/orders/domain/usecases/add_items_to_order_draft_use_case.dart'
    as _i720;
import '../features/orders/domain/usecases/decide_order_approval_use_case.dart'
    as _i828;
import '../features/orders/domain/usecases/duplicate_order_use_case.dart'
    as _i315;
import '../features/orders/domain/usecases/ensure_customer_in_seller_portfolio_use_case.dart'
    as _i583;
import '../features/orders/domain/usecases/get_order_by_id_use_case.dart'
    as _i1062;
import '../features/orders/domain/usecases/get_order_draft_use_case.dart'
    as _i485;
import '../features/orders/domain/usecases/get_order_pricing_summary_use_case.dart'
    as _i305;
import '../features/orders/domain/usecases/get_order_submission_context_use_case.dart'
    as _i1025;
import '../features/orders/domain/usecases/list_local_pending_orders_use_case.dart'
    as _i233;
import '../features/orders/domain/usecases/list_orders_use_case.dart' as _i144;
import '../features/orders/domain/usecases/resolve_order_draft_defaults_use_case.dart'
    as _i530;
import '../features/orders/domain/usecases/save_order_draft_use_case.dart'
    as _i1;
import '../features/orders/domain/usecases/start_order_draft_for_customer_use_case.dart'
    as _i168;
import '../features/orders/domain/usecases/submit_order_use_case.dart' as _i856;
import '../features/orders/presentation/bloc/order_approval_queue_bloc.dart'
    as _i339;
import '../features/orders/presentation/bloc/order_draft_bloc.dart' as _i287;
import '../features/orders/presentation/bloc/order_duplication_cubit.dart'
    as _i21;
import '../features/orders/presentation/bloc/order_history_bloc.dart' as _i125;
import '../features/orders/presentation/bloc/order_items_counter_cubit.dart'
    as _i244;
import '../features/orders/presentation/bloc/order_items_grid_cubit.dart'
    as _i197;
import '../features/orders/presentation/bloc/order_list_bloc.dart' as _i424;
import '../features/orders/presentation/bloc/order_pricing_summary_cubit.dart'
    as _i765;
import '../features/orders/presentation/bloc/order_product_addition_cubit.dart'
    as _i15;
import '../features/orders/presentation/bloc/order_submission_validation_cubit.dart'
    as _i753;
import '../features/organizations/data/datasources/branch_data_source.dart'
    as _i526;
import '../features/organizations/data/datasources/company_data_source.dart'
    as _i384;
import '../features/organizations/data/datasources/firestore_branch_data_source.dart'
    as _i878;
import '../features/organizations/data/datasources/firestore_company_data_source.dart'
    as _i512;
import '../features/organizations/data/datasources/firestore_membership_data_source.dart'
    as _i201;
import '../features/organizations/data/datasources/firestore_organization_data_source.dart'
    as _i455;
import '../features/organizations/data/datasources/firestore_role_data_source.dart'
    as _i892;
import '../features/organizations/data/datasources/firestore_team_data_source.dart'
    as _i23;
import '../features/organizations/data/datasources/membership_data_source.dart'
    as _i361;
import '../features/organizations/data/datasources/organization_data_source.dart'
    as _i268;
import '../features/organizations/data/datasources/role_data_source.dart'
    as _i923;
import '../features/organizations/data/datasources/team_data_source.dart'
    as _i228;
import '../features/organizations/data/mappers/branch_mapper.dart' as _i964;
import '../features/organizations/data/mappers/company_mapper.dart' as _i642;
import '../features/organizations/data/mappers/membership_mapper.dart' as _i714;
import '../features/organizations/data/mappers/organization_mapper.dart'
    as _i719;
import '../features/organizations/data/mappers/role_mapper.dart' as _i1043;
import '../features/organizations/data/mappers/team_mapper.dart' as _i802;
import '../features/organizations/data/repositories/branch_repository_impl.dart'
    as _i375;
import '../features/organizations/data/repositories/company_repository_impl.dart'
    as _i960;
import '../features/organizations/data/repositories/membership_repository_impl.dart'
    as _i537;
import '../features/organizations/data/repositories/organization_repository_impl.dart'
    as _i522;
import '../features/organizations/data/repositories/role_repository_impl.dart'
    as _i69;
import '../features/organizations/data/repositories/team_repository_impl.dart'
    as _i485;
import '../features/organizations/domain/repositories/branch_repository.dart'
    as _i160;
import '../features/organizations/domain/repositories/company_repository.dart'
    as _i799;
import '../features/organizations/domain/repositories/membership_repository.dart'
    as _i957;
import '../features/organizations/domain/repositories/organization_repository.dart'
    as _i756;
import '../features/organizations/domain/repositories/role_repository.dart'
    as _i440;
import '../features/organizations/domain/repositories/team_repository.dart'
    as _i320;
import '../features/organizations/domain/usecases/add_member_to_team_use_case.dart'
    as _i658;
import '../features/organizations/domain/usecases/add_user_to_team_use_case.dart'
    as _i835;
import '../features/organizations/domain/usecases/assign_role_to_user_use_case.dart'
    as _i1030;
import '../features/organizations/domain/usecases/create_branch_use_case.dart'
    as _i906;
import '../features/organizations/domain/usecases/create_company_use_case.dart'
    as _i330;
import '../features/organizations/domain/usecases/create_organization_use_case.dart'
    as _i55;
import '../features/organizations/domain/usecases/create_team_use_case.dart'
    as _i766;
import '../features/organizations/domain/usecases/delete_team_use_case.dart'
    as _i817;
import '../features/organizations/domain/usecases/ensure_system_roles_use_case.dart'
    as _i68;
import '../features/organizations/domain/usecases/get_organization_use_case.dart'
    as _i966;
import '../features/organizations/domain/usecases/get_user_membership_use_case.dart'
    as _i70;
import '../features/organizations/domain/usecases/list_branches_by_company_use_case.dart'
    as _i500;
import '../features/organizations/domain/usecases/list_companies_use_case.dart'
    as _i628;
import '../features/organizations/domain/usecases/remove_member_from_team_use_case.dart'
    as _i335;
import '../features/organizations/domain/usecases/resolve_active_organization_id_use_case.dart'
    as _i267;
import '../features/organizations/domain/usecases/update_branch_use_case.dart'
    as _i820;
import '../features/organizations/domain/usecases/update_company_use_case.dart'
    as _i571;
import '../features/organizations/domain/usecases/update_organization_settings_use_case.dart'
    as _i270;
import '../features/organizations/domain/usecases/update_team_use_case.dart'
    as _i207;
import '../features/organizations/organizations.dart' as _i265;
import '../features/pricing/data/mappers/payment_term_local_mapper.dart'
    as _i162;
import '../features/pricing/data/mappers/price_list_item_local_mapper.dart'
    as _i959;
import '../features/pricing/data/mappers/price_list_local_mapper.dart' as _i794;
import '../features/pricing/data/mappers/price_list_mapper.dart' as _i960;
import '../features/pricing/data/repositories/drift_payment_term_local_store_repository.dart'
    as _i629;
import '../features/pricing/data/repositories/drift_price_list_item_local_store_repository.dart'
    as _i57;
import '../features/pricing/data/repositories/drift_price_list_local_store_repository.dart'
    as _i525;
import '../features/pricing/data/repositories/shared_preferences_discount_policy_repository.dart'
    as _i684;
import '../features/pricing/data/repositories/shared_preferences_payment_term_repository.dart'
    as _i973;
import '../features/pricing/data/repositories/shared_preferences_price_list_item_repository.dart'
    as _i808;
import '../features/pricing/data/repositories/shared_preferences_price_list_repository.dart'
    as _i764;
import '../features/pricing/data/repositories/shared_preferences_promotional_campaign_repository.dart'
    as _i430;
import '../features/pricing/domain/repositories/discount_policy_repository.dart'
    as _i31;
import '../features/pricing/domain/repositories/payment_term_local_store_repository.dart'
    as _i512;
import '../features/pricing/domain/repositories/payment_term_repository.dart'
    as _i358;
import '../features/pricing/domain/repositories/price_list_item_local_store_repository.dart'
    as _i155;
import '../features/pricing/domain/repositories/price_list_item_repository.dart'
    as _i101;
import '../features/pricing/domain/repositories/price_list_local_store_repository.dart'
    as _i661;
import '../features/pricing/domain/repositories/price_list_repository.dart'
    as _i455;
import '../features/pricing/domain/repositories/promotional_campaign_repository.dart'
    as _i211;
import '../features/pricing/domain/services/payment_term_offline_package_entity_loader.dart'
    as _i898;
import '../features/pricing/domain/services/price_list_offline_package_entity_loader.dart'
    as _i1044;
import '../features/pricing/domain/usecases/create_discount_policy_use_case.dart'
    as _i885;
import '../features/pricing/domain/usecases/create_payment_term_use_case.dart'
    as _i881;
import '../features/pricing/domain/usecases/create_price_list_use_case.dart'
    as _i581;
import '../features/pricing/domain/usecases/create_promotional_campaign_use_case.dart'
    as _i938;
import '../features/pricing/domain/usecases/list_active_payment_terms_use_case.dart'
    as _i1068;
import '../features/pricing/domain/usecases/load_initial_payment_term_offline_data_use_case.dart'
    as _i595;
import '../features/pricing/domain/usecases/load_initial_price_list_offline_data_use_case.dart'
    as _i103;
import '../features/pricing/domain/usecases/resolve_applicable_campaigns_use_case.dart'
    as _i277;
import '../features/pricing/domain/usecases/resolve_applicable_price_lists_use_case.dart'
    as _i41;
import '../features/pricing/domain/usecases/resolve_price_for_variant_use_case.dart'
    as _i352;
import '../features/pricing/domain/usecases/update_discount_policy_use_case.dart'
    as _i468;
import '../features/pricing/domain/usecases/update_payment_term_use_case.dart'
    as _i932;
import '../features/pricing/domain/usecases/update_promotional_campaign_use_case.dart'
    as _i339;
import '../features/pricing/domain/usecases/upsert_price_list_items_batch_use_case.dart'
    as _i914;
import '../features/pricing/domain/usecases/validate_discount_use_case.dart'
    as _i531;
import '../features/pricing/presentation/cubit/discount_policy_cubit.dart'
    as _i98;
import '../features/pricing/presentation/cubit/payment_terms_cubit.dart'
    as _i954;
import '../features/pricing/presentation/cubit/price_list_item_batch_cubit.dart'
    as _i49;
import '../features/pricing/presentation/cubit/promotional_campaign_cubit.dart'
    as _i75;
import '../features/pricing/pricing.dart' as _i445;
import '../features/products/data/datasources/drift_product_local_search_index_data_source.dart'
    as _i74;
import '../features/products/data/datasources/firestore_product_remote_search_data_source.dart'
    as _i580;
import '../features/products/data/datasources/product_form_draft_data_source.dart'
    as _i960;
import '../features/products/data/datasources/product_local_search_index_data_source.dart'
    as _i42;
import '../features/products/data/datasources/product_remote_search_data_source.dart'
    as _i671;
import '../features/products/data/datasources/shared_preferences_product_form_draft_data_source.dart'
    as _i1033;
import '../features/products/data/mappers/product_form_draft_mapper.dart'
    as _i325;
import '../features/products/data/mappers/product_mapper.dart' as _i309;
import '../features/products/data/mappers/product_search_index_mapper.dart'
    as _i184;
import '../features/products/data/repositories/product_form_draft_repository_impl.dart'
    as _i873;
import '../features/products/data/repositories/product_search_repository_impl.dart'
    as _i941;
import '../features/products/data/repositories/shared_preferences_category_repository.dart'
    as _i597;
import '../features/products/data/repositories/shared_preferences_collection_repository.dart'
    as _i717;
import '../features/products/data/repositories/shared_preferences_commercial_size_grid_draft_repository.dart'
    as _i79;
import '../features/products/data/repositories/shared_preferences_product_collection_link_repository.dart'
    as _i654;
import '../features/products/data/repositories/shared_preferences_product_color_repository.dart'
    as _i173;
import '../features/products/data/repositories/shared_preferences_product_repository.dart'
    as _i323;
import '../features/products/data/repositories/shared_preferences_product_variant_repository.dart'
    as _i912;
import '../features/products/data/repositories/shared_preferences_season_repository.dart'
    as _i860;
import '../features/products/data/repositories/shared_preferences_size_grid_template_repository.dart'
    as _i409;
import '../features/products/domain/repositories/category_repository.dart'
    as _i648;
import '../features/products/domain/repositories/collection_repository.dart'
    as _i626;
import '../features/products/domain/repositories/commercial_size_grid_draft_repository.dart'
    as _i512;
import '../features/products/domain/repositories/product_collection_link_repository.dart'
    as _i1015;
import '../features/products/domain/repositories/product_color_repository.dart'
    as _i298;
import '../features/products/domain/repositories/product_form_draft_repository.dart'
    as _i459;
import '../features/products/domain/repositories/product_repository.dart'
    as _i321;
import '../features/products/domain/repositories/product_search_repository.dart'
    as _i568;
import '../features/products/domain/repositories/product_variant_repository.dart'
    as _i795;
import '../features/products/domain/repositories/season_repository.dart'
    as _i260;
import '../features/products/domain/repositories/size_grid_template_repository.dart'
    as _i174;
import '../features/products/domain/repositories/variant_availability_repository.dart'
    as _i766;
import '../features/products/domain/services/product_color_similarity_service.dart'
    as _i8;
import '../features/products/domain/usecases/associate_product_colors_use_case.dart'
    as _i1037;
import '../features/products/domain/usecases/associate_product_size_grid_template_use_case.dart'
    as _i70;
import '../features/products/domain/usecases/associate_product_with_collection_use_case.dart'
    as _i452;
import '../features/products/domain/usecases/clear_product_form_draft_use_case.dart'
    as _i19;
import '../features/products/domain/usecases/close_collection_use_case.dart'
    as _i367;
import '../features/products/domain/usecases/create_category_use_case.dart'
    as _i538;
import '../features/products/domain/usecases/create_collection_use_case.dart'
    as _i426;
import '../features/products/domain/usecases/create_product_color_use_case.dart'
    as _i975;
import '../features/products/domain/usecases/create_product_use_case.dart'
    as _i300;
import '../features/products/domain/usecases/create_season_use_case.dart'
    as _i176;
import '../features/products/domain/usecases/create_size_grid_template_use_case.dart'
    as _i715;
import '../features/products/domain/usecases/delete_category_use_case.dart'
    as _i578;
import '../features/products/domain/usecases/delete_product_variant_use_case.dart'
    as _i273;
import '../features/products/domain/usecases/delete_season_use_case.dart'
    as _i389;
import '../features/products/domain/usecases/disassociate_product_from_collection_use_case.dart'
    as _i134;
import '../features/products/domain/usecases/duplicate_size_grid_template_use_case.dart'
    as _i200;
import '../features/products/domain/usecases/generate_product_variants_use_case.dart'
    as _i751;
import '../features/products/domain/usecases/get_commercial_size_grid_draft_use_case.dart'
    as _i801;
import '../features/products/domain/usecases/get_product_by_id_use_case.dart'
    as _i721;
import '../features/products/domain/usecases/get_product_form_draft_use_case.dart'
    as _i1021;
import '../features/products/domain/usecases/get_size_grid_template_by_id_use_case.dart'
    as _i194;
import '../features/products/domain/usecases/get_variant_availability_use_case.dart'
    as _i385;
import '../features/products/domain/usecases/list_categories_use_case.dart'
    as _i435;
import '../features/products/domain/usecases/list_collections_use_case.dart'
    as _i1023;
import '../features/products/domain/usecases/list_product_colors_use_case.dart'
    as _i789;
import '../features/products/domain/usecases/list_product_variants_by_product_use_case.dart'
    as _i530;
import '../features/products/domain/usecases/list_products_by_collection_use_case.dart'
    as _i815;
import '../features/products/domain/usecases/list_seasons_use_case.dart'
    as _i722;
import '../features/products/domain/usecases/list_size_grid_templates_use_case.dart'
    as _i646;
import '../features/products/domain/usecases/mark_product_color_unavailable_use_case.dart'
    as _i76;
import '../features/products/domain/usecases/publish_product_use_case.dart'
    as _i647;
import '../features/products/domain/usecases/reorder_categories_use_case.dart'
    as _i892;
import '../features/products/domain/usecases/reorder_size_grid_template_sizes_use_case.dart'
    as _i236;
import '../features/products/domain/usecases/save_commercial_size_grid_draft_use_case.dart'
    as _i644;
import '../features/products/domain/usecases/save_product_form_draft_use_case.dart'
    as _i244;
import '../features/products/domain/usecases/search_products_use_case.dart'
    as _i268;
import '../features/products/domain/usecases/update_category_use_case.dart'
    as _i328;
import '../features/products/domain/usecases/update_collection_use_case.dart'
    as _i779;
import '../features/products/domain/usecases/update_product_color_use_case.dart'
    as _i657;
import '../features/products/domain/usecases/update_product_media_use_case.dart'
    as _i739;
import '../features/products/domain/usecases/update_product_use_case.dart'
    as _i12;
import '../features/products/domain/usecases/update_product_variant_use_case.dart'
    as _i615;
import '../features/products/domain/usecases/update_season_use_case.dart'
    as _i814;
import '../features/products/domain/usecases/update_size_grid_template_use_case.dart'
    as _i807;
import '../features/products/presentation/bloc/category_form_bloc.dart'
    as _i296;
import '../features/products/presentation/bloc/category_list_bloc.dart'
    as _i689;
import '../features/products/presentation/bloc/collection_form_bloc.dart'
    as _i89;
import '../features/products/presentation/bloc/collection_list_bloc.dart'
    as _i41;
import '../features/products/presentation/bloc/commercial_size_grid_bloc.dart'
    as _i769;
import '../features/products/presentation/bloc/product_color_palette_bloc.dart'
    as _i522;
import '../features/products/presentation/bloc/product_form_bloc.dart' as _i198;
import '../features/products/presentation/bloc/product_media_bloc.dart'
    as _i968;
import '../features/products/presentation/bloc/product_search_bloc.dart'
    as _i965;
import '../features/products/presentation/bloc/season_form_bloc.dart' as _i98;
import '../features/products/presentation/bloc/season_list_bloc.dart' as _i986;
import '../features/products/presentation/bloc/size_grid_template_bloc.dart'
    as _i415;
import '../features/settings/data/datasources/about_app_data_source.dart'
    as _i364;
import '../features/settings/data/datasources/in_memory_about_app_datasource.dart'
    as _i639;
import '../features/settings/data/mappers/about_app_mapper.dart' as _i847;
import '../features/settings/data/mappers/about_app_notes_mapper.dart' as _i370;
import '../features/settings/data/models/about_app_seed_model.dart' as _i477;
import '../features/settings/data/repositories/about_app_repository_impl.dart'
    as _i1060;
import '../features/settings/domain/repositories/about_app_repository.dart'
    as _i794;
import '../features/settings/domain/usecases/get_about_app_use_case.dart'
    as _i713;
import '../features/settings/domain/usecases/search_about_app_notes_use_case.dart'
    as _i916;
import '../features/settings/domain/usecases/submit_about_app_diagnostics_use_case.dart'
    as _i226;
import '../features/settings/presentation/bloc/about_app_bloc.dart' as _i398;
import '../features/targets/data/mappers/target_mapper.dart' as _i730;
import '../features/targets/data/repositories/drift_positivacao_repository.dart'
    as _i8;
import '../features/targets/data/repositories/drift_target_achievement_repository.dart'
    as _i535;
import '../features/targets/data/repositories/shared_preferences_target_alert_dispatch_repository.dart'
    as _i369;
import '../features/targets/data/repositories/shared_preferences_target_alert_settings_repository.dart'
    as _i1066;
import '../features/targets/data/repositories/shared_preferences_target_repository.dart'
    as _i46;
import '../features/targets/domain/repositories/positivacao_repository.dart'
    as _i1031;
import '../features/targets/domain/repositories/target_achievement_repository.dart'
    as _i154;
import '../features/targets/domain/repositories/target_alert_dispatch_repository.dart'
    as _i836;
import '../features/targets/domain/repositories/target_alert_settings_repository.dart'
    as _i256;
import '../features/targets/domain/repositories/target_repository.dart'
    as _i876;
import '../features/targets/domain/services/closing_projection_service.dart'
    as _i862;
import '../features/targets/domain/services/projection_strategy.dart' as _i307;
import '../features/targets/domain/services/ranking_calculation_service.dart'
    as _i444;
import '../features/targets/domain/services/ranking_peer_resolver_service.dart'
    as _i960;
import '../features/targets/domain/services/target_visibility_service.dart'
    as _i951;
import '../features/targets/domain/usecases/create_target_use_case.dart'
    as _i472;
import '../features/targets/domain/usecases/process_target_alert_use_case.dart'
    as _i154;
import '../features/targets/domain/usecases/update_target_use_case.dart'
    as _i604;
import '../features/targets/presentation/cubit/positivacao_dashboard_cubit.dart'
    as _i627;
import '../features/targets/presentation/cubit/positivacao_settings_cubit.dart'
    as _i936;
import '../features/targets/presentation/cubit/ranking_dashboard_cubit.dart'
    as _i758;
import '../features/targets/presentation/cubit/target_dashboard_cubit.dart'
    as _i293;
import '../features/targets/presentation/cubit/target_form_cubit.dart' as _i998;
import '../features/users/data/datasources/cloud_functions_user_access_data_source.dart'
    as _i605;
import '../features/users/data/datasources/cloud_functions_user_role_data_source.dart'
    as _i789;
import '../features/users/data/datasources/firestore_portfolio_assignment_data_source.dart'
    as _i954;
import '../features/users/data/datasources/portfolio_assignment_data_source.dart'
    as _i847;
import '../features/users/data/datasources/user_access_data_source.dart'
    as _i681;
import '../features/users/data/datasources/user_role_data_source.dart' as _i176;
import '../features/users/data/mappers/portfolio_assignment_mapper.dart'
    as _i708;
import '../features/users/data/mappers/user_access_update_result_mapper.dart'
    as _i566;
import '../features/users/data/mappers/user_role_update_result_mapper.dart'
    as _i958;
import '../features/users/data/repositories/portfolio_assignment_repository_impl.dart'
    as _i667;
import '../features/users/data/repositories/user_access_repository_impl.dart'
    as _i591;
import '../features/users/data/repositories/user_role_repository_impl.dart'
    as _i53;
import '../features/users/domain/repositories/portfolio_assignment_repository.dart'
    as _i295;
import '../features/users/domain/repositories/user_access_repository.dart'
    as _i33;
import '../features/users/domain/repositories/user_role_repository.dart'
    as _i262;
import '../features/users/domain/services/portfolio_visibility_service.dart'
    as _i302;
import '../features/users/domain/usecases/assign_portfolio_use_case.dart'
    as _i636;
import '../features/users/domain/usecases/deactivate_user_use_case.dart'
    as _i126;
import '../features/users/domain/usecases/list_commercial_teams_use_case.dart'
    as _i986;
import '../features/users/domain/usecases/list_organization_users_use_case.dart'
    as _i93;
import '../features/users/domain/usecases/list_portfolio_assignments_use_case.dart'
    as _i321;
import '../features/users/domain/usecases/reactivate_user_use_case.dart'
    as _i603;
import '../features/users/domain/usecases/update_user_role_use_case.dart'
    as _i428;
import '../features/users/presentation/bloc/assign_portfolio_bloc.dart'
    as _i433;
import '../features/users/presentation/bloc/team_form_bloc.dart' as _i516;
import '../features/users/presentation/bloc/team_list_bloc.dart' as _i831;
import '../features/users/presentation/bloc/user_list_bloc.dart' as _i244;
import '../features/users/presentation/bloc/user_role_edit_bloc.dart' as _i698;
import '../features/users/users.dart' as _i220;
import 'injection_module.dart' as _i212;
import 'offline_package_loaders_module.dart' as _i418;
import 'sync_module.dart' as _i350;

const String _dev = 'dev';
const String _staging = 'staging';
const String _prod = 'prod';

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appInjectionModule = _$AppInjectionModule();
    final syncModule = _$SyncModule();
    final insightModule = _$InsightModule();
    final offlinePackageLoadersModule = _$OfflinePackageLoadersModule();
    gh.factory<_i619.FavoriteLocalMapper>(
      () => const _i619.FavoriteLocalMapper(),
    );
    gh.factory<_i730.OrderPricingMapper>(
      () => const _i730.OrderPricingMapper(),
    );
    gh.factory<_i162.PaymentTermLocalMapper>(
      () => const _i162.PaymentTermLocalMapper(),
    );
    gh.factory<_i444.RankingCalculationService>(
      () => const _i444.RankingCalculationService(),
    );
    gh.lazySingleton<_i461.AppEnvironment>(
      () => appInjectionModule.appEnvironment,
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => appInjectionModule.firebaseAuth);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => appInjectionModule.secureStorage,
    );
    gh.lazySingleton<_i895.Connectivity>(() => appInjectionModule.connectivity);
    gh.lazySingleton<_i158.SyncRetryPolicy>(
      () => appInjectionModule.syncRetryPolicy,
    );
    gh.lazySingleton<_i935.AppDatabase>(() => appInjectionModule.appDatabase());
    gh.lazySingleton<List<_i17.SyncPushHandler>>(
      () => syncModule.syncPushHandlers,
    );
    gh.lazySingleton<List<_i417.SyncPullSource>>(
      () => syncModule.syncPullSources,
    );
    gh.lazySingleton<_i26.AuthUserMapper>(() => const _i26.AuthUserMapper());
    gh.lazySingleton<_i246.AuditLogEntryMapper>(
      () => const _i246.AuditLogEntryMapper(),
    );
    gh.lazySingleton<_i756.UserProfileMapper>(
      () => const _i756.UserProfileMapper(),
    );
    gh.lazySingleton<_i1010.CatalogShareMapper>(
      () => const _i1010.CatalogShareMapper(),
    );
    gh.lazySingleton<_i203.CrmActivityMapper>(
      () => const _i203.CrmActivityMapper(),
    );
    gh.lazySingleton<_i519.CrmTaskMapper>(() => const _i519.CrmTaskMapper());
    gh.lazySingleton<_i905.NextBestActionService>(
      () => const _i905.NextBestActionService(),
    );
    gh.lazySingleton<_i258.CustomerFormDraftMapper>(
      () => const _i258.CustomerFormDraftMapper(),
    );
    gh.lazySingleton<_i457.CustomerMapper>(() => const _i457.CustomerMapper());
    gh.lazySingleton<_i712.CustomerSegmentMapper>(
      () => const _i712.CustomerSegmentMapper(),
    );
    gh.lazySingleton<_i963.InsightMapper>(() => const _i963.InsightMapper());
    gh.lazySingleton<_i617.AbandonedDraftOrderInsightRule>(
      () => const _i617.AbandonedDraftOrderInsightRule(),
    );
    gh.lazySingleton<_i47.ChurnRiskInsightRule>(
      () => const _i47.ChurnRiskInsightRule(),
    );
    gh.lazySingleton<_i671.CrossSellInsightRule>(
      () => const _i671.CrossSellInsightRule(),
    );
    gh.lazySingleton<_i425.GrowingCustomerInsightRule>(
      () => const _i425.GrowingCustomerInsightRule(),
    );
    gh.lazySingleton<_i572.HighStockLowTurnoverInsightRule>(
      () => const _i572.HighStockLowTurnoverInsightRule(),
    );
    gh.lazySingleton<_i364.InactiveCustomerInsightRule>(
      () => const _i364.InactiveCustomerInsightRule(),
    );
    gh.lazySingleton<_i101.InsufficientMixInsightRule>(
      () => const _i101.InsufficientMixInsightRule(),
    );
    gh.lazySingleton<_i104.ReplenishmentSuggestionInsightRule>(
      () => const _i104.ReplenishmentSuggestionInsightRule(),
    );
    gh.lazySingleton<_i622.RevenueDropInsightRule>(
      () => const _i622.RevenueDropInsightRule(),
    );
    gh.lazySingleton<_i810.UpSellInsightRule>(
      () => const _i810.UpSellInsightRule(),
    );
    gh.lazySingleton<_i864.InsightStructuralValidator>(
      () => const _i864.InsightStructuralValidator(),
    );
    gh.lazySingleton<_i655.StockAlertMapper>(
      () => const _i655.StockAlertMapper(),
    );
    gh.lazySingleton<_i422.StockTurnoverMetricSnapshotMapper>(
      () => const _i422.StockTurnoverMetricSnapshotMapper(),
    );
    gh.lazySingleton<_i333.VariantStockBalanceLocalMapper>(
      () => const _i333.VariantStockBalanceLocalMapper(),
    );
    gh.lazySingleton<_i617.VariantStockBalanceMapper>(
      () => const _i617.VariantStockBalanceMapper(),
    );
    gh.lazySingleton<_i678.WarehouseMapper>(
      () => const _i678.WarehouseMapper(),
    );
    gh.lazySingleton<_i649.InviteMapper>(() => const _i649.InviteMapper());
    gh.lazySingleton<_i265.LeadMapper>(() => const _i265.LeadMapper());
    gh.lazySingleton<_i477.OnboardingProgressMapper>(
      () => const _i477.OnboardingProgressMapper(),
    );
    gh.lazySingleton<_i449.OpportunityMapper>(
      () => const _i449.OpportunityMapper(),
    );
    gh.lazySingleton<_i210.OpportunityOutcomeReasonMapper>(
      () => const _i210.OpportunityOutcomeReasonMapper(),
    );
    gh.lazySingleton<_i772.PipelineStageMapper>(
      () => const _i772.PipelineStageMapper(),
    );
    gh.lazySingleton<_i169.OrderMapper>(() => const _i169.OrderMapper());
    gh.lazySingleton<_i753.OrderStatusTransitionValidator>(
      () => const _i753.OrderStatusTransitionValidator(),
    );
    gh.lazySingleton<_i745.OrderSubmissionValidator>(
      () => const _i745.OrderSubmissionValidator(),
    );
    gh.lazySingleton<_i964.BranchMapper>(() => const _i964.BranchMapper());
    gh.lazySingleton<_i642.CompanyMapper>(() => const _i642.CompanyMapper());
    gh.lazySingleton<_i714.MembershipMapper>(
      () => const _i714.MembershipMapper(),
    );
    gh.lazySingleton<_i719.OrganizationMapper>(
      () => const _i719.OrganizationMapper(),
    );
    gh.lazySingleton<_i1043.RoleMapper>(() => const _i1043.RoleMapper());
    gh.lazySingleton<_i802.TeamMapper>(() => const _i802.TeamMapper());
    gh.lazySingleton<_i959.PriceListItemLocalMapper>(
      () => const _i959.PriceListItemLocalMapper(),
    );
    gh.lazySingleton<_i960.PriceListMapper>(
      () => const _i960.PriceListMapper(),
    );
    gh.lazySingleton<_i325.ProductFormDraftMapper>(
      () => const _i325.ProductFormDraftMapper(),
    );
    gh.lazySingleton<_i309.ProductMapper>(() => const _i309.ProductMapper());
    gh.lazySingleton<_i8.ProductColorSimilarityService>(
      () => const _i8.ProductColorSimilarityService(),
    );
    gh.lazySingleton<_i847.AboutAppMapper>(() => const _i847.AboutAppMapper());
    gh.lazySingleton<_i370.AboutAppNotesMapper>(
      () => const _i370.AboutAppNotesMapper(),
    );
    gh.lazySingleton<_i730.TargetMapper>(() => const _i730.TargetMapper());
    gh.lazySingleton<_i708.PortfolioAssignmentMapper>(
      () => const _i708.PortfolioAssignmentMapper(),
    );
    gh.lazySingleton<_i566.UserAccessUpdateResultMapper>(
      () => const _i566.UserAccessUpdateResultMapper(),
    );
    gh.lazySingleton<_i958.UserRoleUpdateResultMapper>(
      () => const _i958.UserRoleUpdateResultMapper(),
    );
    gh.lazySingleton<_i465.AppClientMetadataProvider>(
      () => _i465.PackageInfoClientMetadataProvider(),
    );
    gh.lazySingleton<_i659.CustomerSegmentDataSource>(
      () => const _i15.SharedPreferencesCustomerSegmentDataSource(),
    );
    gh.lazySingleton<_i512.PaymentTermLocalStoreRepository>(
      () => _i629.DriftPaymentTermLocalStoreRepository(
        gh<_i658.AppDatabase>(),
        gh<_i162.PaymentTermLocalMapper>(),
      ),
    );
    gh.lazySingleton<_i472.LeadRepository>(
      () => _i185.SharedPreferencesLeadRepository(gh<_i265.LeadMapper>()),
    );
    gh.lazySingleton<_i611.ImageCompressor>(
      () => const _i611.FlutterImageCompressor(),
    );
    gh.lazySingleton<_i358.PaymentTermRepository>(
      () => _i973.SharedPreferencesPaymentTermRepository(),
    );
    gh.lazySingleton<_i1031.CatalogPreferencesRepository>(
      () => const _i590.SharedPreferencesCatalogPreferencesRepository(),
    );
    gh.factory<_i595.LoadInitialPaymentTermOfflineDataUseCase>(
      () => _i595.LoadInitialPaymentTermOfflineDataUseCase(
        gh<_i358.PaymentTermRepository>(),
        gh<_i512.PaymentTermLocalStoreRepository>(),
      ),
    );
    gh.lazySingleton<_i298.ProductColorRepository>(
      () => const _i173.SharedPreferencesProductColorRepository(),
    );
    gh.lazySingleton<_i99.SecureSessionStore>(
      () => _i772.SecureFlutterSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i648.CategoryRepository>(
      () => const _i597.SharedPreferencesCategoryRepository(),
    );
    gh.lazySingleton<_i155.PriceListItemLocalStoreRepository>(
      () => _i57.DriftPriceListItemLocalStoreRepository(
        gh<_i658.AppDatabase>(),
        gh<_i959.PriceListItemLocalMapper>(),
      ),
    );
    gh.lazySingleton<_i43.OpportunityRepository>(
      () => _i771.SharedPreferencesOpportunityRepository(
        gh<_i449.OpportunityMapper>(),
      ),
    );
    gh.lazySingleton<_i211.PromotionalCampaignRepository>(
      () => const _i430.SharedPreferencesPromotionalCampaignRepository(),
    );
    gh.lazySingleton<_i1036.CustomerFormDraftDataSource>(
      () => const _i292.SharedPreferencesCustomerFormDraftDataSource(),
    );
    gh.lazySingleton<_i87.InviteAcceptanceMapper>(
      () => _i87.InviteAcceptanceMapper(gh<_i649.InviteMapper>()),
    );
    gh.lazySingleton<_i841.CatalogHomeCacheRepository>(
      () => const _i26.SharedPreferencesCatalogHomeCacheRepository(),
    );
    gh.lazySingleton<_i31.DiscountPolicyRepository>(
      () => const _i684.SharedPreferencesDiscountPolicyRepository(),
    );
    gh.lazySingleton<_i1015.ProductCollectionLinkRepository>(
      () => const _i654.SharedPreferencesProductCollectionLinkRepository(),
    );
    gh.lazySingleton<_i836.TargetAlertDispatchRepository>(
      () => const _i369.SharedPreferencesTargetAlertDispatchRepository(),
    );
    gh.lazySingleton<_i73.NotificationInboxRepository>(
      () => const _i393.SharedPreferencesNotificationInboxRepository(),
    );
    gh.factory<_i1068.ListActivePaymentTermsUseCase>(
      () => _i1068.ListActivePaymentTermsUseCase(
        gh<_i358.PaymentTermRepository>(),
      ),
    );
    gh.lazySingleton<_i512.CommercialSizeGridDraftRepository>(
      () => const _i79.SharedPreferencesCommercialSizeGridDraftRepository(),
    );
    gh.lazySingleton<_i172.WarehouseLocalMapper>(
      () => _i172.WarehouseLocalMapper(gh<_i678.WarehouseMapper>()),
    );
    gh.factory<_i307.ProjectionStrategy>(
      () => const _i307.LinearProjectionStrategy(),
    );
    gh.lazySingleton<_i256.TargetAlertSettingsRepository>(
      () => const _i1066.SharedPreferencesTargetAlertSettingsRepository(),
    );
    gh.factory<_i862.ClosingProjectionService>(
      () => _i862.ClosingProjectionService(
        strategy: gh<_i307.ProjectionStrategy>(),
      ),
    );
    gh.lazySingleton<_i999.CustomerFormDraftRepository>(
      () => _i920.CustomerFormDraftRepositoryImpl(
        dataSource: gh<_i1036.CustomerFormDraftDataSource>(),
        mapper: gh<_i258.CustomerFormDraftMapper>(),
      ),
    );
    gh.factory<_i700.LoadCatalogPreferencesUseCase>(
      () => _i700.LoadCatalogPreferencesUseCase(
        gh<_i1031.CatalogPreferencesRepository>(),
      ),
    );
    gh.factory<_i36.SaveCatalogPreferencesUseCase>(
      () => _i36.SaveCatalogPreferencesUseCase(
        gh<_i1031.CatalogPreferencesRepository>(),
      ),
    );
    gh.lazySingleton<_i174.SizeGridTemplateRepository>(
      () => const _i409.SharedPreferencesSizeGridTemplateRepository(),
    );
    gh.lazySingleton<_i924.OnboardingProgressDataSource>(
      () => const _i1035.SharedPreferencesOnboardingProgressDataSource(),
    );
    gh.factory<_i891.ListPipelineOpportunitiesUseCase>(
      () => _i891.ListPipelineOpportunitiesUseCase(
        gh<_i43.OpportunityRepository>(),
      ),
    );
    gh.factory<_i942.UpdateOpportunityStageUseCase>(
      () =>
          _i942.UpdateOpportunityStageUseCase(gh<_i43.OpportunityRepository>()),
    );
    gh.lazySingleton<_i101.PriceListItemRepository>(
      () => const _i808.SharedPreferencesPriceListItemRepository(),
    );
    gh.lazySingleton<_i431.OrderLocalMapper>(
      () => _i431.OrderLocalMapper(gh<_i169.OrderMapper>()),
    );
    gh.lazySingleton<_i795.ProductVariantRepository>(
      () => const _i912.SharedPreferencesProductVariantRepository(),
    );
    gh.factory<_i447.OrderApprovalDecisionMapper>(
      () => _i447.OrderApprovalDecisionMapper(gh<_i169.OrderMapper>()),
    );
    gh.factory<_i1062.OrderSubmissionMapper>(
      () => _i1062.OrderSubmissionMapper(gh<_i169.OrderMapper>()),
    );
    gh.lazySingleton<_i150.CatalogCampaignRepository>(
      () => const _i565.SharedPreferencesCatalogCampaignRepository(),
    );
    gh.factory<_i169.CreateCampaignUseCase>(
      () => _i169.CreateCampaignUseCase(gh<_i150.CatalogCampaignRepository>()),
    );
    gh.factory<_i961.DeleteCampaignUseCase>(
      () => _i961.DeleteCampaignUseCase(gh<_i150.CatalogCampaignRepository>()),
    );
    gh.factory<_i746.GetCampaignUseCase>(
      () => _i746.GetCampaignUseCase(gh<_i150.CatalogCampaignRepository>()),
    );
    gh.factory<_i328.ListCampaignsUseCase>(
      () => _i328.ListCampaignsUseCase(gh<_i150.CatalogCampaignRepository>()),
    );
    gh.factory<_i598.UpdateCampaignUseCase>(
      () => _i598.UpdateCampaignUseCase(gh<_i150.CatalogCampaignRepository>()),
    );
    gh.lazySingleton<_i639.FutureStockRepository>(
      () => _i1008.ProductVariantFutureStockRepository(
        gh<_i795.ProductVariantRepository>(),
      ),
    );
    gh.lazySingleton<_i81.OrderDraftRepository>(
      () => _i247.DriftOrderDraftRepository(
        gh<_i658.AppDatabase>(),
        gh<_i431.OrderLocalMapper>(),
      ),
    );
    gh.lazySingleton<_i725.CustomerLocalMapper>(
      () => _i725.CustomerLocalMapper(gh<_i457.CustomerMapper>()),
    );
    gh.lazySingleton<_i886.OnboardingProgressRepository>(
      () => _i803.OnboardingProgressRepositoryImpl(
        dataSource: gh<_i924.OnboardingProgressDataSource>(),
        mapper: gh<_i477.OnboardingProgressMapper>(),
      ),
    );
    gh.lazySingleton<_i960.ProductFormDraftDataSource>(
      () => const _i1033.SharedPreferencesProductFormDraftDataSource(),
    );
    gh.lazySingleton<_i610.ConnectivityService>(
      () => _i4.ConnectivityPlusService(gh<_i895.Connectivity>()),
    );
    gh.factory<_i277.ResolveApplicableCampaignsUseCase>(
      () => _i277.ResolveApplicableCampaignsUseCase(
        gh<_i211.PromotionalCampaignRepository>(),
      ),
    );
    gh.lazySingleton<_i626.CollectionRepository>(
      () => const _i717.SharedPreferencesCollectionRepository(),
    );
    gh.lazySingleton<_i260.SeasonRepository>(
      () => const _i860.SharedPreferencesSeasonRepository(),
    );
    gh.lazySingleton<_i527.OpportunityOutcomeReasonRepository>(
      () => _i292.SharedPreferencesOpportunityOutcomeReasonRepository(
        gh<_i210.OpportunityOutcomeReasonMapper>(),
      ),
    );
    gh.factory<_i538.CreateCategoryUseCase>(
      () => _i538.CreateCategoryUseCase(gh<_i648.CategoryRepository>()),
    );
    gh.factory<_i578.DeleteCategoryUseCase>(
      () => _i578.DeleteCategoryUseCase(gh<_i648.CategoryRepository>()),
    );
    gh.factory<_i435.ListCategoriesUseCase>(
      () => _i435.ListCategoriesUseCase(gh<_i648.CategoryRepository>()),
    );
    gh.factory<_i892.ReorderCategoriesUseCase>(
      () => _i892.ReorderCategoriesUseCase(gh<_i648.CategoryRepository>()),
    );
    gh.factory<_i328.UpdateCategoryUseCase>(
      () => _i328.UpdateCategoryUseCase(gh<_i648.CategoryRepository>()),
    );
    gh.factory<_i296.CategoryFormBloc>(
      () => _i296.CategoryFormBloc(
        listCategories: gh<_i435.ListCategoriesUseCase>(),
        createCategory: gh<_i538.CreateCategoryUseCase>(),
        updateCategory: gh<_i328.UpdateCategoryUseCase>(),
      ),
    );
    gh.factory<_i770.CreateLeadUseCase>(
      () => _i770.CreateLeadUseCase(gh<_i472.LeadRepository>()),
    );
    gh.factory<_i904.DisqualifyLeadUseCase>(
      () => _i904.DisqualifyLeadUseCase(gh<_i472.LeadRepository>()),
    );
    gh.factory<_i778.ListLeadsUseCase>(
      () => _i778.ListLeadsUseCase(gh<_i472.LeadRepository>()),
    );
    gh.factory<_i924.QualifyLeadUseCase>(
      () => _i924.QualifyLeadUseCase(gh<_i472.LeadRepository>()),
    );
    gh.factory<_i416.MarkOpportunityLostUseCase>(
      () => _i416.MarkOpportunityLostUseCase(
        gh<_i43.OpportunityRepository>(),
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.factory<_i657.MarkOpportunityWonUseCase>(
      () => _i657.MarkOpportunityWonUseCase(
        gh<_i43.OpportunityRepository>(),
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.lazySingleton<_i321.ProductRepository>(
      () => _i323.SharedPreferencesProductRepository(gh<_i309.ProductMapper>()),
    );
    gh.lazySingleton<_i876.TargetRepository>(
      () => _i46.SharedPreferencesTargetRepository(gh<_i730.TargetMapper>()),
    );
    gh.lazySingleton<_i459.ProductFormDraftRepository>(
      () => _i873.ProductFormDraftRepositoryImpl(
        dataSource: gh<_i960.ProductFormDraftDataSource>(),
        mapper: gh<_i325.ProductFormDraftMapper>(),
      ),
    );
    gh.lazySingleton<_i455.PriceListRepository>(
      () => _i764.SharedPreferencesPriceListRepository(
        gh<_i960.PriceListMapper>(),
      ),
    );
    gh.factory<_i689.CategoryListBloc>(
      () => _i689.CategoryListBloc(
        listCategories: gh<_i435.ListCategoriesUseCase>(),
        deleteCategory: gh<_i578.DeleteCategoryUseCase>(),
        reorderCategories: gh<_i892.ReorderCategoriesUseCase>(),
      ),
    );
    gh.factory<_i249.LoadCatalogHomeCacheUseCase>(
      () => _i249.LoadCatalogHomeCacheUseCase(
        gh<_i841.CatalogHomeCacheRepository>(),
      ),
    );
    gh.factory<_i64.SaveCatalogHomeCacheUseCase>(
      () => _i64.SaveCatalogHomeCacheUseCase(
        gh<_i841.CatalogHomeCacheRepository>(),
      ),
    );
    gh.lazySingleton<_i552.ConflictAuditLogRepository>(
      () => _i59.DriftConflictAuditLogRepository(gh<_i658.AppDatabase>()),
    );
    gh.lazySingleton<_i857.CustomerRepository>(
      () =>
          _i784.SharedPreferencesCustomerRepository(gh<_i457.CustomerMapper>()),
    );
    gh.lazySingleton<_i588.CrmTaskRepository>(
      () => _i150.SharedPreferencesCrmTaskRepository(gh<_i519.CrmTaskMapper>()),
    );
    gh.factory<_i151.GetCatalogCampaignsSectionUseCase>(
      () => _i151.GetCatalogCampaignsSectionUseCase(
        gh<_i150.CatalogCampaignRepository>(),
      ),
    );
    gh.factory<_i19.ClearProductFormDraftUseCase>(
      () => _i19.ClearProductFormDraftUseCase(
        gh<_i459.ProductFormDraftRepository>(),
      ),
    );
    gh.factory<_i1021.GetProductFormDraftUseCase>(
      () => _i1021.GetProductFormDraftUseCase(
        gh<_i459.ProductFormDraftRepository>(),
      ),
    );
    gh.factory<_i244.SaveProductFormDraftUseCase>(
      () => _i244.SaveProductFormDraftUseCase(
        gh<_i459.ProductFormDraftRepository>(),
      ),
    );
    gh.lazySingleton<_i405.SyncCursorRepository>(
      () => _i152.DriftSyncCursorRepository(gh<_i658.AppDatabase>()),
    );
    gh.factory<_i801.GetCommercialSizeGridDraftUseCase>(
      () => _i801.GetCommercialSizeGridDraftUseCase(
        gh<_i512.CommercialSizeGridDraftRepository>(),
      ),
    );
    gh.factory<_i644.SaveCommercialSizeGridDraftUseCase>(
      () => _i644.SaveCommercialSizeGridDraftUseCase(
        gh<_i512.CommercialSizeGridDraftRepository>(),
      ),
    );
    gh.lazySingleton<_i748.CustomerSegmentRepository>(
      () => _i1052.CustomerSegmentRepositoryImpl(
        dataSource: gh<_i659.CustomerSegmentDataSource>(),
        mapper: gh<_i712.CustomerSegmentMapper>(),
      ),
    );
    gh.lazySingleton<_i1031.PositivacaoRepository>(
      () => _i8.DriftPositivacaoRepository(gh<_i658.AppDatabase>()),
    );
    gh.lazySingleton<_i234.OutboxRepository>(
      () => _i170.DriftOutboxRepository(gh<_i658.AppDatabase>()),
    );
    gh.factory<_i789.ListProductColorsUseCase>(
      () => _i789.ListProductColorsUseCase(gh<_i298.ProductColorRepository>()),
    );
    gh.factory<_i76.MarkProductColorUnavailableUseCase>(
      () => _i76.MarkProductColorUnavailableUseCase(
        gh<_i298.ProductColorRepository>(),
      ),
    );
    gh.factory<_i59.CampaignListBloc>(
      () => _i59.CampaignListBloc(
        listCampaigns: gh<_i328.ListCampaignsUseCase>(),
        deleteCampaign: gh<_i961.DeleteCampaignUseCase>(),
      ),
    );
    gh.lazySingleton<List<_i629.InsightRule>>(
      () => insightModule.insightRules(
        gh<_i364.InactiveCustomerInsightRule>(),
        gh<_i622.RevenueDropInsightRule>(),
        gh<_i425.GrowingCustomerInsightRule>(),
        gh<_i671.CrossSellInsightRule>(),
        gh<_i810.UpSellInsightRule>(),
        gh<_i101.InsufficientMixInsightRule>(),
        gh<_i572.HighStockLowTurnoverInsightRule>(),
        gh<_i104.ReplenishmentSuggestionInsightRule>(),
        gh<_i47.ChurnRiskInsightRule>(),
        gh<_i617.AbandonedDraftOrderInsightRule>(),
      ),
    );
    gh.factory<_i546.ListTopOpportunityOutcomeReasonsUseCase>(
      () => _i546.ListTopOpportunityOutcomeReasonsUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
        gh<_i43.OpportunityRepository>(),
      ),
    );
    gh.factory<_i70.AssociateProductSizeGridTemplateUseCase>(
      () => _i70.AssociateProductSizeGridTemplateUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.factory<_i815.ListProductsByCollectionUseCase>(
      () => _i815.ListProductsByCollectionUseCase(
        gh<_i1015.ProductCollectionLinkRepository>(),
        gh<_i321.ProductRepository>(),
      ),
    );
    gh.lazySingleton<_i620.ImageUploadCompressor>(
      () =>
          _i620.ImageUploadCompressor(compressor: gh<_i611.ImageCompressor>()),
    );
    gh.lazySingleton<_i814.ConflictRecordRepository>(
      () => _i566.DriftConflictRecordRepository(gh<_i658.AppDatabase>()),
    );
    gh.lazySingleton<_i154.TargetAchievementRepository>(
      () => _i535.DriftTargetAchievementRepository(gh<_i658.AppDatabase>()),
    );
    gh.lazySingleton<_i799.OfflinePackageStatusRepository>(
      () => _i963.DriftOfflinePackageStatusRepository(gh<_i658.AppDatabase>()),
    );
    gh.factory<_i551.ClearCustomerFormDraftUseCase>(
      () => _i551.ClearCustomerFormDraftUseCase(
        gh<_i999.CustomerFormDraftRepository>(),
      ),
    );
    gh.factory<_i504.GetCustomerFormDraftUseCase>(
      () => _i504.GetCustomerFormDraftUseCase(
        gh<_i999.CustomerFormDraftRepository>(),
      ),
    );
    gh.factory<_i780.SaveCustomerFormDraftUseCase>(
      () => _i780.SaveCustomerFormDraftUseCase(
        gh<_i999.CustomerFormDraftRepository>(),
      ),
    );
    gh.factory<_i254.CreateOpportunityOutcomeReasonUseCase>(
      () => _i254.CreateOpportunityOutcomeReasonUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.factory<_i287.DeactivateOpportunityOutcomeReasonUseCase>(
      () => _i287.DeactivateOpportunityOutcomeReasonUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.factory<_i690.ListOpportunityOutcomeReasonsUseCase>(
      () => _i690.ListOpportunityOutcomeReasonsUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.factory<_i552.UpdateOpportunityOutcomeReasonUseCase>(
      () => _i552.UpdateOpportunityOutcomeReasonUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
      ),
    );
    gh.lazySingleton<_i56.FirebaseAppCheck>(
      () => appInjectionModule.firebaseAppCheck(gh<_i461.AppEnvironment>()),
    );
    gh.lazySingleton<_i141.FirebaseCrashlytics>(
      () => appInjectionModule.firebaseCrashlytics(gh<_i461.AppEnvironment>()),
    );
    gh.lazySingleton<_i398.FirebaseAnalytics>(
      () => appInjectionModule.firebaseAnalytics(gh<_i461.AppEnvironment>()),
    );
    gh.lazySingleton<_i346.FirebasePerformance>(
      () => appInjectionModule.firebasePerformance(gh<_i461.AppEnvironment>()),
    );
    gh.lazySingleton<_i627.FirebaseRemoteConfig>(
      () => appInjectionModule.firebaseRemoteConfig(gh<_i461.AppEnvironment>()),
    );
    gh.lazySingleton<_i477.AboutAppSeedModel>(
      () => appInjectionModule.aboutAppSeedModel(gh<_i461.AppEnvironment>()),
    );
    gh.factory<_i581.CreatePriceListUseCase>(
      () => _i581.CreatePriceListUseCase(gh<_i455.PriceListRepository>()),
    );
    gh.factory<_i41.ResolveApplicablePriceListsUseCase>(
      () => _i41.ResolveApplicablePriceListsUseCase(
        gh<_i455.PriceListRepository>(),
      ),
    );
    gh.factory<_i975.CreateProductColorUseCase>(
      () => _i975.CreateProductColorUseCase(
        gh<_i298.ProductColorRepository>(),
        gh<_i8.ProductColorSimilarityService>(),
      ),
    );
    gh.factory<_i657.UpdateProductColorUseCase>(
      () => _i657.UpdateProductColorUseCase(
        gh<_i298.ProductColorRepository>(),
        gh<_i8.ProductColorSimilarityService>(),
      ),
    );
    gh.factory<_i189.ConflictListCubit>(
      () => _i189.ConflictListCubit(gh<_i814.ConflictRecordRepository>()),
    );
    gh.factory<_i531.ValidateDiscountUseCase>(
      () => _i531.ValidateDiscountUseCase(gh<_i31.DiscountPolicyRepository>()),
    );
    gh.lazySingleton<_i794.PriceListLocalMapper>(
      () => _i794.PriceListLocalMapper(gh<_i960.PriceListMapper>()),
    );
    gh.factory<_i273.DeleteProductVariantUseCase>(
      () => _i273.DeleteProductVariantUseCase(
        gh<_i795.ProductVariantRepository>(),
      ),
    );
    gh.factory<_i530.ListProductVariantsByProductUseCase>(
      () => _i530.ListProductVariantsByProductUseCase(
        gh<_i795.ProductVariantRepository>(),
      ),
    );
    gh.factory<_i615.UpdateProductVariantUseCase>(
      () => _i615.UpdateProductVariantUseCase(
        gh<_i795.ProductVariantRepository>(),
      ),
    );
    gh.lazySingleton<_i932.AnalyticsService>(
      () => _i569.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
    );
    gh.factory<_i720.AddItemsToOrderDraftUseCase>(
      () => _i720.AddItemsToOrderDraftUseCase(gh<_i81.OrderDraftRepository>()),
    );
    gh.factory<_i485.GetOrderDraftUseCase>(
      () => _i485.GetOrderDraftUseCase(gh<_i81.OrderDraftRepository>()),
    );
    gh.factory<_i233.ListLocalPendingOrdersUseCase>(
      () =>
          _i233.ListLocalPendingOrdersUseCase(gh<_i81.OrderDraftRepository>()),
    );
    gh.factory<_i1.SaveOrderDraftUseCase>(
      () => _i1.SaveOrderDraftUseCase(gh<_i81.OrderDraftRepository>()),
    );
    gh.lazySingleton<_i385.PipelineStageRepository>(
      () => _i319.SharedPreferencesPipelineStageRepository(
        gh<_i772.PipelineStageMapper>(),
      ),
    );
    gh.lazySingleton<_i845.AuthDataSource>(
      () => _i814.FirebaseAuthDataSource(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i558.CrmActivityRepository>(
      () => _i699.SharedPreferencesCrmActivityRepository(
        gh<_i203.CrmActivityMapper>(),
      ),
    );
    gh.lazySingleton<_i184.ProductSearchIndexMapper>(
      () => _i184.ProductSearchIndexMapper(gh<_i309.ProductMapper>()),
    );
    gh.lazySingleton<_i217.AuthRepository>(
      () => _i961.AuthRepositoryImpl(
        dataSource: gh<_i845.AuthDataSource>(),
        mapper: gh<_i26.AuthUserMapper>(),
      ),
    );
    gh.factory<_i76.GetNewArrivalsSectionUseCase>(
      () => _i76.GetNewArrivalsSectionUseCase(gh<_i321.ProductRepository>()),
    );
    gh.factory<_i345.ListCampaignRelatedProductsUseCase>(
      () => _i345.ListCampaignRelatedProductsUseCase(
        gh<_i321.ProductRepository>(),
      ),
    );
    gh.factory<_i448.ListCatalogProductsUseCase>(
      () => _i448.ListCatalogProductsUseCase(gh<_i321.ProductRepository>()),
    );
    gh.lazySingleton<_i361.CustomerLocalStoreRepository>(
      () => _i674.DriftCustomerLocalStoreRepository(
        gh<_i658.AppDatabase>(),
        gh<_i725.CustomerLocalMapper>(),
      ),
    );
    gh.factory<_i914.UpsertPriceListItemsBatchUseCase>(
      () => _i914.UpsertPriceListItemsBatchUseCase(
        gh<_i101.PriceListItemRepository>(),
      ),
    );
    gh.factory<_i49.PriceListItemBatchCubit>(
      () => _i49.PriceListItemBatchCubit(
        gh<_i101.PriceListItemRepository>(),
        gh<_i914.UpsertPriceListItemsBatchUseCase>(),
      ),
    );
    gh.factory<_i820.SendPasswordResetEmailUseCase>(
      () => _i820.SendPasswordResetEmailUseCase(gh<_i472.AuthRepository>()),
    );
    gh.factory<_i185.SignInWithEmailAndPasswordUseCase>(
      () => _i185.SignInWithEmailAndPasswordUseCase(gh<_i472.AuthRepository>()),
    );
    gh.factory<_i1042.GetFeaturedCollectionsSectionUseCase>(
      () => _i1042.GetFeaturedCollectionsSectionUseCase(
        gh<_i626.CollectionRepository>(),
      ),
    );
    gh.factory<_i134.DisassociateProductFromCollectionUseCase>(
      () => _i134.DisassociateProductFromCollectionUseCase(
        gh<_i1015.ProductCollectionLinkRepository>(),
      ),
    );
    gh.factory<_i806.CreateCustomerSegmentUseCase>(
      () => _i806.CreateCustomerSegmentUseCase(
        gh<_i748.CustomerSegmentRepository>(),
      ),
    );
    gh.factory<_i869.DeleteCustomerSegmentUseCase>(
      () => _i869.DeleteCustomerSegmentUseCase(
        gh<_i748.CustomerSegmentRepository>(),
      ),
    );
    gh.factory<_i261.ListCustomerSegmentsUseCase>(
      () => _i261.ListCustomerSegmentsUseCase(
        gh<_i748.CustomerSegmentRepository>(),
      ),
    );
    gh.factory<_i959.CreatePipelineStageUseCase>(
      () =>
          _i959.CreatePipelineStageUseCase(gh<_i385.PipelineStageRepository>()),
    );
    gh.factory<_i879.ListPipelineStagesUseCase>(
      () =>
          _i879.ListPipelineStagesUseCase(gh<_i385.PipelineStageRepository>()),
    );
    gh.factory<_i266.RenamePipelineStageUseCase>(
      () =>
          _i266.RenamePipelineStageUseCase(gh<_i385.PipelineStageRepository>()),
    );
    gh.factory<_i482.ReorderPipelineStagesUseCase>(
      () => _i482.ReorderPipelineStagesUseCase(
        gh<_i385.PipelineStageRepository>(),
      ),
    );
    gh.factory<_i452.AssociateProductWithCollectionUseCase>(
      () => _i452.AssociateProductWithCollectionUseCase(
        gh<_i1015.ProductCollectionLinkRepository>(),
        gh<_i626.CollectionRepository>(),
      ),
    );
    gh.factory<_i300.CreateProductUseCase>(
      () => _i300.CreateProductUseCase(gh<_i321.ProductRepository>()),
    );
    gh.factory<_i721.GetProductByIdUseCase>(
      () => _i721.GetProductByIdUseCase(gh<_i321.ProductRepository>()),
    );
    gh.factory<_i522.ProductColorPaletteBloc>(
      () => _i522.ProductColorPaletteBloc(
        listProductColors: gh<_i789.ListProductColorsUseCase>(),
        createProductColor: gh<_i975.CreateProductColorUseCase>(),
        updateProductColor: gh<_i657.UpdateProductColorUseCase>(),
        markProductColorUnavailable:
            gh<_i76.MarkProductColorUnavailableUseCase>(),
      ),
    );
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => appInjectionModule.firebaseFirestore(
        gh<_i461.AppEnvironment>(),
        gh<_i56.FirebaseAppCheck>(),
      ),
    );
    gh.lazySingleton<_i457.FirebaseStorage>(
      () => appInjectionModule.firebaseStorage(
        gh<_i461.AppEnvironment>(),
        gh<_i56.FirebaseAppCheck>(),
      ),
    );
    gh.lazySingleton<_i809.FirebaseFunctions>(
      () => appInjectionModule.firebaseFunctions(
        gh<_i461.AppEnvironment>(),
        gh<_i56.FirebaseAppCheck>(),
      ),
    );
    gh.factory<_i15.OrderProductAdditionCubit>(
      () => _i15.OrderProductAdditionCubit(
        gh<_i720.AddItemsToOrderDraftUseCase>(),
      ),
    );
    gh.factory<_i751.GenerateProductVariantsUseCase>(
      () => _i751.GenerateProductVariantsUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i298.ProductColorRepository>(),
        gh<_i174.SizeGridTemplateRepository>(),
        gh<_i795.ProductVariantRepository>(),
      ),
    );
    gh.factory<_i1037.AssociateProductColorsUseCase>(
      () => _i1037.AssociateProductColorsUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i298.ProductColorRepository>(),
      ),
    );
    gh.factory<_i96.CompleteCrmTaskUseCase>(
      () => _i96.CompleteCrmTaskUseCase(gh<_i588.CrmTaskRepository>()),
    );
    gh.factory<_i1039.CreateCrmTaskUseCase>(
      () => _i1039.CreateCrmTaskUseCase(gh<_i588.CrmTaskRepository>()),
    );
    gh.factory<_i972.ListPendingTasksForCustomerUseCase>(
      () => _i972.ListPendingTasksForCustomerUseCase(
        gh<_i588.CrmTaskRepository>(),
      ),
    );
    gh.factory<_i224.ListPendingTasksForTodayUseCase>(
      () =>
          _i224.ListPendingTasksForTodayUseCase(gh<_i588.CrmTaskRepository>()),
    );
    gh.factory<_i874.ListPendingTasksForWeekUseCase>(
      () => _i874.ListPendingTasksForWeekUseCase(gh<_i588.CrmTaskRepository>()),
    );
    gh.factory<_i711.RescheduleCrmTaskUseCase>(
      () => _i711.RescheduleCrmTaskUseCase(gh<_i588.CrmTaskRepository>()),
    );
    gh.factory<_i214.ClearOnboardingProgressUseCase>(
      () => _i214.ClearOnboardingProgressUseCase(
        gh<_i886.OnboardingProgressRepository>(),
      ),
    );
    gh.factory<_i206.GetOnboardingProgressUseCase>(
      () => _i206.GetOnboardingProgressUseCase(
        gh<_i886.OnboardingProgressRepository>(),
      ),
    );
    gh.factory<_i81.SaveOnboardingProgressUseCase>(
      () => _i81.SaveOnboardingProgressUseCase(
        gh<_i886.OnboardingProgressRepository>(),
      ),
    );
    gh.factory<_i715.CreateSizeGridTemplateUseCase>(
      () => _i715.CreateSizeGridTemplateUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.factory<_i194.GetSizeGridTemplateByIdUseCase>(
      () => _i194.GetSizeGridTemplateByIdUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.factory<_i646.ListSizeGridTemplatesUseCase>(
      () => _i646.ListSizeGridTemplatesUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.factory<_i236.ReorderSizeGridTemplateSizesUseCase>(
      () => _i236.ReorderSizeGridTemplateSizesUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.factory<_i807.UpdateSizeGridTemplateUseCase>(
      () => _i807.UpdateSizeGridTemplateUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
      ),
    );
    gh.lazySingleton<_i349.CrashReporter>(
      () => _i559.FirebaseCrashReporter(
        gh<_i141.FirebaseCrashlytics>(),
        gh<_i461.AppEnvironment>(),
        gh<_i465.AppClientMetadataProvider>(),
      ),
    );
    gh.factory<_i866.OutboxWatcherCubit>(
      () => _i866.OutboxWatcherCubit(gh<_i234.OutboxRepository>()),
    );
    gh.factory<_i427.CreateCustomerUseCase>(
      () => _i427.CreateCustomerUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i860.AddCustomerAddressUseCase>(
      () => _i860.AddCustomerAddressUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i860.UpdateCustomerAddressUseCase>(
      () => _i860.UpdateCustomerAddressUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i860.RemoveCustomerAddressUseCase>(
      () => _i860.RemoveCustomerAddressUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i860.SetPrimaryCustomerAddressUseCase>(
      () => _i860.SetPrimaryCustomerAddressUseCase(
        gh<_i857.CustomerRepository>(),
      ),
    );
    gh.factory<_i442.AddCustomerContactUseCase>(
      () => _i442.AddCustomerContactUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i442.UpdateCustomerContactUseCase>(
      () => _i442.UpdateCustomerContactUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i442.RemoveCustomerContactUseCase>(
      () => _i442.RemoveCustomerContactUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i442.SetPrimaryCustomerContactUseCase>(
      () => _i442.SetPrimaryCustomerContactUseCase(
        gh<_i857.CustomerRepository>(),
      ),
    );
    gh.factory<_i356.GetCustomerByIdUseCase>(
      () => _i356.GetCustomerByIdUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.factory<_i172.UpdateCustomerUseCase>(
      () => _i172.UpdateCustomerUseCase(gh<_i857.CustomerRepository>()),
    );
    gh.lazySingleton<_i364.AboutAppDataSource>(
      () => _i639.InMemoryAboutAppDataSource.injectable(
        seed: gh<_i477.AboutAppSeedModel>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.factory<_i176.CreateSeasonUseCase>(
      () => _i176.CreateSeasonUseCase(gh<_i260.SeasonRepository>()),
    );
    gh.factory<_i389.DeleteSeasonUseCase>(
      () => _i389.DeleteSeasonUseCase(gh<_i260.SeasonRepository>()),
    );
    gh.factory<_i722.ListSeasonsUseCase>(
      () => _i722.ListSeasonsUseCase(gh<_i260.SeasonRepository>()),
    );
    gh.factory<_i814.UpdateSeasonUseCase>(
      () => _i814.UpdateSeasonUseCase(gh<_i260.SeasonRepository>()),
    );
    gh.factory<_i352.ResolvePriceForVariantUseCase>(
      () => _i352.ResolvePriceForVariantUseCase(
        gh<_i41.ResolveApplicablePriceListsUseCase>(),
        gh<_i101.PriceListItemRepository>(),
      ),
    );
    gh.factory<_i683.OpportunityOutcomeReasonAdminBloc>(
      () => _i683.OpportunityOutcomeReasonAdminBloc(
        listReasons: gh<_i690.ListOpportunityOutcomeReasonsUseCase>(),
        createReason: gh<_i254.CreateOpportunityOutcomeReasonUseCase>(),
        updateReason: gh<_i552.UpdateOpportunityOutcomeReasonUseCase>(),
        deactivateReason: gh<_i287.DeactivateOpportunityOutcomeReasonUseCase>(),
      ),
    );
    gh.lazySingleton<_i972.FeatureFlagService>(
      () => _i845.FirebaseFeatureFlagService(gh<_i627.FirebaseRemoteConfig>()),
    );
    gh.lazySingleton<_i1008.PerformanceMonitor>(
      () => _i387.FirebasePerformanceMonitor(gh<_i346.FirebasePerformance>()),
    );
    gh.factory<_i367.CloseCollectionUseCase>(
      () => _i367.CloseCollectionUseCase(gh<_i626.CollectionRepository>()),
    );
    gh.factory<_i426.CreateCollectionUseCase>(
      () => _i426.CreateCollectionUseCase(gh<_i626.CollectionRepository>()),
    );
    gh.factory<_i1023.ListCollectionsUseCase>(
      () => _i1023.ListCollectionsUseCase(gh<_i626.CollectionRepository>()),
    );
    gh.factory<_i779.UpdateCollectionUseCase>(
      () => _i779.UpdateCollectionUseCase(gh<_i626.CollectionRepository>()),
    );
    gh.factory<_i200.DuplicateSizeGridTemplateUseCase>(
      () => _i200.DuplicateSizeGridTemplateUseCase(
        gh<_i174.SizeGridTemplateRepository>(),
        gh<_i715.CreateSizeGridTemplateUseCase>(),
      ),
    );
    gh.factory<_i489.ListCrmActivitiesForCustomerUseCase>(
      () => _i489.ListCrmActivitiesForCustomerUseCase(
        gh<_i558.CrmActivityRepository>(),
      ),
    );
    gh.factory<_i554.ListCrmActivitiesForLeadUseCase>(
      () => _i554.ListCrmActivitiesForLeadUseCase(
        gh<_i558.CrmActivityRepository>(),
      ),
    );
    gh.factory<_i286.ListCrmActivitiesForOpportunityUseCase>(
      () => _i286.ListCrmActivitiesForOpportunityUseCase(
        gh<_i558.CrmActivityRepository>(),
      ),
    );
    gh.factory<_i924.RegisterCrmActivityUseCase>(
      () => _i924.RegisterCrmActivityUseCase(gh<_i558.CrmActivityRepository>()),
    );
    gh.factory<_i154.ProcessTargetAlertUseCase>(
      () => _i154.ProcessTargetAlertUseCase(
        gh<_i256.TargetAlertSettingsRepository>(),
        gh<_i836.TargetAlertDispatchRepository>(),
        gh<_i387.NotificationInboxRepository>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i147.CloudFunctionsService>(
      () => _i147.CloudFunctionsService(
        gh<_i809.FirebaseFunctions>(),
        gh<_i59.FirebaseAuth>(),
        gh<_i465.AppClientMetadataProvider>(),
      ),
    );
    gh.lazySingleton<_i885.SessionService>(
      () => _i520.SessionServiceImpl(
        authRepository: gh<_i217.AuthRepository>(),
        secureSessionStore: gh<_i99.SecureSessionStore>(),
      ),
    );
    gh.factory<_i415.SizeGridTemplateBloc>(
      () => _i415.SizeGridTemplateBloc(
        listSizeGridTemplates: gh<_i646.ListSizeGridTemplatesUseCase>(),
        createSizeGridTemplate: gh<_i715.CreateSizeGridTemplateUseCase>(),
        updateSizeGridTemplate: gh<_i807.UpdateSizeGridTemplateUseCase>(),
        duplicateSizeGridTemplate: gh<_i200.DuplicateSizeGridTemplateUseCase>(),
        reorderSizeGridTemplateSizes:
            gh<_i236.ReorderSizeGridTemplateSizesUseCase>(),
      ),
    );
    gh.lazySingleton<_i526.BranchDataSource>(
      () => _i878.FirestoreBranchDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i384.CompanyDataSource>(
      () => _i512.FirestoreCompanyDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i799.CompanyRepository>(
      () => _i960.CompanyRepositoryImpl(
        dataSource: gh<_i384.CompanyDataSource>(),
        mapper: gh<_i642.CompanyMapper>(),
      ),
    );
    gh.factory<_i339.SalesPipelineBloc>(
      () => _i339.SalesPipelineBloc(
        listStages: gh<_i879.ListPipelineStagesUseCase>(),
        listOutcomeReasons: gh<_i690.ListOpportunityOutcomeReasonsUseCase>(),
        listOpportunities: gh<_i891.ListPipelineOpportunitiesUseCase>(),
        updateStage: gh<_i942.UpdateOpportunityStageUseCase>(),
        markWon: gh<_i657.MarkOpportunityWonUseCase>(),
        markLost: gh<_i416.MarkOpportunityLostUseCase>(),
      ),
    );
    gh.lazySingleton<_i80.WarehouseRemoteDataSource>(
      () => _i504.FirestoreWarehouseDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i361.MembershipDataSource>(
      () => _i201.FirestoreMembershipDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i814.InviteDataSource>(
      () => _i3.FirestoreInviteDataSource(
        gh<_i340.CloudFunctionsService>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i918.InsightEngine>(
      () => _i918.InsightEngine(
        gh<List<_i629.InsightRule>>(),
        gh<_i864.InsightStructuralValidator>(),
      ),
    );
    gh.lazySingleton<_i176.UserRoleDataSource>(
      () => _i789.CloudFunctionsUserRoleDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.lazySingleton<_i661.PriceListLocalStoreRepository>(
      () => _i525.DriftPriceListLocalStoreRepository(
        gh<_i658.AppDatabase>(),
        gh<_i794.PriceListLocalMapper>(),
      ),
    );
    gh.lazySingleton<_i135.StockTurnoverDataSource>(
      () =>
          _i605.FirestoreStockTurnoverDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i336.InviteAcceptanceDataSource>(
      () => _i674.CloudFunctionsInviteAcceptanceDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.lazySingleton<_i957.MembershipRepository>(
      () => _i537.MembershipRepositoryImpl(
        dataSource: gh<_i361.MembershipDataSource>(),
        mapper: gh<_i714.MembershipMapper>(),
      ),
    );
    gh.lazySingleton<_i42.ProductLocalSearchIndexDataSource>(
      () => _i74.DriftProductLocalSearchIndexDataSource(
        gh<_i658.AppDatabase>(),
        gh<_i184.ProductSearchIndexMapper>(),
      ),
    );
    gh.factory<_i1015.ForgotPasswordBloc>(
      () => _i1015.ForgotPasswordBloc(
        sendPasswordResetEmail: gh<_i820.SendPasswordResetEmailUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i1039.OrderApprovalDataSource>(
      () => _i725.CloudFunctionsOrderApprovalDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.factory<_i244.OrderItemsCounterCubit>(
      () => _i244.OrderItemsCounterCubit(gh<_i485.GetOrderDraftUseCase>()),
    );
    gh.lazySingleton<_i904.StorageDataSource>(
      () => _i833.FirebaseStorageDataSource(gh<_i457.FirebaseStorage>()),
    );
    gh.lazySingleton<_i847.PortfolioAssignmentDataSource>(
      () => _i954.FirestorePortfolioAssignmentDataSource(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i1072.CatalogHomeConfigRepository>(
      () => _i288.RemoteConfigCatalogHomeConfigRepository(
        gh<_i972.FeatureFlagService>(),
      ),
    );
    gh.lazySingleton<_i746.ConflictResolutionService>(
      () => _i746.ConflictResolutionService(
        gh<_i814.ConflictRecordRepository>(),
        gh<_i552.ConflictAuditLogRepository>(),
        gh<_i234.OutboxRepository>(),
        uuid: gh<_i706.Uuid>(),
      ),
    );
    gh.factory<_i630.LookbookBloc>(
      () => _i630.LookbookBloc(
        getCampaign: gh<_i746.GetCampaignUseCase>(),
        listRelatedProducts: gh<_i345.ListCampaignRelatedProductsUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i62.WarehouseRepository>(
      () => _i2.WarehouseRepositoryImpl(
        gh<_i80.WarehouseRemoteDataSource>(),
        gh<_i658.AppDatabase>(),
        gh<_i678.WarehouseMapper>(),
        gh<_i172.WarehouseLocalMapper>(),
      ),
    );
    gh.lazySingleton<_i268.OrganizationDataSource>(
      () => _i455.FirestoreOrganizationDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.factory<_i89.CollectionFormBloc>(
      () => _i89.CollectionFormBloc(
        listSeasons: gh<_i722.ListSeasonsUseCase>(),
        createCollection: gh<_i426.CreateCollectionUseCase>(),
        updateCollection: gh<_i779.UpdateCollectionUseCase>(),
      ),
    );
    gh.lazySingleton<_i726.OrderListDataSource>(
      () => _i937.FirestoreOrderListDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i999.InviteAcceptanceRepository>(
      () => _i371.InviteAcceptanceRepositoryImpl(
        dataSource: gh<_i336.InviteAcceptanceDataSource>(),
        mapper: gh<_i87.InviteAcceptanceMapper>(),
      ),
    );
    gh.lazySingleton<_i1068.OrderSubmissionDataSource>(
      () => _i1058.CloudFunctionsOrderSubmissionDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.lazySingleton<_i923.RoleDataSource>(
      () => _i892.FirestoreRoleDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i419.CampaignFormBloc>(
      () => _i419.CampaignFormBloc(
        storage: gh<_i209.StorageDataSource>(),
        createCampaign: gh<_i169.CreateCampaignUseCase>(),
        updateCampaign: gh<_i598.UpdateCampaignUseCase>(),
        listRelatedProducts: gh<_i345.ListCampaignRelatedProductsUseCase>(),
        compressor: gh<_i209.ImageUploadCompressor>(),
      ),
    );
    gh.factory<_i103.LoadInitialPriceListOfflineDataUseCase>(
      () => _i103.LoadInitialPriceListOfflineDataUseCase(
        gh<_i455.PriceListRepository>(),
        gh<_i661.PriceListLocalStoreRepository>(),
      ),
    );
    gh.factory<_i717.ConflictResolutionCubit>(
      () => _i717.ConflictResolutionCubit(
        gh<_i814.ConflictRecordRepository>(),
        gh<_i746.ConflictResolutionService>(),
      ),
    );
    gh.lazySingleton<_i492.OrderPricingDataSource>(
      () => _i708.CloudFunctionsOrderPricingDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.lazySingleton<_i902.InsightDataSource>(
      () => _i837.FirestoreInsightDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i228.TeamDataSource>(
      () => _i23.FirestoreTeamDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i681.UserAccessDataSource>(
      () => _i605.CloudFunctionsUserAccessDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.factory<_i31.PipelineStageAdminBloc>(
      () => _i31.PipelineStageAdminBloc(
        listStages: gh<_i879.ListPipelineStagesUseCase>(),
        createStage: gh<_i959.CreatePipelineStageUseCase>(),
        renameStage: gh<_i266.RenamePipelineStageUseCase>(),
        reorderStages: gh<_i482.ReorderPipelineStagesUseCase>(),
      ),
    );
    gh.lazySingleton<_i1002.FavoriteRemoteDataSource>(
      () => _i349.FirestoreFavoriteRemoteDataSource(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i240.StockAlertDataSource>(
      () => _i8.FirestoreStockAlertDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i979.CatalogShareLookupDataSource>(
      () => _i354.CloudFunctionsCatalogShareLookupDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.factory<_i330.CreateCompanyUseCase>(
      () => _i330.CreateCompanyUseCase(gh<_i799.CompanyRepository>()),
    );
    gh.factory<_i628.ListCompaniesUseCase>(
      () => _i628.ListCompaniesUseCase(gh<_i799.CompanyRepository>()),
    );
    gh.factory<_i571.UpdateCompanyUseCase>(
      () => _i571.UpdateCompanyUseCase(gh<_i799.CompanyRepository>()),
    );
    gh.factory<_i98.SeasonFormBloc>(
      () => _i98.SeasonFormBloc(
        createSeason: gh<_i176.CreateSeasonUseCase>(),
        updateSeason: gh<_i814.UpdateSeasonUseCase>(),
      ),
    );
    gh.lazySingleton<_i432.AuditLogDataSource>(
      () => _i709.FirestoreAuditLogDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i315.PermissionService>(
      () => _i315.PermissionService(gh<_i957.MembershipRepository>()),
    );
    gh.factory<_i70.GetUserMembershipUseCase>(
      () => _i70.GetUserMembershipUseCase(gh<_i957.MembershipRepository>()),
    );
    gh.factory<_i267.ResolveActiveOrganizationIdUseCase>(
      () => _i267.ResolveActiveOrganizationIdUseCase(
        gh<_i957.MembershipRepository>(),
      ),
    );
    gh.lazySingleton<_i33.UserAccessRepository>(
      () => _i591.UserAccessRepositoryImpl(
        dataSource: gh<_i681.UserAccessDataSource>(),
        mapper: gh<_i566.UserAccessUpdateResultMapper>(),
      ),
    );
    gh.factory<_i41.CollectionListBloc>(
      () => _i41.CollectionListBloc(
        listCollections: gh<_i1023.ListCollectionsUseCase>(),
        closeCollection: gh<_i367.CloseCollectionUseCase>(),
      ),
    );
    gh.lazySingleton<_i993.CatalogShareDataSource>(
      () => _i1002.FirestoreCatalogShareDataSource(
        gh<_i340.CloudFunctionsService>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i896.StockAlertRepository>(
      () => _i711.StockAlertRepositoryImpl(
        dataSource: gh<_i240.StockAlertDataSource>(),
        mapper: gh<_i655.StockAlertMapper>(),
      ),
    );
    gh.lazySingleton<_i180.VariantStockBalanceRemoteDataSource>(
      () => _i185.FirestoreVariantStockBalanceDataSource(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i668.UserProfileDataSource>(
      () =>
          _i1043.FirestoreUserProfileDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i671.ProductRemoteSearchDataSource>(
      () => _i580.FirestoreProductRemoteSearchDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i309.ProductMapper>(),
      ),
    );
    gh.lazySingleton<_i1044.PriceListOfflinePackageEntityLoader>(
      () => _i1044.PriceListOfflinePackageEntityLoader(
        gh<_i103.LoadInitialPriceListOfflineDataUseCase>(),
        gh<_i661.PriceListLocalStoreRepository>(),
        gh<_i315.PermissionService>(),
      ),
    );
    gh.lazySingleton<_i503.StockTurnoverRepository>(
      () => _i80.StockTurnoverRepositoryImpl(
        dataSource: gh<_i135.StockTurnoverDataSource>(),
        mapper: gh<_i422.StockTurnoverMetricSnapshotMapper>(),
      ),
    );
    gh.lazySingleton<_i1051.OrderListRepository>(
      () => _i67.OrderListRepositoryImpl(
        dataSource: gh<_i726.OrderListDataSource>(),
        mapper: gh<_i169.OrderMapper>(),
      ),
    );
    gh.factory<_i609.GetActiveWarehousesUseCase>(
      () => _i609.GetActiveWarehousesUseCase(gh<_i62.WarehouseRepository>()),
    );
    gh.factory<_i472.GetWarehousesByCompanyUseCase>(
      () => _i472.GetWarehousesByCompanyUseCase(gh<_i62.WarehouseRepository>()),
    );
    gh.factory<_i316.GetCatalogHomeConfigUseCase>(
      () => _i316.GetCatalogHomeConfigUseCase(
        gh<_i1072.CatalogHomeConfigRepository>(),
      ),
    );
    gh.lazySingleton<_i160.BranchRepository>(
      () => _i375.BranchRepositoryImpl(
        dataSource: gh<_i526.BranchDataSource>(),
        mapper: gh<_i964.BranchMapper>(),
      ),
    );
    gh.factory<_i126.DeactivateUserUseCase>(
      () => _i126.DeactivateUserUseCase(gh<_i33.UserAccessRepository>()),
    );
    gh.factory<_i603.ReactivateUserUseCase>(
      () => _i603.ReactivateUserUseCase(gh<_i33.UserAccessRepository>()),
    );
    gh.factory<_i634.CrmTaskListBloc>(
      () => _i634.CrmTaskListBloc(
        listPendingTasksForWeek: gh<_i874.ListPendingTasksForWeekUseCase>(),
        completeTask: gh<_i96.CompleteCrmTaskUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i794.AboutAppRepository>(
      () => _i1060.AboutAppRepositoryImpl(
        dataSource: gh<_i364.AboutAppDataSource>(),
        mapper: gh<_i847.AboutAppMapper>(),
        notesMapper: gh<_i370.AboutAppNotesMapper>(),
      ),
    );
    gh.lazySingleton<_i295.PortfolioAssignmentRepository>(
      () => _i667.PortfolioAssignmentRepositoryImpl(
        dataSource: gh<_i847.PortfolioAssignmentDataSource>(),
        mapper: gh<_i708.PortfolioAssignmentMapper>(),
      ),
    );
    gh.factory<_i776.LoginBloc>(
      () => _i776.LoginBloc(
        signInWithEmailAndPassword:
            gh<_i185.SignInWithEmailAndPasswordUseCase>(),
        resolveActiveOrganizationId:
            gh<_i267.ResolveActiveOrganizationIdUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i292.SyncEngine>(
      () => _i292.SyncEngine(
        gh<_i234.OutboxRepository>(),
        gh<_i405.SyncCursorRepository>(),
        gh<List<_i17.SyncPushHandler>>(),
        gh<List<_i417.SyncPullSource>>(),
        gh<_i202.AnalyticsService>(),
        gh<_i113.CrashReporter>(),
        retryPolicy: gh<_i158.SyncRetryPolicy>(),
      ),
    );
    gh.factory<_i986.SeasonListBloc>(
      () => _i986.SeasonListBloc(
        listSeasons: gh<_i722.ListSeasonsUseCase>(),
        deleteSeason: gh<_i389.DeleteSeasonUseCase>(),
      ),
    );
    gh.lazySingleton<_i592.OrderApprovalRepository>(
      () => _i455.OrderApprovalRepositoryImpl(
        dataSource: gh<_i1039.OrderApprovalDataSource>(),
        mapper: gh<_i447.OrderApprovalDecisionMapper>(),
      ),
    );
    gh.lazySingleton<_i761.FavoriteRepository>(
      () => _i204.DriftFavoriteRepository(
        gh<_i658.AppDatabase>(),
        gh<_i619.FavoriteLocalMapper>(),
        gh<_i1002.FavoriteRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i753.AuditLogRepository>(
      () => _i303.AuditLogRepositoryImpl(
        dataSource: gh<_i432.AuditLogDataSource>(),
        mapper: gh<_i246.AuditLogEntryMapper>(),
      ),
    );
    gh.lazySingleton<_i262.UserRoleRepository>(
      () => _i53.UserRoleRepositoryImpl(
        dataSource: gh<_i176.UserRoleDataSource>(),
        mapper: gh<_i958.UserRoleUpdateResultMapper>(),
      ),
    );
    gh.lazySingleton<_i202.OrderSubmissionRepository>(
      () => _i167.OrderSubmissionRepositoryImpl(
        dataSource: gh<_i1068.OrderSubmissionDataSource>(),
        mapper: gh<_i1062.OrderSubmissionMapper>(),
      ),
    );
    gh.factory<_i604.UpdateTargetUseCase>(
      () => _i604.UpdateTargetUseCase(
        gh<_i876.TargetRepository>(),
        gh<_i47.PermissionService>(),
        gh<_i753.AuditLogRepository>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i321.ListPortfolioAssignmentsUseCase>(
      () => _i321.ListPortfolioAssignmentsUseCase(
        gh<_i295.PortfolioAssignmentRepository>(),
      ),
    );
    gh.factory<_i1030.AssignRoleToUserUseCase>(
      () => _i1030.AssignRoleToUserUseCase(
        gh<_i957.MembershipRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i856.SubmitOrderUseCase>(
      () => _i856.SubmitOrderUseCase(
        gh<_i202.OrderSubmissionRepository>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i559.AcceptInviteUseCase>(
      () => _i559.AcceptInviteUseCase(gh<_i999.InviteAcceptanceRepository>()),
    );
    gh.factory<_i409.ValidateInviteUseCase>(
      () => _i409.ValidateInviteUseCase(gh<_i999.InviteAcceptanceRepository>()),
    );
    gh.lazySingleton<_i75.InviteRepository>(
      () => _i90.InviteRepositoryImpl(
        dataSource: gh<_i814.InviteDataSource>(),
        mapper: gh<_i649.InviteMapper>(),
      ),
    );
    gh.lazySingleton<_i558.CatalogShareRepository>(
      () => _i54.CatalogShareRepositoryImpl(
        dataSource: gh<_i993.CatalogShareDataSource>(),
        mapper: gh<_i1010.CatalogShareMapper>(),
      ),
    );
    gh.lazySingleton<_i440.RoleRepository>(
      () => _i69.RoleRepositoryImpl(
        dataSource: gh<_i923.RoleDataSource>(),
        mapper: gh<_i1043.RoleMapper>(),
      ),
    );
    gh.lazySingleton<_i320.TeamRepository>(
      () => _i485.TeamRepositoryImpl(
        dataSource: gh<_i228.TeamDataSource>(),
        mapper: gh<_i802.TeamMapper>(),
      ),
    );
    gh.factory<_i938.CreatePromotionalCampaignUseCase>(
      () => _i938.CreatePromotionalCampaignUseCase(
        gh<_i211.PromotionalCampaignRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i339.UpdatePromotionalCampaignUseCase>(
      () => _i339.UpdatePromotionalCampaignUseCase(
        gh<_i211.PromotionalCampaignRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i542.SyncCenterCubit>(
      () => _i542.SyncCenterCubit(
        gh<_i234.OutboxRepository>(),
        gh<_i814.ConflictRecordRepository>(),
        gh<_i799.OfflinePackageStatusRepository>(),
        gh<_i610.ConnectivityService>(),
        gh<_i292.SyncEngine>(),
        gh<_i202.AnalyticsService>(),
        gh<_i113.CrashReporter>(),
      ),
    );
    gh.lazySingleton<_i644.InsightRepository>(
      () => _i666.InsightRepositoryImpl(
        dataSource: gh<_i902.InsightDataSource>(),
        mapper: gh<_i963.InsightMapper>(),
        validator: gh<_i864.InsightStructuralValidator>(),
      ),
    );
    gh.lazySingleton<_i183.OrderPricingRepository>(
      () => _i258.OrderPricingRepositoryImpl(
        dataSource: gh<_i492.OrderPricingDataSource>(),
        mapper: gh<_i730.OrderPricingMapper>(),
      ),
    );
    gh.factory<_i335.RemoveMemberFromTeamUseCase>(
      () => _i335.RemoveMemberFromTeamUseCase(
        gh<_i320.TeamRepository>(),
        gh<_i957.MembershipRepository>(),
      ),
    );
    gh.factory<_i684.ListStockAlertsUseCase>(
      () => _i684.ListStockAlertsUseCase(
        gh<_i896.StockAlertRepository>(),
        gh<_i47.PermissionService>(),
      ),
    );
    gh.lazySingleton<_i756.OrganizationRepository>(
      () => _i522.OrganizationRepositoryImpl(
        dataSource: gh<_i268.OrganizationDataSource>(),
        mapper: gh<_i719.OrganizationMapper>(),
      ),
    );
    gh.factory<_i472.CreateTargetUseCase>(
      () => _i472.CreateTargetUseCase(
        gh<_i876.TargetRepository>(),
        gh<_i47.PermissionService>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i647.PublishProductUseCase>(
      () => _i647.PublishProductUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i739.UpdateProductMediaUseCase>(
      () => _i739.UpdateProductMediaUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i12.UpdateProductUseCase>(
      () => _i12.UpdateProductUseCase(
        gh<_i321.ProductRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.lazySingleton<_i488.UserProfileRepository>(
      () => _i801.UserProfileRepositoryImpl(
        dataSource: gh<_i668.UserProfileDataSource>(),
        mapper: gh<_i756.UserProfileMapper>(),
      ),
    );
    gh.lazySingleton<_i970.SyncScheduler>(
      () => _i970.SyncScheduler(
        gh<_i292.SyncEngine>(),
        gh<_i610.ConnectivityService>(),
      ),
    );
    gh.factory<_i825.GetCustomerFormConfigUseCase>(
      () => _i825.GetCustomerFormConfigUseCase(
        gh<_i756.OrganizationRepository>(),
      ),
    );
    gh.lazySingleton<_i898.PaymentTermOfflinePackageEntityLoader>(
      () => _i898.PaymentTermOfflinePackageEntityLoader(
        gh<_i595.LoadInitialPaymentTermOfflineDataUseCase>(),
        gh<_i512.PaymentTermLocalStoreRepository>(),
        gh<_i315.PermissionService>(),
      ),
    );
    gh.factory<_i421.RecordAuditLogUseCase>(
      () => _i421.RecordAuditLogUseCase(gh<_i753.AuditLogRepository>()),
    );
    gh.factory<_i433.CustomerDetailBloc>(
      () => _i433.CustomerDetailBloc(
        getCustomerById: gh<_i356.GetCustomerByIdUseCase>(),
        listActivitiesForCustomer:
            gh<_i205.ListCrmActivitiesForCustomerUseCase>(),
        listPendingTasksForCustomer:
            gh<_i205.ListPendingTasksForCustomerUseCase>(),
        nextBestActionService: gh<_i205.NextBestActionService>(),
        registerActivity: gh<_i205.RegisterCrmActivityUseCase>(),
        permissionService: gh<_i47.PermissionService>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i766.CreateTeamUseCase>(
      () => _i766.CreateTeamUseCase(
        gh<_i320.TeamRepository>(),
        gh<_i957.MembershipRepository>(),
        gh<_i756.OrganizationRepository>(),
      ),
    );
    gh.factory<_i428.UpdateUserRoleUseCase>(
      () => _i428.UpdateUserRoleUseCase(gh<_i262.UserRoleRepository>()),
    );
    gh.factory<_i713.GetAboutAppUseCase>(
      () => _i713.GetAboutAppUseCase(gh<_i794.AboutAppRepository>()),
    );
    gh.factory<_i916.SearchAboutAppNotesUseCase>(
      () => _i916.SearchAboutAppNotesUseCase(gh<_i794.AboutAppRepository>()),
    );
    gh.factory<_i226.SubmitAboutAppDiagnosticsUseCase>(
      () => _i226.SubmitAboutAppDiagnosticsUseCase(
        gh<_i794.AboutAppRepository>(),
      ),
    );
    gh.factory<_i420.CatalogHomeBloc>(
      () => _i420.CatalogHomeBloc(
        getCatalogHomeConfig: gh<_i316.GetCatalogHomeConfigUseCase>(),
        getFeaturedCollectionsSection:
            gh<_i1042.GetFeaturedCollectionsSectionUseCase>(),
        getNewArrivalsSection: gh<_i76.GetNewArrivalsSectionUseCase>(),
        getCatalogCampaignsSection:
            gh<_i151.GetCatalogCampaignsSectionUseCase>(),
        loadCatalogHomeCache: gh<_i249.LoadCatalogHomeCacheUseCase>(),
        saveCatalogHomeCache: gh<_i64.SaveCatalogHomeCacheUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i90.CreateAccountWithEmailAndPasswordUseCase>(
      () => _i90.CreateAccountWithEmailAndPasswordUseCase(
        gh<_i472.AuthRepository>(),
        gh<_i488.UserProfileRepository>(),
      ),
    );
    gh.lazySingleton<_i344.CatalogShareLookupRepository>(
      () => _i667.CatalogShareLookupRepositoryImpl(
        dataSource: gh<_i979.CatalogShareLookupDataSource>(),
        mapper: gh<_i1010.CatalogShareMapper>(),
      ),
    );
    gh.lazySingleton<_i568.ProductSearchRepository>(
      () => _i941.ProductSearchRepositoryImpl(
        remoteDataSource: gh<_i671.ProductRemoteSearchDataSource>(),
        localDataSource: gh<_i42.ProductLocalSearchIndexDataSource>(),
      ),
    );
    gh.lazySingleton<_i221.VariantStockBalanceRepository>(
      () => _i682.VariantStockBalanceRepositoryImpl(
        gh<_i180.VariantStockBalanceRemoteDataSource>(),
        gh<_i658.AppDatabase>(),
        gh<_i617.VariantStockBalanceMapper>(),
        gh<_i333.VariantStockBalanceLocalMapper>(),
      ),
    );
    gh.factory<_i620.PreviewCatalogShareUseCase>(
      () => _i620.PreviewCatalogShareUseCase(
        gh<_i344.CatalogShareLookupRepository>(),
      ),
    );
    gh.factory<_i298.RegisterCatalogShareOpenUseCase>(
      () => _i298.RegisterCatalogShareOpenUseCase(
        gh<_i344.CatalogShareLookupRepository>(),
      ),
    );
    gh.factory<_i1069.GetVariantInventoryAvailabilityUseCase>(
      () => _i1069.GetVariantInventoryAvailabilityUseCase(
        gh<_i221.VariantStockBalanceRepository>(),
      ),
    );
    gh.factory<_i201.ListAuditLogEntriesUseCase>(
      () => _i201.ListAuditLogEntriesUseCase(
        gh<_i753.AuditLogRepository>(),
        gh<_i47.PermissionService>(),
      ),
    );
    gh.factory<_i628.AcceptInviteBloc>(
      () => _i628.AcceptInviteBloc(
        validateInvite: gh<_i409.ValidateInviteUseCase>(),
        acceptInvite: gh<_i559.AcceptInviteUseCase>(),
        authRepository: gh<_i472.AuthRepository>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i885.CreateDiscountPolicyUseCase>(
      () => _i885.CreateDiscountPolicyUseCase(
        gh<_i31.DiscountPolicyRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i468.UpdateDiscountPolicyUseCase>(
      () => _i468.UpdateDiscountPolicyUseCase(
        gh<_i31.DiscountPolicyRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i722.GetStockTurnoverMetricsUseCase>(
      () => _i722.GetStockTurnoverMetricsUseCase(
        gh<_i503.StockTurnoverRepository>(),
      ),
    );
    gh.factory<_i906.CreateBranchUseCase>(
      () => _i906.CreateBranchUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i500.ListBranchesByCompanyUseCase>(
      () => _i500.ListBranchesByCompanyUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i820.UpdateBranchUseCase>(
      () => _i820.UpdateBranchUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i268.SearchProductsUseCase>(
      () => _i268.SearchProductsUseCase(gh<_i568.ProductSearchRepository>()),
    );
    gh.factory<_i1016.AddFavoriteProductUseCase>(
      () => _i1016.AddFavoriteProductUseCase(gh<_i761.FavoriteRepository>()),
    );
    gh.factory<_i214.RemoveFavoriteProductUseCase>(
      () => _i214.RemoveFavoriteProductUseCase(gh<_i761.FavoriteRepository>()),
    );
    gh.factory<_i487.WatchFavoriteProductIdsUseCase>(
      () =>
          _i487.WatchFavoriteProductIdsUseCase(gh<_i761.FavoriteRepository>()),
    );
    gh.factory<_i98.DiscountPolicyCubit>(
      () => _i98.DiscountPolicyCubit(
        gh<_i31.DiscountPolicyRepository>(),
        gh<_i885.CreateDiscountPolicyUseCase>(),
        gh<_i468.UpdateDiscountPolicyUseCase>(),
      ),
    );
    gh.factory<_i828.DecideOrderApprovalUseCase>(
      () => _i828.DecideOrderApprovalUseCase(
        gh<_i592.OrderApprovalRepository>(),
        gh<_i47.PermissionService>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i968.ProductMediaBloc>(
      () => _i968.ProductMediaBloc(
        storage: gh<_i209.StorageDataSource>(),
        updateMedia: gh<_i739.UpdateProductMediaUseCase>(),
        featureFlagService: gh<_i869.FeatureFlagService>(),
        analyticsService: gh<_i202.AnalyticsService>(),
        compressor: gh<_i209.ImageUploadCompressor>(),
        thumbnailCompressor: gh<_i209.ImageCompressor>(),
      ),
    );
    gh.factory<_i881.CreatePaymentTermUseCase>(
      () => _i881.CreatePaymentTermUseCase(
        gh<_i358.PaymentTermRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i932.UpdatePaymentTermUseCase>(
      () => _i932.UpdatePaymentTermUseCase(
        gh<_i358.PaymentTermRepository>(),
        gh<_i753.AuditLogRepository>(),
      ),
    );
    gh.factory<_i530.ResolveOrderDraftDefaultsUseCase>(
      () => _i530.ResolveOrderDraftDefaultsUseCase(
        gh<_i265.ListBranchesByCompanyUseCase>(),
        gh<_i445.ResolveApplicablePriceListsUseCase>(),
        gh<_i445.ListActivePaymentTermsUseCase>(),
      ),
    );
    gh.factory<_i305.GetOrderPricingSummaryUseCase>(
      () => _i305.GetOrderPricingSummaryUseCase(
        gh<_i183.OrderPricingRepository>(),
        gh<_i356.GetCustomerByIdUseCase>(),
      ),
    );
    gh.factory<_i198.ProductFormBloc>(
      () => _i198.ProductFormBloc(
        getDraft: gh<_i1021.GetProductFormDraftUseCase>(),
        saveDraft: gh<_i244.SaveProductFormDraftUseCase>(),
        clearDraft: gh<_i19.ClearProductFormDraftUseCase>(),
        createProduct: gh<_i300.CreateProductUseCase>(),
        updateProduct: gh<_i12.UpdateProductUseCase>(),
        publishProduct: gh<_i647.PublishProductUseCase>(),
        listCategories: gh<_i435.ListCategoriesUseCase>(),
        listProductColors: gh<_i789.ListProductColorsUseCase>(),
        listSizeGridTemplates: gh<_i646.ListSizeGridTemplatesUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i990.CreateCatalogShareLinkUseCase>(
      () => _i990.CreateCatalogShareLinkUseCase(
        gh<_i558.CatalogShareRepository>(),
      ),
    );
    gh.factory<_i795.GetCatalogShareUseCase>(
      () => _i795.GetCatalogShareUseCase(gh<_i558.CatalogShareRepository>()),
    );
    gh.factory<_i601.RevokeCatalogShareUseCase>(
      () => _i601.RevokeCatalogShareUseCase(gh<_i558.CatalogShareRepository>()),
    );
    gh.factory<_i835.AddUserToTeamUseCase>(
      () => _i835.AddUserToTeamUseCase(gh<_i320.TeamRepository>()),
    );
    gh.factory<_i817.DeleteTeamUseCase>(
      () => _i817.DeleteTeamUseCase(gh<_i320.TeamRepository>()),
    );
    gh.factory<_i765.OrderPricingSummaryCubit>(
      () => _i765.OrderPricingSummaryCubit(
        gh<_i305.GetOrderPricingSummaryUseCase>(),
      ),
    );
    gh.factory<_i954.PaymentTermsCubit>(
      () => _i954.PaymentTermsCubit(
        gh<_i358.PaymentTermRepository>(),
        gh<_i881.CreatePaymentTermUseCase>(),
        gh<_i932.UpdatePaymentTermUseCase>(),
      ),
    );
    gh.factory<_i658.AddMemberToTeamUseCase>(
      () => _i658.AddMemberToTeamUseCase(
        gh<_i320.TeamRepository>(),
        gh<_i957.MembershipRepository>(),
        gh<_i756.OrganizationRepository>(),
      ),
    );
    gh.factory<_i207.UpdateTeamUseCase>(
      () => _i207.UpdateTeamUseCase(
        gh<_i320.TeamRepository>(),
        gh<_i957.MembershipRepository>(),
        gh<_i756.OrganizationRepository>(),
      ),
    );
    gh.factory<_i481.SignUpBloc>(
      () => _i481.SignUpBloc(
        createAccountWithEmailAndPassword:
            gh<_i90.CreateAccountWithEmailAndPasswordUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i998.TargetFormCubit>(
      () => _i998.TargetFormCubit(
        gh<_i876.TargetRepository>(),
        gh<_i472.CreateTargetUseCase>(),
        gh<_i604.UpdateTargetUseCase>(),
      ),
    );
    gh.factory<_i55.CreateOrganizationUseCase>(
      () => _i55.CreateOrganizationUseCase(gh<_i756.OrganizationRepository>()),
    );
    gh.factory<_i966.GetOrganizationUseCase>(
      () => _i966.GetOrganizationUseCase(gh<_i756.OrganizationRepository>()),
    );
    gh.factory<_i270.UpdateOrganizationSettingsUseCase>(
      () => _i270.UpdateOrganizationSettingsUseCase(
        gh<_i756.OrganizationRepository>(),
      ),
    );
    gh.factory<_i398.AboutAppBloc>(
      () => _i398.AboutAppBloc(
        getAboutApp: gh<_i713.GetAboutAppUseCase>(),
        searchNotes: gh<_i916.SearchAboutAppNotesUseCase>(),
        submitDiagnostics: gh<_i226.SubmitAboutAppDiagnosticsUseCase>(),
      ),
    );
    gh.factory<_i68.EnsureSystemRolesUseCase>(
      () => _i68.EnsureSystemRolesUseCase(gh<_i440.RoleRepository>()),
    );
    gh.factory<_i461.CreateInviteUseCase>(
      () => _i461.CreateInviteUseCase(gh<_i75.InviteRepository>()),
    );
    gh.factory<_i509.ListPendingInvitesUseCase>(
      () => _i509.ListPendingInvitesUseCase(gh<_i75.InviteRepository>()),
    );
    gh.factory<_i502.ResendInviteUseCase>(
      () => _i502.ResendInviteUseCase(gh<_i75.InviteRepository>()),
    );
    gh.factory<_i334.RevokeInviteUseCase>(
      () => _i334.RevokeInviteUseCase(gh<_i75.InviteRepository>()),
    );
    gh.factory<_i960.RankingPeerResolverService>(
      () => _i960.RankingPeerResolverService(
        gh<_i265.MembershipRepository>(),
        gh<_i265.TeamRepository>(),
      ),
    );
    gh.factory<_i302.PortfolioVisibilityService>(
      () => _i302.PortfolioVisibilityService(
        gh<_i265.MembershipRepository>(),
        gh<_i265.TeamRepository>(),
      ),
    );
    gh.factory<_i977.LoadInitialCustomerOfflineDataUseCase>(
      () => _i977.LoadInitialCustomerOfflineDataUseCase(
        gh<_i857.CustomerRepository>(),
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i220.PortfolioAssignmentRepository>(),
        gh<_i361.CustomerLocalStoreRepository>(),
      ),
    );
    gh.factory<_i93.ListOrganizationUsersUseCase>(
      () => _i93.ListOrganizationUsersUseCase(
        gh<_i957.MembershipRepository>(),
        gh<_i320.TeamRepository>(),
      ),
    );
    gh.factory<_i636.AssignPortfolioUseCase>(
      () => _i636.AssignPortfolioUseCase(
        gh<_i295.PortfolioAssignmentRepository>(),
        gh<_i265.MembershipRepository>(),
        gh<_i265.TeamRepository>(),
      ),
    );
    gh.factory<_i447.CatalogSharePublicBloc>(
      () => _i447.CatalogSharePublicBloc(
        previewCatalogShare: gh<_i620.PreviewCatalogShareUseCase>(),
        registerCatalogShareOpen: gh<_i298.RegisterCatalogShareOpenUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i63.OrderVisibilityService>(
      () => _i63.OrderVisibilityService(
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i265.TeamRepository>(),
      ),
    );
    gh.factory<_i951.TargetVisibilityService>(
      () => _i951.TargetVisibilityService(
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i265.TeamRepository>(),
      ),
    );
    gh.factory<_i516.TeamFormBloc>(
      () => _i516.TeamFormBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
        createTeam: gh<_i265.CreateTeamUseCase>(),
        updateTeam: gh<_i265.UpdateTeamUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i75.PromotionalCampaignCubit>(
      () => _i75.PromotionalCampaignCubit(
        gh<_i211.PromotionalCampaignRepository>(),
        gh<_i938.CreatePromotionalCampaignUseCase>(),
        gh<_i339.UpdatePromotionalCampaignUseCase>(),
      ),
    );
    gh.factory<_i193.InviteFormBloc>(
      () => _i193.InviteFormBloc(
        createInvite: gh<_i461.CreateInviteUseCase>(),
        membershipRepository: gh<_i957.MembershipRepository>(),
        authRepository: gh<_i472.AuthRepository>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i478.CustomerFormBloc>(
      () => _i478.CustomerFormBloc(
        getConfig: gh<_i825.GetCustomerFormConfigUseCase>(),
        getDraft: gh<_i504.GetCustomerFormDraftUseCase>(),
        saveDraft: gh<_i780.SaveCustomerFormDraftUseCase>(),
        clearDraft: gh<_i551.ClearCustomerFormDraftUseCase>(),
        createCustomer: gh<_i427.CreateCustomerUseCase>(),
        updateCustomer: gh<_i172.UpdateCustomerUseCase>(),
        listOrganizationUsers: gh<_i220.ListOrganizationUsersUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i480.LeadFormBloc>(
      () => _i480.LeadFormBloc(
        createLead: gh<_i770.CreateLeadUseCase>(),
        listOrganizationUsers: gh<_i220.ListOrganizationUsersUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i1062.GetOrderByIdUseCase>(
      () => _i1062.GetOrderByIdUseCase(
        gh<_i1051.OrderListRepository>(),
        gh<_i63.OrderVisibilityService>(),
        gh<_i47.PermissionService>(),
      ),
    );
    gh.factory<_i144.ListOrdersUseCase>(
      () => _i144.ListOrdersUseCase(
        gh<_i1051.OrderListRepository>(),
        gh<_i63.OrderVisibilityService>(),
        gh<_i47.PermissionService>(),
      ),
    );
    gh.lazySingleton<_i325.CustomerOfflinePackageEntityLoader>(
      () => _i325.CustomerOfflinePackageEntityLoader(
        gh<_i977.LoadInitialCustomerOfflineDataUseCase>(),
        gh<_i361.CustomerLocalStoreRepository>(),
      ),
    );
    gh.factory<_i576.ListCustomerPortfolioUseCase>(
      () => _i576.ListCustomerPortfolioUseCase(
        gh<_i857.CustomerRepository>(),
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i220.PortfolioAssignmentRepository>(),
      ),
    );
    gh.lazySingleton<_i766.VariantAvailabilityRepository>(
      () => _i808.InventoryVariantAvailabilityRepository(
        gh<_i221.VariantStockBalanceRepository>(),
        gh<_i795.ProductVariantRepository>(),
        gh<_i639.FutureStockRepository>(),
      ),
    );
    gh.factory<_i293.TargetDashboardCubit>(
      () => _i293.TargetDashboardCubit(
        gh<_i951.TargetVisibilityService>(),
        gh<_i876.TargetRepository>(),
        gh<_i154.TargetAchievementRepository>(),
        gh<_i202.AnalyticsService>(),
        gh<_i862.ClosingProjectionService>(),
        gh<_i154.ProcessTargetAlertUseCase>(),
      ),
    );
    gh.factory<_i698.UserRoleEditBloc>(
      () => _i698.UserRoleEditBloc(
        updateUserRole: gh<_i428.UpdateUserRoleUseCase>(),
        membershipRepository: gh<_i957.MembershipRepository>(),
        authRepository: gh<_i472.AuthRepository>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i581.LeadListBloc>(
      () => _i581.LeadListBloc(
        listLeads: gh<_i778.ListLeadsUseCase>(),
        qualifyLead: gh<_i924.QualifyLeadUseCase>(),
        disqualifyLead: gh<_i904.DisqualifyLeadUseCase>(),
        listOrganizationUsers: gh<_i220.ListOrganizationUsersUseCase>(),
      ),
    );
    gh.factory<_i758.RankingDashboardCubit>(
      () => _i758.RankingDashboardCubit(
        gh<_i951.TargetVisibilityService>(),
        gh<_i960.RankingPeerResolverService>(),
        gh<_i265.GetOrganizationUseCase>(),
        gh<_i876.TargetRepository>(),
        gh<_i154.TargetAchievementRepository>(),
        gh<_i265.MembershipRepository>(),
        gh<_i265.TeamRepository>(),
        gh<_i444.RankingCalculationService>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i249.FavoriteStatusCubit>(
      () => _i249.FavoriteStatusCubit(
        watchFavoriteProductIds: gh<_i487.WatchFavoriteProductIdsUseCase>(),
        addFavoriteProduct: gh<_i1016.AddFavoriteProductUseCase>(),
        removeFavoriteProduct: gh<_i214.RemoveFavoriteProductUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
        sessionService: gh<_i885.SessionService>(),
      ),
    );
    gh.factory<_i936.PositivacaoSettingsCubit>(
      () => _i936.PositivacaoSettingsCubit(
        gh<_i265.GetOrganizationUseCase>(),
        gh<_i265.UpdateOrganizationSettingsUseCase>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i424.OrderListBloc>(
      () => _i424.OrderListBloc(
        listOrders: gh<_i144.ListOrdersUseCase>(),
        listLocalPendingOrders: gh<_i233.ListLocalPendingOrdersUseCase>(),
      ),
    );
    gh.factory<_i438.PreviewCustomerSegmentCountUseCase>(
      () => _i438.PreviewCustomerSegmentCountUseCase(
        gh<_i576.ListCustomerPortfolioUseCase>(),
      ),
    );
    gh.factory<_i522.CustomerPortfolioBloc>(
      () => _i522.CustomerPortfolioBloc(
        listCustomerPortfolio: gh<_i576.ListCustomerPortfolioUseCase>(),
      ),
    );
    gh.factory<_i901.CustomerSegmentBloc>(
      () => _i901.CustomerSegmentBloc(
        listCustomerSegments: gh<_i261.ListCustomerSegmentsUseCase>(),
        createCustomerSegment: gh<_i806.CreateCustomerSegmentUseCase>(),
        deleteCustomerSegment: gh<_i869.DeleteCustomerSegmentUseCase>(),
        previewCustomerSegmentCount:
            gh<_i438.PreviewCustomerSegmentCountUseCase>(),
      ),
    );
    gh.factory<_i986.ListCommercialTeamsUseCase>(
      () => _i986.ListCommercialTeamsUseCase(
        gh<_i265.TeamRepository>(),
        gh<_i93.ListOrganizationUsersUseCase>(),
      ),
    );
    gh.factory<_i0.InviteListBloc>(
      () => _i0.InviteListBloc(
        listPendingInvites: gh<_i509.ListPendingInvitesUseCase>(),
        resendInvite: gh<_i502.ResendInviteUseCase>(),
        revokeInvite: gh<_i334.RevokeInviteUseCase>(),
      ),
    );
    gh.factory<_i831.TeamListBloc>(
      () => _i831.TeamListBloc(
        listCommercialTeams: gh<_i986.ListCommercialTeamsUseCase>(),
        deleteTeam: gh<_i265.DeleteTeamUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i511.CatalogShareSheetBloc>(
      () => _i511.CatalogShareSheetBloc(
        createCatalogShareLink: gh<_i990.CreateCatalogShareLinkUseCase>(),
        getCatalogShare: gh<_i795.GetCatalogShareUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i433.AssignPortfolioBloc>(
      () => _i433.AssignPortfolioBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
        listCommercialTeams: gh<_i986.ListCommercialTeamsUseCase>(),
        listPortfolioAssignments: gh<_i321.ListPortfolioAssignmentsUseCase>(),
        assignPortfolio: gh<_i636.AssignPortfolioUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i627.PositivacaoDashboardCubit>(
      () => _i627.PositivacaoDashboardCubit(
        gh<_i951.TargetVisibilityService>(),
        gh<_i265.GetOrganizationUseCase>(),
        gh<_i1031.PositivacaoRepository>(),
        gh<_i909.GetCustomerByIdUseCase>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i125.OrderHistoryBloc>(
      () => _i125.OrderHistoryBloc(
        getOrderById: gh<_i1062.GetOrderByIdUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i675.CompleteOnboardingUseCase>(
      () =>
          _i675.CompleteOnboardingUseCase(gh<_i55.CreateOrganizationUseCase>()),
    );
    gh.factory<_i244.UserListBloc>(
      () => _i244.UserListBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
        deactivateUser: gh<_i126.DeactivateUserUseCase>(),
        reactivateUser: gh<_i603.ReactivateUserUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i349.GetVariantFutureStockSummaryUseCase>(
      () => _i349.GetVariantFutureStockSummaryUseCase(
        gh<_i766.VariantAvailabilityRepository>(),
        gh<_i639.FutureStockRepository>(),
      ),
    );
    gh.factory<_i583.EnsureCustomerInSellerPortfolioUseCase>(
      () => _i583.EnsureCustomerInSellerPortfolioUseCase(
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i220.PortfolioAssignmentRepository>(),
      ),
    );
    gh.lazySingleton<List<_i84.OfflinePackageEntityLoader>>(
      () => offlinePackageLoadersModule.offlinePackageEntityLoaders(
        gh<_i325.CustomerOfflinePackageEntityLoader>(),
        gh<_i1044.PriceListOfflinePackageEntityLoader>(),
        gh<_i898.PaymentTermOfflinePackageEntityLoader>(),
      ),
    );
    gh.factory<_i339.OrderApprovalQueueBloc>(
      () => _i339.OrderApprovalQueueBloc(
        listOrders: gh<_i144.ListOrdersUseCase>(),
        decideOrderApproval: gh<_i828.DecideOrderApprovalUseCase>(),
      ),
    );
    gh.factory<_i385.GetVariantAvailabilityUseCase>(
      () => _i385.GetVariantAvailabilityUseCase(
        gh<_i766.VariantAvailabilityRepository>(),
      ),
    );
    gh.factory<_i72.ListFavoriteProductsUseCase>(
      () => _i72.ListFavoriteProductsUseCase(
        gh<_i761.FavoriteRepository>(),
        gh<_i321.ProductRepository>(),
        gh<_i385.GetVariantAvailabilityUseCase>(),
      ),
    );
    gh.factory<_i593.OnboardingBloc>(
      () => _i593.OnboardingBloc(
        getProgress: gh<_i206.GetOnboardingProgressUseCase>(),
        saveProgress: gh<_i81.SaveOnboardingProgressUseCase>(),
        clearProgress: gh<_i214.ClearOnboardingProgressUseCase>(),
        completeOnboarding: gh<_i675.CompleteOnboardingUseCase>(),
        authRepository: gh<_i472.AuthRepository>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i965.ProductSearchBloc>(
      () => _i965.ProductSearchBloc(
        searchProducts: gh<_i268.SearchProductsUseCase>(),
        getVariantAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
      ),
    );
    gh.factory<_i578.ProductDetailBloc>(
      () => _i578.ProductDetailBloc(
        getProductById: gh<_i721.GetProductByIdUseCase>(),
        listVariantsByProduct: gh<_i530.ListProductVariantsByProductUseCase>(),
        listProductColors: gh<_i789.ListProductColorsUseCase>(),
        getSizeGridTemplateById: gh<_i194.GetSizeGridTemplateByIdUseCase>(),
        getVariantAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
        resolvePriceForVariant: gh<_i352.ResolvePriceForVariantUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i109.DownloadOfflinePackageUseCase>(
      () => _i109.DownloadOfflinePackageUseCase(
        gh<List<_i84.OfflinePackageEntityLoader>>(),
        gh<_i799.OfflinePackageStatusRepository>(),
      ),
    );
    gh.factory<_i769.CommercialSizeGridBloc>(
      () => _i769.CommercialSizeGridBloc(
        getDraft: gh<_i801.GetCommercialSizeGridDraftUseCase>(),
        saveDraft: gh<_i644.SaveCommercialSizeGridDraftUseCase>(),
        getAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
      ),
    );
    gh.factory<_i1025.GetOrderSubmissionContextUseCase>(
      () => _i1025.GetOrderSubmissionContextUseCase(
        gh<_i356.GetCustomerByIdUseCase>(),
        gh<_i455.PriceListRepository>(),
        gh<_i358.PaymentTermRepository>(),
        gh<_i385.GetVariantAvailabilityUseCase>(),
      ),
    );
    gh.factory<_i331.ProductGridBloc>(
      () => _i331.ProductGridBloc(
        listCatalogProducts: gh<_i448.ListCatalogProductsUseCase>(),
        getVariantAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
        listVariantsByProduct: gh<_i530.ListProductVariantsByProductUseCase>(),
        resolvePriceForVariant: gh<_i352.ResolvePriceForVariantUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.factory<_i168.StartOrderDraftForCustomerUseCase>(
      () => _i168.StartOrderDraftForCustomerUseCase(
        gh<_i583.EnsureCustomerInSellerPortfolioUseCase>(),
        gh<_i909.GetCustomerByIdUseCase>(),
        gh<_i530.ResolveOrderDraftDefaultsUseCase>(),
        gh<_i81.OrderDraftRepository>(),
      ),
    );
    gh.factory<_i318.FavoritesBloc>(
      () => _i318.FavoritesBloc(
        listFavoriteProducts: gh<_i72.ListFavoriteProductsUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
        sessionService: gh<_i885.SessionService>(),
      ),
    );
    gh.factory<_i197.OrderItemsGridCubit>(
      () => _i197.OrderItemsGridCubit(
        listVariantsByProduct: gh<_i530.ListProductVariantsByProductUseCase>(),
        listProductColors: gh<_i789.ListProductColorsUseCase>(),
        getSizeGridTemplateById: gh<_i194.GetSizeGridTemplateByIdUseCase>(),
        getVariantAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
      ),
    );
    gh.factory<_i74.OfflinePackageDownloadCubit>(
      () => _i74.OfflinePackageDownloadCubit(
        gh<_i109.DownloadOfflinePackageUseCase>(),
      ),
    );
    gh.factory<_i186.CatalogFilterBloc>(
      () => _i186.CatalogFilterBloc(
        listCatalogProducts: gh<_i448.ListCatalogProductsUseCase>(),
        getVariantAvailability: gh<_i385.GetVariantAvailabilityUseCase>(),
        listCollections: gh<_i1023.ListCollectionsUseCase>(),
        listSeasons: gh<_i722.ListSeasonsUseCase>(),
        listCategories: gh<_i435.ListCategoriesUseCase>(),
        listProductColors: gh<_i789.ListProductColorsUseCase>(),
        listSizeGridTemplates: gh<_i646.ListSizeGridTemplatesUseCase>(),
        loadCatalogPreferences: gh<_i700.LoadCatalogPreferencesUseCase>(),
        saveCatalogPreferences: gh<_i36.SaveCatalogPreferencesUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
        sessionService: gh<_i885.SessionService>(),
      ),
    );
    gh.factory<_i753.OrderSubmissionValidationCubit>(
      () => _i753.OrderSubmissionValidationCubit(
        gh<_i1025.GetOrderSubmissionContextUseCase>(),
        gh<_i745.OrderSubmissionValidator>(),
      ),
    );
    gh.factory<_i287.OrderDraftBloc>(
      () => _i287.OrderDraftBloc(
        getOrderDraft: gh<_i485.GetOrderDraftUseCase>(),
        startOrderDraftForCustomer:
            gh<_i168.StartOrderDraftForCustomerUseCase>(),
        saveOrderDraft: gh<_i1.SaveOrderDraftUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
        getProductById: gh<_i721.GetProductByIdUseCase>(),
        resolvePriceForVariant: gh<_i352.ResolvePriceForVariantUseCase>(),
      ),
    );
    gh.factory<_i315.DuplicateOrderUseCase>(
      () => _i315.DuplicateOrderUseCase(
        gh<_i1062.GetOrderByIdUseCase>(),
        gh<_i168.StartOrderDraftForCustomerUseCase>(),
        gh<_i81.OrderDraftRepository>(),
        gh<_i720.AddItemsToOrderDraftUseCase>(),
        gh<_i795.ProductVariantRepository>(),
        gh<_i385.GetVariantAvailabilityUseCase>(),
        gh<_i352.ResolvePriceForVariantUseCase>(),
      ),
    );
    gh.factory<_i21.OrderDuplicationCubit>(
      () => _i21.OrderDuplicationCubit(
        gh<_i315.DuplicateOrderUseCase>(),
        gh<_i202.AnalyticsService>(),
      ),
    );
    return this;
  }
}

class _$AppInjectionModule extends _i212.AppInjectionModule {}

class _$SyncModule extends _i350.SyncModule {}

class _$InsightModule extends _i676.InsightModule {}

class _$OfflinePackageLoadersModule extends _i418.OfflinePackageLoadersModule {}
