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
import '../core/database/app_database.dart' as _i935;
import '../core/database/database.dart' as _i658;
import '../core/environment/app_environment.dart' as _i461;
import '../core/feature_flags/feature_flag_service.dart' as _i972;
import '../core/feature_flags/firebase_feature_flag_service.dart' as _i845;
import '../core/functions/app_client_metadata.dart' as _i465;
import '../core/functions/cloud_functions_service.dart' as _i147;
import '../core/functions/functions.dart' as _i340;
import '../core/performance/firebase_performance_monitor.dart' as _i387;
import '../core/performance/performance_monitor.dart' as _i1008;
import '../core/permissions/permission_service.dart' as _i315;
import '../core/permissions/permissions.dart' as _i47;
import '../core/services/crash_reporter.dart' as _i349;
import '../core/services/firebase_crash_reporter.dart' as _i559;
import '../core/storage/firebase_storage_data_source.dart' as _i833;
import '../core/storage/storage_data_source.dart' as _i904;
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
import '../features/organizations/domain/usecases/update_branch_use_case.dart'
    as _i820;
import '../features/organizations/domain/usecases/update_company_use_case.dart'
    as _i571;
import '../features/organizations/domain/usecases/update_organization_settings_use_case.dart'
    as _i270;
import '../features/organizations/domain/usecases/update_team_use_case.dart'
    as _i207;
import '../features/organizations/organizations.dart' as _i265;
import '../features/products/data/mappers/product_mapper.dart' as _i309;
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
    gh.lazySingleton<_i461.AppEnvironment>(
      () => appInjectionModule.appEnvironment,
    );
    gh.lazySingleton<_i59.FirebaseAuth>(() => appInjectionModule.firebaseAuth);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => appInjectionModule.secureStorage,
    );
    gh.lazySingleton<_i935.AppDatabase>(() => appInjectionModule.appDatabase());
    gh.lazySingleton<_i26.AuthUserMapper>(() => const _i26.AuthUserMapper());
    gh.lazySingleton<_i246.AuditLogEntryMapper>(
      () => const _i246.AuditLogEntryMapper(),
    );
    gh.lazySingleton<_i756.UserProfileMapper>(
      () => const _i756.UserProfileMapper(),
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
    gh.lazySingleton<_i309.ProductMapper>(() => const _i309.ProductMapper());
    gh.lazySingleton<_i847.AboutAppMapper>(() => const _i847.AboutAppMapper());
    gh.lazySingleton<_i370.AboutAppNotesMapper>(
      () => const _i370.AboutAppNotesMapper(),
    );
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
    gh.lazySingleton<_i472.LeadRepository>(
      () => _i185.SharedPreferencesLeadRepository(gh<_i265.LeadMapper>()),
    );
    gh.lazySingleton<_i99.SecureSessionStore>(
      () => _i772.SecureFlutterSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i43.OpportunityRepository>(
      () => _i771.SharedPreferencesOpportunityRepository(
        gh<_i449.OpportunityMapper>(),
      ),
    );
    gh.lazySingleton<_i1036.CustomerFormDraftDataSource>(
      () => const _i292.SharedPreferencesCustomerFormDraftDataSource(),
    );
    gh.lazySingleton<_i87.InviteAcceptanceMapper>(
      () => _i87.InviteAcceptanceMapper(gh<_i649.InviteMapper>()),
    );
    gh.lazySingleton<_i999.CustomerFormDraftRepository>(
      () => _i920.CustomerFormDraftRepositoryImpl(
        dataSource: gh<_i1036.CustomerFormDraftDataSource>(),
        mapper: gh<_i258.CustomerFormDraftMapper>(),
      ),
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
    gh.lazySingleton<_i725.CustomerLocalMapper>(
      () => _i725.CustomerLocalMapper(gh<_i457.CustomerMapper>()),
    );
    gh.lazySingleton<_i886.OnboardingProgressRepository>(
      () => _i803.OnboardingProgressRepositoryImpl(
        dataSource: gh<_i924.OnboardingProgressDataSource>(),
        mapper: gh<_i477.OnboardingProgressMapper>(),
      ),
    );
    gh.lazySingleton<_i527.OpportunityOutcomeReasonRepository>(
      () => _i292.SharedPreferencesOpportunityOutcomeReasonRepository(
        gh<_i210.OpportunityOutcomeReasonMapper>(),
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
    gh.lazySingleton<_i857.CustomerRepository>(
      () =>
          _i784.SharedPreferencesCustomerRepository(gh<_i457.CustomerMapper>()),
    );
    gh.lazySingleton<_i588.CrmTaskRepository>(
      () => _i150.SharedPreferencesCrmTaskRepository(gh<_i519.CrmTaskMapper>()),
    );
    gh.lazySingleton<_i748.CustomerSegmentRepository>(
      () => _i1052.CustomerSegmentRepositoryImpl(
        dataSource: gh<_i659.CustomerSegmentDataSource>(),
        mapper: gh<_i712.CustomerSegmentMapper>(),
      ),
    );
    gh.factory<_i546.ListTopOpportunityOutcomeReasonsUseCase>(
      () => _i546.ListTopOpportunityOutcomeReasonsUseCase(
        gh<_i527.OpportunityOutcomeReasonRepository>(),
        gh<_i43.OpportunityRepository>(),
      ),
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
    gh.lazySingleton<_i932.AnalyticsService>(
      () => _i569.FirebaseAnalyticsService(gh<_i398.FirebaseAnalytics>()),
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
    gh.lazySingleton<_i217.AuthRepository>(
      () => _i961.AuthRepositoryImpl(
        dataSource: gh<_i845.AuthDataSource>(),
        mapper: gh<_i26.AuthUserMapper>(),
      ),
    );
    gh.lazySingleton<_i361.CustomerLocalStoreRepository>(
      () => _i674.DriftCustomerLocalStoreRepository(
        gh<_i658.AppDatabase>(),
        gh<_i725.CustomerLocalMapper>(),
      ),
    );
    gh.factory<_i820.SendPasswordResetEmailUseCase>(
      () => _i820.SendPasswordResetEmailUseCase(gh<_i472.AuthRepository>()),
    );
    gh.factory<_i185.SignInWithEmailAndPasswordUseCase>(
      () => _i185.SignInWithEmailAndPasswordUseCase(gh<_i472.AuthRepository>()),
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
    gh.factory<_i776.LoginBloc>(
      () => _i776.LoginBloc(
        signInWithEmailAndPassword:
            gh<_i185.SignInWithEmailAndPasswordUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
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
    gh.lazySingleton<_i349.CrashReporter>(
      () => _i559.FirebaseCrashReporter(
        gh<_i141.FirebaseCrashlytics>(),
        gh<_i461.AppEnvironment>(),
        gh<_i465.AppClientMetadataProvider>(),
      ),
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
    gh.lazySingleton<_i361.MembershipDataSource>(
      () => _i201.FirestoreMembershipDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i814.InviteDataSource>(
      () => _i3.FirestoreInviteDataSource(
        gh<_i340.CloudFunctionsService>(),
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i176.UserRoleDataSource>(
      () => _i789.CloudFunctionsUserRoleDataSource(
        gh<_i340.CloudFunctionsService>(),
      ),
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
    gh.factory<_i1015.ForgotPasswordBloc>(
      () => _i1015.ForgotPasswordBloc(
        sendPasswordResetEmail: gh<_i820.SendPasswordResetEmailUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
      ),
    );
    gh.lazySingleton<_i904.StorageDataSource>(
      () => _i833.FirebaseStorageDataSource(gh<_i457.FirebaseStorage>()),
    );
    gh.lazySingleton<_i847.PortfolioAssignmentDataSource>(
      () => _i954.FirestorePortfolioAssignmentDataSource(
        gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.lazySingleton<_i268.OrganizationDataSource>(
      () => _i455.FirestoreOrganizationDataSource(
        gh<_i974.FirebaseFirestore>(),
        gh<_i340.CloudFunctionsService>(),
      ),
    );
    gh.lazySingleton<_i999.InviteAcceptanceRepository>(
      () => _i371.InviteAcceptanceRepositoryImpl(
        dataSource: gh<_i336.InviteAcceptanceDataSource>(),
        mapper: gh<_i87.InviteAcceptanceMapper>(),
      ),
    );
    gh.lazySingleton<_i923.RoleDataSource>(
      () => _i892.FirestoreRoleDataSource(gh<_i974.FirebaseFirestore>()),
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
    gh.factory<_i330.CreateCompanyUseCase>(
      () => _i330.CreateCompanyUseCase(gh<_i799.CompanyRepository>()),
    );
    gh.factory<_i628.ListCompaniesUseCase>(
      () => _i628.ListCompaniesUseCase(gh<_i799.CompanyRepository>()),
    );
    gh.factory<_i571.UpdateCompanyUseCase>(
      () => _i571.UpdateCompanyUseCase(gh<_i799.CompanyRepository>()),
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
    gh.lazySingleton<_i33.UserAccessRepository>(
      () => _i591.UserAccessRepositoryImpl(
        dataSource: gh<_i681.UserAccessDataSource>(),
        mapper: gh<_i566.UserAccessUpdateResultMapper>(),
      ),
    );
    gh.lazySingleton<_i668.UserProfileDataSource>(
      () =>
          _i1043.FirestoreUserProfileDataSource(gh<_i974.FirebaseFirestore>()),
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
    gh.factory<_i335.RemoveMemberFromTeamUseCase>(
      () => _i335.RemoveMemberFromTeamUseCase(
        gh<_i320.TeamRepository>(),
        gh<_i957.MembershipRepository>(),
      ),
    );
    gh.lazySingleton<_i756.OrganizationRepository>(
      () => _i522.OrganizationRepositoryImpl(
        dataSource: gh<_i268.OrganizationDataSource>(),
        mapper: gh<_i719.OrganizationMapper>(),
      ),
    );
    gh.lazySingleton<_i488.UserProfileRepository>(
      () => _i801.UserProfileRepositoryImpl(
        dataSource: gh<_i668.UserProfileDataSource>(),
        mapper: gh<_i756.UserProfileMapper>(),
      ),
    );
    gh.factory<_i825.GetCustomerFormConfigUseCase>(
      () => _i825.GetCustomerFormConfigUseCase(
        gh<_i756.OrganizationRepository>(),
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
    gh.factory<_i90.CreateAccountWithEmailAndPasswordUseCase>(
      () => _i90.CreateAccountWithEmailAndPasswordUseCase(
        gh<_i472.AuthRepository>(),
        gh<_i488.UserProfileRepository>(),
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
    gh.factory<_i906.CreateBranchUseCase>(
      () => _i906.CreateBranchUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i500.ListBranchesByCompanyUseCase>(
      () => _i500.ListBranchesByCompanyUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i820.UpdateBranchUseCase>(
      () => _i820.UpdateBranchUseCase(gh<_i160.BranchRepository>()),
    );
    gh.factory<_i835.AddUserToTeamUseCase>(
      () => _i835.AddUserToTeamUseCase(gh<_i320.TeamRepository>()),
    );
    gh.factory<_i817.DeleteTeamUseCase>(
      () => _i817.DeleteTeamUseCase(gh<_i320.TeamRepository>()),
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
    gh.factory<_i516.TeamFormBloc>(
      () => _i516.TeamFormBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
        createTeam: gh<_i265.CreateTeamUseCase>(),
        updateTeam: gh<_i265.UpdateTeamUseCase>(),
        analyticsService: gh<_i202.AnalyticsService>(),
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
    gh.factory<_i576.ListCustomerPortfolioUseCase>(
      () => _i576.ListCustomerPortfolioUseCase(
        gh<_i857.CustomerRepository>(),
        gh<_i220.PortfolioVisibilityService>(),
        gh<_i220.PortfolioAssignmentRepository>(),
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
    gh.factory<_i433.AssignPortfolioBloc>(
      () => _i433.AssignPortfolioBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
        listCommercialTeams: gh<_i986.ListCommercialTeamsUseCase>(),
        listPortfolioAssignments: gh<_i321.ListPortfolioAssignmentsUseCase>(),
        assignPortfolio: gh<_i636.AssignPortfolioUseCase>(),
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
    return this;
  }
}

class _$AppInjectionModule extends _i212.AppInjectionModule {}
