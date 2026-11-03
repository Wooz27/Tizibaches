import '../../domain/models/app_user.dart';
import '../../domain/models/failures.dart';
import '../../domain/models/session.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/session_store.dart';

class AuthRepository {
  AuthRepository({
    required ApiService api,
    required SessionStore store,
    required GoogleAuthService google,
  }) : _api = api,
       _store = store,
       _google = google;

  final ApiService _api;
  final SessionStore _store;
  final GoogleAuthService _google;

  Session? _session;
  Session? get session => _session;
  bool get isAuthenticated => _session != null;

  Future<Session?> restore() async {
    final stored = await _store.read();
    if (stored == null) return null;
    _session = stored;

    try {
      final json = await _api.getJson('/api/me/', token: stored.access);
      final refreshed = stored.copyWith(user: AppUser.fromJson(json));
      _session = refreshed;
      await _store.write(refreshed);
      return refreshed;
    } on AppFailure catch (error) {
      if (!error.isUnauthorized) return stored;
      try {
        return await refresh();
      } on AppFailure {
        await _store.clear();
        _session = null;
        return null;
      }
    }
  }

  Future<Session> signInWithGoogle() async {
    final idToken = await _google.signIn();
    final json = await _api.postJson(
      '/api/auth/google/',
      body: {'id_token': idToken},
    );
    final session = Session.fromJson(json);
    _session = session;
    await _store.write(session);
    return session;
  }

  Future<Session> refresh() async {
    final current = _session;
    if (current == null) throw const AuthRequiredFailure();

    try {
      final json = await _api.postJson(
        '/api/auth/refresh/',
        body: {'refresh': current.refresh},
      );
      final updated = current.copyWith(access: json['access'] as String?);
      _session = updated;
      await _store.write(updated);
      return updated;
    } on AppFailure {
      _session = null;
      await _store.clear();
      rethrow;
    }
  }

  Future<T> withAccessToken<T>(Future<T> Function(String access) action) async {
    final current = _session;
    if (current == null) throw const AuthRequiredFailure();

    try {
      return await action(current.access);
    } on AppFailure catch (error) {
      if (!error.isUnauthorized) rethrow;
      final refreshed = await refresh();
      return action(refreshed.access);
    }
  }

  Future<void> signOut() async {
    final refresh = _session?.refresh;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _api.postJson('/api/auth/logout/', body: {'refresh': refresh});
      } on AppFailure {
        // Si no hay red, igual cerramos la sesión local.
      }
    }
    await _google.signOut();
    _session = null;
    await _store.clear();
  }

  Future<bool> readGuest() => _store.readGuest();

  Future<void> writeGuest(bool value) => _store.writeGuest(value);
}
