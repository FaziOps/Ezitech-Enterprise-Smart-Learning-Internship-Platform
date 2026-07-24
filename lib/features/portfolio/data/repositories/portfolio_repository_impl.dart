import '../../../../core/utils/failure.dart';
import '../../domain/entities/portfolio_entity.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../datasources/portfolio_remote_datasource.dart';

class PortfolioRepositoryImpl implements PortfolioRepository {
  PortfolioRepositoryImpl(this._remote);

  final PortfolioRemoteDataSource _remote;

  @override
  Future<Result<PortfolioEntity>> getPortfolio() async {
    try {
      return Result.success(await _remote.getPortfolio());
    } catch (_) {
      // No live LMS/Portfolio endpoint yet (README API table #11) —
      // reflects this build's own Week 1–3 progress so the screen is
      // demoable with content that's actually true rather than generic
      // filler.
      return Result.success(_seedPortfolio());
    }
  }

  PortfolioEntity _seedPortfolio() {
    return PortfolioEntity(
      certificates: [
        CertificateEntity(
          id: 'cert1',
          title: 'Flutter Enterprise Architecture — Ezitech',
          issuedAt: DateTime.now().subtract(const Duration(days: 14)),
          credentialUrl: null,
        ),
      ],
      projects: const [
        PortfolioProjectEntity(
          id: 'proj1',
          title: 'FLUTR-002: Enterprise Smart Learning Platform',
          description:
              'Clean Architecture Flutter app with offline-first sync, glass '
              'morphism design system, and JWT + biometric auth.',
          githubUrl: null,
          skills: ['Flutter', 'Riverpod', 'Clean Architecture', 'Offline-First'],
        ),
      ],
      skills: const [
        SkillEntity(name: 'Flutter', level: 4),
        SkillEntity(name: 'Clean Architecture', level: 4),
        SkillEntity(name: 'State Management (Riverpod)', level: 4),
        SkillEntity(name: 'Offline-First Design', level: 3),
      ],
      internshipHistory: const [
        'Week 1 — Foundation & Architecture (complete)',
        'Week 2 — Core Learning & Internship MVP (complete)',
        'Week 3 — Real-Time, Offline & Extended Features (in progress)',
      ],
    );
  }
}
