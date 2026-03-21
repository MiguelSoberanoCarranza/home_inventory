/// Result type for handling success/error states in a type-safe way.
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result.success(this.data)
      : error = null,
        isSuccess = true;

  const Result.failure(this.error)
      : data = null,
        isSuccess = false;

  bool get isError => !isSuccess;

  /// Returns data if success, or throws if error.
  T get dataOrThrow {
    if (isError) throw Exception(error);
    return data as T;
  }

  /// Returns data if success, or defaultValue if error.
  T getOrElse(T defaultValue) {
    return isSuccess ? data as T : defaultValue;
  }

  /// Maps the success value to a new type.
  Result<R> map<R>(R Function(T) fn) {
    if (isSuccess) {
      return Result.success(fn(data as T));
    }
    return Result.failure(error);
  }

  /// Executes onSuccess for success, onError for failure.
  R when<R>({
    required R Function(T) onSuccess,
    required R Function(String) onError,
  }) {
    if (isSuccess) {
      return onSuccess(data as T);
    }
    return onError(error!);
  }
}