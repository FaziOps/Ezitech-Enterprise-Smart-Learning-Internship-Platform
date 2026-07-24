import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../features/auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/portfolio_remote_datasource.dart';
import '../../data/repositories/portfolio_repository_impl.dart';
import '../../domain/entities/portfolio_entity.dart';
import '../../domain/repositories/portfolio_repository.dart';

final portfolioRemoteDataSourceProvider =
    Provider((ref) => PortfolioRemoteDataSource(ref.watch(apiClientProvider)));

final portfolioRepositoryProvider = Provider<PortfolioRepository>(
  (ref) => PortfolioRepositoryImpl(ref.watch(portfolioRemoteDataSourceProvider)),
);

final portfolioProvider = FutureProvider<PortfolioEntity>((ref) async {
  final result = await ref.watch(portfolioRepositoryProvider).getPortfolio();
  return result.fold((f) => throw f.message, (v) => v);
});
