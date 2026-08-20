import 'package:bloc/bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vestipro/app/vestipro_bloc_observer.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_event.dart';
import 'package:vestipro/features/settings/presentation/bloc/about_app_state.dart';

void main() {
  test('VestiProBlocObserver handles transitions without throwing', () {
    const observer = VestiProBlocObserver();
    final transition = Transition<AboutAppEvent, AboutAppState>(
      currentState: const AboutAppState.initial(),
      event: const AboutAppEvent.started(),
      nextState: const AboutAppState.loading(),
    );

    expect(
      () => observer.onTransition(_ObserverTestBloc(), transition),
      returnsNormally,
    );
  });
}

final class _ObserverTestBloc extends Bloc<AboutAppEvent, AboutAppState> {
  _ObserverTestBloc() : super(const AboutAppState.initial());
}
