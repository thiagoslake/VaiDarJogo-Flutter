import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';

class CasualPlayersScreen extends ConsumerStatefulWidget {
  const CasualPlayersScreen({super.key});

  @override
  ConsumerState<CasualPlayersScreen> createState() =>
      _CasualPlayersScreenState();
}

class _CasualPlayersScreenState extends ConsumerState<CasualPlayersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _players = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCasualPlayers();
  }

  Future<void> _loadCasualPlayers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedGame = ref.read(selectedGameProvider);

      if (selectedGame == null) {
        setState(() {
          _error = 'Nenhum jogo selecionado. Selecione um jogo primeiro.';
          _isLoading = false;
        });
        return;
      }

      // Buscar jogadores avulsos do jogo selecionado
      final response = await SupabaseConfig.client
          .from('game_players')
          .select('''
            players:player_id (
              id,
              name,
              phone_number,
              type,
              birth_date,
              primary_position,
              secondary_position,
              preferred_foot,
              status,
              created_at
            )
          ''')
          .eq('game_id', selectedGame.id)
          .eq('status', 'active')
          .eq('players.type', 'casual')
          .eq('players.status', 'active')
          .order('players(name)', ascending: true);

      // Extrair os dados dos jogadores da resposta
      final players = response
          .map<Map<String, dynamic>>((item) {
            final playerData = item['players'] as Map<String, dynamic>?;
            return playerData ?? {};
          })
          .where((player) => player.isNotEmpty)
          .toList();

      setState(() {
        _players = players;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedGame != null
            ? '5️⃣ Avulsos - ${selectedGame.organizationName}'
            : '5️⃣ Consulta Avulsos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCasualPlayers,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _players.isEmpty
                  ? _buildEmptyState()
                  : _buildPlayersList(),
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
                'Erro ao carregar jogadores',
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
                onPressed: _loadCasualPlayers,
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
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.casino_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum jogador avulso encontrado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Não há jogadores avulsos cadastrados.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Jogador'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayersList() {
    return Column(
      children: [
        // Cabeçalho com total
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.casino,
                  color: Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jogadores Avulsos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Total: ${_players.length} jogador(es)',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Lista de jogadores
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _players.length,
            itemBuilder: (context, index) {
              final player = _players[index];
              return _buildPlayerCard(player, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho do jogador
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.red.withOpacity(0.1),
                  child: Text(
                    player['name'][0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player['name'] ?? 'Sem nome',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '🎲 Avulso',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Text(
                    '$index',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informações do jogador
            _buildInfoRow('📱 Telefone', _formatPhone(player['phone_number'])),

            // Informações de cadastro
            _buildInfoRow(
                '📅 Cadastrado em', _formatDateTime(player['created_at'])),
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
            width: 120,
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

  String _formatPhone(String? phone) {
    if (phone == null) return 'N/A';
    if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return dateTime;
    }
  }
}
