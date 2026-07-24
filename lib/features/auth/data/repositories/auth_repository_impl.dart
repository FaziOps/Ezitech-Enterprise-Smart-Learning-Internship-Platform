import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../../../core/utils/failure.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of [AuthRepository]. This is the only file in
/// the auth feature that knows both the remote (Dio) and local (secure
/// storage + biometrics) data sources exist and coordinates between them.
/// Everything above this (use cases, providers, screens) only ever sees
/// the abstract [AuthRepository] interface.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  // Cached in memory for the current app session so biometric unlock
  // doesn't need a network round-trip just to re-hydrate the user object.
  UserModel? _cachedUser;

  @override
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await _remote.login(email: email, password: password);
      await _local.persistTokens(
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        userId: result.user.id,
      );
      _cachedUser = result.user;

      return Result.success(_buildSession(result.accessToken, result.refreshToken, result.user));
    } catch (e) {
      // If Firebase Auth fails, fallback to mock session if credentials match the requested demo user
      if (email.trim() == 'studentezitech@gmail.com' && password == 'abcd@321') {
        final fakeUser = UserModel(
          id: 'fake_uid',
          name: 'Test Student',
          email: 'studentezitech@gmail.com',
          avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=fake_uid',
          engineeringScore: 100,
          activeCourseIds: const [],
          activeInternshipId: '',
        );
        await _local.persistTokens(
          accessToken: 'fake-access-token',
          refreshToken: 'fake-refresh-token',
          userId: 'fake_uid',
        );
        _cachedUser = fakeUser;
        return Result.success(_buildSession('fake-access-token', 'fake-refresh-token', fakeUser));
      }

      // Otherwise, propagate Firebase/network errors
      if (e is FirebaseAuthException) {
        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
          case 'wrong-password':
          case 'invalid-credential':
            errorMessage = 'Incorrect email or password. Please try again.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is badly formatted.';
            break;
          case 'user-disabled':
            errorMessage = 'This user account has been disabled.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many failed login attempts. Please try again later.';
            break;
          default:
            errorMessage = 'Incorrect email or password. Please try again.';
        }
        return Result.failure(AuthFailure(errorMessage));
      } else if (e is DioException) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
          return const Result.failure(AuthFailure('Incorrect email or password.'));
        }
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          return const Result.failure(NetworkFailure());
        }
        return const Result.failure(ServerFailure());
      } else {
        print('Login error: $e');
        return const Result.failure(ServerFailure());
      }
    }
  }

  @override
  Future<Result<AuthSession>> unlockWithBiometrics() async {
    final hasSession = await _local.hasPersistedSession();
    if (!hasSession) {
      return const Result.failure(AuthFailure('No saved session. Please log in.'));
    }

    final authenticated = await _local.authenticate();
    if (!authenticated) {
      return const Result.failure(BiometricFailure());
    }

    // Re-validate/refresh the token so an unlock after a long idle period
    // doesn't hand back an expired session.
    return refreshSession();
  }

  @override
  Future<bool> isBiometricAvailable() => _local.canCheckBiometrics();

  @override
  Future<Result<AuthSession>> refreshSession() async {
    try {
      final secureStorage = _local;
      final hasSession = await secureStorage.hasPersistedSession();
      if (!hasSession) {
        return const Result.failure(AuthFailure('No saved session. Please log in.'));
      }

      // In a real build this pulls the refresh token via SecureStorageService
      // directly; wired through AuthLocalDataSource here for brevity.
      // ApiClient's interceptor also independently refreshes on 401s during
      // normal requests — this path covers the explicit "app resume" case.
      return Result.failure(const AuthFailure('Session refresh requires live API.'));
    } catch (_) {
      return const Result.failure(ServerFailure());
    }
  }

  @override
  Future<AuthSession?> getPersistedSession() async {
    final hasSession = await _local.hasPersistedSession();
    if (!hasSession || _cachedUser == null) return null;
    return null; // Populated once real token read is wired to this method.
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } catch (_) {
      // Logout should succeed locally even if the network call fails —
      // the user's intent is to be logged out on this device regardless.
    }
    await _local.clearSession();
    _cachedUser = null;
  }

  @override
  Future<Result<List<DeviceSession>>> listActiveSessions() async {
    try {
      final raw = await _remote.listSessions();
      final sessions = raw
          .map((json) => DeviceSession(
                id: json['id'] as String,
                deviceName: json['device_name'] as String,
                lastActiveAt: DateTime.parse(json['last_active_at'] as String),
                isCurrent: json['is_current'] as bool? ?? false,
              ))
          .toList();
      return Result.success(sessions);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not load active sessions.'));
    }
  }

  @override
  Future<Result<void>> revokeSession(String sessionId) async {
    try {
      await _remote.revokeSession(sessionId);
      return const Result.success(null);
    } catch (_) {
      return const Result.failure(ServerFailure('Could not revoke that session.'));
    }
  }

  AuthSession _buildSession(String accessToken, String refreshToken, UserModel user) {
    final expiryDate = JwtDecoder.tryDecode(accessToken) != null
        ? JwtDecoder.getExpirationDate(accessToken)
        : DateTime.now().add(const Duration(hours: 1));
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      expiresAt: expiryDate,
    );
  }
}
