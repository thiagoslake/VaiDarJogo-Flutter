import '../config/supabase_config.dart';
import 'session_management_service.dart';
import 'game_confirmation_config_service.dart';
import 'player_confirmation_service.dart';

/// Serviço para gerenciar atualizações completas de jogos
/// Inclui recriação de sessões, manutenção de configurações e reset de confirmações
class GameUpdateService {
  static final _client = SupabaseConfig.client;

  /// Atualiza um jogo e recria todas as sessões mantendo configurações e resetando confirmações
  static Future<Map<String, dynamic>> updateGameWithSessionRecreation({
    required String gameId,
    required Map<String, dynamic> gameData,
  }) async {
    try {
      print('🔄 Iniciando atualização completa do jogo $gameId...');

      // 1. Verificar se o jogo não está deletado
      final gameStatus = await _getGameStatus(gameId);
      if (gameStatus == 'deleted') {
        print('❌ Não é possível atualizar um jogo deletado');
        return {
          'game_id': gameId,
          'success': false,
          'error': 'Jogo deletado',
          'message': 'Não é possível atualizar um jogo que foi deletado'
        };
      }

      // 2. Salvar configurações de confirmação existentes
      print('💾 Salvando configurações de confirmação existentes...');
      final existingConfig =
          await GameConfirmationConfigService.getGameConfirmationConfig(gameId);

      // 3. Resetar todas as confirmações dos jogadores
      print('🔄 Resetando confirmações dos jogadores...');
      final resetResult = await _resetAllPlayerConfirmations(gameId);

      // 4. Atualizar dados do jogo
      print('📝 Atualizando dados do jogo...');
      await _client.from('games').update(gameData).eq('id', gameId);

      // 5. Recriar todas as sessões
      print('🔄 Recriando sessões...');
      final sessionResult = await SessionManagementService.recreateGameSessions(
          gameId, {...gameData, 'id': gameId});

      // 6. Restaurar configurações de confirmação se existiam
      if (existingConfig != null) {
        print('🔄 Restaurando configurações de confirmação...');
        await _restoreConfirmationConfig(gameId, existingConfig);
      }

      // 7. Preparar resultado
      final result = {
        'game_id': gameId,
        'success': true,
        'message': 'Jogo atualizado com sucesso',
        'details': {
          'configurations_preserved': existingConfig != null,
          'confirmations_reset': resetResult['count'],
          'sessions_removed': sessionResult['removed_sessions'] ?? 0,
          'sessions_created': sessionResult['created_sessions'] ?? 0,
        }
      };

      print('✅ Atualização completa concluída:');
      print('   - Configurações preservadas: ${existingConfig != null}');
      print('   - Confirmações resetadas: ${resetResult['count']}');
      print(
          '   - Sessões removidas: ${sessionResult['removed_sessions'] ?? 0}');
      print('   - Sessões criadas: ${sessionResult['created_sessions'] ?? 0}');

      return result;
    } catch (e) {
      print('❌ Erro na atualização completa do jogo: $e');
      return {
        'game_id': gameId,
        'success': false,
        'error': e.toString(),
        'message': 'Erro ao atualizar jogo: $e'
      };
    }
  }

  /// Resetar todas as confirmações dos jogadores de um jogo
  static Future<Map<String, dynamic>> _resetAllPlayerConfirmations(
      String gameId) async {
    try {
      print('🔄 Resetando confirmações para o jogo $gameId...');

      // Obter todas as confirmações existentes
      final existingConfirmations = await _client
          .from('player_confirmations')
          .select('id, player_id')
          .eq('game_id', gameId);

      int resetCount = 0;

      if (existingConfirmations.isNotEmpty) {
        // Atualizar todas as confirmações para 'pending'
        final updateResult = await _client
            .from('player_confirmations')
            .update({
              'confirmation_type': 'pending',
              'confirmed_at': null,
              'confirmation_method': null,
              'notes': null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('game_id', gameId)
            .select('id');

        resetCount = updateResult.length;
        print('✅ $resetCount confirmações resetadas para pending');
      } else {
        print('ℹ️ Nenhuma confirmação encontrada para resetar');
      }

      return {
        'success': true,
        'count': resetCount,
        'message': '$resetCount confirmações resetadas'
      };
    } catch (e) {
      print('❌ Erro ao resetar confirmações: $e');
      return {
        'success': false,
        'count': 0,
        'error': e.toString(),
        'message': 'Erro ao resetar confirmações: $e'
      };
    }
  }

  /// Restaurar configurações de confirmação após recriação das sessões
  static Future<bool> _restoreConfirmationConfig(
      String gameId, dynamic existingConfig) async {
    try {
      print('🔄 Restaurando configurações de confirmação...');

      // Extrair configurações mensalistas e avulsos
      final monthlyConfigs = existingConfig.monthlyConfigs
          .map<Map<String, dynamic>>((config) => {
                'player_type': 'monthly',
                'confirmation_order': config.confirmationOrder,
                'hours_before_game': config.hoursBeforeGame,
              })
          .toList();

      final casualConfigs = existingConfig.casualConfigs
          .map<Map<String, dynamic>>((config) => {
                'player_type': 'casual',
                'confirmation_order': config.confirmationOrder,
                'hours_before_game': config.hoursBeforeGame,
              })
          .toList();

      // Recriar configuração usando o serviço existente
      await GameConfirmationConfigService.createGameConfirmationConfig(
        gameId: gameId,
        monthlyConfigs: monthlyConfigs,
        casualConfigs: casualConfigs,
      );

      print('✅ Configurações de confirmação restauradas');
      return true;
    } catch (e) {
      print('❌ Erro ao restaurar configurações: $e');
      return false;
    }
  }

  /// Verificar status do jogo
  static Future<String> _getGameStatus(String gameId) async {
    try {
      final response = await _client
          .from('games')
          .select('status')
          .eq('id', gameId)
          .maybeSingle();

      return response?['status'] ?? 'unknown';
    } catch (e) {
      print('❌ Erro ao verificar status do jogo: $e');
      return 'unknown';
    }
  }

  /// Verificar se um jogo tem configurações de confirmação
  static Future<bool> hasConfirmationConfig(String gameId) async {
    try {
      final config =
          await GameConfirmationConfigService.getGameConfirmationConfig(gameId);
      return config != null;
    } catch (e) {
      print('❌ Erro ao verificar configurações: $e');
      return false;
    }
  }

  /// Obter estatísticas de confirmações de um jogo
  static Future<Map<String, dynamic>> getGameConfirmationStats(
      String gameId) async {
    try {
      final confirmations =
          await PlayerConfirmationService.getGameConfirmations(gameId);

      int confirmed = 0;
      int pending = 0;
      int declined = 0;

      for (final confirmation in confirmations) {
        switch (confirmation.confirmationType) {
          case 'confirmed':
            confirmed++;
            break;
          case 'pending':
            pending++;
            break;
          case 'declined':
            declined++;
            break;
        }
      }

      return {
        'total': confirmations.length,
        'confirmed': confirmed,
        'pending': pending,
        'declined': declined,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas: $e');
      return {
        'total': 0,
        'confirmed': 0,
        'pending': 0,
        'declined': 0,
      };
    }
  }
}
