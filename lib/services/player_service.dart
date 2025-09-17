import '../models/player_model.dart';
import '../config/supabase_config.dart';

class PlayerService {
  static final _client = SupabaseConfig.client;

  /// Criar um novo perfil de jogador
  static Future<Player?> createPlayer({
    required String userId,
    required String name,
    required String phoneNumber,
    String type = 'casual',
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
        'type': type,
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
      rethrow;
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
    String? type,
    DateTime? birthDate,
    String? primaryPosition,
    String? secondaryPosition,
    String? preferredFoot,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (type != null) updateData['type'] = type;
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

        final response = await _client
            .from('players')
            .update(updateData)
            .eq('id', playerId)
            .select()
            .single();

        return Player.fromMap(response);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao atualizar jogador: $e');
      rethrow;
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
}
