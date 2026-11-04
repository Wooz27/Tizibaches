import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/models/session.dart';

class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'baches.session';
  static const _guestKey = 'baches.guest';
  static const _reportStatusKey = 'baches.report_status';

  final FlutterSecureStorage _storage;
  String? _memorySession;
  bool _memoryGuest = false;

  Future<Session?> read() async {
    var raw = _memorySession;
    if (raw == null) {
      try {
        raw = await _storage.read(key: _sessionKey);
      } on Exception {
        raw = null;
      }
    }
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return Session.fromJson(decoded.cast<String, dynamic>());
    } on FormatException {
      return null;
    }
  }

  Future<void> write(Session session) async {
    final raw = jsonEncode(session.toJson());
    _memorySession = raw;
    try {
      await _storage.write(key: _sessionKey, value: raw);
    } on Exception {
      // El preview web puede no tener almacenamiento seguro; la sesión sigue en memoria.
    }
  }

  Future<void> clear() async {
    _memorySession = null;
    try {
      await _storage.delete(key: _sessionKey);
      await _storage.delete(key: _reportStatusKey);
    } on Exception {
      // Sin almacenamiento disponible, la sesión en memoria ya quedó limpia.
    }
  }

  Future<Map<String, String>> readReportStatuses() async {
    try {
      final raw = await _storage.read(key: _reportStatusKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } on Exception {
      return {};
    }
  }

  Future<void> writeReportStatuses(Map<String, String> statuses) async {
    try {
      await _storage.write(
        key: _reportStatusKey,
        value: jsonEncode(statuses),
      );
    } on Exception {
      // El aviso se pierde, pero la app sigue funcionando.
    }
  }

  Future<void> clearReportStatuses() async {
    try {
      await _storage.delete(key: _reportStatusKey);
    } on Exception {
      // Sin almacenamiento disponible no hay nada que limpiar.
    }
  }

  Future<bool> readGuest() async {
    if (_memoryGuest) return true;
    try {
      return await _storage.read(key: _guestKey) == 'true';
    } on Exception {
      return false;
    }
  }

  Future<void> writeGuest(bool value) async {
    _memoryGuest = value;
    try {
      await _storage.write(key: _guestKey, value: value.toString());
    } on Exception {
      // El modo invitado también puede vivir solo en memoria.
    }
  }
}
