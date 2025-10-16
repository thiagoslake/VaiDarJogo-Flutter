import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../services/player_service.dart';
import '../models/player_model.dart';
import '../config/supabase_config.dart';
import '../constants/football_positions.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  Player? _player;

  // Variáveis para foto de perfil
  File? _profileImage;
  String? _profileImageUrl;
  bool _isUploadingImage = false;

  // Controllers para edição
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _primaryPositionController = TextEditingController();
  final _secondaryPositionController = TextEditingController();
  final _preferredFootController = TextEditingController();

  // Valores selecionados
  DateTime? _selectedBirthDate;
  String _selectedPrimaryPosition = 'Goleiro';
  String _selectedSecondaryPosition = 'Nenhuma';
  String _selectedPreferredFoot = 'Direita';

  // Controle de visibilidade das senhas
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Usar posições do Futebol 7
  final List<String> _positions = FootballPositions.positions;
  final List<String> _feet = FootballPositions.preferredFeet;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _birthDateController.dispose();
    _primaryPositionController.dispose();
    _secondaryPositionController.dispose();
    _preferredFootController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
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
      final player = await PlayerService.getPlayerByUserId(currentUser.id);

      if (player != null) {
        setState(() {
          _player = player;
          _loadPlayerData();
        });
      } else {
        // Usuário legado sem perfil de jogador - permitir criação
        setState(() {
          _player = null;
          _isEditing = true; // Iniciar em modo de edição para criar perfil
          _loadUserDataForProfile(); // Carregar dados do usuário para o perfil
        });
      }

      // Carregar foto de perfil
      await _loadProfileImage();
    } catch (e) {
      setState(() {
        _error = 'Erro ao criar o perfil do jogador: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadPlayerData() {
    if (_player != null) {
      final currentUser = ref.read(currentUserProvider);
      _nameController.text = _player!.name;
      _emailController.text = currentUser?.email ?? '';
      _phoneController.text = _player!.phoneNumber;
      _selectedBirthDate = _player!.birthDate;

      print('🔍 DEBUG - E-mail carregado no perfil: ${currentUser?.email}');
      // Validar e ajustar posições para as novas posições do Futebol 7
      _selectedPrimaryPosition = _player!.primaryPosition ?? 'Goleiro';
      if (!_positions.contains(_selectedPrimaryPosition)) {
        _selectedPrimaryPosition = 'Goleiro';
      }

      _selectedSecondaryPosition = _player!.secondaryPosition ?? 'Nenhuma';
      if (!FootballPositions.secondaryPositions
          .contains(_selectedSecondaryPosition)) {
        _selectedSecondaryPosition = 'Nenhuma';
      }

      _selectedPreferredFoot = _player!.preferredFoot ?? 'Direita';
      if (!_feet.contains(_selectedPreferredFoot)) {
        _selectedPreferredFoot = 'Direita';
      }

      if (_selectedBirthDate != null) {
        _birthDateController.text = _formatDate(_selectedBirthDate!);
      }
    }
  }

  void _loadUserDataForProfile() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      _nameController.text = currentUser.name;
      _emailController.text = currentUser.email;
      _phoneController.text = currentUser.phone ?? '';
      _selectedPrimaryPosition = 'Goleiro';
      _selectedSecondaryPosition = 'Nenhuma';
      _selectedPreferredFoot = 'Direita';
      print('🔍 DEBUG - Dados do usuário carregados: ${currentUser.email}');
    }
  }

  Future<void> _loadProfileImage() async {
    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        // Usar a URL da foto de perfil do modelo User
        setState(() {
          _profileImageUrl = currentUser.profileImageUrl;
        });
      }
    } catch (e) {
      print('❌ Erro ao carregar foto de perfil: $e');
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2000),
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

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;

    // Verificar se o aniversário ainda não aconteceu este ano
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  String _formatBirthDateWithAge(DateTime birthDate) {
    final age = _calculateAge(birthDate);
    final formattedDate = _formatDate(birthDate);
    return '$formattedDate ($age anos)';
  }

  Future<void> _selectProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
        });

        // Fazer upload automaticamente para o Supabase
        await _uploadProfileImageSimple();
      }
    } catch (e) {
      print('❌ Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadProfileImageSimple() async {
    if (_profileImage == null) return;

    try {
      setState(() {
        _isUploadingImage = true;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('Usuário não encontrado');
      }

      print('📤 Upload iniciado...');

      // Gerar nome único para o arquivo
      final fileName =
          'profile_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Fazer upload
      await SupabaseConfig.client.storage
          .from('profile-images')
          .upload(fileName, _profileImage!);

      print('✅ Upload concluído');

      // Obter URL pública da imagem
      final imageUrl = SupabaseConfig.client.storage
          .from('profile-images')
          .getPublicUrl(fileName);

      // Atualizar o banco de dados
      await SupabaseConfig.client
          .from('users')
          .update({'profile_image_url': imageUrl}).eq('id', currentUser.id);

      // Atualizar o provider
      final updatedUser = currentUser.copyWith(profileImageUrl: imageUrl);
      ref.read(authStateProvider.notifier).updateUser(updatedUser);

      setState(() {
        _profileImageUrl = imageUrl;
        _isUploadingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Foto atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
      });

      print('❌ Erro no upload simples: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSaving = true;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        setState(() {
          _error = 'Usuário não encontrado';
          _isSaving = false;
        });
        return;
      }

      // Atualizar dados do usuário primeiro
      bool userUpdated = await _updateUserData(currentUser);
      if (!userUpdated) {
        setState(() {
          _error = 'Erro ao atualizar dados do usuário';
          _isSaving = false;
        });
        return;
      }

      if (_player == null) {
        // Criar novo perfil de jogador
        final newPlayer = await PlayerService.createPlayer(
          userId: currentUser.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
          primaryPosition: _selectedPrimaryPosition == 'Nenhuma'
              ? null
              : _selectedPrimaryPosition,
          secondaryPosition: _selectedSecondaryPosition == 'Nenhuma'
              ? null
              : _selectedSecondaryPosition,
          preferredFoot: _selectedPreferredFoot,
        );

        if (newPlayer != null) {
          setState(() {
            _player = newPlayer;
            _isEditing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil de jogador criado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _error = 'Erro ao criar perfil de jogador';
          });
        }
      } else {
        // Atualizar perfil de jogador existente
        final updatedPlayer = await PlayerService.updatePlayer(
          playerId: _player!.id,
          name: _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          birthDate: _selectedBirthDate,
          primaryPosition: _selectedPrimaryPosition == 'Nenhuma'
              ? null
              : _selectedPrimaryPosition,
          secondaryPosition: _selectedSecondaryPosition == 'Nenhuma'
              ? null
              : _selectedSecondaryPosition,
          preferredFoot: _selectedPreferredFoot,
        );

        if (updatedPlayer != null) {
          setState(() {
            _player = updatedPlayer;
            _isEditing = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Perfil atualizado com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          setState(() {
            _error = 'Erro ao atualizar perfil';
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      if (_player != null) {
        _loadPlayerData(); // Recarregar dados originais do jogador
      } else {
        _loadUserDataForProfile(); // Recarregar dados do usuário para criação
      }
    });
  }

  Future<bool> _updateUserData(currentUser) async {
    try {
      print('🔍 DEBUG - Iniciando atualização de dados do usuário');
      print('🔍 DEBUG - Email atual: ${currentUser.email}');
      print('🔍 DEBUG - Email novo: ${_emailController.text.trim()}');

      // Email não pode ser alterado - sempre usar o email atual do usuário
      print(
          '🔍 DEBUG - Email não pode ser alterado - usando email atual: ${currentUser.email}');

      // Verificar se a senha foi alterada
      bool passwordChanged = _newPasswordController.text.isNotEmpty;
      print('🔍 DEBUG - Senha alterada: $passwordChanged');

      if (passwordChanged) {
        // Validar senha atual
        if (_currentPasswordController.text.isEmpty) {
          setState(() {
            _error = 'Senha atual é obrigatória para alterar a senha';
          });
          return false;
        }

        // Validar nova senha
        if (_newPasswordController.text != _confirmPasswordController.text) {
          setState(() {
            _error = 'Nova senha e confirmação não coincidem';
          });
          return false;
        }

        if (_newPasswordController.text.length < 6) {
          setState(() {
            _error = 'Nova senha deve ter pelo menos 6 caracteres';
          });
          return false;
        }
      }

      // Atualizar dados básicos do usuário (nome e telefone)
      print('🔍 DEBUG - Atualizando dados básicos do usuário');
      final userUpdated =
          await ref.read(authStateProvider.notifier).updateProfile(
                name: _nameController.text.trim(),
                phone: _phoneController.text.trim(),
              );

      print('🔍 DEBUG - Resultado da atualização de perfil: $userUpdated');

      if (!userUpdated) {
        print('❌ Erro ao atualizar dados básicos do usuário');
        setState(() {
          _error = 'Erro ao atualizar dados do usuário';
        });
        return false;
      }

      print('✅ Dados básicos do usuário atualizados com sucesso');

      // Email não é alterado - sempre usar o email atual do usuário

      // Nota: Alteração de senha agora é feita através do botão "Alterar Senha"

      // Limpar campos de senha após sucesso
      if (passwordChanged) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }

      return true;
    } catch (e) {
      setState(() {
        _error = 'Erro ao atualizar dados do usuário: $e';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        actions: [
          if (!_isEditing && _player != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Editar Perfil',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildProfileContent(currentUser),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.shade600,
          ),
          const SizedBox(height: 16),
          Text(
            'Erro ao criar o perfil do jogador',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red.shade600),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserProfile,
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(currentUser) {
    print(
        '🔍 DEBUG - _buildProfileContent - currentUser: ${currentUser?.email}');
    print('🔍 DEBUG - _buildProfileContent - telefone: ${currentUser?.phone}');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Widget de foto de perfil
            _buildProfilePhotoSection(currentUser),

            const SizedBox(height: 16),

            // Card de informações do usuário
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Colors.blue.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Informações da Conta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Nome', currentUser?.name ?? 'N/A'),
                    _buildInfoRow('Email', currentUser?.email ?? 'N/A'),
                    _buildInfoRow('Telefone', currentUser?.phone ?? 'N/A'),
                    _buildInfoRow(
                        'Cadastrado em',
                        currentUser != null
                            ? _formatDate(currentUser.createdAt)
                            : 'N/A'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Card de informações do jogador
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _player != null
                              ? 'Perfil de Jogador'
                              : 'Criar Perfil de Jogador',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_player == null && !_isEditing) ...[
                      // Mensagem para usuário legado sem perfil
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.orange.shade600,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Você ainda não possui um perfil de jogador.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Clique em "Criar Perfil" para adicionar suas informações de jogador.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                            });
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Criar Perfil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ] else if (_isEditing) ...[
                      _buildEditableFields(),
                    ] else ...[
                      _buildReadOnlyFields(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botões de ação (apenas quando editando)
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_player == null ? 'Criar Perfil' : 'Salvar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
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

  /// Mostra dialog para alterar senha
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              const Text('Alterar Senha'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Senha atual
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Senha Atual',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureCurrentPassword,
              ),
              const SizedBox(height: 16),

              // Nova senha
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Nova Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirmar senha
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nova Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (value != _newPasswordController.text) {
                      return 'Senhas não coincidem';
                    }
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _clearPasswordFields();
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _changePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Alterar Senha'),
            ),
          ],
        );
      },
    );
  }

  /// Altera a senha do usuário
  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty) {
      _showErrorDialog('Senha atual é obrigatória');
      return;
    }

    if (_newPasswordController.text.isEmpty) {
      _showErrorDialog('Nova senha é obrigatória');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Nova senha deve ter pelo menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Nova senha e confirmação não coincidem');
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      final passwordUpdated =
          await ref.read(authStateProvider.notifier).updatePassword(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
              );

      if (passwordUpdated) {
        if (mounted) {
          Navigator.of(context).pop();
          _clearPasswordFields();
          _showSuccessDialog('Senha alterada com sucesso!');
        }
      } else {
        if (mounted) {
          _showErrorDialog('Erro ao alterar senha');
        }
      }
    } catch (e) {
      _showErrorDialog('Erro ao alterar senha: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// Limpa os campos de senha
  void _clearPasswordFields() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  /// Mostra dialog de sucesso
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600),
              const SizedBox(width: 8),
              const Text('Sucesso'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  /// Mostra dialog de erro
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade600),
              const SizedBox(width: 8),
              const Text('Erro'),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfilePhotoSection(currentUser) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Foto de perfil
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null
                      ? FileImage(_profileImage!) as ImageProvider
                      : _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!) as ImageProvider
                          : null,
                  child: _profileImage == null && _profileImageUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[600],
                        )
                      : null,
                ),
                if (_isUploadingImage)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                // Botão de editar foto
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _selectProfileImage,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            // Informações do usuário e botão
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome do usuário
                  Text(
                    currentUser?.name ?? 'Usuário',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Email do usuário
                  Text(
                    currentUser?.email ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botão para alterar foto
                  ElevatedButton.icon(
                    onPressed: _selectProfileImage,
                    icon: const Icon(Icons.photo_camera),
                    label: const Text('Alterar Foto'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyFields() {
    final currentUser = ref.read(currentUserProvider);

    return Column(
      children: [
        _buildInfoRow('Nome', currentUser?.name ?? 'N/A'),
        _buildInfoRow('Email', currentUser?.email ?? 'N/A'),
        _buildInfoRow('Telefone', currentUser?.phone ?? 'N/A'),
        _buildInfoRow(
            'Data de Criação',
            currentUser?.createdAt != null
                ? _formatDate(currentUser!.createdAt)
                : 'N/A'),
        _buildInfoRow(
            'Data de Nascimento',
            _player?.birthDate != null
                ? _formatBirthDateWithAge(_player!.birthDate!)
                : 'N/A'),
        _buildInfoRow('Posição Principal', _player?.primaryPosition ?? 'N/A'),
        _buildInfoRow(
            'Posição Secundária', _player?.secondaryPosition ?? 'N/A'),
        _buildInfoRow('Pé Preferido', _player?.preferredFoot ?? 'N/A'),
        _buildInfoRow(
            'Status', _player?.status == 'active' ? 'Ativo' : 'Inativo'),
      ],
    );
  }

  Widget _buildEditableFields() {
    return Column(
      children: [
        // Nome
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nome',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Nome é obrigatório';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Email - somente leitura para usuários existentes
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            labelText: 'Email',
            prefixIcon: const Icon(Icons.email),
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.lock, color: Colors.grey),
            helperText: 'Email não pode ser alterado após o cadastro',
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
          keyboardType: TextInputType.emailAddress,
          readOnly: true, // Sempre somente leitura
          style: TextStyle(color: Colors.grey.shade600),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email é obrigatório';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Email inválido';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Telefone
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Telefone',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Telefone é obrigatório';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Botão para alterar senha
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_outline),
            label: const Text('Alterar Senha'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Data de nascimento
        TextFormField(
          controller: _birthDateController,
          decoration: const InputDecoration(
            labelText: 'Data de Nascimento',
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          readOnly: true,
          onTap: () => _selectBirthDate(context),
        ),

        const SizedBox(height: 16),

        // Posição principal
        DropdownButtonFormField<String>(
          initialValue: _positions.contains(_selectedPrimaryPosition)
              ? _selectedPrimaryPosition
              : _positions.first,
          decoration: const InputDecoration(
            labelText: 'Posição Principal',
            prefixIcon: Icon(Icons.sports_soccer),
            border: OutlineInputBorder(),
          ),
          items: _positions.map((position) {
            return DropdownMenuItem(
              value: position,
              child: Text(position),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPrimaryPosition = value!;
            });
          },
        ),

        const SizedBox(height: 16),

        // Posição secundária
        DropdownButtonFormField<String>(
          initialValue: FootballPositions.secondaryPositions
                  .contains(_selectedSecondaryPosition)
              ? _selectedSecondaryPosition
              : FootballPositions.secondaryPositions.first,
          decoration: const InputDecoration(
            labelText: 'Posição Secundária',
            prefixIcon: Icon(Icons.sports_soccer),
            border: OutlineInputBorder(),
          ),
          items: FootballPositions.secondaryPositions.map((position) {
            return DropdownMenuItem(
              value: position,
              child: Text(position),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSecondaryPosition = value!;
            });
          },
        ),

        const SizedBox(height: 16),

        // Pé preferido
        DropdownButtonFormField<String>(
          initialValue: _feet.contains(_selectedPreferredFoot)
              ? _selectedPreferredFoot
              : _feet.first,
          decoration: const InputDecoration(
            labelText: 'Pé Preferido',
            prefixIcon: Icon(Icons.directions_run),
            border: OutlineInputBorder(),
          ),
          items: _feet.map((foot) {
            return DropdownMenuItem(
              value: foot,
              child: Text(foot),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedPreferredFoot = value!;
            });
          },
        ),
      ],
    );
  }
}
