import '../config/supabase_config.dart';
import 'session_management_service.dart';

class GameService {
  static final _client = SupabaseConfig.client;

  /// Pausar um jogo (alterar status para 'paused')
  static Future<bool> pauseGame({
    required String gameId,
  }) async {
    try {
      print('⏸️ Pausando jogo: $gameId');

      // 1. Pausar o jogo
      final response = await _client
          .from('games')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .select();

      if (response.isEmpty) {
        throw Exception('Jogo não encontrado');
      }

      print('✅ Jogo pausado com sucesso');

      // 2. Pausar todas as sessões ativas do jogo
      await _pauseGameSessions(gameId);

      return true;
    } catch (e) {
      print('❌ Erro ao pausar jogo: $e');
      rethrow;
    }
  }

  /// Reativar um jogo (alterar status para 'active')
  static Future<bool> resumeGame({
    required String gameId,
  }) async {
    try {
      print('▶️ Reativando jogo: $gameId');

      // 1. Reativar o jogo
      final response = await _client
          .from('games')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .select();

      if (response.isEmpty) {
        throw Exception('Jogo não encontrado');
      }

      print('✅ Jogo reativado com sucesso');

      // 2. Reativar todas as sessões pausadas do jogo
      await _resumeGameSessions(gameId);

      return true;
    } catch (e) {
      print('❌ Erro ao reativar jogo: $e');
      rethrow;
    }
  }

  /// Inativar um jogo (marcar como deletado e remover sessões futuras)
  static Future<bool> deleteGame({
    required String gameId,
  }) async {
    try {
      print('🗑️ Inativando jogo: $gameId');

      // 1. Remover apenas sessões futuras (preservar histórico)
      final removedSessions =
          await SessionManagementService.removeFutureGameSessions(gameId);
      print('✅ $removedSessions sessões futuras removidas');

      // 2. Inativar relacionamentos jogador-jogo (marcar como inativos)
      final playersResponse = await _client
          .from('game_players')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('status', 'confirmed')
          .select();

      print(
          '✅ ${playersResponse.length} relacionamentos jogador-jogo inativados');

      // 3. Marcar o jogo como deletado (não deletar fisicamente)
      final response = await _client
          .from('games')
          .update({
            'status': 'deleted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .select();

      if (response.isEmpty) {
        throw Exception('Jogo não encontrado');
      }

      print('✅ Jogo inativado com sucesso (histórico preservado)');
      return true;
    } catch (e) {
      print('❌ Erro ao inativar jogo: $e');
      rethrow;
    }
  }

  /// Reativar um jogo deletado (marcar como ativo e recriar sessões futuras)
  static Future<bool> reactivateGame({
    required String gameId,
  }) async {
    try {
      print('🔄 Reativando jogo deletado: $gameId');

      // 1. Reativar relacionamentos jogador-jogo (marcar como confirmados)
      final playersResponse = await _client
          .from('game_players')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('status', 'inactive')
          .select();

      print(
          '✅ ${playersResponse.length} relacionamentos jogador-jogo reativados');

      // 2. Marcar o jogo como ativo
      final response = await _client
          .from('games')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', gameId)
          .select();

      if (response.isEmpty) {
        throw Exception('Jogo não encontrado');
      }

      print('✅ Jogo reativado com sucesso');

      // 3. Recriar sessões futuras baseadas nas configurações do jogo
      try {
        print('🔄 Recriando sessões futuras para o jogo reativado...');
        final gameData = response.first;
        final sessionResult =
            await SessionManagementService.recreateGameSessions(
                gameId, gameData);

        if (sessionResult['success']) {
          print(
              '✅ ${sessionResult['created_sessions']} sessões futuras recriadas');
        } else {
          print('⚠️ Erro ao recriar sessões: ${sessionResult['error']}');
        }
      } catch (sessionError) {
        print('⚠️ Erro ao recriar sessões: $sessionError');
        // Não falha a reativação do jogo se houver erro nas sessões
      }

      return true;
    } catch (e) {
      print('❌ Erro ao reativar jogo: $e');
      rethrow;
    }
  }

  /// Verificar se o usuário é administrador do jogo
  static Future<bool> isUserGameAdmin({
    required String gameId,
    required String userId,
  }) async {
    try {
      // Buscar o player_id do usuário
      final playerResponse = await _client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerResponse == null) {
        return false;
      }

      final playerId = playerResponse['id'];

      // Verificar se é administrador na tabela game_players
      final gamePlayerResponse = await _client
          .from('game_players')
          .select('is_admin')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .inFilter('status', ['active', 'confirmed']).maybeSingle();

      if (gamePlayerResponse != null &&
          gamePlayerResponse['is_admin'] == true) {
        return true;
      }

      // Fallback: verificar se é o criador do jogo
      final gameResponse = await _client
          .from('games')
          .select('user_id')
          .eq('id', gameId)
          .maybeSingle();

      if (gameResponse == null) {
        return false;
      }

      return gameResponse['user_id'] == userId;
    } catch (e) {
      print('❌ Erro ao verificar se usuário é administrador do jogo: $e');
      return false;
    }
  }

  /// Obter informações do jogo
  static Future<Map<String, dynamic>?> getGameInfo({
    required String gameId,
  }) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .eq('id', gameId)
          .maybeSingle();

      return response;
    } catch (e) {
      print('❌ Erro ao obter informações do jogo: $e');
      return null;
    }
  }

  /// Verificar se o jogo pode ser pausado
  static Future<bool> canPauseGame({
    required String gameId,
  }) async {
    try {
      final gameInfo = await getGameInfo(gameId: gameId);

      if (gameInfo == null) {
        return false;
      }

      final status = gameInfo['status'] as String?;
      return status == 'active';
    } catch (e) {
      print('❌ Erro ao verificar se jogo pode ser pausado: $e');
      return false;
    }
  }

  /// Verificar se o jogo pode ser reativado
  static Future<bool> canResumeGame({
    required String gameId,
  }) async {
    try {
      final gameInfo = await getGameInfo(gameId: gameId);

      if (gameInfo == null) {
        return false;
      }

      final status = gameInfo['status'] as String?;
      return status == 'paused';
    } catch (e) {
      print('❌ Erro ao verificar se jogo pode ser reativado: $e');
      return false;
    }
  }

  /// Verificar se o jogo pode ser inativado
  static Future<bool> canDeleteGame({
    required String gameId,
  }) async {
    try {
      final gameInfo = await getGameInfo(gameId: gameId);

      if (gameInfo == null) {
        return false;
      }

      final status = gameInfo['status'] as String?;
      return status != 'deleted';
    } catch (e) {
      print('❌ Erro ao verificar se jogo pode ser inativado: $e');
      return false;
    }
  }

  /// Verificar se o jogo pode ser reativado (deletado -> ativo)
  static Future<bool> canReactivateGame({
    required String gameId,
  }) async {
    try {
      final gameInfo = await getGameInfo(gameId: gameId);

      if (gameInfo == null) {
        return false;
      }

      final status = gameInfo['status'] as String?;
      return status == 'deleted';
    } catch (e) {
      print('❌ Erro ao verificar se jogo pode ser reativado: $e');
      return false;
    }
  }

  /// Verificar se o jogo está ativo (não deletado)
  static Future<bool> isGameActive({
    required String gameId,
  }) async {
    try {
      final gameInfo = await getGameInfo(gameId: gameId);

      if (gameInfo == null) {
        return false;
      }

      final status = gameInfo['status'] as String?;
      return status != 'deleted';
    } catch (e) {
      print('❌ Erro ao verificar se jogo está ativo: $e');
      return false;
    }
  }

  /// Pausar todas as sessões ativas de um jogo
  static Future<void> _pauseGameSessions(String gameId) async {
    try {
      print('⏸️ Pausando sessões do jogo: $gameId');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('status', 'active')
          .select();

      print('✅ ${response.length} sessões pausadas com sucesso');
    } catch (e) {
      print('❌ Erro ao pausar sessões do jogo: $e');
      rethrow;
    }
  }

  /// Reativar todas as sessões pausadas de um jogo (apenas próximas sessões)
  static Future<void> _resumeGameSessions(String gameId) async {
    try {
      print('▶️ Reativando próximas sessões do jogo: $gameId');

      // Obter data atual para filtrar apenas sessões futuras
      final today = DateTime.now();
      final todayString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      print('🔍 Data atual para filtro: $todayString');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('game_id', gameId)
          .eq('status', 'paused')
          .gte('session_date', todayString) // Apenas sessões futuras ou de hoje
          .select();

      print('✅ ${response.length} próximas sessões reativadas com sucesso');

      // Log das sessões reativadas
      for (var session in response) {
        print(
            '   📅 Sessão reativada: ${session['session_date']} - ${session['start_time']}');
      }
    } catch (e) {
      print('❌ Erro ao reativar sessões do jogo: $e');
      rethrow;
    }
  }

  /// Pausar uma sessão específica
  static Future<bool> pauseSession({
    required String sessionId,
  }) async {
    try {
      print('⏸️ Pausando sessão: $sessionId');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'paused',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .eq('status', 'active')
          .select();

      if (response.isEmpty) {
        throw Exception('Sessão não encontrada ou já pausada');
      }

      print('✅ Sessão pausada com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao pausar sessão: $e');
      rethrow;
    }
  }

  /// Reativar uma sessão específica
  static Future<bool> resumeSession({
    required String sessionId,
  }) async {
    try {
      print('▶️ Reativando sessão: $sessionId');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'active',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .eq('status', 'paused')
          .select();

      if (response.isEmpty) {
        throw Exception('Sessão não encontrada ou já ativa');
      }

      print('✅ Sessão reativada com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao reativar sessão: $e');
      rethrow;
    }
  }

  /// Cancelar uma sessão específica
  static Future<bool> cancelSession({
    required String sessionId,
  }) async {
    try {
      print('❌ Cancelando sessão: $sessionId');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .inFilter('status', ['active', 'paused'])
          .select();

      if (response.isEmpty) {
        throw Exception('Sessão não encontrada ou já cancelada');
      }

      print('✅ Sessão cancelada com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao cancelar sessão: $e');
      rethrow;
    }
  }

  /// Marcar uma sessão como concluída
  static Future<bool> completeSession({
    required String sessionId,
  }) async {
    try {
      print('✅ Marcando sessão como concluída: $sessionId');

      final response = await _client
          .from('game_sessions')
          .update({
            'status': 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId)
          .inFilter('status', ['active', 'paused'])
          .select();

      if (response.isEmpty) {
        throw Exception('Sessão não encontrada ou já concluída');
      }

      print('✅ Sessão marcada como concluída com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao marcar sessão como concluída: $e');
      rethrow;
    }
  }
}
