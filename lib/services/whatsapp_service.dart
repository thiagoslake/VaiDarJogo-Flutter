import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/whatsapp_config.dart';

class WhatsAppService {
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  static const String _phoneNumberId = WhatsAppConfig.phoneNumberId;
  static const String _accessToken = WhatsAppConfig.accessToken;

  /// Enviar mensagem de texto via WhatsApp
  static Future<WhatsAppResponse> sendTextMessage({
    required String to,
    required String message,
    String? previewUrl,
  }) async {
    try {
      print('📱 Enviando mensagem WhatsApp para: $to');

      const url = '$_baseUrl/$_phoneNumberId/messages';

      final body = {
        'messaging_product': 'whatsapp',
        'to': to,
        'type': 'text',
        'text': {
          'body': message,
          'preview_url': previewUrl ?? false,
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Mensagem WhatsApp enviada com sucesso');
        return WhatsAppResponse(
          success: true,
          messageId: responseData['messages'][0]['id'],
          response: responseData,
        );
      } else {
        print('❌ Erro ao enviar mensagem WhatsApp: ${responseData['error']}');
        return WhatsAppResponse(
          success: false,
          error: responseData['error']['message'],
          response: responseData,
        );
      }
    } catch (e) {
      print('❌ Exceção ao enviar mensagem WhatsApp: $e');
      return WhatsAppResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar mensagem de template via WhatsApp
  static Future<WhatsAppResponse> sendTemplateMessage({
    required String to,
    required String templateName,
    required String languageCode,
    required List<Map<String, String>> parameters,
  }) async {
    try {
      print('📱 Enviando template WhatsApp para: $to');

      const url = '$_baseUrl/$_phoneNumberId/messages';

      final body = {
        'messaging_product': 'whatsapp',
        'to': to,
        'type': 'template',
        'template': {
          'name': templateName,
          'language': {
            'code': languageCode,
          },
          'components': [
            {
              'type': 'body',
              'parameters': parameters
                  .map((param) => {
                        'type': 'text',
                        'text': param['value'],
                      })
                  .toList(),
            }
          ],
        }
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Template WhatsApp enviado com sucesso');
        return WhatsAppResponse(
          success: true,
          messageId: responseData['messages'][0]['id'],
          response: responseData,
        );
      } else {
        print('❌ Erro ao enviar template WhatsApp: ${responseData['error']}');
        return WhatsAppResponse(
          success: false,
          error: responseData['error']['message'],
          response: responseData,
        );
      }
    } catch (e) {
      print('❌ Exceção ao enviar template WhatsApp: $e');
      return WhatsAppResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar mensagem de confirmação de jogo
  static Future<WhatsAppResponse> sendGameConfirmation({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String confirmationLink,
  }) async {
    final message = '''
⚽ *Confirmação de Jogo - VaiDarJogo*

Olá *$playerName*! 

Você foi convidado para o jogo:
🏆 *$gameName*
📅 *$gameDate* às *$gameTime*
📍 *$gameLocation*

Para confirmar sua presença, clique no link:
🔗 $confirmationLink

Ou responda esta mensagem com:
✅ *SIM* - para confirmar
❌ *NÃO* - para recusar

Obrigado por participar! 🎯
    ''';

    return await sendTextMessage(to: to, message: message);
  }

  /// Enviar lembrete de jogo
  static Future<WhatsAppResponse> sendGameReminder({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required int hoursUntilGame,
  }) async {
    String timeText = hoursUntilGame == 1 ? '1 hora' : '$hoursUntilGame horas';

    final message = '''
⏰ *Lembrete de Jogo - VaiDarJogo*

Olá *$playerName*!

Lembrete: Você tem um jogo em *$timeText*!

🏆 *$gameName*
📅 *$gameDate* às *$gameTime*
📍 *$gameLocation*

Não esqueça de levar:
• Roupas adequadas
• Água
• Muito ânimo! ⚽

Nos vemos lá! 🎯
    ''';

    return await sendTextMessage(to: to, message: message);
  }

  /// Enviar notificação de cancelamento
  static Future<WhatsAppResponse> sendGameCancellation({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String reason,
  }) async {
    final message = '''
❌ *Jogo Cancelado - VaiDarJogo*

Olá *$playerName*!

Infelizmente o jogo foi cancelado:

🏆 *$gameName*
📅 *$gameDate* às *$gameTime*

Motivo: $reason

Desculpe pelo inconveniente. 
Novos jogos serão agendados em breve! ⚽
    ''';

    return await sendTextMessage(to: to, message: message);
  }

  /// Enviar notificação de atualização de jogo
  static Future<WhatsAppResponse> sendGameUpdate({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String changes,
  }) async {
    final message = '''
🔄 *Jogo Atualizado - VaiDarJogo*

Olá *$playerName*!

O jogo foi atualizado:

🏆 *$gameName*
📅 *$gameDate* às *$gameTime*
📍 *$gameLocation*

Alterações:
$changes

Confirme se ainda pode participar! ⚽
    ''';

    return await sendTextMessage(to: to, message: message);
  }

  /// Verificar status de entrega da mensagem
  static Future<WhatsAppDeliveryStatus> getDeliveryStatus(
      String messageId) async {
    try {
      final url = '$_baseUrl/$messageId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WhatsAppDeliveryStatus(
          messageId: messageId,
          status: data['statuses'][0]['status'],
          timestamp: DateTime.parse(data['statuses'][0]['timestamp']),
        );
      } else {
        return WhatsAppDeliveryStatus(
          messageId: messageId,
          status: 'error',
          timestamp: DateTime.now(),
          error: 'Failed to get status',
        );
      }
    } catch (e) {
      return WhatsAppDeliveryStatus(
        messageId: messageId,
        status: 'error',
        timestamp: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Validar número de telefone
  static String formatPhoneNumber(String phoneNumber) {
    // Remove todos os caracteres não numéricos
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Adiciona código do país se não tiver
    if (!cleaned.startsWith('55')) {
      cleaned = '55$cleaned';
    }

    return cleaned;
  }

  /// Verificar se o número é válido para WhatsApp
  static bool isValidPhoneNumber(String phoneNumber) {
    final cleaned = formatPhoneNumber(phoneNumber);
    return cleaned.length >= 12 && cleaned.length <= 15;
  }
}

class WhatsAppResponse {
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? response;

  WhatsAppResponse({
    required this.success,
    this.messageId,
    this.error,
    this.response,
  });
}

class WhatsAppDeliveryStatus {
  final String messageId;
  final String status; // 'sent', 'delivered', 'read', 'failed'
  final DateTime timestamp;
  final String? error;

  WhatsAppDeliveryStatus({
    required this.messageId,
    required this.status,
    required this.timestamp,
    this.error,
  });
}
