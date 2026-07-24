import 'package:flutter_test/flutter_test.dart';
import 'package:ezitech_learning_platform/core/utils/failure.dart';
import 'package:ezitech_learning_platform/features/auth/domain/entities/user_entity.dart';
import 'package:ezitech_learning_platform/features/auth/domain/repositories/auth_repository.dart';
import 'package:ezitech_learning_platform/features/auth/domain/usecases/login_usecase.dart';

/// A fake repository — no Dio, no Hive, no device. This is the payoff of
/// Clean Architecture: LoginUseCase's validation rules are tested here
/// without spinning up any framework or network dependency.
class _FakeAuthRepository implements AuthRepository {
  bool loginCalled = false;

  @override
  Future<Result<AuthSession>> login({required String email, required String password}) async {
    loginCalled = true;
    return Result.success(
      AuthSession(
        accessToken: 'fake-token',
        refreshToken: 'fake-refresh',
        user: const UserEntity(
          id: '1',
          name: 'Test Student',
          email: 'test@ezitech.com',
          avatarUrl: null,
          engineeringScore: 100,
          activeCourseIds: [],
          activeInternshipId: null,
        ),
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<bool> isBiometricAvailable() async => false;

  @override
  Future<Result<AuthSession>> unlockWithBiometrics() async =>
      const Result.failure(BiometricFailure());

  @override
  Future<Result<AuthSession>> refreshSession() async => const Result.failure(AuthFailure());

  @override
  Future<AuthSession?> getPersistedSession() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<Result<List<DeviceSession>>> listActiveSessions() async => const Result.success([]);

  @override
  Future<Result<void>> revokeSession(String sessionId) async => const Result.success(null);
}

void main() {
  group('LoginUseCase', () {
    late _FakeAuthRepository repository;
    late LoginUseCase useCase;

    setUp(() {
      repository = _FakeAuthRepository();
      useCase = LoginUseCase(repository);
    });

    test('rejects an invalid email without calling the repository', () async {
      final result = await useCase(email: 'not-an-email', password: 'password123');

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<ValidationFailure>());
      expect(repository.loginCalled, isFalse);
    });

    test('rejects a password shorter than 6 characters', () async {
      final result = await useCase(email: 'student@ezitech.com', password: '123');

      expect(result.isFailure, isTrue);
      expect(result.failure, isA<ValidationFailure>());
      expect(repository.loginCalled, isFalse);
    });

    test('delegates to repository and succeeds with valid input', () async {
      final result = await useCase(email: 'student@ezitech.com', password: 'password123');

      expect(result.isSuccess, isTrue);
      expect(repository.loginCalled, isTrue);
      expect(result.value?.user.name, 'Test Student');
    });
  });
}
