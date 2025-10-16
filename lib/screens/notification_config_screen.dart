import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_config_model.dart';
import '../models/player_model.dart';
import '../services/notification_config_service.dart';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../services/push_notification_service.dart';
import '../constants/app_colors.dart';

class NotificationConfigScreen extends ConsumerStatefulWidget {
  const NotificationConfigScreen({super.key});

  @override
  ConsumerState<NotificationConfigScreen> createState() =>
      _NotificationConfigScreenState();
}

class _NotificationConfigScreenState
    extends ConsumerState<NotificationConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  NotificationConfig? _config;
  Player? _player;

  // Controllers
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  // Valores selecionados
  bool _enabled = true;
  int _advanceHours = 24;
  bool _whatsappEnabled = true;
  bool _emailEnabled = false;
  bool _pushEnabled = true;
  List<String> _selectedGameTypes = ['all'];
  List<String> _selectedDaysOfWeek = ['0', '1', '2', '3', '4', '5', '6'];
  List<int> _selectedTimeSlots = [18, 19, 20, 21];

  final List<String> _gameTypes = ['all', 'monthly', 'casual'];
  final List<String> _daysOfWeek = [
    'Domingo',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado'
  ];
  final List<String> _dayValues = ['0', '1', '2', '3', '4', '5', '6'];
  final List<int> _availableTimeSlots = List.generate(24, (index) => index);

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'Usuário não encontrado';
          _isLoading = false;
        });
        return;
      }

      // Buscar perfil de jogador
      _player = await PlayerService.getPlayerByUserId(currentUser.id);
      if (_player == null) {
        setState(() {
          _error = 'Perfil de jogador não encontrado';
          _isLoading = false;
        });
        return;
      }

      // Buscar ou criar configuração
      _config =
          await NotificationConfigService.getOrCreateDefaultConfig(_player!.id);

      // Carregar dados na interface
      _loadConfigData();
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar configurações: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadConfigData() {
    if (_config != null) {
      setState(() {
        _enabled = _config!.enabled;
        _advanceHours = _config!.advanceHours;
        _whatsappEnabled = _config!.whatsappEnabled;
        _emailEnabled = _config!.emailEnabled;
        _pushEnabled = _config!.pushEnabled;
        _selectedGameTypes = List.from(_config!.gameTypes);
        _selectedDaysOfWeek = List.from(_config!.daysOfWeek);
        _selectedTimeSlots =
            _config!.timeSlots.map((e) => int.tryParse(e) ?? 18).toList();

        _whatsappController.text =
            _config!.whatsappNumber ?? _player?.phoneNumber ?? '';
        _emailController.text = _config!.email ?? '';
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_player == null) return;

    try {
      setState(() {
        _isSaving = true;
        _error = null;
      });

      final config = NotificationConfig(
        id: _config?.id ?? '',
        userId: _player!.id,
        enabled: _enabled,
        advanceHours: _advanceHours,
        whatsappEnabled: _whatsappEnabled,
        emailEnabled: _emailEnabled,
        pushEnabled: _pushEnabled,
        whatsappNumber: _whatsappController.text.trim().isNotEmpty
            ? _whatsappController.text.trim()
            : null,
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        gameTypes: _selectedGameTypes,
        daysOfWeek: _selectedDaysOfWeek,
        timeSlots: _selectedTimeSlots.map((e) => e.toString()).toList(),
        createdAt: _config?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Validar configuração
      if (!NotificationConfigService.validateConfig(config)) {
        setState(() {
          _error = 'Configuração inválida. Verifique os dados inseridos.';
          _isSaving = false;
        });
        return;
      }

      final savedConfig = await NotificationConfigService.saveConfig(config);
      if (savedConfig != null) {
        setState(() {
          _config = savedConfig;
        });

        // Configurar push notifications se habilitado
        if (_pushEnabled) {
          await _setupPushNotifications();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configurações salvas com sucesso!'),
              backgroundColor: Colors.green,
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

  Future<void> _setupPushNotifications() async {
    try {
      // Inicializar push notifications
      await PushNotificationService.initialize();

      // Salvar token FCM no servidor
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        await PushNotificationService.saveFCMTokenToServer(currentUser.id);
      }

      // Inscrever em tópicos relevantes
      await PushNotificationService.subscribeToTopic('game_notifications');
      await PushNotificationService.subscribeToTopic('all_users');
    } catch (e) {
      print('❌ Erro ao configurar push notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Configurar Notificações',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: Colors.transparent,
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
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildConfigContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        color: AppColors.surface,
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
                  elevation: 0,
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

  Widget _buildConfigContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          const Card(
            color: AppColors.surface,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configurações de Notificação',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Configure quando e como receber notificações sobre jogos',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Habilitar/Desabilitar Notificações
          Card(
            color: AppColors.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.toggle_on_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Notificações Habilitadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Switch(
                        value: _enabled,
                        onChanged: (value) {
                          setState(() {
                            _enabled = value;
                          });
                        },
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ative ou desative todas as notificações de jogos',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_enabled) ...[
            const SizedBox(height: 16),

            // Antecedência
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Antecedência da Notificação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Notificar com ${_advanceHours}h de antecedência',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _advanceHours.toDouble(),
                      min: 1,
                      max: 168, // 1 semana
                      divisions: 167,
                      activeColor: AppColors.primary,
                      onChanged: (value) {
                        setState(() {
                          _advanceHours = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '1h',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${_advanceHours}h',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Text(
                          '168h (1 semana)',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Métodos de Notificação
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Métodos de Notificação',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp
                    _buildNotificationMethod(
                      'WhatsApp',
                      Icons.chat_outlined,
                      _whatsappEnabled,
                      (value) => setState(() => _whatsappEnabled = value),
                      _whatsappController,
                      'Número do WhatsApp',
                      'Deixe vazio para usar o telefone do perfil',
                    ),

                    const SizedBox(height: 12),

                    // Email
                    _buildNotificationMethod(
                      'Email',
                      Icons.email_outlined,
                      _emailEnabled,
                      (value) => setState(() => _emailEnabled = value),
                      _emailController,
                      'Endereço de email',
                      'Deixe vazio para usar o email do usuário',
                    ),

                    const SizedBox(height: 12),

                    // Push Notification
                    _buildNotificationMethod(
                      'Push Notification',
                      Icons.phone_android_outlined,
                      _pushEnabled,
                      (value) => setState(() => _pushEnabled = value),
                      null,
                      null,
                      'Notificações diretas no aplicativo',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tipos de Jogo
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.sports_soccer_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Tipos de Jogo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _gameTypes.map((type) {
                        final isSelected = _selectedGameTypes.contains(type);
                        return FilterChip(
                          label: Text(_getGameTypeLabel(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedGameTypes.add(type);
                              } else {
                                _selectedGameTypes.remove(type);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Dias da Semana
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Dias da Semana',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _daysOfWeek.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final dayValue = _dayValues[index];
                        final isSelected =
                            _selectedDaysOfWeek.contains(dayValue);

                        return FilterChip(
                          label: Text(day),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedDaysOfWeek.add(dayValue);
                              } else {
                                _selectedDaysOfWeek.remove(dayValue);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Horários Preferidos
            Card(
              color: AppColors.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.access_time_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Horários Preferidos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Selecione os horários em que você prefere jogar',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableTimeSlots.map((hour) {
                        final isSelected = _selectedTimeSlots.contains(hour);
                        return FilterChip(
                          label: Text('${hour.toString().padLeft(2, '0')}:00'),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTimeSlots.add(hour);
                              } else {
                                _selectedTimeSlots.remove(hour);
                              }
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationMethod(
    String title,
    IconData icon,
    bool enabled,
    ValueChanged<bool> onChanged,
    TextEditingController? controller,
    String? hintText,
    String? description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: enabled ? AppColors.primary : AppColors.iconInactive,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onChanged,
              activeThumbColor: AppColors.primary,
            ),
          ],
        ),
        if (controller != null && enabled) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.dividerLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.dividerLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  String _getGameTypeLabel(String type) {
    switch (type) {
      case 'all':
        return 'Todos';
      case 'monthly':
        return 'Mensais';
      case 'casual':
        return 'Casuais';
      default:
        return type;
    }
  }
}
