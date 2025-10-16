import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import '../constants/football_positions.dart';

class CompletePlayerProfileScreen extends StatefulWidget {
  final String playerId;
  final String playerName;

  const CompletePlayerProfileScreen({
    super.key,
    required this.playerId,
    required this.playerName,
  });

  @override
  State<CompletePlayerProfileScreen> createState() =>
      _CompletePlayerProfileScreenState();
}

class _CompletePlayerProfileScreenState
    extends State<CompletePlayerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _primaryPositionController = TextEditingController();
  final _secondaryPositionController = TextEditingController();
  final _preferredFootController = TextEditingController();

  String? _selectedPrimaryPosition;
  String? _selectedSecondaryPosition;
  String? _selectedPreferredFoot;
  DateTime? _selectedBirthDate;
  bool _isLoading = false;

  // Usar posições do Futebol 7
  final List<String> _positions = FootballPositions.positions;
  final List<String> _feet = FootballPositions.preferredFeet;

  @override
  void dispose() {
    _birthDateController.dispose();
    _primaryPositionController.dispose();
    _secondaryPositionController.dispose();
    _preferredFootController.dispose();
    super.dispose();
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ??
          DateTime.now().subtract(const Duration(days: 6570)), // 18 anos atrás
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'BR'),
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await PlayerService.updatePlayer(
        playerId: widget.playerId,
        birthDate: _selectedBirthDate,
        primaryPosition: _selectedPrimaryPosition,
        secondaryPosition: _selectedSecondaryPosition,
        preferredFoot: _selectedPreferredFoot,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil complementado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true para indicar sucesso
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro ao salvar perfil: $e'),
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
        title: const Text('Complementar Perfil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed:
                _isLoading ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.person_add,
                        size: 48,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Complementar Perfil',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jogador: ${widget.playerName}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Mensalista',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Data de Nascimento
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📅 Data de Nascimento',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _birthDateController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          hintText: 'Selecione a data de nascimento',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: _selectBirthDate,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Data de nascimento é obrigatória';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Posição Primária
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚽ Posição Primária',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPrimaryPosition,
                        decoration: const InputDecoration(
                          hintText: 'Selecione a posição primária',
                          border: OutlineInputBorder(),
                        ),
                        items: _positions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(
                              position,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPrimaryPosition = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Posição primária é obrigatória';
                          }
                          return null;
                        },
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Posição Secundária
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '⚽ Posição Secundária',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSecondaryPosition,
                        decoration: const InputDecoration(
                          hintText: 'Selecione a posição secundária (opcional)',
                          border: OutlineInputBorder(),
                        ),
                        items: _positions.map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(
                              position,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSecondaryPosition = value;
                          });
                        },
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Pé Preferido
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🦶 Pé Preferido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedPreferredFoot,
                        decoration: const InputDecoration(
                          hintText: 'Selecione o pé preferido',
                          border: OutlineInputBorder(),
                        ),
                        items: _feet.map((foot) {
                          return DropdownMenuItem(
                            value: foot,
                            child: Text(
                              foot,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPreferredFoot = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pé preferido é obrigatório';
                          }
                          return null;
                        },
                        isExpanded: true,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Botão Salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Salvando...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text(
                              'Salvar Perfil',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
