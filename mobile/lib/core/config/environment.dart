abstract final class Environment {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://physiomanage.onrender.com/api/v1',
  );
}
