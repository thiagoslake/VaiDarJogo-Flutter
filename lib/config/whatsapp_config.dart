class WhatsAppConfig {
  // Configurações do WhatsApp Business API
  // IMPORTANTE: Em produção, use variáveis de ambiente ou um arquivo de configuração seguro

  // Phone Number ID do WhatsApp Business
  static const String phoneNumberId = 'YOUR_PHONE_NUMBER_ID';

  // Access Token do WhatsApp Business
  static const String accessToken = 'YOUR_ACCESS_TOKEN';

  // Webhook Verify Token
  static const String webhookVerifyToken = 'YOUR_WEBHOOK_VERIFY_TOKEN';

  // URL do webhook (onde o WhatsApp enviará as atualizações)
  static const String webhookUrl = 'https://your-domain.com/webhook/whatsapp';

  // Configurações de templates
  static const Map<String, String> templates = {
    'game_confirmation': 'game_confirmation_template',
    'game_reminder': 'game_reminder_template',
    'game_cancellation': 'game_cancellation_template',
    'game_update': 'game_update_template',
  };

  // Configurações de rate limiting
  static const int maxMessagesPerMinute = 80;
  static const int maxMessagesPerHour = 1000;

  // Configurações de retry
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);

  // Configurações de timeout
  static const Duration requestTimeout = Duration(seconds: 30);

  // Verificar se as configurações estão válidas
  static bool get isConfigured {
    return phoneNumberId != 'YOUR_PHONE_NUMBER_ID' &&
        accessToken != 'YOUR_ACCESS_TOKEN' &&
        phoneNumberId.isNotEmpty &&
        accessToken.isNotEmpty;
  }

  // Obter configurações para debug (sem expor tokens)
  static Map<String, String> get debugConfig {
    return {
      'phoneNumberId': phoneNumberId.isNotEmpty
          ? '${phoneNumberId.substring(0, 4)}...'
          : 'Not configured',
      'accessToken': accessToken.isNotEmpty
          ? '${accessToken.substring(0, 8)}...'
          : 'Not configured',
      'webhookUrl': webhookUrl,
      'isConfigured': isConfigured.toString(),
    };
  }
}
