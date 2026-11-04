class AppFailure implements Exception {
  const AppFailure(this.message, {this.statusCode, this.canceled = false});

  final String message;
  final int? statusCode;
  final bool canceled;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class AuthRequiredFailure extends AppFailure {
  const AuthRequiredFailure()
    : super('Necesitas una cuenta para hacer esta acción.', statusCode: 401);
}
