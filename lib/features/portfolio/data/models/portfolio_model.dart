import '../../domain/entities/portfolio_entity.dart';

class PortfolioModel extends PortfolioEntity {
  const PortfolioModel({
    required super.certificates,
    required super.projects,
    required super.skills,
    required super.internshipHistory,
  });

  factory PortfolioModel.fromJson(Map<String, dynamic> json) => PortfolioModel(
        certificates: (json['certificates'] as List? ?? [])
            .map((e) => CertificateEntity(
                  id: e['id'] as String,
                  title: e['title'] as String,
                  issuedAt: DateTime.parse(e['issued_at'] as String),
                  credentialUrl: e['credential_url'] as String?,
                ))
            .toList(),
        projects: (json['projects'] as List? ?? [])
            .map((e) => PortfolioProjectEntity(
                  id: e['id'] as String,
                  title: e['title'] as String,
                  description: e['description'] as String? ?? '',
                  githubUrl: e['github_url'] as String?,
                  skills: List<String>.from(e['skills'] as List? ?? []),
                ))
            .toList(),
        skills: (json['skills'] as List? ?? [])
            .map((e) => SkillEntity(
                  name: e['name'] as String,
                  level: (e['level'] as num?)?.toInt() ?? 1,
                ))
            .toList(),
        internshipHistory: List<String>.from(json['internship_history'] as List? ?? []),
      );
}
