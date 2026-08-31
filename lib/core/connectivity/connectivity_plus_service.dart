import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

import 'connectivity_service.dart';

/// [ConnectivityService] backed by `package:connectivity_plus` (TASK-109).
///
/// A device is considered connected when at least one of the results
/// `connectivity_plus` reports (it can report more than one active
/// interface, e.g. Wi-Fi *and* mobile data) is not [ConnectivityResult.none].
@LazySingleton(as: ConnectivityService)
final class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection);

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}
