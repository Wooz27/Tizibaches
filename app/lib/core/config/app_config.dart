abstract final class AppConfig {
  static const cityName = 'Tizimín';
  static const cityState = 'Yucatán';
  static const cityLat = 21.1430;
  static const cityLon = -88.1519;
  static const cityZoom = 13.5;

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  // Opcional: el client ID del cliente Android. El flujo por ID token funciona
  // solo con el Web client como serverClientId, pero algunos proyectos lo usan.
  static const googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
  );

  static const publicWebUrl = String.fromEnvironment(
    'PUBLIC_WEB_URL',
    defaultValue: 'http://10.0.2.2:4321/mapa',
  );

  static const useDemoData = bool.fromEnvironment(
    'USE_DEMO_DATA',
    defaultValue: false,
  );

  // Solo para previews de diseño; nunca se activa en un build normal.
  static const startAsGuest = bool.fromEnvironment(
    'START_AS_GUEST',
    defaultValue: false,
  );

  static bool get hasGoogleClientId => googleServerClientId.trim().isNotEmpty;

  static String get normalizedApiBaseUrl =>
      apiBaseUrl.replaceFirst(RegExp(r'/$'), '');
}
