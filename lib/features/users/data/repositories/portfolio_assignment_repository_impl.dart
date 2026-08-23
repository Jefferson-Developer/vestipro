import 'package:injectable/injectable.dart';

import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/portfolio_assignment.dart';
import '../../domain/repositories/portfolio_assignment_repository.dart';
import '../datasources/portfolio_assignment_data_source.dart';
import '../mappers/portfolio_assignment_mapper.dart';

@LazySingleton(as: PortfolioAssignmentRepository)
final class PortfolioAssignmentRepositoryImpl
    implements PortfolioAssignmentRepository {
  const PortfolioAssignmentRepositoryImpl({
    required this.dataSource,
    required this.mapper,
  });

  final PortfolioAssignmentDataSource dataSource;
  final PortfolioAssignmentMapper mapper;

  @override
  Future<AppResult<PortfolioAssignment>> create(
    PortfolioAssignment assignment,
  ) async {
    try {
      final dto = await dataSource.create(mapper.toDto(assignment));
      return AppSuccess<PortfolioAssignment>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<PortfolioAssignment>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<PortfolioAssignment>(
        UnexpectedFailure(
          'Unexpected error creating portfolio assignment.',
          code: 'portfolio_assignment_create_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByOrganization({
    required String organizationId,
    required String companyId,
  }) async {
    try {
      final dtos = await dataSource.listActiveByOrganization(
        organizationId: organizationId,
        companyId: companyId,
      );
      return AppSuccess<List<PortfolioAssignment>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<PortfolioAssignment>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<PortfolioAssignment>>(
        UnexpectedFailure(
          'Unexpected error listing portfolio assignments.',
          code: 'portfolio_assignment_list_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<List<PortfolioAssignment>>> listActiveByUser({
    required String organizationId,
    required String companyId,
    required String userId,
  }) async {
    try {
      final dtos = await dataSource.listActiveByUser(
        organizationId: organizationId,
        companyId: companyId,
        userId: userId,
      );
      return AppSuccess<List<PortfolioAssignment>>(
        dtos.map(mapper.toEntity).toList(growable: false),
      );
    } on AppException catch (exception) {
      return AppFailure<List<PortfolioAssignment>>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<List<PortfolioAssignment>>(
        UnexpectedFailure(
          'Unexpected error listing user portfolio assignments.',
          code: 'portfolio_assignment_list_user_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PortfolioAssignment?>> findActiveCustomerAssignment({
    required String organizationId,
    required String companyId,
    required String customerId,
  }) async {
    try {
      final dto = await dataSource.findActiveCustomerAssignment(
        organizationId: organizationId,
        companyId: companyId,
        customerId: customerId,
      );
      return AppSuccess<PortfolioAssignment?>(
        dto == null ? null : mapper.toEntity(dto),
      );
    } on AppException catch (exception) {
      return AppFailure<PortfolioAssignment?>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<PortfolioAssignment?>(
        UnexpectedFailure(
          'Unexpected error loading active customer assignment.',
          code: 'portfolio_assignment_find_customer_unexpected',
          cause: exception,
        ),
      );
    }
  }

  @override
  Future<AppResult<PortfolioAssignment>> endAssignment({
    required String organizationId,
    required String id,
    required PortfolioAssignmentStatus status,
    required DateTime endedAt,
    required String endedBy,
  }) async {
    try {
      final dto = await dataSource.endAssignment(
        organizationId: organizationId,
        id: id,
        status: status.code,
        endedAt: endedAt,
        endedBy: endedBy,
      );
      return AppSuccess<PortfolioAssignment>(mapper.toEntity(dto));
    } on AppException catch (exception) {
      return AppFailure<PortfolioAssignment>(
        mapAppExceptionToFailure(exception),
      );
    } catch (exception) {
      return AppFailure<PortfolioAssignment>(
        UnexpectedFailure(
          'Unexpected error ending portfolio assignment.',
          code: 'portfolio_assignment_end_unexpected',
          cause: exception,
        ),
      );
    }
  }
}
