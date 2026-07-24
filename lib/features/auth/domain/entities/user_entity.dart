import 'package:equatable/equatable.dart';

/// Domain-layer representation of the authenticated student.
///
/// Deliberately has no JSON/serialization logic — that belongs to
/// [UserModel] in the data layer. Keeping this clean means domain-layer
/// use cases and presentation-layer widgets never import Dio, Hive, or
/// any data-layer concern, which is the whole point of Clean Architecture:
/// business rules don't know or care how data arrives.
class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.engineeringScore,
    required this.activeCourseIds,
    required this.activeInternshipId,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final int engineeringScore;
  final List<String> activeCourseIds;
  final String? activeInternshipId;

  static const empty = UserEntity(
    id: '',
    name: '',
    email: '',
    avatarUrl: null,
    engineeringScore: 0,
    activeCourseIds: [],
    activeInternshipId: null,
  );

  bool get isEmpty => this == UserEntity.empty;
  bool get isNotEmpty => this != UserEntity.empty;

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        avatarUrl,
        engineeringScore,
        activeCourseIds,
        activeInternshipId,
      ];
}

/// Result of a successful authentication — tokens are kept in the domain
/// layer as opaque strings; only the data layer (SecureStorage) knows how
/// they're persisted.
class AuthSession extends Equatable {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final UserEntity user;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [accessToken, refreshToken, user, expiresAt];
}
