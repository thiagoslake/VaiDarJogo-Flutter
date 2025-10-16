import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import 'auth_provider.dart';

// Modelo para representar um jogo
class Game {
  final String id;
  final String userId;
  final String organizationName;
  final String location;
  final String? address;
  final String status;
  final DateTime createdAt;
  final int? playersPerTeam;
  final int? substitutesPerTeam;
  final int? numberOfTeams;
  final String? startTime;
  final String? endTime;
  final String? gameDate;
  final String? dayOfWeek;
  final String? frequency;
  final String? endDate;
  final Map<String, dynamic>? priceConfig;

  Game({
    required this.id,
    required this.userId,
    required this.organizationName,
    required this.location,
    this.address,
    required this.status,
    required this.createdAt,
    this.playersPerTeam,
    this.substitutesPerTeam,
    this.numberOfTeams,
    this.startTime,
    this.endTime,
    this.gameDate,
    this.dayOfWeek,
    this.frequency,
    this.endDate,
    this.priceConfig,
  });

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      id: map['id'].toString(),
      userId: map['user_id'] ?? '',
      organizationName: map['organization_name'] ?? '',
      location: map['location'] ?? '',
      address: map['address'],
      status: map['status'] ?? 'inactive',
      createdAt: DateTime.parse(map['created_at']),
      playersPerTeam: map['players_per_team'],
      substitutesPerTeam: map['substitutes_per_team'],
      numberOfTeams: map['number_of_teams'],
      startTime: map['start_time'],
      endTime: map['end_time'],
      gameDate: map['game_date'],
      dayOfWeek: map['day_of_week'],
      frequency: map['frequency'],
      endDate: map['end_date'],
      priceConfig: map['price_config'] != null
          ? Map<String, dynamic>.from(map['price_config'])
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Game && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  String get displayName => '$organizationName - $location';
}

// Provider para a lista de jogos do usuário atual
final gamesListProvider = FutureProvider<List<Game>>((ref) async {
  try {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return [];
    }

    final response = await SupabaseConfig.client
        .from('games')
        .select(
            'id, user_id, organization_name, location, address, status, created_at, players_per_team, substitutes_per_team, number_of_teams, start_time, end_time, game_date, day_of_week, frequency, end_date, price_config')
        .eq('user_id', currentUser.id)
        .order('created_at', ascending: false);

    final games = response.map<Game>((game) => Game.fromMap(game)).toList();

    // Remover duplicatas baseado no ID
    final uniqueGames = <String, Game>{};
    for (final game in games) {
      uniqueGames[game.id] = game;
    }

    return uniqueGames.values.toList();
  } catch (e) {
    print('❌ Erro ao carregar jogos: $e');
    return [];
  }
});

// Provider para o jogo selecionado
final selectedGameProvider = StateProvider<Game?>((ref) => null);

// Provider para verificar se há jogos disponíveis
final hasGamesProvider = Provider<bool>((ref) {
  final gamesAsync = ref.watch(gamesListProvider);
  return gamesAsync.when(
    data: (games) => games.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

// Provider para obter todos os jogos ativos do usuário atual
final activeGamesProvider = FutureProvider<List<Game>>((ref) async {
  try {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return [];
    }

    final response = await SupabaseConfig.client
        .from('games')
        .select(
            'id, user_id, organization_name, location, address, status, created_at, players_per_team, substitutes_per_team, number_of_teams, start_time, end_time, game_date, day_of_week, frequency, end_date, price_config')
        .eq('user_id', currentUser.id)
        .eq('status', 'active')
        .order('created_at', ascending: false);

    return response.map<Game>((game) => Game.fromMap(game)).toList();
  } catch (e) {
    print('❌ Erro ao buscar jogos ativos: $e');
    return [];
  }
});

// Provider para obter o jogo ativo mais recente do usuário atual (compatibilidade)
final activeGameProvider = FutureProvider<Game?>((ref) async {
  final activeGames = await ref.watch(activeGamesProvider.future);
  return activeGames.isNotEmpty ? activeGames.first : null;
});
