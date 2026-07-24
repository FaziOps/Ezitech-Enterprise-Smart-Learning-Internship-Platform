import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so tokens are Keychain-backed on iOS and
/// Keystore-backed on Android (per the Implementation Plan's security
/// section) — never written to Hive or SharedPreferences, which are not
/// encrypted at rest.
class SecureStorageService {
  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  final FlutterSecureStorage _storage;

  static const _kAccessToken = 'ezitech_access_token';
  static const _kRefreshToken = 'ezitech_refresh_token';
  static const _kUserId = 'ezitech_user_id';
  static const _kBiometricEnabled = 'ezitech_biometric_enabled';

  Future<void> writeAccessToken(String token) => _storage.write(key: _kAccessToken, value: token);
  Future<String?> readAccessToken() => _storage.read(key: _kAccessToken);

  Future<void> writeRefreshToken(String token) => _storage.write(key: _kRefreshToken, value: token);
  Future<String?> readRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> writeUserId(String id) => _storage.write(key: _kUserId, value: id);
  Future<String?> readUserId() => _storage.read(key: _kUserId);

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _kBiometricEnabled, value: enabled.toString());
  Future<bool> isBiometricEnabled() async =>
      (await _storage.read(key: _kBiometricEnabled)) == 'true';

  Future<void> clearAll() => _storage.deleteAll();
}
