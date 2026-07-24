import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/failure.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/biometric_login_usecase.dart';
import '../../domain/usecases/login_usecase.dart';

// --- Core singletons -------------------------------------------------
final secureStorageProvider = Provider((ref) => SecureStorageService());
final apiClientProvider = Provider((ref) => ApiClient(ref.watch(secureStorageProvider)));

// --- Auth data layer ---------------------------------------------------
final authRemoteDataSourceProvider =
    Provider((ref) => AuthRemoteDataSource(ref.watch(apiClientProvider)));
final authLocalDataSourceProvider =
    Provider((ref) => AuthLocalDataSource(ref.watch(secureStorageProvider)));

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepositoryImpl(
      ref.watch(authRemoteDataSourceProvider),
      ref.watch(authLocalDataSourceProvider),
    ));

// --- Use cases ---------------------------------------------------------
final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));
final biometricLoginUseCaseProvider =
    Provider((ref) => BiometricLoginUseCase(ref.watch(authRepositoryProvider)));

// --- Auth state notifier -------------------------------------------------
enum AuthStatus { unknown, authenticating, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user = UserEntity.empty,
    this.errorMessage,
  });

  final AuthStatus status;
  final UserEntity user;
  final String? errorMessage;

  AuthState copyWith({AuthStatus? status, UserEntity? user, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  static const initial = AuthState(status: AuthStatus.unknown);
}

/// The single source of truth for "is a user logged in" — GoRouter's
/// redirect logic (core/router/app_router.dart) listens to this via
/// ref.watch so navigation reacts automatically to login/logout.
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._loginUseCase, this._biometricUseCase) : super(AuthState.initial);

  final LoginUseCase _loginUseCase;
  final BiometricLoginUseCase _biometricUseCase;

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating);
    final result = await _loginUseCase(email: email, password: password);
    result.fold(
      (failure) => state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ),
      (session) => state = AuthState(status: AuthStatus.authenticated, user: session.user),
    );
  }

  Future<void> unlockWithBiometrics() async {
    state = state.copyWith(status: AuthStatus.authenticating);
    final result = await _biometricUseCase();
    result.fold(
      (failure) => state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: failure.message,
      ),
      (session) => state = AuthState(status: AuthStatus.authenticated, user: session.user),
    );
  }

  void logout() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.watch(loginUseCaseProvider),
    ref.watch(biometricLoginUseCaseProvider),
  );
});
