import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/errors.dart';
import '../../../core/utils/utils.dart';
import '../domain/entities/personal_data_export.dart';
import '../domain/repositories/personal_data_export_repository.dart';
import '../domain/usecases/personal_data_export_use_cases.dart';

enum PersonalDataExportViewStatus { loading, ready, failure }

final class PersonalDataExportState {
  const PersonalDataExportState({
    this.status = PersonalDataExportViewStatus.loading,
    this.exports = const <PersonalDataExport>[],
    this.requesting = false,
    this.download,
    this.failure,
  });

  final PersonalDataExportViewStatus status;
  final List<PersonalDataExport> exports;
  final bool requesting;
  final PersonalDataExportDownload? download;
  final Failure? failure;

  PersonalDataExportState copyWith({
    PersonalDataExportViewStatus? status,
    List<PersonalDataExport>? exports,
    bool? requesting,
    PersonalDataExportDownload? download,
    Failure? failure,
  }) => PersonalDataExportState(
    status: status ?? this.status,
    exports: exports ?? this.exports,
    requesting: requesting ?? this.requesting,
    download: download,
    failure: failure,
  );
}

final class PersonalDataExportCubit extends Cubit<PersonalDataExportState> {
  PersonalDataExportCubit({
    required this.repository,
    required this.requestExport,
    required this.getDownload,
    required this.organizationId,
    required this.userId,
  }) : super(const PersonalDataExportState());

  final PersonalDataExportRepository repository;
  final RequestPersonalDataExport requestExport;
  final GetPersonalDataExportDownload getDownload;
  final String organizationId;
  final String userId;
  StreamSubscription<AppResult<List<PersonalDataExport>>>? _subscription;

  Future<void> load() async {
    await _subscription?.cancel();
    _subscription = repository
        .watchExports(organizationId: organizationId, userId: userId)
        .listen(_onExports, onError: _onStreamError);
  }

  Future<void> request() async {
    if (state.requesting) return;
    emit(state.copyWith(requesting: true));
    final result = await requestExport(organizationId: organizationId);
    switch (result) {
      case AppSuccess<String>():
        emit(state.copyWith(requesting: false));
      case AppFailure<String>(:final failure):
        emit(state.copyWith(requesting: false, failure: failure));
    }
  }

  Future<void> download(String exportId) async {
    final result = await getDownload(exportId: exportId);
    switch (result) {
      case AppSuccess<PersonalDataExportDownload>(:final value):
        emit(state.copyWith(download: value));
      case AppFailure<PersonalDataExportDownload>(:final failure):
        emit(state.copyWith(failure: failure));
    }
  }

  void _onExports(AppResult<List<PersonalDataExport>> result) {
    switch (result) {
      case AppSuccess<List<PersonalDataExport>>(:final value):
        emit(
          state.copyWith(
            status: PersonalDataExportViewStatus.ready,
            exports: value,
          ),
        );
      case AppFailure<List<PersonalDataExport>>(:final failure):
        emit(
          state.copyWith(
            status: PersonalDataExportViewStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void _onStreamError(Object error, StackTrace stackTrace) => emit(
    state.copyWith(
      status: PersonalDataExportViewStatus.failure,
      failure: UnexpectedFailure(
        'Não foi possível acompanhar suas exportações.',
        code: 'personal_data_export_stream_unexpected',
        cause: error,
      ),
    ),
  );

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
