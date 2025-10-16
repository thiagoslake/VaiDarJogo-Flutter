import 'dart:async';
import '../config/supabase_config.dart';
import '../models/notification_model.dart';
import '../models/notification_config_model.dart';
import 'whatsapp_service.dart';
import 'email_service.dart';
import 'push_notification_service.dart';

class NotificationSchedulerService {
  static Timer? _schedulerTimer;
  static bool _isRunning = false;
  static const Duration _checkInterval = Duration(minutes: 5);

  /// Inicializar o agendador de notificações
  static Future<void> initialize() async {
    if (_isRunning) return;

    print('⏰ Inicializando Notification Scheduler...');

    _isRunning = true;
    _schedulerTimer = Timer.periodic(_checkInterval, (_) {
      _processScheduledNotifications();
    });

    // Processar imediatamente na inicialização
    await _processScheduledNotifications();

    print('✅ Notification Scheduler inicializado');
  }

  /// Parar o agendador de notificações
  static void stop() {
    print('⏹️ Parando Notification Scheduler...');

    _schedulerTimer?.cancel();
    _schedulerTimer = null;
    _isRunning = false;

    print('✅ Notification Scheduler parado');
  }

  /// Processar notificações agendadas
  static Future<void> _processScheduledNotifications() async {
    try {
      print('🔍 Verificando notificações agendadas...');

      final now = DateTime.now();
      final notifications = await _getPendingNotifications(now);

      if (notifications.isEmpty) {
        print('ℹ️ Nenhuma notificação pendente encontrada');
        return;
      }

      print('📋 Encontradas ${notifications.length} notificações pendentes');

      for (final notification in notifications) {
        await _processNotification(notification);
      }
    } catch (e) {
      print('❌ Erro ao processar notificações agendadas: $e');
    }
  }

  /// Obter notificações pendentes
  static Future<List<Notification>> _getPendingNotifications(
      DateTime now) async {
    try {
      final response = await SupabaseConfig.client
          .from('notifications')
          .select('*')
          .eq('status', 'pending')
          .lte('scheduled_for', now.toIso8601String())
          .order('scheduled_for', ascending: true);

      return response.map((data) => Notification.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao buscar notificações pendentes: $e');
      return [];
    }
  }

  /// Processar uma notificação individual
  static Future<void> _processNotification(Notification notification) async {
    try {
      print('📤 Processando notificação: ${notification.id}');

      // Atualizar status para 'sending'
      await _updateNotificationStatus(notification.id, 'sending');

      // Obter configurações do jogador
      final config = await _getPlayerNotificationConfig(notification.playerId);
      if (config == null) {
        print(
            '⚠️ Configuração de notificação não encontrada para jogador: ${notification.playerId}');
        await _updateNotificationStatus(
            notification.id, 'failed', 'Configuração não encontrada');
        return;
      }

      // Verificar se as notificações estão habilitadas
      if (!config.enabled) {
        print(
            '⚠️ Notificações desabilitadas para jogador: ${notification.playerId}');
        await _updateNotificationStatus(
            notification.id, 'cancelled', 'Notificações desabilitadas');
        return;
      }

      // Enviar notificações pelos canais habilitados
      final results = await _sendNotificationByChannels(notification, config);

      // Atualizar status baseado nos resultados
      await _updateNotificationResults(notification.id, results);
    } catch (e) {
      print('❌ Erro ao processar notificação ${notification.id}: $e');
      await _updateNotificationStatus(notification.id, 'failed', e.toString());
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

  /// Enviar notificação pelos canais habilitados
  static Future<Map<String, NotificationChannelResult>>
      _sendNotificationByChannels(
    Notification notification,
    NotificationConfig config,
  ) async {
    final results = <String, NotificationChannelResult>{};

    // Obter dados do jogador e jogo
    final playerData = await _getPlayerData(notification.playerId);
    final gameData = await _getGameData(notification.gameId);

    if (playerData == null || gameData == null) {
      print('❌ Dados do jogador ou jogo não encontrados');
      return results;
    }

    // WhatsApp
    if (config.whatsappEnabled && notification.channels.contains('whatsapp')) {
      results['whatsapp'] = await _sendWhatsAppNotification(
        notification,
        config,
        playerData,
        gameData,
      );
    }

    // Email
    if (config.emailEnabled && notification.channels.contains('email')) {
      results['email'] = await _sendEmailNotification(
        notification,
        config,
        playerData,
        gameData,
      );
    }

    // Push Notification
    if (config.pushEnabled && notification.channels.contains('push')) {
      results['push'] = await _sendPushNotification(
        notification,
        config,
        playerData,
        gameData,
      );
    }

    return results;
  }

  /// Enviar notificação via WhatsApp
  static Future<NotificationChannelResult> _sendWhatsAppNotification(
    Notification notification,
    NotificationConfig config,
    Map<String, dynamic> playerData,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final phoneNumber = WhatsAppService.formatPhoneNumber(
        config.whatsappNumber ?? playerData['phone_number'] ?? '',
      );

      if (!WhatsAppService.isValidPhoneNumber(phoneNumber)) {
        return NotificationChannelResult(
          channel: 'whatsapp',
          success: false,
          error: 'Número de telefone inválido',
        );
      }

      WhatsAppResponse response;

      switch (notification.type) {
        case 'game_confirmation':
          response = await WhatsAppService.sendGameConfirmation(
            to: phoneNumber,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            confirmationLink:
                'https://vaidarjogo.com/confirm/${notification.id}',
          );
          break;

        case 'game_reminder':
          response = await WhatsAppService.sendGameReminder(
            to: phoneNumber,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            hoursUntilGame: _calculateHoursUntilGame(gameData['game_date']),
          );
          break;

        case 'game_cancellation':
          response = await WhatsAppService.sendGameCancellation(
            to: phoneNumber,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            reason: notification.metadata['reason'] ?? 'Não especificado',
          );
          break;

        case 'game_update':
          response = await WhatsAppService.sendGameUpdate(
            to: phoneNumber,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            changes: notification.metadata['changes'] ??
                'Detalhes não especificados',
          );
          break;

        default:
          response = await WhatsAppService.sendTextMessage(
            to: phoneNumber,
            message: notification.message,
          );
      }

      return NotificationChannelResult(
        channel: 'whatsapp',
        success: response.success,
        messageId: response.messageId,
        error: response.error,
        response: response.response,
      );
    } catch (e) {
      return NotificationChannelResult(
        channel: 'whatsapp',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar notificação via Email
  static Future<NotificationChannelResult> _sendEmailNotification(
    Notification notification,
    NotificationConfig config,
    Map<String, dynamic> playerData,
    Map<String, dynamic> gameData,
  ) async {
    try {
      final email = config.email ?? playerData['email'] ?? '';

      if (!EmailService.isValidEmail(email)) {
        return NotificationChannelResult(
          channel: 'email',
          success: false,
          error: 'Email inválido',
        );
      }

      EmailResponse response;

      switch (notification.type) {
        case 'game_confirmation':
          response = await EmailService.sendGameConfirmationEmail(
            to: email,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            confirmationLink:
                'https://vaidarjogo.com/confirm/${notification.id}',
          );
          break;

        case 'game_reminder':
          response = await EmailService.sendGameReminderEmail(
            to: email,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            hoursUntilGame: _calculateHoursUntilGame(gameData['game_date']),
          );
          break;

        case 'game_cancellation':
          response = await EmailService.sendGameCancellationEmail(
            to: email,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            reason: notification.metadata['reason'] ?? 'Não especificado',
          );
          break;

        case 'game_update':
          response = await EmailService.sendGameUpdateEmail(
            to: email,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            changes: notification.metadata['changes'] ??
                'Detalhes não especificados',
          );
          break;

        default:
          response = await EmailService.sendEmail(
            to: email,
            subject: notification.title,
            htmlContent: notification.message,
          );
      }

      return NotificationChannelResult(
        channel: 'email',
        success: response.success,
        messageId: response.messageId,
        error: response.error,
        response: response.response,
      );
    } catch (e) {
      return NotificationChannelResult(
        channel: 'email',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar notificação via Push
  static Future<NotificationChannelResult> _sendPushNotification(
    Notification notification,
    NotificationConfig config,
    Map<String, dynamic> playerData,
    Map<String, dynamic> gameData,
  ) async {
    try {
      // Obter FCM token do jogador
      final fcmToken = await _getPlayerFCMToken(notification.playerId);

      if (fcmToken == null) {
        return NotificationChannelResult(
          channel: 'push',
          success: false,
          error: 'FCM token não encontrado',
        );
      }

      PushNotificationResponse response;

      switch (notification.type) {
        case 'game_confirmation':
          response = await PushNotificationService.sendGameConfirmationPush(
            to: fcmToken,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            gameId: notification.gameId,
          );
          break;

        case 'game_reminder':
          response = await PushNotificationService.sendGameReminderPush(
            to: fcmToken,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            gameId: notification.gameId,
            hoursUntilGame: _calculateHoursUntilGame(gameData['game_date']),
          );
          break;

        case 'game_cancellation':
          response = await PushNotificationService.sendGameCancellationPush(
            to: fcmToken,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            reason: notification.metadata['reason'] ?? 'Não especificado',
            gameId: notification.gameId,
          );
          break;

        case 'game_update':
          response = await PushNotificationService.sendGameUpdatePush(
            to: fcmToken,
            playerName: playerData['name'] ?? '',
            gameName: gameData['organization_name'] ?? '',
            gameDate: gameData['game_date'] ?? '',
            gameTime: gameData['start_time'] ?? '',
            gameLocation: gameData['location'] ?? '',
            changes: notification.metadata['changes'] ??
                'Detalhes não especificados',
            gameId: notification.gameId,
          );
          break;

        default:
          // Converter Map<String, dynamic> para Map<String, String>
          final data = notification.metadata.map(
            (key, value) => MapEntry(key, value.toString()),
          );

          response = await PushNotificationService.sendPushNotification(
            to: fcmToken,
            title: notification.title,
            body: notification.message,
            data: data,
          );
      }

      return NotificationChannelResult(
        channel: 'push',
        success: response.success,
        messageId: response.messageId,
        error: response.error,
        response: response.response,
      );
    } catch (e) {
      return NotificationChannelResult(
        channel: 'push',
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Obter dados do jogador
  static Future<Map<String, dynamic>?> _getPlayerData(String playerId) async {
    try {
      final response = await SupabaseConfig.client
          .from('players')
          .select('*, users(*)')
          .eq('id', playerId)
          .single();

      return response;
    } catch (e) {
      print('❌ Erro ao buscar dados do jogador: $e');
      return null;
    }
  }

  /// Obter dados do jogo
  static Future<Map<String, dynamic>?> _getGameData(String gameId) async {
    try {
      final response = await SupabaseConfig.client
          .from('games')
          .select('*')
          .eq('id', gameId)
          .single();

      return response;
    } catch (e) {
      print('❌ Erro ao buscar dados do jogo: $e');
      return null;
    }
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

  /// Calcular horas até o jogo
  static int _calculateHoursUntilGame(String gameDate) {
    try {
      final gameDateTime = DateTime.parse(gameDate);
      final now = DateTime.now();
      final difference = gameDateTime.difference(now);
      return difference.inHours;
    } catch (e) {
      return 0;
    }
  }

  /// Atualizar status da notificação
  static Future<void> _updateNotificationStatus(
    String notificationId,
    String status, [
    String? errorMessage,
  ]) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'sent') {
        updateData['sent_at'] = DateTime.now().toIso8601String();
      }

      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      await SupabaseConfig.client
          .from('notifications')
          .update(updateData)
          .eq('id', notificationId);
    } catch (e) {
      print('❌ Erro ao atualizar status da notificação: $e');
    }
  }

  /// Atualizar resultados da notificação
  static Future<void> _updateNotificationResults(
    String notificationId,
    Map<String, NotificationChannelResult> results,
  ) async {
    try {
      final hasSuccess = results.values.any((result) => result.success);
      final hasFailure = results.values.any((result) => !result.success);

      String status;
      if (hasSuccess && !hasFailure) {
        status = 'sent';
      } else if (hasSuccess && hasFailure) {
        status = 'partial';
      } else {
        status = 'failed';
      }

      await _updateNotificationStatus(notificationId, status);

      // Salvar logs dos canais
      for (final result in results.values) {
        await _saveNotificationLog(notificationId, result);
      }
    } catch (e) {
      print('❌ Erro ao atualizar resultados da notificação: $e');
    }
  }

  /// Salvar log da notificação
  static Future<void> _saveNotificationLog(
    String notificationId,
    NotificationChannelResult result,
  ) async {
    try {
      await SupabaseConfig.client.from('notification_logs').insert({
        'notification_id': notificationId,
        'channel': result.channel,
        'status': result.success ? 'sent' : 'failed',
        'error_message': result.error,
        'response': result.response,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Erro ao salvar log da notificação: $e');
    }
  }

  /// Agendar notificação
  static Future<String?> scheduleNotification({
    required String playerId,
    required String gameId,
    required String type,
    required String title,
    required String message,
    required List<String> channels,
    required DateTime scheduledFor,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notificationData = {
        'player_id': playerId,
        'game_id': gameId,
        'type': type,
        'title': title,
        'message': message,
        'channels': channels,
        'scheduled_for': scheduledFor.toIso8601String(),
        'metadata': metadata ?? {},
        'status': 'pending',
        'retry_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await SupabaseConfig.client
          .from('notifications')
          .insert(notificationData)
          .select('id')
          .single();

      print('✅ Notificação agendada: ${response['id']}');
      return response['id'];
    } catch (e) {
      print('❌ Erro ao agendar notificação: $e');
      return null;
    }
  }
}

class NotificationChannelResult {
  final String channel;
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? response;

  NotificationChannelResult({
    required this.channel,
    required this.success,
    this.messageId,
    this.error,
    this.response,
  });
}
