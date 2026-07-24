import '../../../../core/utils/failure.dart';
import '../entities/portfolio_entity.dart';

/// Read-only per the Implementation Plan's Week 3 scope — no
/// create/edit/delete here. Full portfolio editing isn't in the case
/// study brief at all; this just presents what the LMS/Internship
/// systems already know about the student.
abstract class PortfolioRepository {
  Future<Result<PortfolioEntity>> getPortfolio();
}
