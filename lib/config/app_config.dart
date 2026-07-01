/// Konfigurasi global aplikasi.
/// Ganti via `--dart-define=API_BASE_URL=...` saat run/build.
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
