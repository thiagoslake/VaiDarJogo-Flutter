class AppConfig {
  // Configurações gerais do app
  static const String appName = 'VaiDarJogo';
  static const String appVersion = '1.0.0';

  // Configurações de debug
  static const bool debugMode = true;
  static const bool enableLogs = true;

  // Configurações de timeout
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 15);

  // Configurações de cache
  static const Duration cacheTimeout = Duration(hours: 1);

  // Configurações de validação
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;

  // Configurações de UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Configurações de animação
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
}
