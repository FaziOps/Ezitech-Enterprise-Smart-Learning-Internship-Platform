import '../../../../core/utils/failure.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class BiometricLoginUseCase {
  const BiometricLoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthSession>> call() async {
    final available = await _repository.isBiometricAvailable();
    if (!available) {
      return const Result.failure(
        BiometricFailure('Biometric login is not available on this device.'),
      );
    }
    return _repository.unlockWithBiometrics();
  }
}
