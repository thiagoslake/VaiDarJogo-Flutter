import '../config/supabase_config.dart';
import '../models/player_confirmation_model.dart';

class PlayerConfirmationService {
  static final _client = SupabaseConfig.client;

  /// Obter confirmação de um jogador para um jogo específico
  static Future<PlayerConfirmation?> getPlayerConfirmation(
    String gameId,
    String playerId,
  ) async {
    try {
      final response = await _client
          .from('player_confirmations')
          .select('*')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .maybeSingle();

      if (response != null) {
        return PlayerConfirmation.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao obter confirmação do jogador: $e');
      return null;
    }
  }

  /// Obter todas as confirmações de um jogo
  static Future<List<PlayerConfirmation>> getGameConfirmations(
      String gameId) async {
    try {
      final response = await _client
          .from('player_confirmations')
          .select('*')
          .eq('game_id', gameId)
          .order('created_at', ascending: false);

      return response.map((data) => PlayerConfirmation.fromMap(data)).toList();
    } catch (e) {
      print('❌ Erro ao obter confirmações do jogo: $e');
      return [];
    }
  }

  /// Obter todos os jogadores do jogo com suas confirmações (se existirem)
  static Future<List<Map<String, dynamic>>> getGameConfirmationsWithPlayerInfo(
    String gameId,
  ) async {
    try {
      print('🔍 Buscando jogadores para o jogo: $gameId');

      // Primeiro, verificar quantos registros existem na tabela game_players
      print(
          '📊 Verificando registros na tabela game_players para o jogo: $gameId');

      // Buscar todos os registros sem join primeiro para debug
      final allGamePlayers =
          await _client.from('game_players').select('*').eq('game_id', gameId);

      print('📋 Registros brutos encontrados: ${allGamePlayers.length}');
      for (int i = 0; i < allGamePlayers.length; i++) {
        final record = allGamePlayers[i];
        print(
            '   ${i + 1}. Player ID: ${record['player_id']}, Status: ${record['status']}, Type: ${record['player_type']}');
      }

      // Agora fazer a consulta com join (usando left join para users)
      final gamePlayersResponse = await _client.from('game_players').select('''
            *,
            players!inner(
              id,
              name,
              phone_number,
              users(
                id,
                email
              )
            )
          ''').eq('game_id', gameId).order('created_at', ascending: false);

      print('📊 Jogadores encontrados com join: ${gamePlayersResponse.length}');

      // Debug: verificar se o problema está no join
      if (allGamePlayers.length != gamePlayersResponse.length) {
        print('⚠️ PROBLEMA DETECTADO: Join está filtrando registros!');
        print('   Registros brutos: ${allGamePlayers.length}');
        print('   Registros com join: ${gamePlayersResponse.length}');

        // Verificar quais player_ids não estão retornando no join
        final joinedPlayerIds =
            gamePlayersResponse.map((gp) => gp['player_id']).toSet();
        final allPlayerIds =
            allGamePlayers.map((gp) => gp['player_id']).toSet();
        final missingPlayerIds = allPlayerIds.difference(joinedPlayerIds);

        if (missingPlayerIds.isNotEmpty) {
          print('❌ Player IDs que não retornaram no join: $missingPlayerIds');

          // Verificar se esses players existem na tabela players
          for (final missingPlayerId in missingPlayerIds) {
            final playerCheck = await _client
                .from('players')
                .select('id, name, user_id')
                .eq('id', missingPlayerId)
                .maybeSingle();

            if (playerCheck == null) {
              print(
                  '   ❌ Player $missingPlayerId não existe na tabela players');
            } else {
              print(
                  '   ✅ Player $missingPlayerId existe: ${playerCheck['name']}');

              // Verificar se o user existe
              final userCheck = await _client
                  .from('users')
                  .select('id, email')
                  .eq('id', playerCheck['user_id'])
                  .maybeSingle();

              if (userCheck == null) {
                print(
                    '   ❌ User ${playerCheck['user_id']} não existe na tabela users');
              } else {
                print(
                    '   ✅ User ${playerCheck['user_id']} existe: ${userCheck['email']}');
              }
            }
          }
        }
      }

      // Para cada jogador, buscar confirmação (se existir)
      final List<Map<String, dynamic>> result = [];

      for (final gamePlayer in gamePlayersResponse) {
        final playerId = gamePlayer['player_id'];
        final playerName =
            gamePlayer['players']['name'] ?? 'Nome não informado';
        final playerStatus = gamePlayer['status'] ?? 'sem status';

        print(
            '👤 Processando jogador: $playerName (ID: $playerId, Status: $playerStatus)');

        // Buscar confirmação do jogador (se existir)
        final confirmationResponse = await _client
            .from('player_confirmations')
            .select('*')
            .eq('game_id', gameId)
            .eq('player_id', playerId)
            .maybeSingle();

        final confirmationType =
            confirmationResponse?['confirmation_type'] ?? 'pending';
        print('✅ Confirmação do jogador $playerName: $confirmationType');

        // Combinar os dados - sempre incluir o jogador, mesmo sem confirmação
        final playersData = gamePlayer['players'];
        final usersData = playersData?['users'];

        // Garantir que users não seja null
        if (usersData == null && playersData != null) {
          playersData['users'] = {
            'id': null,
            'email': null,
          };
        }

        final combinedData = {
          'player_id': playerId,
          'game_id': gameId,
          'confirmation_type': confirmationType,
          'confirmed_at': confirmationResponse?['confirmed_at'],
          'confirmation_method': confirmationResponse?['confirmation_method'],
          'notes': confirmationResponse?['notes'],
          'created_at': confirmationResponse?['created_at'],
          'updated_at': confirmationResponse?['updated_at'],
          'players': playersData,
          'game_players': {
            'player_type': gamePlayer['player_type'],
            'is_admin': gamePlayer['is_admin'],
            'status': playerStatus,
          },
        };

        result.add(combinedData);
      }

      print('🎯 Total de jogadores processados: ${result.length}');
      return result;
    } catch (e) {
      print('❌ Erro ao obter jogadores com confirmações: $e');
      return [];
    }
  }

  /// Confirmar presença de um jogador
  static Future<PlayerConfirmation?> confirmPlayerPresence({
    required String gameId,
    required String playerId,
    String? notes,
    String confirmationMethod = 'manual',
  }) async {
    try {
      // Verificar se já existe confirmação
      final existingConfirmation =
          await getPlayerConfirmation(gameId, playerId);

      if (existingConfirmation != null) {
        // Atualizar confirmação existente
        final updateData = {
          'confirmation_type': 'confirmed',
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmation_method': confirmationMethod,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .update(updateData)
            .eq('id', existingConfirmation.id)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      } else {
        // Criar nova confirmação
        final confirmationData = {
          'game_id': gameId,
          'player_id': playerId,
          'confirmation_type': 'confirmed',
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmation_method': confirmationMethod,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .insert(confirmationData)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      }
    } catch (e) {
      print('❌ Erro ao confirmar presença do jogador: $e');
      return null;
    }
  }

  /// Declinar presença de um jogador
  static Future<PlayerConfirmation?> declinePlayerPresence({
    required String gameId,
    required String playerId,
    String? notes,
    String confirmationMethod = 'manual',
  }) async {
    try {
      // Verificar se já existe confirmação
      final existingConfirmation =
          await getPlayerConfirmation(gameId, playerId);

      if (existingConfirmation != null) {
        // Atualizar confirmação existente
        final updateData = {
          'confirmation_type': 'declined',
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmation_method': confirmationMethod,
          'notes': notes,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .update(updateData)
            .eq('id', existingConfirmation.id)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      } else {
        // Criar nova confirmação
        final confirmationData = {
          'game_id': gameId,
          'player_id': playerId,
          'confirmation_type': 'declined',
          'confirmed_at': DateTime.now().toIso8601String(),
          'confirmation_method': confirmationMethod,
          'notes': notes,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .insert(confirmationData)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      }
    } catch (e) {
      print('❌ Erro ao declinar presença do jogador: $e');
      return null;
    }
  }

  /// Resetar confirmação de um jogador (voltar para pending)
  static Future<PlayerConfirmation?> resetPlayerConfirmation({
    required String gameId,
    required String playerId,
  }) async {
    try {
      // Verificar se já existe confirmação
      final existingConfirmation =
          await getPlayerConfirmation(gameId, playerId);

      if (existingConfirmation != null) {
        // Atualizar confirmação existente
        final updateData = {
          'confirmation_type': 'pending',
          'confirmed_at': null,
          'confirmation_method': null,
          'notes': null,
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .update(updateData)
            .eq('id', existingConfirmation.id)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      } else {
        // Criar nova confirmação pendente
        final confirmationData = {
          'game_id': gameId,
          'player_id': playerId,
          'confirmation_type': 'pending',
          'confirmed_at': null,
          'confirmation_method': null,
          'notes': null,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _client
            .from('player_confirmations')
            .insert(confirmationData)
            .select()
            .single();

        return PlayerConfirmation.fromMap(response);
      }
    } catch (e) {
      print('❌ Erro ao resetar confirmação do jogador: $e');
      return null;
    }
  }

  /// Obter estatísticas de confirmações de um jogo
  static Future<Map<String, dynamic>> getGameConfirmationStats(
      String gameId) async {
    try {
      final response = await _client
          .from('player_confirmations')
          .select('confirmation_type')
          .eq('game_id', gameId);

      int confirmed = 0;
      int declined = 0;
      int pending = 0;

      for (final confirmation in response) {
        switch (confirmation['confirmation_type']) {
          case 'confirmed':
            confirmed++;
            break;
          case 'declined':
            declined++;
            break;
          case 'pending':
            pending++;
            break;
        }
      }

      final total = confirmed + declined + pending;

      return {
        'total': total,
        'confirmed': confirmed,
        'declined': declined,
        'pending': pending,
        'confirmation_rate': total > 0 ? (confirmed / total * 100).round() : 0,
      };
    } catch (e) {
      print('❌ Erro ao obter estatísticas de confirmação: $e');
      return {
        'total': 0,
        'confirmed': 0,
        'declined': 0,
        'pending': 0,
        'confirmation_rate': 0,
        'error': e.toString(),
      };
    }
  }

  /// Obter confirmações por tipo de jogador
  static Future<Map<String, List<Map<String, dynamic>>>>
      getConfirmationsByPlayerType(
    String gameId,
  ) async {
    try {
      // Primeiro, obter todas as confirmações do jogo
      final confirmationsResponse =
          await _client.from('player_confirmations').select('''
            *,
            players!inner(
              id,
              name,
              phone_number
            )
          ''').eq('game_id', gameId);

      final monthlyConfirmations = <Map<String, dynamic>>[];
      final casualConfirmations = <Map<String, dynamic>>[];

      for (final confirmation in confirmationsResponse) {
        final playerId = confirmation['player_id'];

        // Buscar informações do game_players
        final gamePlayerResponse = await _client
            .from('game_players')
            .select('player_type')
            .eq('game_id', gameId)
            .eq('player_id', playerId)
            .maybeSingle();

        final playerType = gamePlayerResponse?['player_type'] ?? 'casual';

        // Combinar os dados
        final combinedData = {
          ...confirmation,
          'game_players': {
            'player_type': playerType,
          },
        };

        if (playerType == 'monthly') {
          monthlyConfirmations.add(combinedData);
        } else if (playerType == 'casual') {
          casualConfirmations.add(combinedData);
        }
      }

      return {
        'monthly': monthlyConfirmations,
        'casual': casualConfirmations,
      };
    } catch (e) {
      print('❌ Erro ao obter confirmações por tipo de jogador: $e');
      return {
        'monthly': [],
        'casual': [],
      };
    }
  }

  /// Deletar confirmação de um jogador
  static Future<bool> deletePlayerConfirmation({
    required String gameId,
    required String playerId,
  }) async {
    try {
      await _client
          .from('player_confirmations')
          .delete()
          .eq('game_id', gameId)
          .eq('player_id', playerId);

      return true;
    } catch (e) {
      print('❌ Erro ao deletar confirmação do jogador: $e');
      return false;
    }
  }

  /// Deletar todas as confirmações de um jogo
  static Future<bool> deleteAllGameConfirmations(String gameId) async {
    try {
      await _client.from('player_confirmations').delete().eq('game_id', gameId);

      return true;
    } catch (e) {
      print('❌ Erro ao deletar todas as confirmações do jogo: $e');
      return false;
    }
  }

  /// Obter apenas jogadores confirmados de um jogo
  static Future<List<Map<String, dynamic>>> getConfirmedPlayers(
    String gameId,
  ) async {
    try {
      print('🔍 Buscando jogadores confirmados para o jogo: $gameId');

      // Buscar confirmações confirmadas com informações do jogador (usando LEFT JOIN para users)
      final confirmationsResponse = await _client
          .from('player_confirmations')
          .select('''
            *,
            players!inner(
              id,
              name,
              phone_number,
              users(
                id,
                email
              )
            )
          ''')
          .eq('game_id', gameId)
          .eq('confirmation_type', 'confirmed')
          .order('confirmed_at', ascending: false);

      print(
          '📊 Confirmações confirmadas encontradas: ${confirmationsResponse.length}');

      // Para cada confirmação, buscar informações do game_players
      final List<Map<String, dynamic>> result = [];

      for (final confirmation in confirmationsResponse) {
        final playerId = confirmation['player_id'];
        final playerName =
            confirmation['players']['name'] ?? 'Nome não informado';

        print('👤 Processando jogador confirmado: $playerName (ID: $playerId)');

        // Buscar informações do game_players
        final gamePlayerResponse = await _client
            .from('game_players')
            .select('player_type, is_admin')
            .eq('game_id', gameId)
            .eq('player_id', playerId)
            .maybeSingle();

        // Garantir que users não seja null
        final playersData = confirmation['players'];
        final usersData = playersData?['users'];

        if (usersData == null && playersData != null) {
          playersData['users'] = {
            'id': null,
            'email': null,
          };
        }

        // Combinar os dados
        final combinedData = {
          ...confirmation,
          'players': playersData,
          'game_players': gamePlayerResponse ??
              {
                'player_type': 'casual',
                'is_admin': false,
              },
        };

        result.add(combinedData);
      }

      print('🎯 Total de jogadores confirmados processados: ${result.length}');
      return result;
    } catch (e) {
      print('❌ Erro ao obter jogadores confirmados: $e');
      return [];
    }
  }
}
