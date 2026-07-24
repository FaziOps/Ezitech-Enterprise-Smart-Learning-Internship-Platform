import '../../../../core/utils/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

/// A use case is a single business action, independently testable with a
/// fake [AuthRepository] and no widget/network setup. Validation rules
/// that belong to "what counts as a valid login attempt" live here, not
/// in the widget's onPressed handler.
class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return const Result.failure(ValidationFailure('Enter a valid email address.'));
    }
    if (password.length < 6) {
      return const Result.failure(
        ValidationFailure('Password must be at least 6 characters.'),
      );
    }

    return _repository.login(email: trimmedEmail, password: password);
  }
}
