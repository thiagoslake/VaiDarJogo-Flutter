import '../models/notification_config_model.dart';
import '../config/supabase_config.dart';

class NotificationConfigService {
  static final _client = SupabaseConfig.client;

  /// Obter configuração de notificação do usuário
  static Future<NotificationConfig?> getNotificationConfig(String userId) async {
    try {
      final response = await _client
          .from('notification_configs')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return NotificationConfig.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter configuração de notificação: $e');
      return null;
    }
  }

  /// Criar configuração de notificação padrão
  static Future<NotificationConfig?> createDefaultConfig(String userId) async {
    try {
      final configData = {
        'user_id': userId,
        'game_reminders': true,
        'game_cancellations': true,
        'game_updates': true,
        'player_requests': true,
        'admin_notifications': true,
        'push_notifications': true,
        'email_notifications': false,
        'sms_notifications': false,
        'reminder_time': 30,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('notification_configs')
          .insert(configData)
          .select()
          .single();

      return NotificationConfig.fromMap(response);
    } catch (e) {
      print('❌ Erro ao criar configuração padrão: $e');
      return null;
    }
  }

  /// Atualizar configuração de notificação
  static Future<NotificationConfig?> updateConfig(NotificationConfig config) async {
    try {
      final updateData = {
        'game_reminders': config.gameReminders,
        'game_cancellations': config.gameCancellations,
        'game_updates': config.gameUpdates,
        'player_requests': config.playerRequests,
        'admin_notifications': config.adminNotifications,
        'push_notifications': config.pushNotifications,
        'email_notifications': config.emailNotifications,
        'sms_notifications': config.smsNotifications,
        'reminder_time': config.reminderTime,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('notification_configs')
          .update(updateData)
          .eq('id', config.id)
          .select()
          .single();

      return NotificationConfig.fromMap(response);
    } catch (e) {
      print('❌ Erro ao atualizar configuração: $e');
      return null;
    }
  }

  /// Obter ou criar configuração de notificação
  static Future<NotificationConfig> getOrCreateConfig(String userId) async {
    try {
      // Tentar obter configuração existente
      final existingConfig = await getNotificationConfig(userId);
      if (existingConfig != null) {
        return existingConfig;
      }

      // Criar configuração padrão se não existir
      final newConfig = await createDefaultConfig(userId);
      if (newConfig != null) {
        return newConfig;
      }

      // Se falhar, retornar configuração padrão em memória
      return NotificationConfig(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      print('❌ Erro ao obter/criar configuração: $e');
      // Retornar configuração padrão em memória
      return NotificationConfig(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Verificar se notificação está habilitada
  static Future<bool> isNotificationEnabled(String userId, String type) async {
    try {
      final config = await getNotificationConfig(userId);
      if (config == null) return true; // Padrão é habilitado

      switch (type) {
        case 'game_reminders':
          return config.gameReminders;
        case 'game_cancellations':
          return config.gameCancellations;
        case 'game_updates':
          return config.gameUpdates;
        case 'player_requests':
          return config.playerRequests;
        case 'admin_notifications':
          return config.adminNotifications;
        default:
          return true;
      }
    } catch (e) {
      print('❌ Erro ao verificar notificação: $e');
      return true; // Padrão é habilitado
    }
  }

  /// Deletar configuração de notificação
  static Future<bool> deleteConfig(String configId) async {
    try {
      await _client
          .from('notification_configs')
          .delete()
          .eq('id', configId);

      return true;
    } catch (e) {
      print('❌ Erro ao deletar configuração: $e');
      return false;
    }
  }

  /// Método de compatibilidade - obter ou criar configuração padrão
  static Future<NotificationConfig> getOrCreateDefaultConfig(String userId) async {
    return await getOrCreateConfig(userId);
  }

  /// Validar configuração
  static bool validateConfig(NotificationConfig config) {
    // Validações básicas
    if (config.userId.isEmpty) return false;
    if (config.reminderTime < 0 || config.reminderTime > 1440) return false; // 0 a 24 horas
    return true;
  }

  /// Salvar configuração
  static Future<NotificationConfig?> saveConfig(NotificationConfig config) async {
    return await updateConfig(config);
  }
}
