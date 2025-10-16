import '../config/supabase_config.dart';
import '../models/user_model.dart';

class UserService {
  static final _client = SupabaseConfig.client;

  /// Buscar jogadores disponíveis para adicionar ao jogo (não estão no jogo)
  static Future<List<User>> getAvailableUsersForGame(String gameId) async {
    try {
      // Buscar todos os jogadores ativos da tabela players
      final allPlayersData = await getAllPlayers();

      // Filtrar jogadores que não estão no jogo
      final availablePlayers = <User>[];

      for (final playerData in allPlayersData) {
        final isInGame = await isPlayerInGame(playerData['id'], gameId);
        if (!isInGame) {
          // Converter dados do player para User para manter compatibilidade
          final user = User(
            id: playerData['user_id'],
            name: playerData['name'],
            email: '', // Será preenchido se necessário
            phone: playerData['phone_number'],
            isActive: true,
            createdAt: DateTime.parse(playerData['created_at']),
          );
          availablePlayers.add(user);
        }
      }

      return availablePlayers;
    } catch (e) {
      print('❌ Erro ao buscar jogadores disponíveis para o jogo: $e');
      return [];
    }
  }

  /// Buscar todos os jogadores da tabela players
  static Future<List<Map<String, dynamic>>> getAllPlayers() async {
    try {
      final response = await _client.from('players').select('''
            id,
            name,
            phone_number,
            user_id,
            status,
            created_at
          ''').eq('status', 'active').order('name', ascending: true);

      return response;
    } catch (e) {
      print('❌ Erro ao buscar jogadores: $e');
      return [];
    }
  }

  /// Verificar se um jogador está no jogo
  static Future<bool> isPlayerInGame(String playerId, String gameId) async {
    try {
      final response = await _client
          .from('game_players')
          .select('id')
          .eq('player_id', playerId)
          .eq('game_id', gameId)
          .inFilter('status', ['active', 'confirmed']).maybeSingle();

      return response != null;
    } catch (e) {
      print('❌ Erro ao verificar se jogador está no jogo: $e');
      return false;
    }
  }
}
