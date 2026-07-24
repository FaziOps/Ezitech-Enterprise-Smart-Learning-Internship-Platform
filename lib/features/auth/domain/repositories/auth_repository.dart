import '../../../../core/utils/failure.dart';
import '../entities/user_entity.dart';

/// Domain-layer contract. The presentation layer (providers/screens) and
/// use cases depend on this interface only — never on the concrete
/// [AuthRepositoryImpl] in the data layer. This is what lets either
/// engineer swap the data source (real API vs mock vs test fake) without
/// touching UI or business logic code.
abstract class AuthRepository {
  /// Authenticates against the Ezitech Auth API and persists the session.
  Future<Result<AuthSession>> login({
    required String email,
    required String password,
  });

  /// Attempts biometric unlock using a previously persisted session.
  /// Returns [AuthFailure] if no session exists to unlock.
  Future<Result<AuthSession>> unlockWithBiometrics();

  /// Whether the device supports and has enrolled biometrics.
  Future<bool> isBiometricAvailable();

  /// Refreshes the access token using the stored refresh token.
  Future<Result<AuthSession>> refreshSession();

  /// Returns the last persisted session without hitting the network,
  /// or null if the user has never logged in / has logged out.
  Future<AuthSession?> getPersistedSession();

  /// Clears all tokens and cached user state.
  Future<void> logout();

  /// Lists active sessions/devices for the multi-session UI (Full-Scope
  /// backlog item — interface defined now so the data layer can be built
  /// against it later without changing this contract).
  Future<Result<List<DeviceSession>>> listActiveSessions();

  Future<Result<void>> revokeSession(String sessionId);
}

class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.lastActiveAt,
    required this.isCurrent,
  });

  final String id;
  final String deviceName;
  final DateTime lastActiveAt;
  final bool isCurrent;
}
