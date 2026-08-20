import '../../../../core/errors/errors.dart';
import '../dtos/about_app_dto.dart';
import '../models/about_app_seed_model.dart';
import 'about_app_data_source.dart';

final class InMemoryAboutAppDataSource implements AboutAppDataSource {
  const InMemoryAboutAppDataSource({
    required this.seed,
    this.exception,
    this.delay = Duration.zero,
  });

  final AboutAppSeedModel seed;
  final AppException? exception;
  final Duration delay;

  @override
  Future<AboutAppDto> getAboutApp() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    final error = exception;
    if (error != null) {
      throw error;
    }

    return seed.toDto();
  }
}
