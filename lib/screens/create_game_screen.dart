import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/safe_location_field.dart';
import '../services/session_management_service.dart';

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() => _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers para os campos
  final _organizationNameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _playersPerTeamController = TextEditingController(text: '7');
  final _substitutesPerTeamController = TextEditingController(text: '3');
  final _numberOfTeamsController = TextEditingController(text: '4');
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _gameDateController = TextEditingController();

  // Valores selecionados
  String _selectedFrequency = 'Jogo Avulso';
  String _selectedDayOfWeek = '';
  TimeOfDay _startTime = const TimeOfDay(hour: 19, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  DateTime _selectedDate = DateTime.now();

  // Dados do local selecionado (usados no callback)
  // String _selectedLocation = '';
  // String? _selectedAddress;
  // double? _selectedLat;
  // double? _selectedLng;

  final List<String> _frequencies = [
    'Diária',
    'Semanal',
    'Mensal',
    'Anual',
    'Jogo Avulso'
  ];

  final List<String> _daysOfWeek = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo'
  ];

  @override
  void initState() {
    super.initState();
    _gameDateController.text = _formatDate(_selectedDate);
    _startTimeController.text = _formatTime(_startTime);
    _endTimeController.text = _formatTime(_endTime);
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

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  void _onLocationSelected(
      String location, String? address, double? lat, double? lng) {
    setState(() {
      // Atualizar os controllers
      _locationController.text = location;
      _addressController.text = address ?? '';
    });

    // Log para debug
    print('📍 Local selecionado: $location');
    print('🏠 Endereço: $address');
    print('🗺️ Coordenadas: $lat, $lng');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _gameDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startTimeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _createGame() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Usuário não autenticado'),
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
        'user_id': currentUser.id,
        'organization_name': _organizationNameController.text.trim(),
        'location': _locationController.text.trim(),
        'address': _addressController.text.trim(),
        'players_per_team': int.parse(_playersPerTeamController.text),
        'substitutes_per_team': int.parse(_substitutesPerTeamController.text),
        'number_of_teams': int.parse(_numberOfTeamsController.text),
        'start_time': _startTimeController.text,
        'end_time': _endTimeController.text,
        'game_date': _gameDateController.text,
        'day_of_week': _selectedDayOfWeek.isEmpty ? null : _selectedDayOfWeek,
        'frequency': _selectedFrequency,
        'status': 'active',
        'price_config': {},
      };

      print('📝 Criando jogo com dados: $gameData');

      // Criar novo jogo
      final result = await SupabaseConfig.client
          .from('games')
          .insert(gameData)
          .select()
          .single();

      print('✅ Jogo criado com sucesso: ${result['id']}');

      // Criar sessões baseadas nas configurações do jogo
      try {
        print('🔄 Criando sessões para o novo jogo...');
        final sessionResult =
            await SessionManagementService.createNewSessions(result);
        print('✅ ${sessionResult.length} sessões criadas com sucesso');
      } catch (sessionError) {
        print('⚠️ Erro ao criar sessões: $sessionError');
        // Não falha a criação do jogo se houver erro nas sessões
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Jogo criado com sucesso! Sessões configuradas.'),
            backgroundColor: Colors.green,
          ),
        );

        // Voltar para a tela anterior
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      print('❌ Erro ao criar jogo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao criar jogo: $e'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Novo Jogo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Informações da Organização
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '🏢 Informações da Organização',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _organizationNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome da Organização *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome da organização é obrigatório';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SafeLocationField(
                              labelText: 'Local *',
                              hintText: 'Digite o nome do local...',
                              onLocationSelected: _onLocationSelected,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Local é obrigatório';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Configuração dos Times
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '⚽ Configuração dos Times',
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
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.people),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = int.tryParse(value);
                                      if (num == null || num < 5 || num > 11) {
                                        return 'Entre 5 e 11';
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
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.person_add),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Campo obrigatório';
                                      }
                                      final num = int.tryParse(value);
                                      if (num == null || num < 0 || num > 10) {
                                        return 'Entre 0 e 10';
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
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.groups),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Campo obrigatório';
                                }
                                final num = int.tryParse(value);
                                if (num == null || num < 2 || num > 8) {
                                  return 'Entre 2 e 8';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Data e Horário
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📅 Data e Horário',
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
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                                suffixIcon: Icon(Icons.date_range),
                              ),
                              readOnly: true,
                              onTap: () => _selectDate(context),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Data é obrigatória';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _startTimeController,
                                    decoration: const InputDecoration(
                                      labelText: 'Horário de Início *',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                      suffixIcon: Icon(Icons.schedule),
                                    ),
                                    readOnly: true,
                                    onTap: () => _selectStartTime(context),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Horário é obrigatório';
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
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.access_time),
                                      suffixIcon: Icon(Icons.schedule),
                                    ),
                                    readOnly: true,
                                    onTap: () => _selectEndTime(context),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Horário é obrigatório';
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

                    // Frequência e Dia da Semana
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
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
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.repeat),
                              ),
                              items: _frequencies.map((String frequency) {
                                return DropdownMenuItem<String>(
                                  value: frequency,
                                  child: Text(frequency),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedFrequency = newValue!;
                                  // Resetar dia da semana se não for semanal
                                  if (newValue != 'Semanal') {
                                    _selectedDayOfWeek = '';
                                  }
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
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_view_week),
                                ),
                                items: _daysOfWeek.map((String day) {
                                  return DropdownMenuItem<String>(
                                    value: day,
                                    child: Text(day),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedDayOfWeek = newValue ?? '';
                                  });
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Botão de Criar Jogo
                    ElevatedButton(
                      onPressed: _createGame,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        '🎮 Criar Jogo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
