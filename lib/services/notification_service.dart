import '../config/supabase_config.dart';
import '../models/notification_model.dart';
import '../models/notification_config_model.dart';
import 'whatsapp_service.dart';
import 'email_service.dart';
import 'push_notification_service.dart';
import 'notification_scheduler_service.dart';

class NotificationService {
  /// Enviar notificação de confirmação de jogo
  static Future<bool> sendGameConfirmation({
    required String playerId,
    required String gameId,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String confirmationLink,
  }) async {
    try {
      print('🔔 Enviando notificação de confirmação de jogo...');

      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null || !config.enabled) {
        print('⚠️ Notificações desabilitadas para jogador: $playerId');
        return false;
      }

      // Determinar canais a serem usados
      final channels = <String>[];
      if (config.whatsappEnabled) channels.add('whatsapp');
      if (config.emailEnabled) channels.add('email');
      if (config.pushEnabled) channels.add('push');

      if (channels.isEmpty) {
        print('⚠️ Nenhum canal de notificação habilitado');
        return false;
      }

      // Criar notificação no banco
      final notificationId =
          await NotificationSchedulerService.scheduleNotification(
        playerId: playerId,
        gameId: gameId,
        type: 'game_confirmation',
        title: 'Confirmação de Jogo - $gameName',
        message:
            'Você foi convidado para o jogo $gameName em $gameDate às $gameTime',
        channels: channels,
        scheduledFor: DateTime.now(),
        metadata: {
          'player_name': playerName,
          'game_name': gameName,
          'game_date': gameDate,
          'game_time': gameTime,
          'game_location': gameLocation,
          'confirmation_link': confirmationLink,
        },
      );

      if (notificationId != null) {
        print('✅ Notificação de confirmação agendada: $notificationId');
        return true;
      } else {
        print('❌ Erro ao agendar notificação de confirmação');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de confirmação: $e');
      return false;
    }
  }

  /// Enviar notificação de lembrete de jogo
  static Future<bool> sendGameReminder({
    required String playerId,
    required String gameId,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required int hoursUntilGame,
  }) async {
    try {
      print('🔔 Enviando notificação de lembrete de jogo...');

      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null || !config.enabled) {
        print('⚠️ Notificações desabilitadas para jogador: $playerId');
        return false;
      }

      // Verificar se o jogador quer receber lembretes com essa antecedência
      if (hoursUntilGame > config.advanceHours) {
        print(
            '⚠️ Jogador não quer receber lembretes com $hoursUntilGame horas de antecedência');
        return false;
      }

      // Determinar canais a serem usados
      final channels = <String>[];
      if (config.whatsappEnabled) channels.add('whatsapp');
      if (config.emailEnabled) channels.add('email');
      if (config.pushEnabled) channels.add('push');

      if (channels.isEmpty) {
        print('⚠️ Nenhum canal de notificação habilitado');
        return false;
      }

      // Criar notificação no banco
      final notificationId =
          await NotificationSchedulerService.scheduleNotification(
        playerId: playerId,
        gameId: gameId,
        type: 'game_reminder',
        title: 'Lembrete de Jogo - $gameName',
        message:
            'Você tem um jogo em ${hoursUntilGame}h: $gameName em $gameDate às $gameTime',
        channels: channels,
        scheduledFor: DateTime.now(),
        metadata: {
          'player_name': playerName,
          'game_name': gameName,
          'game_date': gameDate,
          'game_time': gameTime,
          'game_location': gameLocation,
          'hours_until': hoursUntilGame.toString(),
        },
      );

      if (notificationId != null) {
        print('✅ Notificação de lembrete agendada: $notificationId');
        return true;
      } else {
        print('❌ Erro ao agendar notificação de lembrete');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de lembrete: $e');
      return false;
    }
  }

  /// Enviar notificação de cancelamento de jogo
  static Future<bool> sendGameCancellation({
    required String playerId,
    required String gameId,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String reason,
  }) async {
    try {
      print('🔔 Enviando notificação de cancelamento de jogo...');

      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null || !config.enabled) {
        print('⚠️ Notificações desabilitadas para jogador: $playerId');
        return false;
      }

      // Determinar canais a serem usados
      final channels = <String>[];
      if (config.whatsappEnabled) channels.add('whatsapp');
      if (config.emailEnabled) channels.add('email');
      if (config.pushEnabled) channels.add('push');

      if (channels.isEmpty) {
        print('⚠️ Nenhum canal de notificação habilitado');
        return false;
      }

      // Criar notificação no banco
      final notificationId =
          await NotificationSchedulerService.scheduleNotification(
        playerId: playerId,
        gameId: gameId,
        type: 'game_cancellation',
        title: 'Jogo Cancelado - $gameName',
        message: 'O jogo $gameName foi cancelado. Motivo: $reason',
        channels: channels,
        scheduledFor: DateTime.now(),
        metadata: {
          'player_name': playerName,
          'game_name': gameName,
          'game_date': gameDate,
          'game_time': gameTime,
          'reason': reason,
        },
      );

      if (notificationId != null) {
        print('✅ Notificação de cancelamento agendada: $notificationId');
        return true;
      } else {
        print('❌ Erro ao agendar notificação de cancelamento');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de cancelamento: $e');
      return false;
    }
  }

  /// Enviar notificação de atualização de jogo
  static Future<bool> sendGameUpdate({
    required String playerId,
    required String gameId,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String changes,
  }) async {
    try {
      print('🔔 Enviando notificação de atualização de jogo...');

      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null || !config.enabled) {
        print('⚠️ Notificações desabilitadas para jogador: $playerId');
        return false;
      }

      // Determinar canais a serem usados
      final channels = <String>[];
      if (config.whatsappEnabled) channels.add('whatsapp');
      if (config.emailEnabled) channels.add('email');
      if (config.pushEnabled) channels.add('push');

      if (channels.isEmpty) {
        print('⚠️ Nenhum canal de notificação habilitado');
        return false;
      }

      // Criar notificação no banco
      final notificationId =
          await NotificationSchedulerService.scheduleNotification(
        playerId: playerId,
        gameId: gameId,
        type: 'game_update',
        title: 'Jogo Atualizado - $gameName',
        message: 'O jogo $gameName foi atualizado. Alterações: $changes',
        channels: channels,
        scheduledFor: DateTime.now(),
        metadata: {
          'player_name': playerName,
          'game_name': gameName,
          'game_date': gameDate,
          'game_time': gameTime,
          'game_location': gameLocation,
          'changes': changes,
        },
      );

      if (notificationId != null) {
        print('✅ Notificação de atualização agendada: $notificationId');
        return true;
      } else {
        print('❌ Erro ao agendar notificação de atualização');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao enviar notificação de atualização: $e');
      return false;
    }
  }

  /// Enviar notificação para múltiplos jogadores
  static Future<Map<String, bool>> sendNotificationToMultiplePlayers({
    required List<String> playerIds,
    required String gameId,
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> metadata,
  }) async {
    final results = <String, bool>{};

    for (final playerId in playerIds) {
      try {
        final success = await _sendNotificationToPlayer(
          playerId: playerId,
          gameId: gameId,
          type: type,
          title: title,
          message: message,
          metadata: metadata,
        );
        results[playerId] = success;
      } catch (e) {
        print('❌ Erro ao enviar notificação para jogador $playerId: $e');
        results[playerId] = false;
      }
    }

    return results;
  }

  /// Enviar notificação para um jogador específico
  static Future<bool> _sendNotificationToPlayer({
    required String playerId,
    required String gameId,
    required String type,
    required String title,
    required String message,
    required Map<String, dynamic> metadata,
  }) async {
    try {
      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null || !config.enabled) {
        return false;
      }

      // Determinar canais a serem usados
      final channels = <String>[];
      if (config.whatsappEnabled) channels.add('whatsapp');
      if (config.emailEnabled) channels.add('email');
      if (config.pushEnabled) channels.add('push');

      if (channels.isEmpty) {
        return false;
      }

      // Criar notificação no banco
      final notificationId =
          await NotificationSchedulerService.scheduleNotification(
        playerId: playerId,
        gameId: gameId,
        type: type,
        title: title,
        message: message,
        channels: channels,
        scheduledFor: DateTime.now(),
        metadata: metadata,
      );

      return notificationId != null;
    } catch (e) {
      print('❌ Erro ao enviar notificação para jogador $playerId: $e');
      return false;
    }
  }

  /// Obter configurações de notificação do jogador
  static Future<NotificationConfig?> _getPlayerNotificationConfig(
      String playerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('notification_configs')
          .select('*')
          .eq('player_id', playerId)
          .single();

      return NotificationConfig.fromMap(response);
    } catch (e) {
      print('❌ Erro ao buscar configuração do jogador: $e');
      return null;
    }
  }

  /// Obter estatísticas de notificações de um jogador
  static Future<Map<String, int>> getPlayerNotificationStats(
      String playerId) async {
    try {
      final response = await SupabaseConfig.client.rpc('get_notification_stats',
          params: {'player_id_param': playerId}).single();

      return {
        'total': response['total_notifications'] ?? 0,
        'sent': response['sent_notifications'] ?? 0,
        'failed': response['failed_notifications'] ?? 0,
        'pending': response['pending_notifications'] ?? 0,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de notificações: $e');
      return {
        'total': 0,
        'sent': 0,
        'failed': 0,
        'pending': 0,
      };
    }
  }

  /// Obter histórico de notificações de um jogador
  static Future<List<Notification>> getPlayerNotificationHistory(
    String playerId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await SupabaseConfig.client
          .from('notifications')
          .select('*')
          .eq('player_id', playerId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((data) => Notification.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter histórico de notificações: $e');
      return [];
    }
  }

  /// Marcar notificação como lida
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      await SupabaseConfig.client.from('notifications').update({
        'status': 'read',
        'read_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId);

      return true;
    } catch (e) {
      print('❌ Erro ao marcar notificação como lida: $e');
      return false;
    }
  }

  /// Limpar notificações antigas
  static Future<int> cleanupOldNotifications() async {
    try {
      final response =
          await SupabaseConfig.client.rpc('cleanup_old_notifications');

      return response ?? 0;
    } catch (e) {
      print('❌ Erro ao limpar notificações antigas: $e');
      return 0;
    }
  }

  /// Limpar logs antigos
  static Future<int> cleanupOldLogs() async {
    try {
      final response =
          await SupabaseConfig.client.rpc('cleanup_old_notification_logs');

      return response ?? 0;
    } catch (e) {
      print('❌ Erro ao limpar logs antigos: $e');
      return 0;
    }
  }

  /// Testar configurações de notificação
  static Future<Map<String, bool>> testNotificationChannels(
      String playerId) async {
    final results = <String, bool>{};

    try {
      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(playerId);
      if (config == null) {
        return {'error': true};
      }

      // Testar WhatsApp
      if (config.whatsappEnabled) {
        try {
          final phoneNumber = WhatsAppService.formatPhoneNumber(
            config.whatsappNumber ?? '',
          );

          if (WhatsAppService.isValidPhoneNumber(phoneNumber)) {
            final response = await WhatsAppService.sendTextMessage(
              to: phoneNumber,
              message:
                  '🔔 Teste de notificação do VaiDarJogo - WhatsApp funcionando!',
            );
            results['whatsapp'] = response.success;
          } else {
            results['whatsapp'] = false;
          }
        } catch (e) {
          results['whatsapp'] = false;
        }
      }

      // Testar Email
      if (config.emailEnabled) {
        try {
          final email = config.email ?? '';

          if (EmailService.isValidEmail(email)) {
            final response = await EmailService.sendEmail(
              to: email,
              subject: '🔔 Teste de Notificação - VaiDarJogo',
              htmlContent:
                  '<h2>Teste de Notificação</h2><p>Este é um teste do sistema de notificações do VaiDarJogo. Se você recebeu este email, o sistema está funcionando corretamente!</p>',
              textContent:
                  'Teste de Notificação - VaiDarJogo\n\nEste é um teste do sistema de notificações do VaiDarJogo. Se você recebeu este email, o sistema está funcionando corretamente!',
            );
            results['email'] = response.success;
          } else {
            results['email'] = false;
          }
        } catch (e) {
          results['email'] = false;
        }
      }

      // Testar Push Notification
      if (config.pushEnabled) {
        try {
          final fcmToken = await _getPlayerFCMToken(playerId);

          if (fcmToken != null) {
            final response = await PushNotificationService.sendPushNotification(
              to: fcmToken,
              title: '🔔 Teste de Notificação',
              body:
                  'Teste do sistema de notificações do VaiDarJogo - Push funcionando!',
              data: {'type': 'test'},
            );
            results['push'] = response.success;
          } else {
            results['push'] = false;
          }
        } catch (e) {
          results['push'] = false;
        }
      }
    } catch (e) {
      print('❌ Erro ao testar canais de notificação: $e');
      results['error'] = true;
    }

    return results;
  }

  /// Obter FCM token do jogador
  static Future<String?> _getPlayerFCMToken(String playerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('player_fcm_tokens')
          .select('fcm_token')
          .eq('player_id', playerId)
          .eq('is_active', true)
          .single();

      return response['fcm_token'];
    } catch (e) {
      print('❌ Erro ao buscar FCM token do jogador: $e');
      return null;
    }
  }
}
