import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/core/design_system/design_system.dart';
import 'package:vestipro/core/utils/utils.dart';
import 'package:vestipro/features/after_sales/after_sales.dart';

class _FakePostSaleEventRepository implements PostSaleEventRepository {
  _FakePostSaleEventRepository(this._events);

  final List<PostSaleEvent> _events;

  @override
  Future<AppResult<PostSaleEventSubmissionResult>> registerPostSaleEvent({
    required String organizationId,
    required String companyId,
    required String orderId,
    required String eventId,
    required PostSaleEventType type,
    String? description,
  }) => throw UnimplementedError();

  @override
  Stream<AppResult<List<PostSaleEvent>>> watchByOrder({
    required String organizationId,
    required String orderId,
  }) async* {
    yield AppSuccess<List<PostSaleEvent>>(_events);
  }
}

PostSaleEvent _buildEvent({
  String id = 'event-1',
  PostSaleEventType type = PostSaleEventType.delivered,
  String? description,
}) {
  return PostSaleEvent(
    id: id,
    organizationId: 'org-1',
    companyId: 'company-1',
    orderId: 'order-1',
    orderNumber: '000001',
    customerId: 'customer-1',
    sellerId: 'rep-1',
    type: type,
    description: description,
    source: PostSaleEventSource.manual,
    createdBy: 'rep-1',
    createdByName: 'Rep One',
    createdAt: DateTime.utc(2026, 6, 1, 10),
    notifiedSeller: true,
  );
}

Widget _buildApp(List<PostSaleEvent> events) {
  final repository = _FakePostSaleEventRepository(events);
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('pt'),
    home: Scaffold(
      body: PostSaleTimelineSection(
        organizationId: 'org-1',
        orderId: 'order-1',
        createCubit: () => PostSaleTimelineCubit(
          WatchPostSaleTimelineForOrderUseCase(repository),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders the empty state when no event is registered yet', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(const <PostSaleEvent>[]));
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhum evento de pós-venda registrado para este pedido.'),
      findsOneWidget,
    );
  });

  testWidgets('renders every event of a full timeline', (tester) async {
    await tester.pumpWidget(
      _buildApp(<PostSaleEvent>[
        _buildEvent(id: 'event-1', type: PostSaleEventType.dispatched),
        _buildEvent(id: 'event-2', type: PostSaleEventType.delivered),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Despachado'), findsOneWidget);
    expect(find.text('Entregue'), findsOneWidget);
  });

  testWidgets('highlights a "problema reportado" event', (tester) async {
    await tester.pumpWidget(
      _buildApp(<PostSaleEvent>[
        _buildEvent(
          id: 'event-1',
          type: PostSaleEventType.problemReported,
          description: 'Cliente reportou avaria na peça.',
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Problema reportado'), findsOneWidget);
    expect(find.text('Cliente reportou avaria na peça.'), findsOneWidget);

    final entry = tester.widget<AppTimeline>(find.byType(AppTimeline));
    expect(entry.entries.single.isHighlighted, isTrue);
  });
}
