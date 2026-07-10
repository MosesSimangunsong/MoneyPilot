class ApiConstants {
  const ApiConstants._();

  static const String defaultBackendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://127.0.0.1:5000',
  );
}
