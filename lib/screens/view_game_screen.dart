import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';

class ViewGameScreen extends ConsumerStatefulWidget {
  const ViewGameScreen({super.key});

  @override
  ConsumerState<ViewGameScreen> createState() => _ViewGameScreenState();
}

class _ViewGameScreenState extends ConsumerState<ViewGameScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _game;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGame();
  }

  Future<void> _loadGame() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) {
        setState(() {
          _error = 'Nenhum jogo selecionado';
          _isLoading = false;
        });
        return;
      }

      // Buscar o jogo selecionado
      final response = await SupabaseConfig.client
          .from('games')
          .select('*')
          .eq('id', selectedGame.id)
          .single();

      setState(() {
        _game = response;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('2️⃣ Visualizar Jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadGame,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _game == null
                  ? _buildNoGameState()
                  : _buildGameInfo(),
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
                'Erro ao carregar jogo',
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
                onPressed: _loadGame,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoGameState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_soccer_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum jogo configurado',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure um jogo primeiro para visualizar suas características.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.add),
                label: const Text('Configurar Jogo'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(
                    Icons.sports_soccer,
                    size: 48,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _game!['organization_name'] ?? 'Sem nome',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${_game!['status'] ?? 'N/A'}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Informações da Organização
          _buildInfoCard(
            title: '🏢 Informações da Organização',
            children: [
              _buildInfoRow('Nome', _game!['organization_name'] ?? 'N/A'),
              _buildInfoRow('Local', _game!['location'] ?? 'N/A'),
              if (_game!['address'] != null)
                _buildInfoRow('Endereço', _game!['address']),
            ],
          ),

          const SizedBox(height: 16),

          // Configuração dos Times
          _buildInfoCard(
            title: '⚽ Configuração dos Times',
            children: [
              _buildInfoRow('Jogadores por Time',
                  '${_game!['players_per_team'] ?? 'N/A'}'),
              _buildInfoRow('Reservas por Time',
                  '${_game!['substitutes_per_team'] ?? 'N/A'}'),
              _buildInfoRow(
                  'Número de Times', '${_game!['number_of_teams'] ?? 'N/A'}'),
            ],
          ),

          const SizedBox(height: 16),

          // Data e Horário
          _buildInfoCard(
            title: '📅 Data e Horário',
            children: [
              _buildInfoRow('Data do Jogo', _formatDate(_game!['game_date'])),
              _buildInfoRow(
                  'Horário de Início', _formatTime(_game!['start_time'])),
              _buildInfoRow('Horário de Fim', _formatTime(_game!['end_time'])),
              if (_game!['day_of_week'] != null)
                _buildInfoRow('Dia da Semana', _game!['day_of_week']),
              _buildInfoRow('Frequência', _game!['frequency'] ?? 'N/A'),
            ],
          ),

          const SizedBox(height: 16),

          // Configuração de Preços
          if (_game!['price_config'] != null)
            _buildInfoCard(
              title: '💰 Configuração de Preços',
              children: [
                _buildInfoRow(
                    'Preço Mensalista',
                    _formatPrice(
                        _game!['price_config']['monthly_player_price'])),
                _buildInfoRow(
                    'Preço Avulso',
                    _formatPrice(
                        _game!['price_config']['casual_player_price'])),
              ],
            ),

          const SizedBox(height: 16),

          // Informações do Sistema
          _buildInfoCard(
            title: 'ℹ️ Informações do Sistema',
            children: [
              _buildInfoRow('ID do Jogo', _game!['id']),
              _buildInfoRow('Criado em', _formatDateTime(_game!['created_at'])),
              _buildInfoRow(
                  'Atualizado em', _formatDateTime(_game!['updated_at'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    } catch (e) {
      return date;
    }
  }

  String _formatTime(String? time) {
    if (time == null) return 'N/A';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return time;
    } catch (e) {
      return time;
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    return 'R\$ ${price.toStringAsFixed(2)}';
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}
