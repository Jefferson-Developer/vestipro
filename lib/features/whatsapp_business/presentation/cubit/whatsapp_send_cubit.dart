import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/analytics/analytics.dart';
import '../../../../core/errors/errors.dart';
import '../../../../core/utils/utils.dart';
import '../../domain/entities/whatsapp_models.dart';
import '../../domain/usecases/whatsapp_use_cases.dart';

enum WhatsAppSendStatus {
  initial,
  loading,
  ready,
  requestingOptIn,
  sending,
  sent,
  failure,
}

final class WhatsAppSendState {
  const WhatsAppSendState({
    this.status = WhatsAppSendStatus.initial,
    this.context,
    this.selectedTemplate,
    this.variables = const <String>[],
    this.failure,
  });

  final WhatsAppSendStatus status;
  final WhatsAppContext? context;
  final WhatsAppTemplate? selectedTemplate;
  final List<String> variables;
  final Failure? failure;

  bool get canSend =>
      context?.optIn?.isActive == true &&
      selectedTemplate != null &&
      variables.length == selectedTemplate!.variables.length &&
      variables.every((value) => value.trim().isNotEmpty) &&
      status != WhatsAppSendStatus.sending;

  WhatsAppSendState copyWith({
    WhatsAppSendStatus? status,
    WhatsAppContext? context,
    WhatsAppTemplate? selectedTemplate,
    List<String>? variables,
    Failure? failure,
  }) => WhatsAppSendState(
    status: status ?? this.status,
    context: context ?? this.context,
    selectedTemplate: selectedTemplate ?? this.selectedTemplate,
    variables: variables ?? this.variables,
    failure: failure,
  );
}

@injectable
final class WhatsAppSendCubit extends Cubit<WhatsAppSendState> {
  WhatsAppSendCubit({
    required this.loadContext,
    required this.updateOptIn,
    required this.sendMessage,
    required this.analytics,
  }) : super(const WhatsAppSendState());

  final LoadWhatsAppContextUseCase loadContext;
  final UpdateWhatsAppOptInUseCase updateOptIn;
  final SendWhatsAppMessageUseCase sendMessage;
  final AnalyticsService analytics;
  String? _organizationId;
  String? _customerId;
  String? _catalogShareId;
  String? _notificationId;

  Future<void> load({
    required String organizationId,
    required String customerId,
    String? catalogShareId,
    String? notificationId,
  }) async {
    _organizationId = organizationId;
    _customerId = customerId;
    _catalogShareId = catalogShareId;
    _notificationId = notificationId;
    emit(const WhatsAppSendState(status: WhatsAppSendStatus.loading));
    final result = await loadContext(
      organizationId: organizationId,
      customerId: customerId,
    );
    switch (result) {
      case AppSuccess<WhatsAppContext>(value: final value):
        final template = value.templates.firstOrNull;
        emit(
          WhatsAppSendState(
            status: WhatsAppSendStatus.ready,
            context: value,
            selectedTemplate: template,
            variables: List<String>.filled(template?.variables.length ?? 0, ''),
          ),
        );
      case AppFailure<WhatsAppContext>(failure: final failure):
        emit(
          WhatsAppSendState(
            status: WhatsAppSendStatus.failure,
            failure: failure,
          ),
        );
    }
  }

  void selectTemplate(WhatsAppTemplate template) {
    emit(
      state.copyWith(
        status: WhatsAppSendStatus.ready,
        selectedTemplate: template,
        variables: List<String>.filled(template.variables.length, ''),
      ),
    );
  }

  void updateVariable(int index, String value) {
    if (index < 0 || index >= state.variables.length) return;
    final values = [...state.variables]..[index] = value;
    emit(state.copyWith(status: WhatsAppSendStatus.ready, variables: values));
  }

  Future<void> requestOptIn() async {
    final organizationId = _organizationId;
    final customerId = _customerId;
    if (organizationId == null || customerId == null) return;
    emit(state.copyWith(status: WhatsAppSendStatus.requestingOptIn));
    final result = await updateOptIn(
      organizationId: organizationId,
      customerId: customerId,
      status: WhatsAppOptInStatus.requested,
      channel: 'seller_app',
    );
    switch (result) {
      case AppSuccess<void>():
        await analytics.logEvent(AnalyticsEvents.whatsAppOptInRequested);
        await load(
          organizationId: organizationId,
          customerId: customerId,
          catalogShareId: _catalogShareId,
          notificationId: _notificationId,
        );
      case AppFailure<void>(failure: final failure):
        emit(
          state.copyWith(status: WhatsAppSendStatus.failure, failure: failure),
        );
    }
  }

  Future<void> send() async {
    final organizationId = _organizationId;
    final customerId = _customerId;
    final template = state.selectedTemplate;
    if (!state.canSend ||
        organizationId == null ||
        customerId == null ||
        template == null) {
      return;
    }
    emit(state.copyWith(status: WhatsAppSendStatus.sending));
    final result = await sendMessage(
      organizationId: organizationId,
      customerId: customerId,
      templateId: template.id,
      variables: state.variables,
      catalogShareId: _catalogShareId,
      notificationId: _notificationId,
    );
    switch (result) {
      case AppSuccess<WhatsAppSendResult>():
        await analytics.logEvent(
          AnalyticsEvents.whatsAppMessageSent,
          parameters: {
            'template_language': template.language,
            'has_catalog_share': _catalogShareId != null,
            'has_notification': _notificationId != null,
          },
        );
        emit(state.copyWith(status: WhatsAppSendStatus.sent));
      case AppFailure<WhatsAppSendResult>(failure: final failure):
        emit(
          state.copyWith(status: WhatsAppSendStatus.failure, failure: failure),
        );
    }
  }

  Future<void> retry() async {
    final organizationId = _organizationId;
    final customerId = _customerId;
    if (organizationId != null && customerId != null) {
      await load(
        organizationId: organizationId,
        customerId: customerId,
        catalogShareId: _catalogShareId,
        notificationId: _notificationId,
      );
    }
  }
}
