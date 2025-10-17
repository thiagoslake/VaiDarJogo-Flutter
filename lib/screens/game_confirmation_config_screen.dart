import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/confirmation_send_config_model.dart';
import '../models/confirmation_config_complete_model.dart';
import '../services/game_confirmation_config_service.dart';
import '../providers/selected_game_provider.dart';
import '../constants/app_colors.dart';

class GameConfirmationConfigScreen extends ConsumerStatefulWidget {
  const GameConfirmationConfigScreen({super.key});

  @override
  ConsumerState<GameConfirmationConfigScreen> createState() =>
      _GameConfirmationConfigScreenState();
}

class _GameConfirmationConfigScreenState
    extends ConsumerState<GameConfirmationConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  ConfirmationConfigComplete? _config;

  // Configurações para mensalistas
  final List<ConfirmationSendConfig> _monthlyConfigs = [];
  final List<ConfirmationSendConfig> _casualConfigs = [];

  // Controllers para mensalistas
  final List<TextEditingController> _monthlyHoursControllers = [];
  final List<TextEditingController> _casualHoursControllers = [];

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    for (final controller in _monthlyHoursControllers) {
      controller.dispose();
    }
    for (final controller in _casualHoursControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) {
        setState(() {
          _error = 'Jogo não selecionado';
          _isLoading = false;
        });
        return;
      }

      // Verificar se o jogo está ativo
      if (selectedGame.status != 'active') {
        setState(() {
          _error =
              'Configuração não disponível para jogos pausados ou inativos';
          _isLoading = false;
        });
        return;
      }

      print('🔄 Carregando configurações para o jogo: ${selectedGame.id}');

      // Carregar configuração existente
      _config = await GameConfirmationConfigService.getGameConfirmationConfig(
        selectedGame.id,
      );

      if (_config != null) {
        print('✅ Configuração encontrada no banco de dados');
        print(
            '📊 Mensalistas: ${_config!.monthlyConfigs.length} configurações');
        print('📊 Avulsos: ${_config!.casualConfigs.length} configurações');

        _monthlyConfigs.clear();
        _casualConfigs.clear();
        _monthlyConfigs.addAll(_config!.monthlyConfigs);
        _casualConfigs.addAll(_config!.casualConfigs);

        // Mostrar feedback visual de que as configurações foram carregadas
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '✅ Configurações carregadas: ${_config!.monthlyConfigs.length} mensalistas, ${_config!.casualConfigs.length} avulsos'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        print('ℹ️ Nenhuma configuração encontrada, usando padrão');
        // Configuração padrão se não existir
        _initializeDefaultConfigs();
      }

      _initializeControllers();
    } catch (e) {
      print('❌ Erro ao carregar configurações: $e');
      setState(() {
        _error = 'Erro ao carregar configurações: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeDefaultConfigs() {
    _monthlyConfigs.clear();
    _casualConfigs.clear();

    // Configuração padrão para mensalistas
    _monthlyConfigs.add(ConfirmationSendConfig(
      id: '',
      gameConfirmationConfigId: '',
      playerType: 'monthly',
      confirmationOrder: 1,
      hoursBeforeGame: 48,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    _monthlyConfigs.add(ConfirmationSendConfig(
      id: '',
      gameConfirmationConfigId: '',
      playerType: 'monthly',
      confirmationOrder: 2,
      hoursBeforeGame: 24,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    // Configuração padrão para avulsos
    _casualConfigs.add(ConfirmationSendConfig(
      id: '',
      gameConfirmationConfigId: '',
      playerType: 'casual',
      confirmationOrder: 1,
      hoursBeforeGame: 24,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));

    _casualConfigs.add(ConfirmationSendConfig(
      id: '',
      gameConfirmationConfigId: '',
      playerType: 'casual',
      confirmationOrder: 2,
      hoursBeforeGame: 12,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  void _initializeControllers() {
    // Limpar controllers existentes
    for (final controller in _monthlyHoursControllers) {
      controller.dispose();
    }
    for (final controller in _casualHoursControllers) {
      controller.dispose();
    }

    _monthlyHoursControllers.clear();
    _casualHoursControllers.clear();

    // Inicializar controllers para mensalistas
    for (final config in _monthlyConfigs) {
      final controller =
          TextEditingController(text: config.hoursBeforeGame.toString());
      _monthlyHoursControllers.add(controller);
    }

    // Inicializar controllers para avulsos
    for (final config in _casualConfigs) {
      final controller =
          TextEditingController(text: config.hoursBeforeGame.toString());
      _casualHoursControllers.add(controller);
    }
  }

  void _addMonthlyConfig() {
    setState(() {
      final newOrder = _monthlyConfigs.length + 1;
      _monthlyConfigs.add(ConfirmationSendConfig(
        id: '',
        gameConfirmationConfigId: '',
        playerType: 'monthly',
        confirmationOrder: newOrder,
        hoursBeforeGame: 24,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _monthlyHoursControllers.add(TextEditingController(text: '24'));
    });
  }

  void _addCasualConfig() {
    setState(() {
      final newOrder = _casualConfigs.length + 1;
      _casualConfigs.add(ConfirmationSendConfig(
        id: '',
        gameConfirmationConfigId: '',
        playerType: 'casual',
        confirmationOrder: newOrder,
        hoursBeforeGame: 12,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      _casualHoursControllers.add(TextEditingController(text: '12'));
    });
  }

  void _removeMonthlyConfig(int index) {
    if (_monthlyConfigs.length > 1) {
      setState(() {
        _monthlyConfigs.removeAt(index);
        _monthlyHoursControllers[index].dispose();
        _monthlyHoursControllers.removeAt(index);

        // Reordenar
        for (int i = 0; i < _monthlyConfigs.length; i++) {
          _monthlyConfigs[i] =
              _monthlyConfigs[i].copyWith(confirmationOrder: i + 1);
        }
      });
    }
  }

  void _removeCasualConfig(int index) {
    if (_casualConfigs.length > 1) {
      setState(() {
        _casualConfigs.removeAt(index);
        _casualHoursControllers[index].dispose();
        _casualHoursControllers.removeAt(index);

        // Reordenar
        for (int i = 0; i < _casualConfigs.length; i++) {
          _casualConfigs[i] =
              _casualConfigs[i].copyWith(confirmationOrder: i + 1);
        }
      });
    }
  }

  bool _validateConfigurations() {
    // Verificar se há pelo menos uma configuração para cada tipo
    if (_monthlyConfigs.isEmpty || _casualConfigs.isEmpty) {
      return false;
    }

    // Verificar se a menor hora dos mensalistas é maior que a maior hora dos avulsos
    // Isso garante que mensalistas sempre recebam confirmações antes dos avulsos
    final monthlyMinHours = _monthlyConfigs
        .map((config) => config.hoursBeforeGame)
        .reduce((a, b) => a < b ? a : b);

    final casualMaxHours = _casualConfigs
        .map((config) => config.hoursBeforeGame)
        .reduce((a, b) => a > b ? a : b);

    return monthlyMinHours > casualMaxHours;
  }

  Future<void> _saveConfig() async {
    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      // Atualizar configurações com valores dos controllers
      for (int i = 0; i < _monthlyConfigs.length; i++) {
        final hours = int.tryParse(_monthlyHoursControllers[i].text) ?? 24;
        _monthlyConfigs[i] =
            _monthlyConfigs[i].copyWith(hoursBeforeGame: hours);
      }

      for (int i = 0; i < _casualConfigs.length; i++) {
        final hours = int.tryParse(_casualHoursControllers[i].text) ?? 12;
        _casualConfigs[i] = _casualConfigs[i].copyWith(hoursBeforeGame: hours);
      }

      // Validar configurações
      if (!_validateConfigurations()) {
        setState(() {
          _error =
              'Configurações inválidas: mensalistas devem receber confirmações antes dos avulsos';
          _isSaving = false;
        });
        return;
      }

      final selectedGame = ref.read(selectedGameProvider);
      if (selectedGame == null) {
        setState(() {
          _error = 'Jogo não selecionado';
          _isSaving = false;
        });
        return;
      }

      // Salvar configuração (o método updateGameConfirmationConfig já trata criação e atualização)
      final savedConfig =
          await GameConfirmationConfigService.updateGameConfirmationConfig(
        gameId: selectedGame.id,
        monthlyConfigs: _monthlyConfigs,
        casualConfigs: _casualConfigs,
      );

      if (savedConfig != null) {
        setState(() {
          _config = savedConfig;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Configurações salvas com sucesso!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        setState(() {
          _error = 'Erro ao salvar configurações';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao salvar: $e';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedGame = ref.watch(selectedGameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Confirmação de Presença',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && _error == null)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save_outlined, size: 20),
              onPressed: _isSaving ? null : _saveConfig,
              tooltip: 'Salvar Configurações',
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.1),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : _error != null
              ? _buildErrorState()
              : _buildConfigContent(selectedGame),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        color: AppColors.card,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.alert,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadConfig,
                icon: const Icon(Icons.refresh_outlined, size: 18),
                label: const Text('Tentar Novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigContent(selectedGame) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Card(
            color: AppColors.card,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedGame?.organizationName ?? 'Jogo',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Configure quando enviar confirmações de presença',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Indicador de status das configurações
                        Row(
                          children: [
                            Icon(
                              _config != null ? Icons.check_circle : Icons.info,
                              color: _config != null
                                  ? AppColors.success
                                  : AppColors.primary,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _config != null
                                  ? 'Configurações salvas'
                                  : 'Configurações padrão',
                              style: TextStyle(
                                color: _config != null
                                    ? AppColors.success
                                    : AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Configurações para Mensalistas
          _buildPlayerTypeConfig(
            'Mensalistas',
            Icons.people,
            _monthlyConfigs,
            _monthlyHoursControllers,
            _addMonthlyConfig,
            _removeMonthlyConfig,
          ),

          const SizedBox(height: 16),

          // Configurações para Avulsos
          _buildPlayerTypeConfig(
            'Avulsos',
            Icons.person,
            _casualConfigs,
            _casualHoursControllers,
            _addCasualConfig,
            _removeCasualConfig,
          ),

          const SizedBox(height: 16),

          // Validação
          if (!_validateConfigurations())
            Card(
              color: AppColors.alert.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_outlined,
                      color: AppColors.alert,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Mensalistas devem receber confirmações antes dos avulsos',
                        style: TextStyle(
                          color: AppColors.alert,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPlayerTypeConfig(
    String title,
    IconData icon,
    List<ConfirmationSendConfig> configs,
    List<TextEditingController> controllers,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Card(
      color: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  onPressed: onAdd,
                  tooltip: 'Adicionar Confirmação',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(configs.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          const Text(
                            'Horas antes do jogo:',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              controller: controllers[index],
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.card,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.dividerLight),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.dividerLight),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'h',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (configs.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline,
                            color: AppColors.alert),
                        onPressed: () => onRemove(index),
                        tooltip: 'Remover Confirmação',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.alert.withOpacity(0.1),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
