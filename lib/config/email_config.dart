class EmailConfig {
  // Configurações do serviço de email (SendGrid, Mailgun, etc.)
  // IMPORTANTE: Em produção, use variáveis de ambiente ou um arquivo de configuração seguro

  // URL base da API de email
  static const String baseUrl = 'https://api.sendgrid.com/v3/mail';

  // API Key do serviço de email
  static const String apiKey = 'YOUR_EMAIL_API_KEY';

  // Email remetente
  static const String fromEmail = 'noreply@vaidarjogo.com';
  static const String fromName = 'VaiDarJogo';

  // Configurações de rate limiting
  static const int maxEmailsPerMinute = 100;
  static const int maxEmailsPerHour = 1000;

  // Configurações de retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Configurações de timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Templates de email
  static const Map<String, String> templates = {
    'game_confirmation': 'game_confirmation_template',
    'game_reminder': 'game_reminder_template',
    'game_cancellation': 'game_cancellation_template',
    'game_update': 'game_update_template',
  };

  // Configurações de tracking
  static const bool enableOpenTracking = true;
  static const bool enableClickTracking = true;

  // Configurações de bounce handling
  static const bool enableBounceHandling = true;
  static const String bounceWebhookUrl =
      'https://your-domain.com/webhook/email/bounce';

  // Verificar se as configurações estão válidas
  static bool get isConfigured {
    return apiKey != 'YOUR_EMAIL_API_KEY' &&
        apiKey.isNotEmpty &&
        fromEmail.isNotEmpty &&
        fromName.isNotEmpty;
  }

  // Obter configurações para debug (sem expor chaves)
  static Map<String, String> get debugConfig {
    return {
      'baseUrl': baseUrl,
      'apiKey':
          apiKey.isNotEmpty ? '${apiKey.substring(0, 8)}...' : 'Not configured',
      'fromEmail': fromEmail,
      'fromName': fromName,
      'isConfigured': isConfigured.toString(),
    };
  }

  // Configurações específicas por ambiente
  static Map<String, dynamic> get environmentConfig {
    // Em produção, isso viria de variáveis de ambiente
    return {
      'development': {
        'baseUrl': 'https://api.sendgrid.com/v3/mail',
        'fromEmail': 'dev@vaidarjogo.com',
        'fromName': 'VaiDarJogo (Dev)',
      },
      'staging': {
        'baseUrl': 'https://api.sendgrid.com/v3/mail',
        'fromEmail': 'staging@vaidarjogo.com',
        'fromName': 'VaiDarJogo (Staging)',
      },
      'production': {
        'baseUrl': 'https://api.sendgrid.com/v3/mail',
        'fromEmail': 'noreply@vaidarjogo.com',
        'fromName': 'VaiDarJogo',
      },
    };
  }
}
