import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../domain/models/failures.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = (baseUrl ?? AppConfig.normalizedApiBaseUrl).replaceFirst(
        RegExp(r'/$'),
        '',
      );

  final http.Client _client;
  final String _baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$_baseUrl$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Map<String, String> _headers(String? token) => {
    'Accept': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> getJson(
    String path, {
    String? token,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _client.get(_uri(path, query), headers: _headers(token)),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    final response = await _send(
      () => _client.post(
        _uri(path),
        headers: {..._headers(token), 'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required Map<String, String> fields,
    required Uint8List photoBytes,
    required String photoName,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll(_headers(token))
      ..fields.addAll(fields)
      ..files.add(
        http.MultipartFile.fromBytes('photo', photoBytes, filename: photoName),
      );

    final response = await _send(
      () async => http.Response.fromStream(await _client.send(request)),
    );
    return _decode(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() action) async {
    try {
      return await action().timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw const AppFailure(
        'El servidor tardó demasiado en responder. Intentá de nuevo.',
      );
    } on AppFailure {
      rethrow;
    } on http.ClientException {
      throw const AppFailure(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    } on Exception {
      throw const AppFailure(
        'No se pudo conectar con el servidor. Revisa tu conexión.',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.trim();
    dynamic decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        decoded = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return decoded.cast<String, dynamic>();
      return const {};
    }

    throw _failureFrom(response.statusCode, decoded);
  }

  AppFailure _failureFrom(int status, dynamic decoded) {
    if (decoded is Map) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return AppFailure(detail.trim(), statusCode: status);
      }

      for (final value in decoded.values) {
        if (value is List && value.isNotEmpty) {
          return AppFailure(value.first.toString(), statusCode: status);
        }
        if (value is String && value.trim().isNotEmpty) {
          return AppFailure(value.trim(), statusCode: status);
        }
      }
    }

    return switch (status) {
      400 => const AppFailure(
        'Revisa los datos del reporte e intenta de nuevo.',
        statusCode: 400,
      ),
      401 => const AppFailure(
        'Tu sesión venció. Vuelve a entrar.',
        statusCode: 401,
      ),
      403 => const AppFailure(
        'No tienes permiso para hacer esta acción.',
        statusCode: 403,
      ),
      404 => const AppFailure(
        'No encontramos lo que buscabas.',
        statusCode: 404,
      ),
      409 => const AppFailure(
        'Esa cuenta ya está vinculada con otro acceso.',
        statusCode: 409,
      ),
      429 => const AppFailure(
        'Demasiados intentos. Esperá un momento.',
        statusCode: 429,
      ),
      >= 500 => AppFailure(
        'El servidor falló. Intentá de nuevo en unos minutos.',
        statusCode: status,
      ),
      _ => AppFailure('La solicitud falló ($status).', statusCode: status),
    };
  }
}
