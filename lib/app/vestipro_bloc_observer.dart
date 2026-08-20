import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

final class VestiProBlocObserver extends BlocObserver {
  const VestiProBlocObserver();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    _debugLog(
      bloc: bloc,
      action: 'transition',
      fields: <String, Object?>{
        'event': transition.event.runtimeType,
        'from': transition.currentState.runtimeType,
        'to': transition.nextState.runtimeType,
      },
    );
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    _debugLog(
      bloc: bloc,
      action: 'change',
      fields: <String, Object?>{
        'from': change.currentState.runtimeType,
        'to': change.nextState.runtimeType,
      },
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);
    _debugLog(
      bloc: bloc,
      action: 'error',
      fields: <String, Object?>{'errorType': error.runtimeType},
    );
  }

  void _debugLog({
    required BlocBase<dynamic> bloc,
    required String action,
    required Map<String, Object?> fields,
  }) {
    if (!kDebugMode) {
      return;
    }

    developer.log(
      <String, Object?>{
        'bloc': bloc.runtimeType,
        'action': action,
        ...fields,
      }.toString(),
      name: 'vestipro.bloc',
    );
  }
}
