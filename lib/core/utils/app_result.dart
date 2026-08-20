import '../errors/failure.dart';

sealed class AppResult<T> {
  const AppResult();

  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(Failure failure) onFailure,
  }) {
    return switch (this) {
      AppSuccess<T>(value: final value) => onSuccess(value),
      AppFailure<T>(failure: final failure) => onFailure(failure),
    };
  }
}

final class AppSuccess<T> extends AppResult<T> {
  const AppSuccess(this.value);

  final T value;
}

final class AppFailure<T> extends AppResult<T> {
  const AppFailure(this.failure);

  final Failure failure;
}
