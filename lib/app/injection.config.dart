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
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../core/analytics/analytics_service.dart' as _i932;
import '../core/analytics/firebase_analytics_service.dart' as _i569;
import '../core/auth/data/datasources/auth_data_source.dart' as _i845;
import '../core/auth/data/datasources/firebase_auth_data_source.dart' as _i814;
import '../core/auth/data/mappers/auth_user_mapper.dart' as _i26;
import '../core/auth/data/repositories/auth_repository_impl.dart' as _i961;
import '../core/auth/domain/repositories/auth_repository.dart' as _i217;
import '../core/environment/app_environment.dart' as _i461;
import '../core/feature_flags/feature_flag_service.dart' as _i972;
import '../core/feature_flags/firebase_feature_flag_service.dart' as _i845;
import '../core/functions/app_client_metadata.dart' as _i465;
import '../core/functions/cloud_functions_service.dart' as _i147;
import '../core/performance/firebase_performance_monitor.dart' as _i387;
import '../core/performance/performance_monitor.dart' as _i1008;
import '../core/permissions/permission_service.dart' as _i315;
import '../core/services/crash_reporter.dart' as _i349;
import '../core/services/firebase_crash_reporter.dart' as _i559;
import '../core/storage/firebase_storage_data_source.dart' as _i833;
import '../core/storage/storage_data_source.dart' as _i904;
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
    gh.lazySingleton<_i26.AuthUserMapper>(() => const _i26.AuthUserMapper());
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
    gh.lazySingleton<_i465.AppClientMetadataProvider>(
      () => _i465.PackageInfoClientMetadataProvider(),
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
    gh.lazySingleton<_i957.MembershipRepository>(
      () => _i537.MembershipRepositoryImpl(
        dataSource: gh<_i361.MembershipDataSource>(),
        mapper: gh<_i714.MembershipMapper>(),
      ),
    );
    gh.lazySingleton<_i904.StorageDataSource>(
      () => _i833.FirebaseStorageDataSource(gh<_i457.FirebaseStorage>()),
    );
    gh.lazySingleton<_i923.RoleDataSource>(
      () => _i892.FirestoreRoleDataSource(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i268.OrganizationDataSource>(
      () =>
          _i455.FirestoreOrganizationDataSource(gh<_i974.FirebaseFirestore>()),
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
    gh.lazySingleton<_i315.PermissionService>(
      () => _i315.PermissionService(gh<_i957.MembershipRepository>()),
    );
    gh.factory<_i1030.AssignRoleToUserUseCase>(
      () => _i1030.AssignRoleToUserUseCase(gh<_i957.MembershipRepository>()),
    );
    gh.factory<_i70.GetUserMembershipUseCase>(
      () => _i70.GetUserMembershipUseCase(gh<_i957.MembershipRepository>()),
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
    return this;
  }
}

class _$AppInjectionModule extends _i212.AppInjectionModule {}
