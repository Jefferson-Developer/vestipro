import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vestipro/core/connectivity/connectivity.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('ConnectivityPlusService', () {
    late _MockConnectivity connectivity;
    late ConnectivityPlusService service;

    setUp(() {
      connectivity = _MockConnectivity();
      service = ConnectivityPlusService(connectivity);
    });

    test('isConnected is true when at least one interface is active', () async {
      when(() => connectivity.checkConnectivity()).thenAnswer(
        (_) async => [ConnectivityResult.none, ConnectivityResult.wifi],
      );

      expect(await service.isConnected, isTrue);
    });

    test('isConnected is false when every interface reports none', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await service.isConnected, isFalse);
    });

    test(
      'onConnectivityChanged maps the plugin stream to a bool stream',
      () async {
        when(() => connectivity.onConnectivityChanged).thenAnswer(
          (_) => Stream<List<ConnectivityResult>>.fromIterable(
            <List<ConnectivityResult>>[
              [ConnectivityResult.wifi],
              [ConnectivityResult.none],
              [ConnectivityResult.mobile],
            ],
          ),
        );

        final emissions = await service.onConnectivityChanged.toList();

        expect(emissions, <bool>[true, false, true]);
      },
    );
  });
}
