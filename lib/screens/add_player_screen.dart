import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/supabase_config.dart';
import '../providers/selected_game_provider.dart';
import '../services/player_service.dart';
import '../constants/football_positions.dart';

class AddPlayerScreen extends ConsumerStatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  ConsumerState<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends ConsumerState<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _selectedPlayerType = 'monthly';

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _primaryPositionController = TextEditingController();
  final _secondaryPositionController = TextEditingController();
  final _preferredFootController = TextEditingController();

  // Valores selecionados
  DateTime? _selectedBirthDate;
  String _selectedPrimaryPosition = 'Meio Direita';
  String _selectedSecondaryPosition = 'Nenhuma';
  String _selectedPreferredFoot = 'Direita';

  // Usar posições do Futebol 7
  final List<String> _positions = FootballPositions.positions;
  final List<String> _feet = FootballPositions.preferredFeet;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _primaryPositionController.dispose();
    _secondaryPositionController.dispose();
    _preferredFootController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatPhone(String phone) {
    // Remove todos os caracteres não numéricos
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');

    // Formata o telefone brasileiro
    if (cleaned.length == 11) {
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 7)}-${cleaned.substring(7)}';
    } else if (cleaned.length == 10) {
      return '(${cleaned.substring(0, 2)}) ${cleaned.substring(2, 6)}-${cleaned.substring(6)}';
    }
    return phone;
  }

  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '❌ Nenhum jogo selecionado. Volte ao menu principal e selecione um jogo.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final phoneNumber = _phoneController.text.replaceAll(RegExp(r'\D'), '');

      // Verificar se o jogador já existe
      print('🔍 Verificando se jogador já existe com telefone: $phoneNumber');
      final existingPlayer = await SupabaseConfig.client
          .from('players')
          .select('id, name, phone_number')
          .eq('phone_number', phoneNumber)
          .maybeSingle();

      String playerId;

      if (existingPlayer != null) {
        // Jogador já existe
        playerId = existingPlayer['id'];
        print('✅ Jogador já existe: ${existingPlayer['name']} (ID: $playerId)');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'ℹ️ Jogador ${existingPlayer['name']} já está cadastrado. Adicionando ao jogo...'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Criar novo jogador
        print('📝 Criando novo jogador...');

        // Validar e corrigir preferred_foot se necessário
        String validPreferredFoot = _selectedPreferredFoot;
        if (validPreferredFoot == 'Ambas') {
          validPreferredFoot = 'Ambidestro';
          print('⚠️ Corrigindo preferred_foot de "Ambas" para "Ambidestro"');
        }

        // Criar perfil do jogador (sem tipo)
        final player = await PlayerService.createPlayer(
          userId: '', // Será preenchido depois se necessário
          name: _nameController.text.trim(),
          phoneNumber: phoneNumber,
          birthDate: _selectedBirthDate,
          primaryPosition: _selectedPrimaryPosition,
          secondaryPosition: _selectedSecondaryPosition == 'Nenhuma'
              ? null
              : _selectedSecondaryPosition,
          preferredFoot: validPreferredFoot,
        );

        if (player == null) {
          throw Exception('Erro ao criar perfil do jogador');
        }

        playerId = player.id;
        print('✅ Jogador criado com sucesso: $playerId');
      }

      // Verificar se o jogador já está relacionado ao jogo
      print('🔍 Verificando se jogador já está relacionado ao jogo...');
      final existingRelation = await SupabaseConfig.client
          .from('game_players')
          .select('id, status')
          .eq('game_id', selectedGame.id)
          .eq('player_id', playerId)
          .maybeSingle();

      if (existingRelation != null) {
        // Jogador já está relacionado ao jogo
        print(
            'ℹ️ Jogador já está relacionado ao jogo (ID: ${existingRelation['id']})');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ℹ️ Jogador já está cadastrado neste jogo!'),
              backgroundColor: Colors.orange,
            ),
          );

          // Retornar true mesmo se já estiver cadastrado
          Navigator.of(context).pop(true);
        }
      } else {
        // Criar relacionamento jogador-jogo
        print('🔗 Criando relacionamento jogador-jogo...');

        // Adicionar jogador ao jogo com o tipo selecionado
        final gamePlayer = await PlayerService.addPlayerToGame(
          gameId: selectedGame.id,
          playerId: playerId,
          playerType: _selectedPlayerType,
        );

        if (gamePlayer == null) {
          throw Exception('Erro ao adicionar jogador ao jogo');
        }

        print('✅ Relacionamento criado com sucesso: ${gamePlayer.id}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Jogador adicionado ao jogo com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Retornar true para indicar sucesso
          Navigator.of(context).pop(true);
        }
      }

      // Limpar formulário apenas se criou um novo jogador
      if (existingPlayer == null && mounted) {
        print('🔍 Debug - mounted: true, limpando formulário...');
        _formKey.currentState?.reset();
        _nameController.clear();
        _phoneController.clear();
        _birthDateController.clear();
        _selectedBirthDate = null;
        _selectedPlayerType = 'monthly';
        _selectedPrimaryPosition = 'Meias';
        _selectedSecondaryPosition = 'Nenhuma';
        _selectedPreferredFoot = 'Direita';
      }
    } catch (e) {
      print('❌ Erro ao processar jogador: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao processar jogador: $e'),
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
        title: const Text('👤 Adicionar Jogador ao Jogo'),
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
                    // Tipo de Jogador
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '👤 Tipo de Jogador',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'monthly',
                                  label: Text('📅 Mensalista'),
                                  tooltip: 'Jogador fixo mensal',
                                ),
                                ButtonSegment<String>(
                                  value: 'casual',
                                  label: Text('🎲 Avulso'),
                                  tooltip: 'Jogador eventual',
                                ),
                              ],
                              selected: {_selectedPlayerType},
                              onSelectionChanged: (Set<String> selection) {
                                setState(() {
                                  _selectedPlayerType = selection.first;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Informações Básicas
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '📋 Informações Básicas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome Completo *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nome é obrigatório';
                                }
                                if (value.trim().length < 2) {
                                  return 'Nome deve ter pelo menos 2 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefone *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                                hintText: '(11) 99999-9999',
                              ),
                              keyboardType: TextInputType.phone,
                              onChanged: (value) {
                                final formatted = _formatPhone(value);
                                if (formatted != value) {
                                  _phoneController.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                        offset: formatted.length),
                                  );
                                }
                              },
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Telefone é obrigatório';
                                }
                                final cleaned =
                                    value.replaceAll(RegExp(r'\D'), '');
                                if (cleaned.length < 10) {
                                  return 'Telefone deve ter pelo menos 10 dígitos';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Informações Específicas para Mensalistas
                    if (_selectedPlayerType == 'monthly') ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⚽ Informações do Jogador',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _birthDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Data de Nascimento *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.cake),
                                  suffixIcon: Icon(Icons.date_range),
                                ),
                                readOnly: true,
                                onTap: () => _selectBirthDate(context),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Data de nascimento é obrigatória';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPrimaryPosition,
                                decoration: const InputDecoration(
                                  labelText: 'Posição Principal *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.sports_soccer),
                                ),
                                items: _positions.map((String position) {
                                  return DropdownMenuItem<String>(
                                    value: position,
                                    child: Text(position),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPrimaryPosition = newValue!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSecondaryPosition,
                                decoration: const InputDecoration(
                                  labelText: 'Posição Secundária',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.sports_soccer),
                                ),
                                items: FootballPositions.secondaryPositions
                                    .map((String position) {
                                  return DropdownMenuItem<String>(
                                    value: position,
                                    child: Text(position),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedSecondaryPosition = newValue!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPreferredFoot,
                                decoration: const InputDecoration(
                                  labelText: 'Perna Preferida *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.directions_run),
                                ),
                                items: _feet.map((String foot) {
                                  return DropdownMenuItem<String>(
                                    value: foot,
                                    child: Text(foot),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedPreferredFoot = newValue!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Botão Salvar
                    ElevatedButton(
                      onPressed: _savePlayer,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        '➕ Adicionar ao Jogo',
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
