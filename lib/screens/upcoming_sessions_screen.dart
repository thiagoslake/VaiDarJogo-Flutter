import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';

class UpcomingSessionsScreen extends ConsumerStatefulWidget {
  const UpcomingSessionsScreen({super.key});

  @override
  ConsumerState<UpcomingSessionsScreen> createState() =>
      _UpcomingSessionsScreenState();
}

class _UpcomingSessionsScreenState
    extends ConsumerState<UpcomingSessionsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
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

      print(
          '🔍 Debug - Carregando sessões para o jogo: ${selectedGame.organizationName} (ID: ${selectedGame.id})');

      // Buscar todas as sessões do jogo selecionado (incluindo todas as datas e status)
      final response = await SupabaseConfig.client
          .from('game_sessions')
          .select('''
            id,
            session_date,
            start_time,
            end_time,
            status,
            notes,
            created_at,
            updated_at
          ''')
          .eq('game_id', selectedGame.id)
          .order('session_date', ascending: true);

      print('🔍 Debug - Sessões encontradas: ${response.length}');

      setState(() {
        _sessions = List<Map<String, dynamic>>.from(response);
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
            ? 'Sessões do Jogo - ${selectedGame.organizationName}'
            : 'Sessões do Jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
            tooltip: 'Atualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _sessions.isEmpty
                  ? _buildEmptyState()
                  : _buildSessionsList(),
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
                'Erro ao carregar sessões',
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
                onPressed: _loadSessions,
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
                Icons.schedule_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma sessão cadastrada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Não há sessões de jogo cadastradas para este jogo.',
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

  Widget _buildSessionsList() {
    return Column(
      children: [
        // Cabeçalho com estatísticas
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      color: Colors.purple,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sessões do Jogo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total: ${_sessions.length} sessão(ões)',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Estatísticas por status
                _buildStatusStatistics(),
              ],
            ),
          ),
        ),

        // Lista de sessões
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _sessions.length,
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return _buildSessionCard(session, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, int index) {
    final selectedGame = ref.watch(selectedGameProvider);
    final sessionDate = DateTime.parse(session['session_date']);
    final formattedDate = _formatDate(sessionDate);
    // Considerar sessões do dia atual como futuras, não passadas
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final sessionDateOnly =
        DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    final isPastSession = sessionDateOnly.isBefore(todayDate);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isPastSession
              ? Border.all(color: Colors.grey.withOpacity(0.3), width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabeçalho da sessão
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPastSession
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isPastSession ? Colors.grey : Colors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedGame?.organizationName ?? 'Jogo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isPastSession ? Colors.grey[600] : null,
                          ),
                        ),
                        Text(
                          selectedGame?.location ?? 'Local não informado',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(session['status']),
                ],
              ),

              const SizedBox(height: 12),

              // Data da sessão (destaque principal)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPastSession
                      ? Colors.grey.withOpacity(0.05)
                      : Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPastSession
                        ? Colors.grey.withOpacity(0.2)
                        : Colors.blue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data principal
                    Row(
                      children: [
                        Icon(
                          isPastSession ? Icons.history : Icons.calendar_today,
                          size: 18,
                          color: isPastSession
                              ? Colors.grey[600]
                              : Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPastSession
                                  ? Colors.grey[600]
                                  : Colors.blue[700],
                            ),
                          ),
                        ),
                        // Indicador de sessão passada/futura
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPastSession
                                ? Colors.grey.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPastSession ? Colors.grey : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isPastSession ? 'Passada' : 'Futura',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPastSession
                                  ? Colors.grey[600]
                                  : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Horários de início e fim (destaque)
                    Row(
                      children: [
                        // Horário de início
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.play_arrow,
                                      size: 14,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Início',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(session['start_time']),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isPastSession
                                        ? Colors.grey[600]
                                        : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Horário de fim
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.stop,
                                      size: 14,
                                      color: Colors.red[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Fim',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTime(session['end_time']),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isPastSession
                                        ? Colors.grey[600]
                                        : Colors.red[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Notas (se existirem)
              if (session['notes'] != null &&
                  session['notes'].toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Notas: ${session['notes']}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusStatistics() {
    final statusCounts = <String, int>{};
    for (var session in _sessions) {
      final status = session['status'] ?? 'unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: statusCounts.entries.map((entry) {
        final status = entry.key;
        final count = entry.value;
        return _buildStatusChip(status, showCount: true, count: count);
      }).toList(),
    );
  }

  Widget _buildStatusChip(String? status,
      {bool showCount = false, int? count}) {
    Color color;
    IconData icon;

    switch (status?.toLowerCase()) {
      case 'active':
        color = Colors.green;
        icon = Icons.play_circle_outline;
        break;
      case 'paused':
        color = Colors.orange;
        icon = Icons.pause_circle_outline;
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case 'completed':
        color = Colors.blue;
        icon = Icons.check_circle_outline;
        break;
      case 'confirmed':
        color = Colors.teal;
        icon = Icons.verified;
        break;
      case 'in_progress':
        color = Colors.amber;
        icon = Icons.hourglass_empty;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            showCount
                ? '${_getStatusText(status)} ($count)'
                : _getStatusText(status),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final weekdays = [
      'Domingo',
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado'
    ];

    final months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro'
    ];

    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');

    return '$weekday, $day de $month de ${date.year}';
  }

  String _formatTime(String? time) {
    if (time == null || time.isEmpty) return '--:--';
    try {
      final parts = time.split(':');
      if (parts.length >= 2) {
        // Garantir que horas e minutos tenham 2 dígitos
        final hour = parts[0].padLeft(2, '0');
        final minute = parts[1].padLeft(2, '0');
        return '$hour:$minute';
      }
      return time;
    } catch (e) {
      return '--:--';
    }
  }

  String _getStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return 'Ativa';
      case 'paused':
        return 'Pausada';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Concluída';
      case 'confirmed':
        return 'Confirmada';
      case 'in_progress':
        return 'Em Andamento';
      default:
        return status ?? 'Não definido';
    }
  }
}
