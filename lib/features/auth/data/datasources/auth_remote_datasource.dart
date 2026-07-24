import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

/// Wraps real Firebase Authentication SDK calls for sign-in and sign-out.
class AuthRemoteDataSource {
  const AuthRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<({String accessToken, String refreshToken, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    // Sign in to Firebase Auth
    final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    
    final firebaseUser = credential.user!;
    final token = await firebaseUser.getIdToken() ?? '';
    
    final user = UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'Student',
      email: firebaseUser.email ?? email,
      avatarUrl: 'https://api.dicebear.com/7.x/adventurer/svg?seed=${firebaseUser.uid}',
      engineeringScore: 100, // Default base score
      activeCourseIds: const [],
      activeInternshipId: '',
    );

    return (
      accessToken: token,
      refreshToken: firebaseUser.refreshToken ?? '',
      user: user,
    );
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return await user.getIdToken(true) ?? '';
    }
    return '';
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  Future<List<Map<String, dynamic>>> listSessions() async {
    return [
      {
        'id': 'session_mock_1',
        'device_name': 'Android Emulator (Pixel 9)',
        'last_active_at': DateTime.now().toIso8601String(),
        'is_current': true,
      }
    ];
  }

  Future<void> revokeSession(String sessionId) async {
    // Mock successful revocation
  }
}
