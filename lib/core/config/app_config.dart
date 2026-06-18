class AppConfig {
  const AppConfig._();

  static const String ipAddress = String.fromEnvironment(
    'API_IP',
    defaultValue: '10.106.252.120',
  );

  static const String ocrApiBase = 'http://$ipAddress:8001/api/v1';
  static const String chatApiBase = 'http://$ipAddress:8002/api/v1';

  static const Duration ocrTimeout = Duration(seconds: 30);
  static const Duration chatTimeout = Duration(seconds: 90);
}
