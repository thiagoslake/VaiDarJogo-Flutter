class FirebaseConfig {
  // Configurações do Firebase para Push Notifications
  // IMPORTANTE: Em produção, use variáveis de ambiente ou um arquivo de configuração seguro

  // Server Key do Firebase (para envio de notificações)
  static const String serverKey = 'YOUR_FIREBASE_SERVER_KEY';

  // Sender ID do Firebase
  static const String senderId = 'YOUR_FIREBASE_SENDER_ID';

  // Project ID do Firebase
  static const String projectId = 'YOUR_FIREBASE_PROJECT_ID';

  // Configurações de canais Android
  static const Map<String, String> androidChannels = {
    'vaidarjogo_channel': 'VaiDarJogo Notifications',
    'game_reminders': 'Game Reminders',
    'game_updates': 'Game Updates',
    'general': 'General Notifications',
  };

  // Configurações de tópicos
  static const List<String> defaultTopics = [
    'all_users',
    'game_notifications',
  ];

  // Configurações de rate limiting
  static const int maxNotificationsPerMinute = 100;
  static const int maxNotificationsPerHour = 1000;

  // Configurações de retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Configurações de timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Verificar se as configurações estão válidas
  static bool get isConfigured {
    return serverKey != 'YOUR_FIREBASE_SERVER_KEY' &&
        senderId != 'YOUR_FIREBASE_SENDER_ID' &&
        projectId != 'YOUR_FIREBASE_PROJECT_ID' &&
        serverKey.isNotEmpty &&
        senderId.isNotEmpty &&
        projectId.isNotEmpty;
  }

  // Obter configurações para debug (sem expor chaves)
  static Map<String, String> get debugConfig {
    return {
      'serverKey': serverKey.isNotEmpty
          ? '${serverKey.substring(0, 8)}...'
          : 'Not configured',
      'senderId': senderId.isNotEmpty
          ? '${senderId.substring(0, 4)}...'
          : 'Not configured',
      'projectId': projectId.isNotEmpty
          ? '${projectId.substring(0, 8)}...'
          : 'Not configured',
      'isConfigured': isConfigured.toString(),
    };
  }

  // Configurações específicas por ambiente
  static Map<String, dynamic> get environmentConfig {
    return {
      'development': {
        'serverKey': 'YOUR_DEV_FIREBASE_SERVER_KEY',
        'senderId': 'YOUR_DEV_FIREBASE_SENDER_ID',
        'projectId': 'vaidarjogo-dev',
      },
      'staging': {
        'serverKey': 'YOUR_STAGING_FIREBASE_SERVER_KEY',
        'senderId': 'YOUR_STAGING_FIREBASE_SENDER_ID',
        'projectId': 'vaidarjogo-staging',
      },
      'production': {
        'serverKey': 'YOUR_PROD_FIREBASE_SERVER_KEY',
        'senderId': 'YOUR_PROD_FIREBASE_SENDER_ID',
        'projectId': 'vaidarjogo-prod',
      },
    };
  }
}
