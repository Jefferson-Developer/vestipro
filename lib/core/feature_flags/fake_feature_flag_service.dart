import 'feature_flag_registry.dart';
import 'feature_flag_service.dart';

/// In-memory [FeatureFlagService] for unit/BLoC/widget tests (TASK-018) —
/// same reasoning as `FakeAnalyticsService` (TASK-017): lets a use case,
/// BLoC or widget that reads a flag be tested without depending on the real
/// `firebase_remote_config` SDK or a platform channel mock.
///
/// Every key still must be registered in [FeatureFlagRegistry] — reading an
/// unregistered key throws [ArgumentError], same as the real
/// implementation, so tests catch a typo/removed flag the same way
/// production code would.
final class FakeFeatureFlagService implements FeatureFlagService {
  FakeFeatureFlagService({Map<String, Object>? overrides})
    : _overrides = Map<String, Object>.of(overrides ?? const {});

  final Map<String, Object> _overrides;

  /// Overrides [flagKey] for the rest of this fake's lifetime. [value] must
  /// match the type declared for [flagKey] in [FeatureFlagRegistry].
  void overrideFlag(String flagKey, Object value) {
    _overrides[flagKey] = value;
  }

  /// Clears every override, restoring every flag to its registry default.
  void reset() {
    _overrides.clear();
  }

  @override
  bool isEnabled(String flagKey) => _read<bool>(flagKey);

  @override
  String getString(String flagKey) => _read<String>(flagKey);

  @override
  int getInt(String flagKey) => _read<int>(flagKey);

  T _read<T>(String flagKey) {
    final definition = FeatureFlagRegistry.definitionOf(flagKey);
    return (_overrides[flagKey] ?? definition.defaultValue) as T;
  }
}
