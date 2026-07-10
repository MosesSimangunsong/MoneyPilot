class ApiConstants {
  const ApiConstants._();

  /// Base URL default backend untuk berita dan analisis.
  ///
  /// Nilai ini dibaca saat build lewat:
  /// `--dart-define=BACKEND_BASE_URL=http://...`
  static const String defaultBackendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
}
