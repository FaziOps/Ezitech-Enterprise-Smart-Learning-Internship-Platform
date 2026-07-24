import 'package:equatable/equatable.dart';

class CertificateEntity extends Equatable {
  const CertificateEntity({
    required this.id,
    required this.title,
    required this.issuedAt,
    required this.credentialUrl,
  });

  final String id;
  final String title;
  final DateTime issuedAt;
  final String? credentialUrl;

  @override
  List<Object?> get props => [id, title, issuedAt, credentialUrl];
}

class PortfolioProjectEntity extends Equatable {
  const PortfolioProjectEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.githubUrl,
    required this.skills,
  });

  final String id;
  final String title;
  final String description;
  final String? githubUrl;
  final List<String> skills;

  @override
  List<Object?> get props => [id, title, description, githubUrl, skills];
}

class SkillEntity extends Equatable {
  const SkillEntity({required this.name, required this.level});

  final String name;
  final int level; // 1-5

  @override
  List<Object?> get props => [name, level];
}

class PortfolioEntity extends Equatable {
  const PortfolioEntity({
    required this.certificates,
    required this.projects,
    required this.skills,
    required this.internshipHistory,
  });

  final List<CertificateEntity> certificates;
  final List<PortfolioProjectEntity> projects;
  final List<SkillEntity> skills;
  final List<String> internshipHistory;

  @override
  List<Object?> get props => [certificates, projects, skills, internshipHistory];
}
