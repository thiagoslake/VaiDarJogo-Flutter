import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../config/supabase_config.dart';

class AdminRequestsScreen extends ConsumerStatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  ConsumerState<AdminRequestsScreen> createState() =>
      _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends ConsumerState<AdminRequestsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _requests = [];
  String? _error;
  String _filter = 'pending'; // 'pending', 'approved', 'rejected'

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

      // Buscar solicitações para jogos que o usuário administra
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
            ),
            users:user_id (
              id,
              name,
              email,
              phone,
              created_at,
              last_login_at,
              is_active
            )
          ''')
          .eq('games.user_id', currentUser.id)
          .order('requested_at', ascending: false);

      // Buscar dados dos jogadores separadamente para cada solicitação
      final List<Map<String, dynamic>> requestsWithPlayers = [];

      for (final request in response) {
        final userId = request['user_id'];
        if (userId != null) {
          try {
            // Buscar dados do jogador
            final playerResponse =
                await SupabaseConfig.client.from('players').select('''
                  id,
                  name,
                  phone_number,
                  type,
                  birth_date,
                  primary_position,
                  secondary_position,
                  preferred_foot,
                  status
                ''').eq('user_id', userId).maybeSingle();

            // Adicionar dados do jogador à solicitação
            final requestWithPlayer = Map<String, dynamic>.from(request);
            requestWithPlayer['player'] = playerResponse;
            requestsWithPlayers.add(requestWithPlayer);
          } catch (e) {
            // Se não conseguir buscar o jogador, adicionar sem dados do jogador
            final requestWithPlayer = Map<String, dynamic>.from(request);
            requestWithPlayer['player'] = null;
            requestsWithPlayers.add(requestWithPlayer);
          }
        } else {
          requestsWithPlayers.add(request);
        }
      }

      setState(() {
        _requests = requestsWithPlayers;
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

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _ApprovalDialog(request: request),
    );

    if (result != null) {
      try {
        // Chamar função do banco para aprovar
        await SupabaseConfig.client
            .rpc('approve_participation_request', params: {
          'request_id': request['id'],
          'response_msg': result['message'],
          'player_type': result['playerType'],
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Solicitação aprovada! Jogador adicionado como ${result['playerType'] == 'monthly' ? 'mensalista' : 'avulso'}.'),
              backgroundColor: Colors.green,
            ),
          );
          _loadRequests(); // Recarregar lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao aprovar solicitação: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectionDialog(),
    );

    if (result != null) {
      try {
        // Chamar função do banco para rejeitar
        await SupabaseConfig.client
            .rpc('reject_participation_request', params: {
          'request_id': request['id'],
          'response_msg': result,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitação rejeitada.'),
              backgroundColor: Colors.orange,
            ),
          );
          _loadRequests(); // Recarregar lista
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao rejeitar solicitação: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                      ButtonSegment(
                        value: 'all',
                        label: Text('Todas'),
                        icon: Icon(Icons.list),
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
                    ? 'Você ainda não recebeu nenhuma solicitação de participação'
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
    final user = request['users'] as Map<String, dynamic>?;
    final player = request['players'] as Map<String, dynamic>?;
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

            const SizedBox(height: 16),

            // Dados do usuário
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dados do Usuário',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerInfoRow('👤 Nome', user['name'] ?? 'N/A'),
                    _buildPlayerInfoRow('📧 Email', user['email'] ?? 'N/A'),
                    _buildPlayerInfoRow(
                        '📱 Telefone', _formatPhone(user['phone'])),
                    _buildPlayerInfoRow(
                        '📅 Cadastrado em', _formatDate(user['created_at'])),
                    _buildPlayerInfoRow(
                        '🔄 Último Login', _formatDate(user['last_login_at'])),
                    _buildPlayerInfoRow('✅ Status',
                        user['is_active'] == true ? 'Ativo' : 'Inativo'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Dados do perfil de jogador
            if (player != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Perfil de Jogador',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildPlayerInfoRow('👤 Nome', player['name'] ?? 'N/A'),
                    _buildPlayerInfoRow(
                        '📱 Telefone', _formatPhone(player['phone_number'])),
                    _buildPlayerInfoRow('🎯 Tipo',
                        player['type'] == 'monthly' ? 'Mensalista' : 'Avulso'),
                    _buildPlayerInfoRow('🎂 Data de Nascimento',
                        _formatDate(player['birth_date'])),
                    _buildPlayerInfoRow('⚽ Posição Principal',
                        player['primary_position'] ?? 'N/A'),
                    _buildPlayerInfoRow('🔄 Posição Secundária',
                        player['secondary_position'] ?? 'N/A'),
                    _buildPlayerInfoRow(
                        '🦵 Pé Preferido', player['preferred_foot'] ?? 'N/A'),
                    _buildPlayerInfoRow('✅ Status',
                        player['status'] == 'active' ? 'Ativo' : 'Inativo'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveRequest(request),
                      icon: const Icon(Icons.check),
                      label: const Text('Aprovar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _rejectRequest(request),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              ),
            ),
          ),
        ],
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

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
    }
    return phone;
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

class _ApprovalDialog extends StatefulWidget {
  final Map<String, dynamic> request;

  const _ApprovalDialog({required this.request});

  @override
  State<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends State<_ApprovalDialog> {
  String _selectedPlayerType = 'casual'; // Padrão: avulso
  final _messageController = TextEditingController();

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'N/A';
    if (phone.length == 11) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 7)}-${phone.substring(7)}';
    } else if (phone.length == 10) {
      return '(${phone.substring(0, 2)}) ${phone.substring(2, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.request['users'] as Map<String, dynamic>?;
    final player = widget.request['players'] as Map<String, dynamic>?;
    final game = widget.request['games'] as Map<String, dynamic>?;

    return AlertDialog(
      title: const Text('Aprovar Solicitação'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do jogador
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usuário: ${user?['name'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Email: ${user?['email'] ?? 'N/A'}'),
                  Text('Telefone: ${_formatPhone(user?['phone'])}'),
                  if (player != null) ...[
                    const SizedBox(height: 8),
                    const Text('Perfil de Jogador:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                        'Tipo: ${player['type'] == 'monthly' ? 'Mensalista' : 'Avulso'}'),
                    Text('Posição: ${player['primary_position'] ?? 'N/A'}'),
                    Text('Pé: ${player['preferred_foot'] ?? 'N/A'}'),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Informações do jogo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jogo: ${game?['organization_name'] ?? 'N/A'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Local: ${game?['location'] ?? 'N/A'}'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Seleção do tipo de jogador
            const Text(
              'Tipo de Jogador:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: const Text('🎲 Avulso'),
              subtitle: const Text('Jogador eventual'),
              value: 'casual',
              groupValue: _selectedPlayerType,
              onChanged: (value) {
                setState(() {
                  _selectedPlayerType = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('📅 Mensalista'),
              subtitle: const Text('Jogador fixo mensal'),
              value: 'monthly',
              groupValue: _selectedPlayerType,
              onChanged: (value) {
                setState(() {
                  _selectedPlayerType = value!;
                });
              },
            ),

            const SizedBox(height: 16),

            // Mensagem opcional
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Mensagem (opcional)',
                hintText: 'Mensagem de boas-vindas para o jogador',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop({
              'playerType': _selectedPlayerType,
              'message': _messageController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Aprovar'),
        ),
      ],
    );
  }
}

class _RejectionDialog extends StatefulWidget {
  @override
  State<_RejectionDialog> createState() => _RejectionDialogState();
}

class _RejectionDialogState extends State<_RejectionDialog> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejeitar Solicitação'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tem certeza que deseja rejeitar esta solicitação?',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Motivo da rejeição (opcional)',
              hintText: 'Explique o motivo da rejeição',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(_messageController.text.trim());
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Rejeitar'),
        ),
      ],
    );
  }
}
