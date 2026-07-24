import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/offline_indicator.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../providers/course_providers.dart';
import '../widgets/course_card.dart';

class CourseListScreen extends ConsumerWidget {
  const CourseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(coursesListProvider);

    return ResponsiveCenter(
      child: CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text('Courses', style: Theme.of(context).textTheme.headlineSmall),
                ),
                const OfflineIndicator(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.md),
          sliver: coursesAsync.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, st) => SliverToBoxAdapter(
              child: GlassContainer(child: Text('Could not load courses: $err')),
            ),
            data: (courses) => SliverList.separated(
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) => CourseCard(
                course: courses[i],
                onTap: () => context.push('/courses/${courses[i].id}'),
              ),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
      ),
    );
  }
}
