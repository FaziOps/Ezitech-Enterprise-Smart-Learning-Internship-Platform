import '../../domain/entities/user_entity.dart';

/// Data-layer model. Handles the wire format from the Ezitech Auth API
/// and converts to/from the pure [UserEntity] the rest of the app uses.
/// If the backend changes field names or nesting, only this file changes.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.avatarUrl,
    required super.engineeringScore,
    required super.activeCourseIds,
    required super.activeInternshipId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      engineeringScore: (json['engineering_score'] as num?)?.toInt() ?? 0,
      activeCourseIds: (json['active_course_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      activeInternshipId: json['active_internship_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatar_url': avatarUrl,
        'engineering_score': engineeringScore,
        'active_course_ids': activeCourseIds,
        'active_internship_id': activeInternshipId,
      };

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        name: entity.name,
        email: entity.email,
        avatarUrl: entity.avatarUrl,
        engineeringScore: entity.engineeringScore,
        activeCourseIds: entity.activeCourseIds,
        activeInternshipId: entity.activeInternshipId,
      );
}
