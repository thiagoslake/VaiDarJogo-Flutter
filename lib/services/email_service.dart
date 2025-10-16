import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/email_config.dart';

class EmailService {
  static const String _baseUrl = EmailConfig.baseUrl;
  static const String _apiKey = EmailConfig.apiKey;
  static const String _fromEmail = EmailConfig.fromEmail;
  static const String _fromName = EmailConfig.fromName;

  /// Enviar email simples
  static Future<EmailResponse> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String? textContent,
    List<String>? cc,
    List<String>? bcc,
    List<EmailAttachment>? attachments,
  }) async {
    try {
      print('📧 Enviando email para: $to');

      const url = '$_baseUrl/send';

      final body = {
        'personalizations': [
          {
            'to': [
              {'email': to}
            ],
            if (cc != null && cc.isNotEmpty)
              'cc': cc.map((email) => {'email': email}).toList(),
            if (bcc != null && bcc.isNotEmpty)
              'bcc': bcc.map((email) => {'email': email}).toList(),
          }
        ],
        'from': {
          'email': _fromEmail,
          'name': _fromName,
        },
        'subject': subject,
        'content': [
          {
            'type': 'text/html',
            'value': htmlContent,
          },
          if (textContent != null)
            {
              'type': 'text/plain',
              'value': textContent,
            },
        ],
        if (attachments != null && attachments.isNotEmpty)
          'attachments': attachments.map((att) => att.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 202) {
        print('✅ Email enviado com sucesso');
        return EmailResponse(
          success: true,
          messageId: responseData['message_id'],
          response: responseData,
        );
      } else {
        print('❌ Erro ao enviar email: ${responseData['errors']}');
        return EmailResponse(
          success: false,
          error: responseData['errors']?.first['message'] ?? 'Unknown error',
          response: responseData,
        );
      }
    } catch (e) {
      print('❌ Exceção ao enviar email: $e');
      return EmailResponse(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Enviar email de confirmação de jogo
  static Future<EmailResponse> sendGameConfirmationEmail({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String confirmationLink,
  }) async {
    final subject = '⚽ Confirmação de Jogo - $gameName';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Confirmação de Jogo</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #4CAF50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .game-info { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #4CAF50; }
            .button { display: inline-block; background: #4CAF50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 6px; margin: 10px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⚽ VaiDarJogo</h1>
                <h2>Confirmação de Jogo</h2>
            </div>
            <div class="content">
                <p>Olá <strong>$playerName</strong>!</p>
                
                <p>Você foi convidado para participar de um jogo:</p>
                
                <div class="game-info">
                    <h3>🏆 $gameName</h3>
                    <p><strong>📅 Data:</strong> $gameDate</p>
                    <p><strong>🕐 Horário:</strong> $gameTime</p>
                    <p><strong>📍 Local:</strong> $gameLocation</p>
                </div>
                
                <p>Para confirmar sua presença, clique no botão abaixo:</p>
                
                <a href="$confirmationLink" class="button">✅ Confirmar Presença</a>
                
                <p>Ou copie e cole este link no seu navegador:</p>
                <p style="word-break: break-all; background: #eee; padding: 10px; border-radius: 4px;">$confirmationLink</p>
                
                <p><strong>Importante:</strong> Confirme sua presença o mais rápido possível para garantir sua vaga no jogo!</p>
            </div>
            <div class="footer">
                <p>Este é um email automático do sistema VaiDarJogo.</p>
                <p>Se você não solicitou este convite, pode ignorar este email.</p>
            </div>
        </div>
    </body>
    </html>
    ''';

    final textContent = '''
    Confirmação de Jogo - VaiDarJogo
    
    Olá $playerName!
    
    Você foi convidado para o jogo:
    🏆 $gameName
    📅 $gameDate às $gameTime
    📍 $gameLocation
    
    Para confirmar sua presença, acesse:
    $confirmationLink
    
    Obrigado por participar!
    ''';

    return await sendEmail(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      textContent: textContent,
    );
  }

  /// Enviar email de lembrete de jogo
  static Future<EmailResponse> sendGameReminderEmail({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required int hoursUntilGame,
  }) async {
    String timeText = hoursUntilGame == 1 ? '1 hora' : '$hoursUntilGame horas';

    final subject = '⏰ Lembrete: Jogo em $timeText - $gameName';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Lembrete de Jogo</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #FF9800; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .game-info { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF9800; }
            .reminder-box { background: #fff3cd; border: 1px solid #ffeaa7; padding: 15px; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>⏰ VaiDarJogo</h1>
                <h2>Lembrete de Jogo</h2>
            </div>
            <div class="content">
                <p>Olá <strong>$playerName</strong>!</p>
                
                <div class="reminder-box">
                    <h3>🔔 Lembrete</h3>
                    <p>Você tem um jogo em <strong>$timeText</strong>!</p>
                </div>
                
                <div class="game-info">
                    <h3>🏆 $gameName</h3>
                    <p><strong>📅 Data:</strong> $gameDate</p>
                    <p><strong>🕐 Horário:</strong> $gameTime</p>
                    <p><strong>📍 Local:</strong> $gameLocation</p>
                </div>
                
                <h4>📋 Não esqueça de levar:</h4>
                <ul>
                    <li>Roupas adequadas para futebol</li>
                    <li>Água para hidratação</li>
                    <li>Muito ânimo e disposição! ⚽</li>
                </ul>
                
                <p><strong>Nos vemos lá!</strong> 🎯</p>
            </div>
            <div class="footer">
                <p>Este é um lembrete automático do sistema VaiDarJogo.</p>
            </div>
        </div>
    </body>
    </html>
    ''';

    final textContent = '''
    Lembrete de Jogo - VaiDarJogo
    
    Olá $playerName!
    
    Lembrete: Você tem um jogo em $timeText!
    
    🏆 $gameName
    📅 $gameDate às $gameTime
    📍 $gameLocation
    
    Não esqueça de levar:
    • Roupas adequadas
    • Água
    • Muito ânimo! ⚽
    
    Nos vemos lá! 🎯
    ''';

    return await sendEmail(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      textContent: textContent,
    );
  }

  /// Enviar email de cancelamento de jogo
  static Future<EmailResponse> sendGameCancellationEmail({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String reason,
  }) async {
    final subject = '❌ Jogo Cancelado - $gameName';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Jogo Cancelado</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #f44336; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .game-info { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #f44336; }
            .cancellation-box { background: #ffebee; border: 1px solid #ffcdd2; padding: 15px; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>❌ VaiDarJogo</h1>
                <h2>Jogo Cancelado</h2>
            </div>
            <div class="content">
                <p>Olá <strong>$playerName</strong>!</p>
                
                <div class="cancellation-box">
                    <h3>⚠️ Cancelamento</h3>
                    <p>Infelizmente o jogo foi cancelado.</p>
                </div>
                
                <div class="game-info">
                    <h3>🏆 $gameName</h3>
                    <p><strong>📅 Data:</strong> $gameDate</p>
                    <p><strong>🕐 Horário:</strong> $gameTime</p>
                </div>
                
                <p><strong>Motivo do cancelamento:</strong></p>
                <p>$reason</p>
                
                <p>Desculpe pelo inconveniente. Novos jogos serão agendados em breve! ⚽</p>
            </div>
            <div class="footer">
                <p>Este é um aviso automático do sistema VaiDarJogo.</p>
            </div>
        </div>
    </body>
    </html>
    ''';

    final textContent = '''
    Jogo Cancelado - VaiDarJogo
    
    Olá $playerName!
    
    Infelizmente o jogo foi cancelado:
    
    🏆 $gameName
    📅 $gameDate às $gameTime
    
    Motivo: $reason
    
    Desculpe pelo inconveniente. 
    Novos jogos serão agendados em breve! ⚽
    ''';

    return await sendEmail(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      textContent: textContent,
    );
  }

  /// Enviar email de atualização de jogo
  static Future<EmailResponse> sendGameUpdateEmail({
    required String to,
    required String playerName,
    required String gameName,
    required String gameDate,
    required String gameTime,
    required String gameLocation,
    required String changes,
  }) async {
    final subject = '🔄 Jogo Atualizado - $gameName';

    final htmlContent = '''
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Jogo Atualizado</title>
        <style>
            body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
            .container { max-width: 600px; margin: 0 auto; padding: 20px; }
            .header { background: #2196F3; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
            .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
            .game-info { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #2196F3; }
            .update-box { background: #e3f2fd; border: 1px solid #bbdefb; padding: 15px; border-radius: 6px; margin: 20px 0; }
            .footer { text-align: center; margin-top: 30px; color: #666; font-size: 14px; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>🔄 VaiDarJogo</h1>
                <h2>Jogo Atualizado</h2>
            </div>
            <div class="content">
                <p>Olá <strong>$playerName</strong>!</p>
                
                <div class="update-box">
                    <h3>📝 Atualização</h3>
                    <p>O jogo foi atualizado com novas informações.</p>
                </div>
                
                <div class="game-info">
                    <h3>🏆 $gameName</h3>
                    <p><strong>📅 Data:</strong> $gameDate</p>
                    <p><strong>🕐 Horário:</strong> $gameTime</p>
                    <p><strong>📍 Local:</strong> $gameLocation</p>
                </div>
                
                <p><strong>Alterações realizadas:</strong></p>
                <p>$changes</p>
                
                <p>Confirme se ainda pode participar! ⚽</p>
            </div>
            <div class="footer">
                <p>Este é um aviso automático do sistema VaiDarJogo.</p>
            </div>
        </div>
    </body>
    </html>
    ''';

    final textContent = '''
    Jogo Atualizado - VaiDarJogo
    
    Olá $playerName!
    
    O jogo foi atualizado:
    
    🏆 $gameName
    📅 $gameDate às $gameTime
    📍 $gameLocation
    
    Alterações:
    $changes
    
    Confirme se ainda pode participar! ⚽
    ''';

    return await sendEmail(
      to: to,
      subject: subject,
      htmlContent: htmlContent,
      textContent: textContent,
    );
  }

  /// Validar endereço de email
  static bool isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }
}

class EmailResponse {
  final bool success;
  final String? messageId;
  final String? error;
  final Map<String, dynamic>? response;

  EmailResponse({
    required this.success,
    this.messageId,
    this.error,
    this.response,
  });
}

class EmailAttachment {
  final String content;
  final String filename;
  final String type;
  final String? disposition;

  EmailAttachment({
    required this.content,
    required this.filename,
    required this.type,
    this.disposition,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'filename': filename,
      'type': type,
      if (disposition != null) 'disposition': disposition,
    };
  }
}
