import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import 'selected_game_provider.dart';

// Provider para gerenciar atualizações de status do jogo
class GameStatusNotifier extends StateNotifier<AsyncValue<void>> {
  GameStatusNotifier() : super(const AsyncValue.data(null));

  /// Atualiza o status de um jogo específico
  Future<void> updateGameStatus(String gameId, String newStatus) async {
    state = const AsyncValue.loading();

    try {
      // Atualizar status no banco de dados
      await SupabaseConfig.client
          .from('games')
          .update({'status': newStatus}).eq('id', gameId);

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Ativa um jogo
  Future<void> activateGame(String gameId) async {
    await updateGameStatus(gameId, 'active');
  }

  /// Inativa um jogo
  Future<void> deactivateGame(String gameId) async {
    await updateGameStatus(gameId, 'inactive');
  }

  /// Alterna o status de um jogo (ativo <-> inativo)
  Future<void> toggleGameStatus(String gameId, String currentStatus) async {
    final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
    await updateGameStatus(gameId, newStatus);
  }
}

// Provider para o notifier de status
final gameStatusProvider =
    StateNotifierProvider<GameStatusNotifier, AsyncValue<void>>((ref) {
  return GameStatusNotifier();
});

// Provider para obter o status atual de um jogo específico
final gameStatusProviderFuture =
    FutureProvider.family<String, String>((ref, gameId) async {
  try {
    final response = await SupabaseConfig.client
        .from('games')
        .select('status')
        .eq('id', gameId)
        .single();

    return response['status'] as String;
  } catch (e) {
    throw Exception('Erro ao buscar status do jogo: $e');
  }
});

// Provider para verificar se um jogo está ativo
final isGameActiveProvider =
    FutureProvider.family<bool, String>((ref, gameId) async {
  final status = await ref.watch(gameStatusProviderFuture(gameId).future);
  return status == 'active';
});

// Provider para obter informações completas de um jogo
final gameInfoProvider =
    FutureProvider.family<Game?, String>((ref, gameId) async {
  try {
    final response = await SupabaseConfig.client
        .from('games')
        .select(
            'id, user_id, organization_name, location, address, status, created_at, players_per_team, substitutes_per_team, number_of_teams, start_time, end_time, game_date, day_of_week, frequency, end_date, price_config')
        .eq('id', gameId)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return Game.fromMap(response);
  } catch (e) {
    print('❌ Erro ao buscar informações do jogo $gameId: $e');
    return null;
  }
});
