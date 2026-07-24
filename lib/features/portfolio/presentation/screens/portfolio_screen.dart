import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../core/widgets/responsive_center.dart';
import '../providers/portfolio_providers.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioAsync = ref.watch(portfolioProvider);

    return ResponsiveCenter(
      child: ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
      children: [
        Text('Engineering Portfolio', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Read-only preview — built from your course and internship progress.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: AppSpacing.md),
        portfolioAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => GlassContainer(child: Text('Could not load portfolio: $e')),
          data: (portfolio) => Column(
            children: [
              _SkillsCard(skills: portfolio.skills),
              const SizedBox(height: AppSpacing.md),
              _CertificatesCard(certificates: portfolio.certificates),
              const SizedBox(height: AppSpacing.md),
              _ProjectsCard(projects: portfolio.projects),
              const SizedBox(height: AppSpacing.md),
              _InternshipHistoryCard(history: portfolio.internshipHistory),
            ],
          ),
        ),
      ],
      ),
    );
  }
}

class _SkillsCard extends StatelessWidget {
  const _SkillsCard({required this.skills});
  final List skills;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in skills)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.glassFillStrong,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s.name, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < s.level ? Icons.circle : Icons.circle_outlined,
                            size: 6,
                            color: i < s.level ? AppColors.primary : AppColors.textDisabled,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CertificatesCard extends StatelessWidget {
  const _CertificatesCard({required this.certificates});
  final List certificates;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Certificates', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          if (certificates.isEmpty)
            const Text('No certificates yet.', style: TextStyle(color: AppColors.textMuted))
          else
            for (final c in certificates)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_outlined, size: 18, color: AppColors.aiAccent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(c.title, overflow: TextOverflow.ellipsis)),
                    Text(
                      '${c.issuedAt.day}/${c.issuedAt.month}/${c.issuedAt.year}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _ProjectsCard extends StatelessWidget {
  const _ProjectsCard({required this.projects});
  final List projects;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Projects', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          if (projects.isEmpty)
            const Text('No projects yet.', style: TextStyle(color: AppColors.textMuted))
          else
            for (final p in projects)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.title, style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 2),
                    Text(p.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        for (final s in p.skills)
                          Text('#$s', style: const TextStyle(fontSize: 11, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _InternshipHistoryCard extends StatelessWidget {
  const _InternshipHistoryCard({required this.history});
  final List<String> history;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Internship History', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final h in history)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('• $h', style: const TextStyle(color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}
