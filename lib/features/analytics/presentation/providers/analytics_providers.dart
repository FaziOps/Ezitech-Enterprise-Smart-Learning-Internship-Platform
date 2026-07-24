import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/analytics_repository.dart';
import '../../domain/entities/analytics_entity.dart';

final analyticsRepositoryProvider = Provider((_) => AnalyticsRepository());

final learningAnalyticsProvider = FutureProvider<LearningAnalyticsEntity>((ref) async {
  return ref.watch(analyticsRepositoryProvider).getAnalytics();
});
