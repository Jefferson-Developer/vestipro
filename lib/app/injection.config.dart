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
import '../features/organizations/domain/usecases/update_branch_use_case.dart'
    as _i820;
import '../features/organizations/domain/usecases/update_company_use_case.dart'
    as _i571;
import '../features/organizations/domain/usecases/update_organization_settings_use_case.dart'
    as _i270;
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
import '../features/users/data/datasources/cloud_functions_user_role_data_source.dart'
    as _i789;
import '../features/users/data/datasources/user_role_data_source.dart' as _i176;
import '../features/users/data/mappers/user_role_update_result_mapper.dart'
    as _i958;
import '../features/users/data/repositories/user_role_repository_impl.dart'
    as _i53;
import '../features/users/domain/repositories/user_role_repository.dart'
    as _i262;
import '../features/users/domain/usecases/list_organization_users_use_case.dart'
    as _i93;
import '../features/users/domain/usecases/update_user_role_use_case.dart'
    as _i428;
import '../features/users/presentation/bloc/user_list_bloc.dart' as _i244;
import '../features/users/presentation/bloc/user_role_edit_bloc.dart' as _i698;
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
    gh.lazySingleton<_i26.AuthUserMapper>(() => const _i26.AuthUserMapper());
    gh.lazySingleton<_i246.AuditLogEntryMapper>(
      () => const _i246.AuditLogEntryMapper(),
    );
    gh.lazySingleton<_i756.UserProfileMapper>(
      () => const _i756.UserProfileMapper(),
    );
    gh.lazySingleton<_i649.InviteMapper>(() => const _i649.InviteMapper());
    gh.lazySingleton<_i477.OnboardingProgressMapper>(
      () => const _i477.OnboardingProgressMapper(),
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
    gh.lazySingleton<_i847.AboutAppMapper>(() => const _i847.AboutAppMapper());
    gh.lazySingleton<_i370.AboutAppNotesMapper>(
      () => const _i370.AboutAppNotesMapper(),
    );
    gh.lazySingleton<_i958.UserRoleUpdateResultMapper>(
      () => const _i958.UserRoleUpdateResultMapper(),
    );
    gh.lazySingleton<_i465.AppClientMetadataProvider>(
      () => _i465.PackageInfoClientMetadataProvider(),
    );
    gh.lazySingleton<_i99.SecureSessionStore>(
      () => _i772.SecureFlutterSessionStore(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i87.InviteAcceptanceMapper>(
      () => _i87.InviteAcceptanceMapper(gh<_i649.InviteMapper>()),
    );
    gh.lazySingleton<_i924.OnboardingProgressDataSource>(
      () => const _i1035.SharedPreferencesOnboardingProgressDataSource(),
    );
    gh.lazySingleton<_i886.OnboardingProgressRepository>(
      () => _i803.OnboardingProgressRepositoryImpl(
        dataSource: gh<_i924.OnboardingProgressDataSource>(),
        mapper: gh<_i477.OnboardingProgressMapper>(),
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
    gh.lazySingleton<_i845.AuthDataSource>(
      () => _i814.FirebaseAuthDataSource(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i217.AuthRepository>(
      () => _i961.AuthRepositoryImpl(
        dataSource: gh<_i845.AuthDataSource>(),
        mapper: gh<_i26.AuthUserMapper>(),
      ),
    );
    gh.factory<_i820.SendPasswordResetEmailUseCase>(
      () => _i820.SendPasswordResetEmailUseCase(gh<_i472.AuthRepository>()),
    );
    gh.factory<_i185.SignInWithEmailAndPasswordUseCase>(
      () => _i185.SignInWithEmailAndPasswordUseCase(gh<_i472.AuthRepository>()),
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
    gh.lazySingleton<_i364.AboutAppDataSource>(
      () => _i639.InMemoryAboutAppDataSource.injectable(
        seed: gh<_i477.AboutAppSeedModel>(),
      ),
      registerFor: {_dev, _staging, _prod},
    );
    gh.lazySingleton<_i972.FeatureFlagService>(
      () => _i845.FirebaseFeatureFlagService(gh<_i627.FirebaseRemoteConfig>()),
    );
    gh.lazySingleton<_i1008.PerformanceMonitor>(
      () => _i387.FirebasePerformanceMonitor(gh<_i346.FirebasePerformance>()),
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
    gh.lazySingleton<_i794.AboutAppRepository>(
      () => _i1060.AboutAppRepositoryImpl(
        dataSource: gh<_i364.AboutAppDataSource>(),
        mapper: gh<_i847.AboutAppMapper>(),
        notesMapper: gh<_i370.AboutAppNotesMapper>(),
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
    gh.factory<_i421.RecordAuditLogUseCase>(
      () => _i421.RecordAuditLogUseCase(gh<_i753.AuditLogRepository>()),
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
    gh.factory<_i766.CreateTeamUseCase>(
      () => _i766.CreateTeamUseCase(gh<_i320.TeamRepository>()),
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
    gh.factory<_i93.ListOrganizationUsersUseCase>(
      () => _i93.ListOrganizationUsersUseCase(
        gh<_i957.MembershipRepository>(),
        gh<_i320.TeamRepository>(),
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
    gh.factory<_i244.UserListBloc>(
      () => _i244.UserListBloc(
        listOrganizationUsers: gh<_i93.ListOrganizationUsersUseCase>(),
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
    gh.factory<_i0.InviteListBloc>(
      () => _i0.InviteListBloc(
        listPendingInvites: gh<_i509.ListPendingInvitesUseCase>(),
        resendInvite: gh<_i502.ResendInviteUseCase>(),
        revokeInvite: gh<_i334.RevokeInviteUseCase>(),
      ),
    );
    gh.factory<_i675.CompleteOnboardingUseCase>(
      () =>
          _i675.CompleteOnboardingUseCase(gh<_i55.CreateOrganizationUseCase>()),
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
