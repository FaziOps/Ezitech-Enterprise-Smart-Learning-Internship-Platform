import 'package:local_auth/local_auth.dart';
import '../../../../core/storage/secure_storage_service.dart';

/// Handles the two local-only auth concerns: biometric prompts and
/// reading/writing the persisted session to secure storage. Kept separate
/// from [AuthRemoteDataSource] because these operations never touch the
/// network — useful when the offline-first repository decides which
/// source to hit first.
class AuthLocalDataSource {
  AuthLocalDataSource(this._secureStorage) : _localAuth = LocalAuthentication();

  final SecureStorageService _secureStorage;
  final LocalAuthentication _localAuth;

  Future<bool> canCheckBiometrics() async {
    final supported = await _localAuth.isDeviceSupported();
    final canCheck = await _localAuth.canCheckBiometrics;
    return supported && canCheck;
  }

  Future<bool> authenticate() async {
    return _localAuth.authenticate(
      localizedReason: 'Unlock Ezitech with biometrics',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
  }

  Future<void> persistTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    await _secureStorage.writeAccessToken(accessToken);
    await _secureStorage.writeRefreshToken(refreshToken);
    await _secureStorage.writeUserId(userId);
  }

  Future<bool> hasPersistedSession() async {
    final token = await _secureStorage.readRefreshToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() => _secureStorage.clearAll();
}
