import '../models/player_model.dart';
import '../models/game_player_model.dart';
import '../config/supabase_config.dart';
import '../utils/error_handler.dart';

class PlayerService {
  static final _client = SupabaseConfig.client;

  /// Criar um novo perfil de jogador
  static Future<Player?> createPlayer({
    required String userId,
    required String name,
    required String phoneNumber,
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
  }) async {
    try {
      print('📝 Criando perfil de jogador para usuário: $userId');

      final playerData = {
        'user_id': userId,
        'name': name,
        'phone_number': phoneNumber,
        'status': 'active',
        'birth_date': birthDate?.toIso8601String().split('T')[0],
        'primary_position': primaryPosition,
        'secondary_position': secondaryPosition,
        'preferred_foot': preferredFoot,
      };

      print('📝 Dados do jogador: $playerData');

      final response =
          await _client.from('players').insert(playerData).select().single();

      print('✅ Perfil de jogador criado com sucesso: ${response['id']}');
      return Player.fromMap(response);
    } catch (e) {
      print('❌ Erro ao criar perfil de jogador: $e');
      // Lançar erro com mensagem amigável
      throw Exception(ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Buscar jogador por ID do usuário
  static Future<Player?> getPlayerByUserId(String userId) async {
    try {
      final response = await _client
          .from('players')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return Player.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar jogador por user_id: $e');
      return null;
    }
  }

  /// Buscar jogador por ID
  static Future<Player?> getPlayerById(String playerId) async {
    try {
      final response = await _client
          .from('players')
          .select('*')
          .eq('id', playerId)
          .maybeSingle();

      if (response != null) {
        return Player.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar jogador por ID: $e');
      return null;
    }
  }

  /// Atualizar perfil de jogador
  static Future<Player?> updatePlayer({
    required String playerId,
    String? name,
    String? phoneNumber,
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
    String? status,
  }) async {
    try {
      print('🔍 DEBUG - Iniciando atualização de jogador: $playerId');
      print(
          '🔍 DEBUG - Dados a atualizar: name=$name, phoneNumber=$phoneNumber');

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (birthDate != null) {
        updateData['birth_date'] = birthDate.toIso8601String().split('T')[0];
      }
      if (primaryPosition != null) {
        updateData['primary_position'] = primaryPosition;
      }
      if (secondaryPosition != null) {
        updateData['secondary_position'] = secondaryPosition;
      }
      if (preferredFoot != null) updateData['preferred_foot'] = preferredFoot;
      if (status != null) updateData['status'] = status;

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();

        // Atualizar dados na tabela players
        final response = await _client
            .from('players')
            .update(updateData)
            .eq('id', playerId)
            .select()
            .single();

        print('✅ Dados atualizados na tabela players');

        // Se telefone foi alterado, sincronizar com a tabela users
        if (phoneNumber != null) {
          print('🔍 DEBUG - Sincronizando telefone com tabela users');

          try {
            // Buscar o user_id do jogador
            final playerData = await _client
                .from('players')
                .select('user_id')
                .eq('id', playerId)
                .single();

            final userId = playerData['user_id'];

            // Atualizar telefone na tabela users
            await _client
                .from('users')
                .update({'phone': phoneNumber}).eq('id', userId);

            print('✅ Telefone sincronizado na tabela users: $phoneNumber');
          } catch (e) {
            print('⚠️ Erro ao sincronizar telefone com users: $e');
            // Não falhar a atualização do jogador por causa disso
          }
        }

        print('✅ Perfil de jogador atualizado com sucesso');
        return Player.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao atualizar jogador: $e');
      // Lançar erro com mensagem amigável
      throw Exception(ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Verificar se usuário já tem perfil de jogador
  static Future<bool> hasPlayerProfile(String userId) async {
    try {
      final response = await _client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar perfil de jogador: $e');
      return false;
    }
  }

  /// Verificar se número de telefone já está sendo usado
  static Future<bool> isPhoneNumberInUse(String phoneNumber) async {
    try {
      final response = await _client
          .from('players')
          .select('id')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar telefone: $e');
      return false;
    }
  }

  /// Buscar jogador por número de telefone
  static Future<Player?> getPlayerByPhoneNumber(String phoneNumber) async {
    try {
      final response = await _client
          .from('players')
          .select('*')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      if (response != null) {
        return Player.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar jogador por telefone: $e');
      return null;
    }
  }

  /// Deletar perfil de jogador
  static Future<bool> deletePlayer(String playerId) async {
    try {
      await _client.from('players').delete().eq('id', playerId);

      return true;
    } catch (e) {
      print('❌ Erro ao deletar jogador: $e');
      return false;
    }
  }

  // =====================================================
  // MÉTODOS PARA GERENCIAR RELACIONAMENTO JOGADOR-JOGO
  // =====================================================

  /// Adicionar jogador a um jogo com tipo específico
  static Future<GamePlayer?> addPlayerToGame({
    required String gameId,
    required String playerId,
    required String playerType, // 'monthly' ou 'casual'
    String status = 'active',
    bool isAdmin = false, // Se o jogador é administrador do jogo
  }) async {
    try {
      print(
          '🔗 Adicionando jogador $playerId ao jogo $gameId como $playerType${isAdmin ? ' (ADMIN)' : ''}');

      final relationData = {
        'game_id': gameId,
        'player_id': playerId,
        'player_type': playerType,
        'status': status,
        'is_admin': isAdmin,
        'joined_at': DateTime.now().toIso8601String(),
      };

      print('🔍 DEBUG - Dados a inserir: $relationData');

      final response = await _client
          .from('game_players')
          .insert(relationData)
          .select()
          .single();

      print('✅ Jogador adicionado ao jogo com sucesso: ${response['id']}');
      print('🔍 DEBUG - Response completa: $response');

      final gamePlayer = GamePlayer.fromMap(response);
      print('🔍 DEBUG - GamePlayer criado: ${gamePlayer.id}');
      return gamePlayer;
    } catch (e) {
      print('❌ Erro ao adicionar jogador ao jogo: $e');
      print('🔍 DEBUG - Erro completo: ${e.toString()}');
      throw Exception(ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Adicionar criador do jogo como administrador e mensalista
  static Future<GamePlayer?> addGameCreatorAsAdmin({
    required String gameId,
    required String userId,
  }) async {
    try {
      print(
          '👑 Adicionando criador do jogo como administrador e mensalista...');
      print('🔍 DEBUG - Game ID: $gameId');
      print('🔍 DEBUG - User ID: $userId');

      // Buscar o player_id do usuário
      print('🔍 DEBUG - Buscando player_id para user_id: $userId');
      final playerResponse = await _client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      print('🔍 DEBUG - Player response: $playerResponse');

      if (playerResponse == null) {
        print('❌ Player não encontrado para o usuário criador: $userId');
        throw Exception(
            'Perfil de jogador não encontrado. Complete seu perfil primeiro.');
      }

      final playerId = playerResponse['id'];
      print('🔍 DEBUG - Player ID encontrado: $playerId');

      // Adicionar o jogador ao jogo como mensalista e administrador
      print('🔍 DEBUG - Chamando addPlayerToGame...');
      final gamePlayer = await addPlayerToGame(
        gameId: gameId,
        playerId: playerId,
        playerType: 'monthly',
        status: 'confirmed', // Usar 'confirmed' para criadores
        isAdmin: true,
      );

      print('✅ Criador adicionado como jogador mensalista e administrador');
      print('🔍 DEBUG - GamePlayer retornado: ${gamePlayer?.id}');
      return gamePlayer;
    } catch (e) {
      print('❌ Erro ao adicionar criador como administrador: $e');
      print('🔍 DEBUG - Stack trace completo: ${e.toString()}');
      rethrow;
    }
  }

  /// Atualizar tipo de jogador em um jogo específico
  static Future<GamePlayer?> updatePlayerTypeInGame({
    required String gamePlayerId,
    required String playerType, // 'monthly' ou 'casual'
  }) async {
    try {
      print('🔄 Atualizando tipo do jogador $gamePlayerId para $playerType');

      final updateData = {
        'player_type': playerType,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('game_players')
          .update(updateData)
          .eq('id', gamePlayerId)
          .select()
          .single();

      print('✅ Tipo do jogador atualizado com sucesso');
      return GamePlayer.fromMap(response);
    } catch (e) {
      print('❌ Erro ao atualizar tipo do jogador: $e');
      throw Exception(ErrorHandler.getFriendlyErrorMessage(e));
    }
  }

  /// Buscar relacionamento jogador-jogo
  static Future<GamePlayer?> getGamePlayer({
    required String gameId,
    required String playerId,
  }) async {
    try {
      final response = await _client
          .from('game_players')
          .select('*')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .maybeSingle();

      if (response != null) {
        return GamePlayer.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar relacionamento jogador-jogo: $e');
      return null;
    }
  }

  /// Buscar todos os jogadores de um jogo por tipo
  static Future<List<GamePlayer>> getGamePlayersByType({
    required String gameId,
    required String playerType, // 'monthly' ou 'casual'
  }) async {
    try {
      print(
          '🔍 DEBUG - Buscando jogadores do tipo $playerType no jogo: $gameId');

      final response = await _client
          .from('game_players')
          .select('''
            id,
            game_id,
            player_id,
            player_type,
            status,
            is_admin,
            joined_at,
            created_at,
            updated_at,
            players!inner(
              id,
              name,
              phone_number,
              birth_date,
              primary_position,
              secondary_position,
              preferred_foot,
              status,
              user_id
            )
          ''')
          .eq('game_id', gameId)
          .eq('player_type', playerType)
          .inFilter('status', ['active', 'confirmed'])
          .order('joined_at', ascending: false);

      print(
          '🔍 DEBUG - Jogadores do tipo $playerType encontrados: ${response.length}');

      return (response as List)
          .map<GamePlayer>((item) => GamePlayer.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar jogadores por tipo: $e');
      return [];
    }
  }

  /// Buscar todos os jogadores de um jogo
  static Future<List<GamePlayer>> getGamePlayers({
    required String gameId,
  }) async {
    try {
      print('🔍 DEBUG - Buscando jogadores do jogo: $gameId');

      // Primeiro, buscar todos os registros para ver quais status existem
      final allResponse = await _client
          .from('game_players')
          .select('id, status')
          .eq('game_id', gameId);

      print('🔍 DEBUG - Todos os registros encontrados: ${allResponse.length}');
      for (var record in allResponse) {
        print(
            '🔍 DEBUG - Registro: id=${record['id']}, status=${record['status']}');
      }

      // Buscar jogadores com status 'active' ou 'confirmed'
      final response = await _client
          .from('game_players')
          .select('''
            id,
            game_id,
            player_id,
            player_type,
            status,
            is_admin,
            joined_at,
            created_at,
            updated_at,
            players!inner(
              id,
              name,
              phone_number,
              birth_date,
              primary_position,
              secondary_position,
              preferred_foot,
              status,
              user_id
            )
          ''')
          .eq('game_id', gameId)
          .inFilter('status', ['active', 'confirmed'])
          .order('joined_at', ascending: false);

      print(
          '🔍 DEBUG - Response do getGamePlayers: ${response.length} jogadores encontrados');

      final gamePlayers = (response as List)
          .map<GamePlayer>((item) => GamePlayer.fromMap(item))
          .toList();

      print('🔍 DEBUG - GamePlayers mapeados: ${gamePlayers.length}');
      return gamePlayers;
    } catch (e) {
      print('❌ Erro ao buscar jogadores do jogo: $e');
      print('🔍 DEBUG - Erro completo: ${e.toString()}');
      return [];
    }
  }

  /// Verificar se um jogador é administrador de um jogo
  static Future<bool> isPlayerGameAdmin({
    required String gameId,
    required String playerId,
  }) async {
    try {
      // Primeiro, verificar se é administrador na tabela game_players
      final gamePlayerResponse = await _client
          .from('game_players')
          .select('is_admin')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .eq('status', 'active')
          .maybeSingle();

      if (gamePlayerResponse != null &&
          gamePlayerResponse['is_admin'] == true) {
        print('🔍 Jogador é administrador (via game_players.is_admin)');
        return true;
      }

      // Fallback: verificar se é o criador do jogo (compatibilidade)
      final playerResponse = await _client
          .from('players')
          .select('user_id')
          .eq('id', playerId)
          .maybeSingle();

      if (playerResponse == null) {
        return false;
      }

      final userId = playerResponse['user_id'];

      final gameResponse = await _client
          .from('games')
          .select('user_id')
          .eq('id', gameId)
          .maybeSingle();

      if (gameResponse == null) {
        return false;
      }

      final gameAdminId = gameResponse['user_id'];
      final isAdmin = userId == gameAdminId;

      print('🔍 Verificação de administrador:');
      print('   - Jogador user_id: $userId');
      print('   - Jogo admin user_id: $gameAdminId');
      print('   - É administrador (criador): $isAdmin');

      return isAdmin;
    } catch (e) {
      print('❌ Erro ao verificar se jogador é administrador: $e');
      return false;
    }
  }

  /// Remover jogador de um jogo (deletar relação da tabela game_players)
  static Future<bool> removePlayerFromGame({
    required String gameId,
    required String playerId,
  }) async {
    try {
      // Verificar se o jogador é administrador do jogo
      final isAdmin = await isPlayerGameAdmin(
        gameId: gameId,
        playerId: playerId,
      );

      if (isAdmin) {
        print('❌ Não é possível remover o administrador do jogo');
        throw Exception('Não é possível remover o administrador do jogo');
      }

      // Deletar a relação jogador-jogo da tabela game_players
      await _client
          .from('game_players')
          .delete()
          .eq('game_id', gameId)
          .eq('player_id', playerId);

      print('✅ Jogador removido do jogo com sucesso (relação deletada)');
      return true;
    } catch (e) {
      print('❌ Erro ao remover jogador do jogo: $e');
      rethrow; // Re-lançar o erro para que a UI possa tratá-lo
    }
  }

  /// Verificar se jogador está em um jogo
  static Future<bool> isPlayerInGame({
    required String gameId,
    required String playerId,
  }) async {
    try {
      final response = await _client
          .from('game_players')
          .select('id')
          .eq('game_id', gameId)
          .eq('player_id', playerId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar se jogador está no jogo: $e');
      return false;
    }
  }

  /// Promover jogador a administrador do jogo
  static Future<bool> promotePlayerToAdmin({
    required String gameId,
    required String playerId,
  }) async {
    try {
      // Verificar se o jogador está no jogo
      final isInGame = await isPlayerInGame(
        gameId: gameId,
        playerId: playerId,
      );

      if (!isInGame) {
        throw Exception('Jogador não está participando do jogo');
      }

      // Atualizar o jogador para administrador
      await _client
          .from('game_players')
          .update({'is_admin': true})
          .eq('game_id', gameId)
          .eq('player_id', playerId);

      print('✅ Jogador promovido a administrador com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao promover jogador a administrador: $e');
      rethrow;
    }
  }

  /// Remover privilégios de administrador do jogador
  static Future<bool> demotePlayerFromAdmin({
    required String gameId,
    required String playerId,
  }) async {
    try {
      // Verificar se é o último administrador (excluindo o próprio jogador)
      print(
          '🔍 DEBUG - Verificando administradores para gameId: $gameId, playerId: $playerId');

      final otherAdminsCount = await _client
          .from('game_players')
          .select('id, player_id, is_admin, status')
          .eq('game_id', gameId)
          .eq('is_admin', true)
          .inFilter('status', ['active', 'confirmed']).neq(
              'player_id', playerId);

      print(
          '🔍 DEBUG - Outros administradores encontrados: ${otherAdminsCount.length}');
      print('🔍 DEBUG - Dados dos outros administradores: $otherAdminsCount');

      if (otherAdminsCount.isEmpty) {
        print('❌ DEBUG - É o último administrador, impedindo remoção');
        throw Exception(
            'Não é possível remover o último administrador do jogo');
      }

      print('✅ DEBUG - Há outros administradores, permitindo remoção');

      // Remover privilégios de administrador
      await _client
          .from('game_players')
          .update({'is_admin': false})
          .eq('game_id', gameId)
          .eq('player_id', playerId);

      print('✅ Privilégios de administrador removidos com sucesso');
      return true;
    } catch (e) {
      print('❌ Erro ao remover privilégios de administrador: $e');
      rethrow;
    }
  }

  /// Buscar todos os administradores de um jogo
  static Future<List<GamePlayer>> getGameAdmins({
    required String gameId,
  }) async {
    try {
      print('🔍 DEBUG - Buscando administradores do jogo: $gameId');

      final response = await _client
          .from('game_players')
          .select('''
            id,
            game_id,
            player_id,
            player_type,
            status,
            is_admin,
            joined_at,
            created_at,
            updated_at,
            players!inner(
              id,
              name,
              phone_number,
              birth_date,
              primary_position,
              secondary_position,
              preferred_foot,
              status,
              user_id
            )
          ''')
          .eq('game_id', gameId)
          .eq('is_admin', true)
          .inFilter('status', ['active', 'confirmed'])
          .order('joined_at', ascending: true);

      print('🔍 DEBUG - Administradores encontrados: ${response.length}');

      return (response as List)
          .map<GamePlayer>((item) => GamePlayer.fromMap(item))
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar administradores do jogo: $e');
      return [];
    }
  }

  /// Verificar se um jogador tem cadastro completo
  /// Um cadastro é considerado completo quando tem:
  /// - birth_date (data de nascimento)
  /// - primary_position (posição principal)
  /// - preferred_foot (pé preferido)
  static Future<bool> hasCompleteProfile(String playerId) async {
    try {
      final response = await _client
          .from('players')
          .select('birth_date, primary_position, preferred_foot')
          .eq('id', playerId)
          .maybeSingle();

      if (response == null) {
        return false;
      }

      // Verificar se todos os campos obrigatórios estão preenchidos
      final hasBirthDate = response['birth_date'] != null &&
          response['birth_date'].toString().isNotEmpty;
      final hasPrimaryPosition = response['primary_position'] != null &&
          response['primary_position'].toString().isNotEmpty;
      final hasPreferredFoot = response['preferred_foot'] != null &&
          response['preferred_foot'].toString().isNotEmpty;

      final isComplete = hasBirthDate && hasPrimaryPosition && hasPreferredFoot;

      print('🔍 Verificação de cadastro completo para jogador $playerId:');
      print('   - Data de nascimento: ${hasBirthDate ? "✅" : "❌"}');
      print('   - Posição principal: ${hasPrimaryPosition ? "✅" : "❌"}');
      print('   - Pé preferido: ${hasPreferredFoot ? "✅" : "❌"}');
      print('   - Cadastro completo: ${isComplete ? "✅" : "❌"}');

      return isComplete;
    } catch (e) {
      print('❌ Erro ao verificar cadastro completo: $e');
      return false;
    }
  }
}
