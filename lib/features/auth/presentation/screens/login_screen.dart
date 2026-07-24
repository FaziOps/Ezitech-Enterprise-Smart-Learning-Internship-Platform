import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/ambient_background.dart';
import '../../../../core/widgets/glass_container.dart';
import '../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    ref.listen(authControllerProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      body: AmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLogo(context),
                    const SizedBox(height: AppSpacing.xxl),
                    GlassContainer(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back', style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Sign in to continue your learning journey',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              hintText: 'you@ezitech.com',
                              prefixIcon: Icon(Icons.mail_outline),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Log In'),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                                child: Text('or', style: TextStyle(color: AppColors.textMuted)),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => ref
                                      .read(authControllerProvider.notifier)
                                      .unlockWithBiometrics(),
                              icon: const Icon(Icons.fingerprint),
                              label: const Text('Unlock with Biometrics'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.glassBorder),
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return Column(
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: BorderRadius.circular(AppRadius.md),
          width: 72,
          height: 72,
          child: const Icon(Icons.school_outlined, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Ezitech', style: Theme.of(context).textTheme.headlineMedium),
        Text(
          'Learning & Internship Platform',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  void _submit() {
    ref.read(authControllerProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );
  }
}
