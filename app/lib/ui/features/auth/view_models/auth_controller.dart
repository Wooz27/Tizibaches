import 'package:flutter/foundation.dart';

import '../../../../core/config/app_config.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/session.dart';

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository repository})
    : _repository = repository;

  final AuthRepository _repository;

  Session? _session;
  bool _booting = true;
  bool _guest = false;
  bool _busy = false;
  String? _error;

  Session? get session => _session;
  bool get isSignedIn => _session != null;
  bool get isGuest => _guest;
  bool get booting => _booting;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> bootstrap() async {
    try {
      _session = await _repository.restore();
      if (_session == null) {
        _guest = AppConfig.startAsGuest || await _repository.readGuest();
      }
    } finally {
      _booting = false;
      notifyListeners();
    }
  }

  Future<bool> signIn() async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _repository.signInWithGoogle();
      _guest = false;
      await _repository.writeGuest(false);
      return true;
    } on AppFailure catch (failure) {
      if (!failure.canceled) _error = failure.message;
      return false;
    } on Exception {
      _error = 'No se pudo iniciar sesión. Intentá de nuevo.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> continueAsGuest() async {
    _guest = true;
    _error = null;
    await _repository.writeGuest(true);
    notifyListeners();
  }

  Future<void> leaveGuest() async {
    _guest = false;
    await _repository.writeGuest(false);
    notifyListeners();
  }

  Future<void> signOut() async {
    _busy = true;
    notifyListeners();
    await _repository.signOut();
    _session = null;
    _guest = false;
    _busy = false;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
