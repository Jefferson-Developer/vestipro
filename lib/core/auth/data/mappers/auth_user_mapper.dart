import 'package:injectable/injectable.dart';

import '../../domain/entities/session_user.dart';
import '../dtos/auth_user_dto.dart';

@lazySingleton
final class AuthUserMapper {
  const AuthUserMapper();

  SessionUser toEntity(AuthUserDto dto) {
    return SessionUser(
      uid: dto.uid,
      email: dto.email,
      displayName: dto.displayName,
      emailVerified: dto.emailVerified,
    );
  }
}
