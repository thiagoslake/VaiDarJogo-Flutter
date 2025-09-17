import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';
import '../providers/game_status_provider.dart';
import '../services/session_management_service.dart';

class EditGameScreen extends ConsumerStatefulWidget {
  const EditGameScreen({super.key});

  @override
  ConsumerState<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends ConsumerState<EditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers para os campos
  final _organizationNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _playersPerTeamController = TextEditingController();
  final _substitutesPerTeamController = TextEditingController();
  final _numberOfTeamsController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _gameDateController = TextEditingController();

  // Valores selecionados
  String _selectedFrequency = 'Jogo Avulso';
  String _selectedDayOfWeek = '';
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  DateTime _selectedDate = DateTime.now();

  final List<String> _frequencies = [
    'Diária',
    'Semanal',
    'Mensal',
    'Anual',
    'Jogo Avulso'
  ];

  final List<String> _daysOfWeek = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  void _loadGameData() {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame != null) {
      _organizationNameController.text = selectedGame.organizationName;
      _locationController.text = selectedGame.location;
      _addressController.text = selectedGame.address ?? '';
      _playersPerTeamController.text =
          selectedGame.playersPerTeam?.toString() ?? '7';
      _substitutesPerTeamController.text =
          selectedGame.substitutesPerTeam?.toString() ?? '3';
      _numberOfTeamsController.text =
          selectedGame.numberOfTeams?.toString() ?? '4';

      if (selectedGame.startTime != null) {
        final startTimeParts = selectedGame.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(startTimeParts[0]),
          minute: int.parse(startTimeParts[1]),
        );
        _startTimeController.text = selectedGame.startTime!;
      }

      if (selectedGame.endTime != null) {
        final endTimeParts = selectedGame.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(endTimeParts[0]),
          minute: int.parse(endTimeParts[1]),
        );
        _endTimeController.text = selectedGame.endTime!;
      }

      if (selectedGame.gameDate != null) {
        _selectedDate = DateTime.parse(selectedGame.gameDate!);
        _gameDateController.text = _formatDate(_selectedDate);
      }

      _selectedFrequency = selectedGame.frequency ?? 'Jogo Avulso';
      _selectedDayOfWeek =
          _mapDayOfWeekFromDatabase(selectedGame.dayOfWeek ?? '');
    }
  }

  /// Mapeia o dia da semana do banco de dados para o formato da interface
  String _mapDayOfWeekFromDatabase(String? dayFromDb) {
    if (dayFromDb == null || dayFromDb.isEmpty) return '';

    print('🔄 Mapeando dia da semana: "$dayFromDb"');

    // Mapear valores do banco para valores da interface
    switch (dayFromDb) {
      case 'Segunda':
        print('✅ Mapeado para: Segunda-feira');
        return 'Segunda-feira';
      case 'Terça':
        print('✅ Mapeado para: Terça-feira');
        return 'Terça-feira';
      case 'Quarta':
        print('✅ Mapeado para: Quarta-feira');
        return 'Quarta-feira';
      case 'Quinta':
        print('✅ Mapeado para: Quinta-feira');
        return 'Quinta-feira';
      case 'Sexta':
        print('✅ Mapeado para: Sexta-feira');
        return 'Sexta-feira';
      case 'Sábado':
        print('✅ Mapeado para: Sábado');
        return 'Sábado';
      case 'Domingo':
        print('✅ Mapeado para: Domingo');
        return 'Domingo';
      default:
        // Se já estiver no formato correto, retorna como está
        if (_daysOfWeek.contains(dayFromDb)) {
          print('✅ Já está no formato correto: $dayFromDb');
          return dayFromDb;
        }
        print('⚠️ Dia não reconhecido: $dayFromDb');
        return '';
    }
  }

  /// Mapeia o dia da semana da interface para o formato do banco de dados
  String _mapDayOfWeekToDatabase(String dayFromUI) {
    if (dayFromUI.isEmpty) return '';

    // Mapear valores da interface para valores do banco
    switch (dayFromUI) {
      case 'Segunda-feira':
        return 'Segunda';
      case 'Terça-feira':
        return 'Terça';
      case 'Quarta-feira':
        return 'Quarta';
      case 'Quinta-feira':
        return 'Quinta';
      case 'Sexta-feira':
        return 'Sexta';
      case 'Sábado':
        return 'Sábado';
      case 'Domingo':
        return 'Domingo';
      default:
        return dayFromUI;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Converte data do formato brasileiro (DD/MM/YYYY) para formato PostgreSQL (YYYY-MM-DD)
  String _convertDateToPostgreSQL(String brazilianDate) {
    if (brazilianDate.isEmpty) return '';

    try {
      final parts = brazilianDate.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      print('❌ Erro ao converter data: $e');
    }

    return brazilianDate; // Retorna original se não conseguir converter
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          _startTimeController.text = _formatTime(picked);
        } else {
          _endTime = picked;
          _endTimeController.text = _formatTime(picked);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _gameDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _updateGame() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Nenhum jogo selecionado'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final gameData = {
        'organization_name': _organizationNameController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'players_per_team': int.parse(_playersPerTeamController.text),
        'substitutes_per_team': int.parse(_substitutesPerTeamController.text),
        'number_of_teams': int.parse(_numberOfTeamsController.text),
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'game_date': _convertDateToPostgreSQL(_gameDateController.text),
        'day_of_week': _selectedDayOfWeek.isEmpty
            ? null
            : _mapDayOfWeekToDatabase(_selectedDayOfWeek),
        'frequency': _selectedFrequency,
      };

      print('📝 Atualizando jogo com dados: $gameData');

      // Atualizar jogo no banco
      await SupabaseConfig.client
          .from('games')
          .update(gameData)
          .eq('id', selectedGame.id);

      // Recriar sessões baseadas nas novas configurações
      try {
        print('🔄 Recriando sessões para o jogo atualizado...');
        final gameDataWithId = {
          ...gameData,
          'id': selectedGame.id,
        };
        final sessionResult =
            await SessionManagementService.recreateGameSessions(
                selectedGame.id, gameDataWithId);

        if (sessionResult['success']) {
          print(
              '✅ Sessões recriadas: ${sessionResult['removed_sessions']} removidas, ${sessionResult['created_sessions']} criadas');
        } else {
          print('⚠️ Erro ao recriar sessões: ${sessionResult['error']}');
        }
      } catch (sessionError) {
        print('⚠️ Erro ao recriar sessões: $sessionError');
        // Não falha a atualização do jogo se houver erro nas sessões
      }

      // Atualizar providers
      ref.invalidate(gamesListProvider);
      ref.invalidate(activeGamesProvider);
      ref.invalidate(activeGameProvider);
      ref.invalidate(gameInfoProvider(selectedGame.id));

      // Recarregar os dados do jogo selecionado com as informações mais recentes
      try {
        final updatedGame =
            await ref.read(gameInfoProvider(selectedGame.id).future);
        if (updatedGame != null) {
          ref.read(selectedGameProvider.notifier).state = updatedGame;
          print('✅ Dados do jogo selecionado atualizados com sucesso');
        }
      } catch (e) {
        print('⚠️ Erro ao recarregar dados do jogo selecionado: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jogo atualizado com sucesso! Sessões recriadas.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ Erro ao atualizar jogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao atualizar jogo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _playersPerTeamController.dispose();
    _substitutesPerTeamController.dispose();
    _numberOfTeamsController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _gameDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    if (selectedGame == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('3️⃣ Alterar Jogo'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          centerTitle: true,
        ),
        body: const Center(
          child: Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Nenhum jogo selecionado',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Selecione um jogo na tela principal para poder editá-lo.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('3️⃣ Alterar Jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.edit,
                        size: 48,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Alterar Jogo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Modifique as configurações do jogo "${selectedGame.organizationName}"',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Nome da Organização
              TextFormField(
                controller: _organizationNameController,
                decoration: const InputDecoration(
                  labelText: 'Nome da Organização *',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nome da organização é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Local
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Local *',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Local é obrigatório';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Endereço
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Endereço',
                  prefixIcon: Icon(Icons.home),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // Configuração de Times
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚽ Configuração de Times',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _playersPerTeamController,
                              decoration: const InputDecoration(
                                labelText: 'Jogadores por Time *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Obrigatório';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 1) {
                                  return 'Número inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _substitutesPerTeamController,
                              decoration: const InputDecoration(
                                labelText: 'Reservas por Time *',
                                prefixIcon: Icon(Icons.person_add),
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Obrigatório';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 0) {
                                  return 'Número inválido';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _numberOfTeamsController,
                        decoration: const InputDecoration(
                          labelText: 'Número de Times *',
                          prefixIcon: Icon(Icons.groups),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Número de times é obrigatório';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 2) {
                            return 'Mínimo 2 times';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Horários
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⏰ Horários',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Horário de Início *',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, true),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Horário de início é obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Horário de Término *',
                                prefixIcon: Icon(Icons.access_time),
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              onTap: () => _selectTime(context, false),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Horário de término é obrigatório';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Data e Frequência
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Data e Frequência',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _gameDateController,
                        decoration: const InputDecoration(
                          labelText: 'Data do Jogo *',
                          prefixIcon: Icon(Icons.calendar_today),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Data do jogo é obrigatória';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frequência *',
                          prefixIcon: Icon(Icons.repeat),
                          border: OutlineInputBorder(),
                        ),
                        items: _frequencies.map((frequency) {
                          return DropdownMenuItem<String>(
                            value: frequency,
                            child: Text(frequency),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFrequency = value!;
                          });
                        },
                      ),
                      if (_selectedFrequency != 'Jogo Avulso') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDayOfWeek.isEmpty
                              ? null
                              : _selectedDayOfWeek,
                          decoration: const InputDecoration(
                            labelText: 'Dia da Semana',
                            prefixIcon: Icon(Icons.calendar_view_week),
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('Selecione um dia'),
                            ),
                            ..._daysOfWeek.map((day) {
                              return DropdownMenuItem<String>(
                                value: day,
                                child: Text(day),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedDayOfWeek = value ?? '';
                            });
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão de Atualizar
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _updateGame,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_isLoading ? 'Atualizando...' : 'Atualizar Jogo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
