import 'package:injectable/injectable.dart';

import '../../domain/entities/user_profile.dart';
import '../dtos/user_profile_dto.dart';

@lazySingleton
final class UserProfileMapper {
  const UserProfileMapper();

  UserProfile toEntity(UserProfileDto dto) {
    return UserProfile(
      uid: dto.uid,
      name: dto.name,
      email: dto.email,
      createdAt: dto.createdAt,
      termsVersion: dto.termsVersion,
      termsAcceptedAt: dto.termsAcceptedAt,
    );
  }

  UserProfileDto toDto(UserProfile entity) {
    return UserProfileDto(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      createdAt: entity.createdAt,
      termsVersion: entity.termsVersion,
      termsAcceptedAt: entity.termsAcceptedAt,
    );
  }
}
