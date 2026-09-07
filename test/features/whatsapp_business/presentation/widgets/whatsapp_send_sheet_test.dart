import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/analytics/analytics.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/errors/errors.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/whatsapp_business/whatsapp_business.dart';

final class _Analytics implements AnalyticsService {
  final events = <String>[];
  @override
  Future<void> logEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async => events.add(name);
  @override
  Future<void> setUserId(String? userId) async {}
  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {}
}

final class _Repository implements WhatsAppRepository {
  _Repository({required this.context, this.sendFailure});
  WhatsAppContext context;
  final Failure? sendFailure;
  WhatsAppOptInStatus? changedStatus;
  List<String>? sentVariables;

  @override
  Future<AppResult<WhatsAppContext>> loadContext({
    required String organizationId,
    required String customerId,
  }) async => AppSuccess(context);

  @override
  Future<AppResult<void>> updateOptIn({
    required String organizationId,
    required String customerId,
    required WhatsAppOptInStatus status,
    required String channel,
  }) async {
    changedStatus = status;
    context = WhatsAppContext(
      optIn: WhatsAppOptIn(
        customerId: customerId,
        status: status,
        channel: channel,
        requestedAt: DateTime.utc(2026),
      ),
      templates: context.templates,
      messages: context.messages,
    );
    return const AppSuccess(null);
  }

  @override
  Future<AppResult<WhatsAppSendResult>> send({
    required String organizationId,
    required String customerId,
    required String templateId,
    required List<String> variables,
    String? catalogShareId,
    String? notificationId,
  }) async {
    sentVariables = variables;
    if (sendFailure case final failure?) return AppFailure(failure);
    return const AppSuccess(
      WhatsAppSendResult(
        messageId: 'message-1',
        status: WhatsAppDeliveryStatus.sent,
      ),
    );
  }
}

WhatsAppSendCubit _cubit(_Repository repository, _Analytics analytics) =>
    WhatsAppSendCubit(
      loadContext: LoadWhatsAppContextUseCase(repository),
      updateOptIn: UpdateWhatsAppOptInUseCase(repository),
      sendMessage: SendWhatsAppMessageUseCase(repository),
      analytics: analytics,
    );

Future<void> _open(
  WidgetTester tester,
  _Repository repository,
  _Analytics analytics,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => WhatsAppSendSheet.show(
              context: context,
              createCubit: () => _cubit(repository, analytics),
              organizationId: 'org-1',
              customerId: 'customer-1',
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

void main() {
  const template = WhatsAppTemplate(
    id: 'template-1',
    name: 'catalogo',
    language: 'pt_BR',
    variables: ['Nome', 'Link'],
  );

  testWidgets('requires and records opt-in before exposing message composer', (
    tester,
  ) async {
    final repository = _Repository(
      context: const WhatsAppContext(templates: [template], messages: []),
    );
    final analytics = _Analytics();
    await _open(tester, repository, analytics);
    expect(find.text('Consentimento obrigatorio'), findsOneWidget);
    expect(find.text('Enviar por WhatsApp'), findsOneWidget);
    await tester.tap(find.text('Solicitar consentimento'));
    await tester.pumpAndSettle();
    expect(repository.changedStatus, WhatsAppOptInStatus.requested);
    expect(find.text('Consentimento solicitado'), findsOneWidget);
    expect(analytics.events, contains(AnalyticsEvents.whatsAppOptInRequested));
  });

  testWidgets(
    'selects approved template, fills variables and reports success',
    (tester) async {
      final repository = _Repository(
        context: WhatsAppContext(
          optIn: WhatsAppOptIn(
            customerId: 'customer-1',
            status: WhatsAppOptInStatus.accepted,
            channel: 'form',
            requestedAt: DateTime.utc(2026),
          ),
          templates: const [template],
          messages: const [],
        ),
      );
      final analytics = _Analytics();
      await _open(tester, repository, analytics);
      await tester.enterText(
        find.byKey(const ValueKey('whatsapp_variable_0')),
        'Ana',
      );
      await tester.enterText(
        find.byKey(const ValueKey('whatsapp_variable_1')),
        'https://catalogo',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(AppButton, 'Enviar por WhatsApp'));
      await tester.pumpAndSettle();
      expect(repository.sentVariables, ['Ana', 'https://catalogo']);
      expect(find.text('Mensagem enviada ao WhatsApp.'), findsOneWidget);
      expect(analytics.events, contains(AnalyticsEvents.whatsAppMessageSent));
    },
  );

  testWidgets('shows comprehensible send failure and permits manual retry', (
    tester,
  ) async {
    final repository = _Repository(
      context: WhatsAppContext(
        optIn: WhatsAppOptIn(
          customerId: 'customer-1',
          status: WhatsAppOptInStatus.accepted,
          channel: 'form',
          requestedAt: DateTime.utc(2026),
        ),
        templates: const [template],
        messages: const [],
      ),
      sendFailure: const UnexpectedFailure('Limite de envios atingido.'),
    );
    await _open(tester, repository, _Analytics());
    await tester.enterText(
      find.byKey(const ValueKey('whatsapp_variable_0')),
      'Ana',
    );
    await tester.enterText(
      find.byKey(const ValueKey('whatsapp_variable_1')),
      'Link',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(AppButton, 'Enviar por WhatsApp'));
    await tester.pumpAndSettle();
    expect(find.text('Limite de envios atingido.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets(
    'renders real delivery states in customer communication history',
    (tester) async {
      final repository = _Repository(
        context: WhatsAppContext(
          optIn: WhatsAppOptIn(
            customerId: 'customer-1',
            status: WhatsAppOptInStatus.accepted,
            channel: 'form',
            requestedAt: DateTime.utc(2026),
          ),
          templates: const [template],
          messages: [
            WhatsAppMessage(
              id: '1',
              templateName: 'Pedido aprovado',
              status: WhatsAppDeliveryStatus.read,
              createdAt: DateTime.utc(2026),
            ),
            WhatsAppMessage(
              id: '2',
              templateName: 'Pedido enviado',
              status: WhatsAppDeliveryStatus.failed,
              createdAt: DateTime.utc(2026),
              failureReason: 'Numero invalido',
            ),
          ],
        ),
      );
      await _open(tester, repository, _Analytics());
      expect(find.text('Historico de comunicacao'), findsOneWidget);
      expect(find.text('Lido'), findsOneWidget);
      expect(find.text('Numero invalido'), findsOneWidget);
    },
  );
}
