import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/branch.dart';
import '../../domain/repositories/branch_repository.dart';
import '../../domain/value_objects/branch_address.dart';
import '../../domain/value_objects/branch_status.dart';
import '../../domain/value_objects/branch_type.dart';
import '../datasources/branch_data_source.dart';
import '../mappers/branch_mapper.dart';

@LazySingleton(as: BranchRepository)
final class BranchRepositoryImpl implements BranchRepository {
  const BranchRepositoryImpl({required this.dataSource, required this.mapper});

  final BranchDataSource dataSource;
  final BranchMapper mapper;

  @override
  Future<AppResult<Branch>> create({
    required String id,
    required String organizationId,
    required String companyId,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required String createdBy,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final dto = mapper.toDto(
        Branch(
          id: id,
          organizationId: organizationId,
          companyId: companyId,
          name: name,
          type: type,
          address: address,
          status: BranchStatus.active,
          version: 1,
          createdAt: now,
          createdBy: createdBy,
          updatedAt: now,
          updatedBy: createdBy,
        ),
      );

      final createdDto = await dataSource.create(dto);
      return AppSuccess<Branch>(mapper.toEntity(createdDto));
    } on AppException catch (exception) {
      return AppFailure<Branch>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Branch>(
        UnexpectedFailure(
          'Unexpected error creating branch.',
          code: 'branch_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<Branch>>> listByCompany({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final dtos = await dataSource.listByCompany(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<Branch>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<Branch>>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<List<Branch>>(
        UnexpectedFailure(
          'Unexpected error listing branches.',
          code: 'branch_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Branch>> getById({
    required String organizationId,
    required String id,
  }) async {
    try {
      final dto = await dataSource.getById(
        organizationId: organizationId,
        id: id,
      );
      if (dto == null) {
        return AppFailure<Branch>(
          const NotFoundFailure('Branch not found.', code: 'branch_not_found'),
        );
      }
      return AppSuccess<Branch>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<Branch>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Branch>(
        UnexpectedFailure(
          'Unexpected error loading branch.',
          code: 'branch_get_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<Branch>> update({
    required String organizationId,
    required String id,
    required String name,
    required BranchType type,
    BranchAddress? address,
    required BranchStatus status,
    required String updatedBy,
  }) async {
    try {
      final updatedDto = await dataSource.update(
        organizationId: organizationId,
        id: id,
        name: name,
        type: mapper.typeToDto(type),
        address: address == null ? null : mapper.addressToDto(address),
        status: mapper.statusToDto(status),
        updatedAt: DateTime.now().toUtc(),
        updatedBy: updatedBy,
      );
      return AppSuccess<Branch>(mapper.toEntity(updatedDto));
    } on AppException catch (exception) {
      return AppFailure<Branch>(mapAppExceptionToFailure(exception));
    } catch (exception) {
      return AppFailure<Branch>(
        UnexpectedFailure(
          'Unexpected error updating branch.',
          code: 'branch_update_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
