import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';

class ParticipationRequestsScreen extends ConsumerStatefulWidget {
  const ParticipationRequestsScreen({super.key});

  @override
  ConsumerState<ParticipationRequestsScreen> createState() =>
      _ParticipationRequestsScreenState();
}

class _ParticipationRequestsScreenState
    extends ConsumerState<ParticipationRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
  String? _error;
  String _filter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) return;

      // Buscar solicitações do usuário
      final response = await SupabaseConfig.client
          .from('participation_requests')
          .select('''
            id,
            status,
            requested_at,
            responded_at,
            response_message,
            games:game_id (
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
              frequency
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('requested_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_filter == 'all') return _requests;
    return _requests.where((request) => request['status'] == _filter).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pendente';
      case 'approved':
        return 'Aprovado';
      case 'rejected':
        return 'Rejeitado';
      default:
        return 'Desconhecido';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitações de Participação'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'all',
                        label: Text('Todas'),
                        icon: Icon(Icons.list),
                      ),
                      ButtonSegment(
                        value: 'pending',
                        label: Text('Pendentes'),
                        icon: Icon(Icons.pending),
                      ),
                      ButtonSegment(
                        value: 'approved',
                        label: Text('Aprovadas'),
                        icon: Icon(Icons.check),
                      ),
                      ButtonSegment(
                        value: 'rejected',
                        label: Text('Rejeitadas'),
                        icon: Icon(Icons.close),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _filter = selection.first;
                      });
                    },
                  ),
                ),
              ],
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

    if (_filteredRequests.isEmpty && !_isLoading) {
      return _buildEmptyState();
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        final request = _filteredRequests[index];
        return _buildRequestCard(request);
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
                'Erro ao carregar solicitações',
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
                onPressed: _loadRequests,
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
    String message;
    IconData icon;

    switch (_filter) {
      case 'pending':
        message = 'Nenhuma solicitação pendente';
        icon = Icons.pending_outlined;
        break;
      case 'approved':
        message = 'Nenhuma solicitação aprovada';
        icon = Icons.check_circle_outline;
        break;
      case 'rejected':
        message = 'Nenhuma solicitação rejeitada';
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Nenhuma solicitação encontrada';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _filter == 'all'
                    ? 'Você ainda não enviou nenhuma solicitação de participação'
                    : 'Tente alterar o filtro para ver outras solicitações',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final game = request['games'] as Map<String, dynamic>?;
    final status = request['status'] as String;
    final statusColor = _getStatusColor(status);
    final statusText = _getStatusText(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho com status
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor,
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        game?['organization_name'] ?? 'Jogo não encontrado',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '📍 ${game?['location'] ?? 'Local não informado'}',
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
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: const TextStyle(
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
            if (game != null) ...[
              _buildInfoRow(
                  '📅 Dia da Semana', game['day_of_week'] ?? 'Não informado'),
              _buildInfoRow('🕐 Horário',
                  _formatTime(game['start_time'], game['end_time'])),
              _buildInfoRow('⚽ Jogadores por Time',
                  '${game['players_per_team'] ?? 'N/A'}'),
              _buildInfoRow(
                  '🔄 Frequência', game['frequency'] ?? 'Não informado'),
            ],

            const SizedBox(height: 12),

            // Informações da solicitação
            _buildInfoRow('📅 Data da Solicitação',
                _formatDateTime(request['requested_at'])),

            if (request['responded_at'] != null)
              _buildInfoRow('📅 Data da Resposta',
                  _formatDateTime(request['responded_at'])),

            if (request['response_message'] != null &&
                request['response_message'].toString().isNotEmpty)
              _buildInfoRow('💬 Mensagem', request['response_message']),

            // Ações baseadas no status
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sua solicitação está aguardando aprovação do administrador do jogo.',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'approved') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Parabéns! Sua solicitação foi aprovada. Você agora pode participar deste jogo.',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (status == 'rejected') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sua solicitação foi rejeitada. Você pode tentar novamente ou buscar outros jogos.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'N/A';
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year} às ${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}
