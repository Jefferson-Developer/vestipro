import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_about_app_use_case.dart';
import 'about_app_state.dart';

final class AboutAppCubit extends Cubit<AboutAppState> {
  AboutAppCubit(this._getAboutApp) : super(const AboutAppInitial());

  final GetAboutAppUseCase _getAboutApp;

  Future<void> load() async {
    emit(const AboutAppLoading());

    final result = await _getAboutApp();

    if (isClosed) {
      return;
    }

    emit(
      result.fold(onSuccess: AboutAppLoaded.new, onFailure: AboutAppError.new),
    );
  }
}
