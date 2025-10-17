import '../config/supabase_config.dart';
import '../models/confirmation_send_log_model.dart';

class ConfirmationSendLogService {
  static final _client = SupabaseConfig.client;

  /// Criar log de envio de confirmação
  static Future<ConfirmationSendLog?> createSendLog({
    required String gameId,
    required String playerId,
    String? sendConfigId,
    required DateTime scheduledFor,
    String? channel,
    String? messageContent,
  }) async {
    try {
      final logData = {
        'game_id': gameId,
        'player_id': playerId,
        'send_config_id': sendConfigId,
        'scheduled_for': scheduledFor.toIso8601String(),
        'status': 'pending',
        'channel': channel,
        'message_content': messageContent,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('confirmation_send_logs')
          .insert(logData)
          .select()
          .single();

      return ConfirmationSendLog.fromMap(response);
    } catch (e) {
      print('❌ Erro ao criar log de envio: $e');
      return null;
    }
  }

  /// Atualizar status de um log de envio
  static Future<ConfirmationSendLog?> updateSendLogStatus({
    required String logId,
    required String status,
    String? errorMessage,
    DateTime? sentAt,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (errorMessage != null) {
        updateData['error_message'] = errorMessage;
      }

      if (sentAt != null) {
        updateData['sent_at'] = sentAt.toIso8601String();
      } else if (status == 'sent') {
        updateData['sent_at'] = DateTime.now().toIso8601String();
      }

      final response = await _client
          .from('confirmation_send_logs')
          .update(updateData)
          .eq('id', logId)
          .select()
          .single();

      return ConfirmationSendLog.fromMap(response);
    } catch (e) {
      print('❌ Erro ao atualizar status do log: $e');
      return null;
    }
  }

  /// Obter logs de envio de um jogo
  static Future<List<ConfirmationSendLog>> getGameSendLogs(
      String gameId) async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('game_id', gameId)
          .order('scheduled_for', ascending: false);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs de envio do jogo: $e');
      return [];
    }
  }

  /// Obter logs de envio de um jogador
  static Future<List<ConfirmationSendLog>> getPlayerSendLogs({
    required String gameId,
    required String playerId,
  }) async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .order('scheduled_for', ascending: false);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs de envio do jogador: $e');
      return [];
    }
  }

  /// Obter logs pendentes para envio
  static Future<List<ConfirmationSendLog>> getPendingSendLogs() async {
    try {
      final now = DateTime.now();
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('status', 'pending')
          .lte('scheduled_for', now.toIso8601String())
          .order('scheduled_for', ascending: true);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs pendentes: $e');
      return [];
    }
  }

  /// Obter logs por status
  static Future<List<ConfirmationSendLog>> getSendLogsByStatus(
      String status) async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('status', status)
          .order('created_at', ascending: false);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs por status: $e');
      return [];
    }
  }

  /// Obter estatísticas de logs de envio
  static Future<Map<String, dynamic>> getSendLogStats(String gameId) async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('status')
          .eq('game_id', gameId);

      int pending = 0;
      int sent = 0;
      int failed = 0;
      int cancelled = 0;

      for (final log in response) {
        switch (log['status']) {
          case 'pending':
            pending++;
            break;
          case 'sent':
            sent++;
            break;
          case 'failed':
            failed++;
            break;
          case 'cancelled':
            cancelled++;
            break;
        }
      }

      final total = pending + sent + failed + cancelled;

      return {
        'total': total,
        'pending': pending,
        'sent': sent,
        'failed': failed,
        'cancelled': cancelled,
        'success_rate': total > 0 ? (sent / total * 100).round() : 0,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de logs: $e');
      return {
        'total': 0,
        'pending': 0,
        'sent': 0,
        'failed': 0,
        'cancelled': 0,
        'success_rate': 0,
        'error': e.toString(),
      };
    }
  }

  /// Obter logs com informações do jogador
  static Future<List<Map<String, dynamic>>> getSendLogsWithPlayerInfo(
      String gameId) async {
    try {
      final response = await _client.from('confirmation_send_logs').select('''
            *,
            players!inner(
              id,
              name,
              phone_number
            ),
            confirmation_send_configs(
              player_type,
              confirmation_order,
              hours_before_game
            )
          ''').eq('game_id', gameId).order('scheduled_for', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erro ao obter logs com informações do jogador: $e');
      return [];
    }
  }

  /// Cancelar logs pendentes de um jogo
  static Future<bool> cancelPendingLogs(String gameId) async {
    try {
      await _client
          .from('confirmation_send_logs')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      print('❌ Erro ao cancelar logs pendentes: $e');
      return false;
    }
  }

  /// Cancelar logs pendentes de um jogador específico
  static Future<bool> cancelPlayerPendingLogs({
    required String gameId,
    required String playerId,
  }) async {
    try {
      await _client
          .from('confirmation_send_logs')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .eq('status', 'pending');

      return true;
    } catch (e) {
      print('❌ Erro ao cancelar logs pendentes do jogador: $e');
      return false;
    }
  }

  /// Deletar logs antigos (mais de 30 dias)
  static Future<int> deleteOldLogs({int daysOld = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

      final response = await _client
          .from('confirmation_send_logs')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String())
          .select('id');

      return response.length;
    } catch (e) {
      print('❌ Erro ao deletar logs antigos: $e');
      return 0;
    }
  }

  /// Obter logs por canal
  static Future<List<ConfirmationSendLog>> getSendLogsByChannel(
      String channel) async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('channel', channel)
          .order('created_at', ascending: false);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs por canal: $e');
      return [];
    }
  }

  /// Obter logs com erro
  static Future<List<ConfirmationSendLog>> getFailedSendLogs() async {
    try {
      final response = await _client
          .from('confirmation_send_logs')
          .select('*')
          .eq('status', 'failed')
          .order('created_at', ascending: false);

      return response.map((data) => ConfirmationSendLog.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter logs com falha: $e');
      return [];
    }
  }
}
