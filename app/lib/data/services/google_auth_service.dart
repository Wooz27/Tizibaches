import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_config.dart';
import '../../domain/models/failures.dart';

class GoogleAuthService {
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (!AppConfig.hasGoogleClientId) {
      throw const AppFailure(
        'Falta GOOGLE_WEB_CLIENT_ID: es el cliente Web, no el Android.',
      );
    }
    if (AppConfig.googleAndroidClientId.isNotEmpty &&
        AppConfig.googleAndroidClientId == AppConfig.googleServerClientId) {
      throw const AppFailure(
        'El serverClientId es el client ID Android. Usa el client ID Web en GOOGLE_WEB_CLIENT_ID.',
      );
    }
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: AppConfig.googleAndroidClientId.trim().isEmpty
          ? null
          : AppConfig.googleAndroidClientId,
      serverClientId: AppConfig.googleServerClientId,
    );
    _initialized = true;
  }

  Future<String> signIn() async {
    await _ensureInitialized();

    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw const AppFailure(
          'Google no devolvió un token válido. Intenta de nuevo.',
        );
      }
      return idToken;
    } on GoogleSignInException catch (error) {
      final description = error.description?.trim();
      if (kDebugMode) {
        debugPrint(
          'GoogleSignInException code=${error.code} description=$description',
        );
      }

      final normalized = description?.toLowerCase() ?? '';
      final isAccountReauth = normalized.contains('reauth');
      final isDeveloperConsole =
          normalized.contains('28444') ||
          normalized.contains('developer console');
      final isUserCancel =
          error.code == GoogleSignInExceptionCode.canceled &&
          !isAccountReauth &&
          !isDeveloperConsole &&
          (description == null || description.isEmpty);

      if (isUserCancel) {
        throw const AppFailure(
          'Cancelaste el inicio de sesión.',
          canceled: true,
        );
      }

      throw AppFailure(
        isDeveloperConsole
            ? 'Google 28444: el cliente Android no está configurado. En Google Cloud crea un cliente Android para mx.tizimin.baches con el SHA-1 de la firma debug.'
            : isAccountReauth
            ? 'Google rechazó la cuenta ([16] Account reauth failed). Revisa el cliente Android: package mx.tizimin.baches y el SHA-1 de la firma debug.'
            : description != null && description.isNotEmpty
            ? 'No se pudo entrar con Google: $description'
            : 'No se pudo entrar con Google. Revisa el cliente Android y la pantalla de consentimiento.',
      );
    }
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    try {
      await GoogleSignIn.instance.signOut();
    } on GoogleSignInException {
      // La sesión local se limpia igual.
    }
  }
}
