import 'package:freezed_annotation/freezed_annotation.dart';

part 'about_app_event.freezed.dart';

@freezed
sealed class AboutAppEvent with _$AboutAppEvent {
  const factory AboutAppEvent.started() = AboutAppStarted;

  const factory AboutAppEvent.searchQueryChanged(String query) =
      AboutAppSearchQueryChanged;

  const factory AboutAppEvent.nextPageRequested() = AboutAppNextPageRequested;

  const factory AboutAppEvent.diagnosticsSubmitted() =
      AboutAppDiagnosticsSubmitted;
}
