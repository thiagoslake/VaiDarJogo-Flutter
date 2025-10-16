import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';

class GameSearchScreen extends ConsumerStatefulWidget {
  const GameSearchScreen({super.key});

  @override
  ConsumerState<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends ConsumerState<GameSearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _games = [];
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchGames() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final searchTerm = _searchController.text.trim();

      // Se não há termo de busca, listar todos os jogos ativos
      if (searchTerm.isEmpty) {
        final response = await SupabaseConfig.client
            .from('games')
            .select('''
              id,
              organization_name,
              location,
              address,
              status,
              created_at,
              players_per_team,
              substitutes_per_team,
              number_of_teams,
              start_time,
              end_time,
              game_date,
              day_of_week,
              frequency,
              user_id
            ''')
            .eq('status', 'active')
            .order('created_at', ascending: false)
            .limit(50);

        setState(() {
          _games = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      } else {
        // Buscar jogos públicos que correspondem ao termo de busca
        final response = await SupabaseConfig.client
            .from('games')
            .select('''
              id,
              organization_name,
              location,
              address,
              status,
              created_at,
              players_per_team,
              substitutes_per_team,
              number_of_teams,
              start_time,
              end_time,
              game_date,
              day_of_week,
              frequency,
              user_id
            ''')
            .eq('status', 'active')
            .or('organization_name.ilike.%$searchTerm%,location.ilike.%$searchTerm%')
            .order('created_at', ascending: false)
            .limit(20);

        setState(() {
          _games = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestParticipation(Map<String, dynamic> game) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Verificar se já está participando
    try {
      // Primeiro, buscar o player_id do usuário
      final playerResponse = await SupabaseConfig.client
          .from('players')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (playerResponse == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Usuário não possui perfil de jogador. Crie um perfil primeiro.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final existingParticipation = await SupabaseConfig.client
          .from('game_players')
          .select('id')
          .eq('game_id', game['id'])
          .eq('player_id', playerResponse['id'])
          .maybeSingle();

      if (existingParticipation != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você já está participando deste jogo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      // Ignorar erro de verificação
    }

    // Mostrar diálogo de confirmação
    final confirmed = await _showParticipationDialog(game);
    if (!confirmed) return;

    try {
      // Criar solicitação de participação
      await SupabaseConfig.client.from('participation_requests').insert({
        'game_id': game['id'],
        'user_id': currentUser.id,
        'status': 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Solicitação enviada com sucesso! Aguarde aprovação do administrador.'),
            backgroundColor: Colors.green,
          ),
        );

        // Retornar para a tela anterior com indicação de mudança
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar solicitação: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showParticipationDialog(Map<String, dynamic> game) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Solicitar Participação'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Você deseja solicitar participação no jogo:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['organization_name'] ?? 'Sem nome',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('📍 ${game['location'] ?? 'Local não informado'}'),
                      if (game['day_of_week'] != null)
                        Text('📅 ${game['day_of_week']}'),
                      if (game['start_time'] != null)
                        Text('🕐 ${game['start_time']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Sua solicitação será enviada para o administrador do jogo para aprovação.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Solicitar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Jogos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Barra de busca
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar jogos...',
                      hintText:
                          'Digite o nome da organização ou local (deixe vazio para listar todos)',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchGames(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _searchGames,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
          ),

          // Botão para listar todos os jogos
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        _searchController.clear();
                        _searchGames();
                      },
                icon: const Icon(Icons.list),
                label: const Text('Listar Todos os Jogos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Resultados
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_games.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return _buildGameCard(game);
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro na busca',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _searchGames,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final hasSearched = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                hasSearched ? Icons.search_off : Icons.sports_soccer_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                hasSearched
                    ? 'Nenhum jogo encontrado'
                    : 'Nenhum jogo cadastrado',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasSearched
                    ? 'Tente usar outros termos de busca'
                    : 'Não há jogos disponíveis no momento',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (!hasSearched) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _searchGames,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar Lista'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do jogo
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.sports_soccer,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game['organization_name'] ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '📍 ${game['location'] ?? 'Local não informado'}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Ativo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações do jogo
            _buildInfoRow(
                '📅 Dia da Semana', game['day_of_week'] ?? 'Não informado'),
            _buildInfoRow('🕐 Horário',
                _formatTime(game['start_time'], game['end_time'])),
            _buildInfoRow(
                '⚽ Jogadores por Time', '${game['players_per_team'] ?? 'N/A'}'),
            _buildInfoRow('🔄 Reservas por Time',
                '${game['substitutes_per_team'] ?? 'N/A'}'),
            _buildInfoRow(
                '🏟️ Número de Times', '${game['number_of_teams'] ?? 'N/A'}'),
            _buildInfoRow(
                '🔄 Frequência', game['frequency'] ?? 'Não informado'),

            const SizedBox(height: 16),

            // Botão de solicitação
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _requestParticipation(game),
                icon: const Icon(Icons.person_add),
                label: const Text('Solicitar Participação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? startTime, String? endTime) {
    if (startTime == null && endTime == null) return 'Não informado';
    if (startTime == null) return 'Até $endTime';
    if (endTime == null) return 'A partir de $startTime';
    return '$startTime - $endTime';
  }
}
