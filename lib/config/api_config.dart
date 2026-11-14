/// Configurazione di rete del client.
///
/// Il valore predefinito funziona con:
///  - simulatore iOS / app macOS / browser sullo stesso computer del server
///    (http://127.0.0.1:8080)
///
/// Per un telefono reale o un emulatore Android usare --dart-define:
///  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080     (emulatore Android)
///  flutter run --dart-define=API_BASE_URL=http://192.168.1.9:8080  (telefono in Wi-Fi)
class ApiConfig {
  /// Modificabile anche nei test.
  static String baseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );

  static const Duration timeout = Duration(seconds: 15);
}
