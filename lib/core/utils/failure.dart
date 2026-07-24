/// Base class for all domain-layer failures.
///
/// Use cases return `Either<Failure, T>`-style results (implemented here as
/// a lightweight Result type instead of pulling in dartz, to keep the
/// dependency count down for a 2-person team). Every repository method
/// should catch data-layer exceptions (DioException, HiveError, etc.) and
/// translate them into one of these before they cross into the domain
/// layer — presentation code should never see a raw DioException.
sealed class Failure {
  const Failure(this.message);
  final String message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data could not be read.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid credentials.']);
}

class BiometricFailure extends Failure {
  const BiometricFailure([super.message = 'Biometric authentication failed.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class Result<T> {
  const Result.success(this.value) : failure = null;
  const Result.failure(this.failure) : value = null;

  final T? value;
  final Failure? failure;

  bool get isSuccess => failure == null;
  bool get isFailure => failure != null;

  R fold<R>(R Function(Failure) onFailure, R Function(T) onSuccess) {
    if (isFailure) return onFailure(failure as Failure);
    return onSuccess(value as T);
  }
}
