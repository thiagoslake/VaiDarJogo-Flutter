import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';
import '../providers/game_status_provider.dart';
import '../services/session_management_service.dart';
import '../services/game_update_service.dart';
import '../widgets/safe_location_field.dart';

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
  final _endDateController = TextEditingController();
  final _monthlyPriceController = TextEditingController();
  final _casualPriceController = TextEditingController();

  // Valores selecionados
  String _selectedFrequency = 'Jogo Avulso';
  String _selectedDayOfWeek = '';
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  DateTime _selectedDate = DateTime.now();
  DateTime? _selectedEndDate;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recarregar dados quando as dependências mudarem
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGameData();
    });
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

      // Carregar endDate
      if (selectedGame.endDate != null && selectedGame.endDate!.isNotEmpty) {
        try {
          _selectedEndDate = DateTime.parse(selectedGame.endDate!);
          _endDateController.text = _formatDate(_selectedEndDate!);
          print('✅ Data limite carregada: ${_endDateController.text}');
        } catch (e) {
          print('❌ Erro ao carregar data limite: $e');
          _selectedEndDate = null;
          _endDateController.clear();
        }
      } else {
        print('ℹ️ Nenhuma data limite definida para este jogo');
        _selectedEndDate = null;
        _endDateController.clear();
      }

      _selectedFrequency = selectedGame.frequency ?? 'Jogo Avulso';
      _selectedDayOfWeek =
          _mapDayOfWeekFromDatabase(selectedGame.dayOfWeek ?? '');

      // Carregar preços se existirem
      if (selectedGame.priceConfig != null) {
        final monthlyPrice = selectedGame.priceConfig!['monthly'];
        final casualPrice = selectedGame.priceConfig!['casual'];

        if (monthlyPrice != null && monthlyPrice > 0) {
          _monthlyPriceController.text = monthlyPrice.toString();
        }

        if (casualPrice != null && casualPrice > 0) {
          _casualPriceController.text = casualPrice.toString();
        }
      }
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
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Força a atualização do campo de data final
  void _updateEndDateField() {
    if (_selectedEndDate != null) {
      final formattedDate = _formatDate(_selectedEndDate!);
      if (_endDateController.text != formattedDate) {
        _endDateController.text = formattedDate;
      }
    } else {
      if (_endDateController.text.isNotEmpty) {
        _endDateController.clear();
      }
    }
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

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _selectedDate.add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
        _endDateController.text = _formatDate(picked);
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
        'game_date': _selectedFrequency == 'Jogo Avulso'
            ? _gameDateController.text
            : null,
        'day_of_week': _selectedDayOfWeek.isEmpty
            ? null
            : _mapDayOfWeekToDatabase(_selectedDayOfWeek),
        'frequency': _selectedFrequency,
        'end_date':
            _selectedEndDate != null ? _formatDate(_selectedEndDate!) : null,
        'price_config': {
          'monthly': _monthlyPriceController.text.isNotEmpty
              ? double.tryParse(_monthlyPriceController.text) ?? 0.0
              : 0.0,
          'casual': _casualPriceController.text.isNotEmpty
              ? double.tryParse(_casualPriceController.text) ?? 0.0
              : 0.0,
        },
      };

      print('📝 Atualizando jogo com dados: $gameData');

      // Usar o novo serviço de atualização completa
      final updateResult =
          await GameUpdateService.updateGameWithSessionRecreation(
        gameId: selectedGame.id,
        gameData: gameData,
      );

      if (updateResult['success']) {
        print('✅ Jogo atualizado com sucesso:');
        print(
            '   - Configurações preservadas: ${updateResult['details']['configurations_preserved']}');
        print(
            '   - Confirmações resetadas: ${updateResult['details']['confirmations_reset']}');
        print(
            '   - Sessões removidas: ${updateResult['details']['sessions_removed']}');
        print(
            '   - Sessões criadas: ${updateResult['details']['sessions_created']}');
      } else {
        print('❌ Erro na atualização: ${updateResult['error']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${updateResult['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
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
        final details = updateResult['details'];
        final configPreserved = details['configurations_preserved']
            ? 'Configurações preservadas'
            : 'Sem configurações';
        final confirmationsReset = details['confirmations_reset'];
        final sessionsCreated = details['sessions_created'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Jogo atualizado! $configPreserved, $confirmationsReset confirmações resetadas, $sessionsCreated sessões criadas.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
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
    _monthlyPriceController.dispose();
    _casualPriceController.dispose();
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

              // Local do Jogo
              SafeLocationField(
                labelText: 'Local do Jogo *',
                hintText: 'Digite o nome do local ou organização...',
                initialValue: _locationController.text,
                initialAddress: _addressController.text,
                onLocationSelected: (location, address, lat, lng) {
                  // Preencher tanto o local quanto a organização com o mesmo valor
                  _locationController.text = location;
                  _organizationNameController.text = location;
                  if (address != null && address.isNotEmpty) {
                    _addressController.text = address;
                  }
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Local do jogo é obrigatório';
                  }
                  return null;
                },
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

              // Frequência
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔄 Frequência',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                            // Inicializar data se for Jogo Avulso
                            if (value == 'Jogo Avulso' &&
                                _gameDateController.text.isEmpty) {
                              _gameDateController.text =
                                  _formatDate(_selectedDate);
                            }
                            // Forçar atualização do campo de data final
                            _updateEndDateField();
                          });
                        },
                      ),
                      if (_selectedFrequency == 'Semanal') ...[
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

              // Campo de data final para frequências recorrentes
              if (_selectedFrequency != 'Jogo Avulso') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Data Final da Recorrência *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event_available),
                    hintText: 'Selecione a data final',
                    helperText:
                        'Defina até quando as sessões devem ser criadas',
                  ),
                  readOnly: true,
                  onTap: () => _selectEndDate(context),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Data final é obrigatória para frequências recorrentes';
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Data (apenas para Jogo Avulso)
              if (_selectedFrequency == 'Jogo Avulso') ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '📅 Data do Jogo',
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              // Preços
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '💰 Preços',
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
                              controller: _monthlyPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mensal',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_month),
                                hintText: 'Ex: 50.00',
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final price = double.tryParse(value);
                                  if (price == null || price < 0) {
                                    return 'Preço inválido';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _casualPriceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Avulso',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event),
                                hintText: 'Ex: 15.00',
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final price = double.tryParse(value);
                                  if (price == null || price < 0) {
                                    return 'Preço inválido';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Os preços são opcionais. Deixe em branco se não houver cobrança.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
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
