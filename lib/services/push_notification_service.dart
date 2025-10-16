import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/firebase_config.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static String? _fcmToken;
  static String? _userId;

  /// Inicializar o serviço de push notifications
  static Future<void> initialize() async {
    try {
      print('🔔 Inicializando Push Notifications...');

      // Solicitar permissões
      await _requestPermissions();

      // Obter token FCM
      await _getFCMToken();

      // Configurar handlers
      _setupMessageHandlers();

      print('✅ Push Notifications inicializado com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar Push Notifications: $e');
    }
  }

  /// Solicitar permissões para notificações
  static Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('🔔 Status de permissão: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Permissões de notificação concedidas');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        print('⚠️ Permissões provisórias concedidas');
      } else {
        print('❌ Permissões de notificação negadas');
      }
    } catch (e) {
      print('❌ Erro ao solicitar permissões: $e');
    }
  }

  /// Obter token FCM
  static Future<String?> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      print('🔔 FCM Token: ${_fcmToken?.substring(0, 20)}...');

      // Salvar token localmente
      if (_fcmToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', _fcmToken!);
      }

      return _fcmToken;
    } catch (e) {
      print('❌ Erro ao obter FCM token: $e');
      return null;
    }
  }

  /// Configurar handlers de mensagens
  static void _setupMessageHandlers() {
    // Mensagem em foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 Mensagem recebida em foreground: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Mensagem em background (quando app está minimizado)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Mensagem aberta em background: ${message.messageId}');
      _handleBackgroundMessage(message);
    });

    // Mensagem quando app está fechado
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('🔔 Mensagem inicial: ${message.messageId}');
        _handleInitialMessage(message);
      }
    });
  }

  /// Processar mensagem em foreground
  static void _handleForegroundMessage(RemoteMessage message) {
    // Aqui você pode mostrar um SnackBar ou dialog
    // Por enquanto, apenas logamos
    print('📱 Título: ${message.notification?.title}');
    print('📱 Corpo: ${message.notification?.body}');
    print('📱 Dados: ${message.data}');
  }

  /// Processar mensagem em background
  static void _handleBackgroundMessage(RemoteMessage message) {
    // Navegar para a tela apropriada baseada nos dados
    final data = message.data;
    if (data['type'] == 'game_confirmation') {
      // Navegar para tela de confirmação
      print('🎯 Navegando para confirmação de jogo');
    } else if (data['type'] == 'game_reminder') {
      // Navegar para detalhes do jogo
      print('🎯 Navegando para detalhes do jogo');
    }
  }

  /// Processar mensagem inicial
  static void _handleInitialMessage(RemoteMessage message) {
    // Similar ao background, mas para quando o app é aberto via notificação
    _handleBackgroundMessage(message);
  }

  /// Enviar notificação push via FCM
  static Future<PushNotificationResponse> sendPushNotification({
    required String to,
    required String title,
    required String body,
    Map<String, String>? data,
    String? imageUrl,
  }) async {
    try {
      print('🔔 Enviando push notification para: $to');

      const url = 'https://fcm.googleapis.com/fcm/send';

      final payload = {
        'to': to,
        'notification': {
          'title': title,
          'body': body,
          if (imageUrl != null) 'image': imageUrl,
        },
        'data': data ?? {},
        'android': {
          'priority': 'high',
          'notification': {
            'sound': 'default',
            'channel_id': 'vaidarjogo_channel',
          },
        },
        'apns': {
          'payload': {
            'aps': {
              'sound': 'default',
              'badge': 1,
            },
          },
        },
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'key=${FirebaseConfig.serverKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success'] == 1) {
        print('✅ Push notification enviada com sucesso');
        return PushNotificationResponse(
          success: true,
          messageId: responseData['results'][0]['message_id'],
          response: responseData,
        );
      } else {
        print(
            '❌ Erro ao enviar push notification: ${responseData['results']?[0]['error']}');
        return PushNotificationResponse(
          success: false,
          error: responseData['results']?[0]['error'] ?? 'Unknown error',
          response: responseData,
        );
      }
    } catch (e) {
      print('❌ Exceção ao enviar push notification: $e');
      return PushNotificationResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar notificação de confirmação de jogo
  static Future<PushNotificationResponse> sendGameConfirmationPush({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String gameId,
  }) async {
    const title = '⚽ Confirmação de Jogo';
    final body = 'Você foi convidado para $gameName em $gameDate às $gameTime';

    final data = {
      'type': 'game_confirmation',
      'game_id': gameId,
      'game_name': gameName,
      'game_date': gameDate,
      'game_time': gameTime,
      'game_location': gameLocation,
      'player_name': playerName,
    };

    return await sendPushNotification(
      to: to,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Enviar notificação de lembrete de jogo
  static Future<PushNotificationResponse> sendGameReminderPush({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String gameId,
    required int hoursUntilGame,
  }) async {
    String timeText = hoursUntilGame == 1 ? '1 hora' : '$hoursUntilGame horas';

    const title = '⏰ Lembrete de Jogo';
    final body = 'Você tem um jogo em $timeText: $gameName';

    final data = {
      'type': 'game_reminder',
      'game_id': gameId,
      'game_name': gameName,
      'game_date': gameDate,
      'game_time': gameTime,
      'game_location': gameLocation,
      'player_name': playerName,
      'hours_until': hoursUntilGame.toString(),
    };

    return await sendPushNotification(
      to: to,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Enviar notificação de cancelamento de jogo
  static Future<PushNotificationResponse> sendGameCancellationPush({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String reason,
    required String gameId,
  }) async {
    const title = '❌ Jogo Cancelado';
    final body = 'O jogo $gameName foi cancelado';

    final data = {
      'type': 'game_cancellation',
      'game_id': gameId,
      'game_name': gameName,
      'game_date': gameDate,
      'game_time': gameTime,
      'player_name': playerName,
      'reason': reason,
    };

    return await sendPushNotification(
      to: to,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Enviar notificação de atualização de jogo
  static Future<PushNotificationResponse> sendGameUpdatePush({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String changes,
    required String gameId,
  }) async {
    const title = '🔄 Jogo Atualizado';
    final body = 'O jogo $gameName foi atualizado';

    final data = {
      'type': 'game_update',
      'game_id': gameId,
      'game_name': gameName,
      'game_date': gameDate,
      'game_time': gameTime,
      'game_location': gameLocation,
      'player_name': playerName,
      'changes': changes,
    };

    return await sendPushNotification(
      to: to,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Obter token FCM atual
  static Future<String?> getFCMToken() async {
    _fcmToken ??= await _getFCMToken();
    return _fcmToken;
  }

  /// Salvar token FCM no servidor
  static Future<bool> saveFCMTokenToServer(String userId) async {
    try {
      final token = await getFCMToken();
      if (token == null) return false;

      // Aqui você faria uma chamada para sua API para salvar o token
      // Por enquanto, apenas simulamos
      print('💾 Salvando FCM token no servidor para usuário: $userId');

      _userId = userId;
      return true;
    } catch (e) {
      print('❌ Erro ao salvar FCM token no servidor: $e');
      return false;
    }
  }

  /// Remover token FCM do servidor
  static Future<bool> removeFCMTokenFromServer() async {
    try {
      if (_userId == null) return false;

      // Aqui você faria uma chamada para sua API para remover o token
      print('🗑️ Removendo FCM token do servidor para usuário: $_userId');

      _userId = null;
      return true;
    } catch (e) {
      print('❌ Erro ao remover FCM token do servidor: $e');
      return false;
    }
  }

  /// Configurar tópicos
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ Inscrito no tópico: $topic');
    } catch (e) {
      print('❌ Erro ao se inscrever no tópico $topic: $e');
    }
  }

  /// Cancelar inscrição em tópicos
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ Cancelou inscrição no tópico: $topic');
    } catch (e) {
      print('❌ Erro ao cancelar inscrição no tópico $topic: $e');
    }
  }

  /// Verificar se as notificações estão habilitadas
  static Future<bool> areNotificationsEnabled() async {
    try {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      print('❌ Erro ao verificar status das notificações: $e');
      return false;
    }
  }
}

class PushNotificationResponse {
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? response;

  PushNotificationResponse({
    required this.success,
    this.messageId,
    this.error,
    this.response,
  });
}
