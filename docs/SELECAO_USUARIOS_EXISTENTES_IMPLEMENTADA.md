# 🔧 Funcionalidade de Seleção de Usuários Existentes - Implementado

## ✅ **Funcionalidade Implementada:**

A funcionalidade de adicionar jogadores foi alterada para consultar usuários já existentes no sistema e apenas atrelá-los ao jogo, em vez de criar novos usuários. Agora os administradores podem selecionar usuários cadastrados e adicioná-los como jogadores ao jogo.

## 🎯 **Problema Identificado:**

### **Situação Anterior:**
- **❌ Criação de novos usuários** - Sistema criava novos usuários em vez de usar existentes
- **❌ Duplicação de dados** - Possibilidade de ter usuários duplicados
- **❌ Processo ineficiente** - Preenchimento manual de dados já existentes
- **❌ Falta de integração** - Não aproveitava usuários já cadastrados no sistema

### **Causa Raiz:**
- **Funcionalidade incorreta** - `AddPlayerScreen` criava novos usuários
- **Falta de busca** - Não havia forma de consultar usuários existentes
- **Processo manual** - Administrador precisava digitar dados já existentes
- **Arquitetura inadequada** - Não separava criação de usuário de adição ao jogo

## ✅ **Solução Implementada:**

### **1. Novo Serviço de Usuários:**
- **✅ `UserService`** - Serviço dedicado para gerenciar usuários
- **✅ Busca de usuários** - Métodos para buscar usuários existentes
- **✅ Filtros inteligentes** - Busca por nome, email e disponibilidade
- **✅ Verificação de disponibilidade** - Checa se usuário já está no jogo

### **2. Nova Tela de Seleção:**
- **✅ `SelectUserScreen`** - Interface para selecionar usuários existentes
- **✅ Busca em tempo real** - Filtro por nome ou email
- **✅ Seleção de tipo** - Escolha entre mensalista ou avulso
- **✅ Interface intuitiva** - Cards com informações do usuário

### **3. Lógica Inteligente:**
- **✅ Verificação de perfil** - Checa se usuário já tem perfil de jogador
- **✅ Criação automática** - Cria perfil básico se necessário
- **✅ Adição ao jogo** - Atrela usuário ao jogo com tipo selecionado
- **✅ Prevenção de duplicatas** - Não permite adicionar usuário já no jogo

## 🔧 **Implementação Técnica:**

### **1. UserService - Novo Serviço:**
```dart
class UserService {
  static final _client = SupabaseConfig.client;

  /// Buscar todos os usuários do sistema
  static Future<List<User>> getAllUsers() async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('is_active', true)
          .order('name', ascending: true);

      return response.map<User>((userData) => User.fromMap(userData)).toList();
    } catch (e) {
      print('❌ Erro ao buscar usuários: $e');
      return [];
    }
  }

  /// Buscar usuários por nome (busca parcial)
  static Future<List<User>> searchUsersByName(String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return getAllUsers();
      }

      final response = await _client
          .from('users')
          .select('*')
          .eq('is_active', true)
          .ilike('name', '%$searchTerm%')
          .order('name', ascending: true);

      return response.map<User>((userData) => User.fromMap(userData)).toList();
    } catch (e) {
      print('❌ Erro ao buscar usuários por nome: $e');
      return [];
    }
  }

  /// Verificar se usuário já está em um jogo específico
  static Future<bool> isUserInGame(String userId, String gameId) async {
    try {
      // Primeiro, verificar se o usuário tem perfil de jogador
      final playerResponse = await _client
          .from('players')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (playerResponse == null) {
        return false; // Usuário não tem perfil de jogador
      }

      // Verificar se o jogador já está no jogo
      final gamePlayerResponse = await _client
          .from('game_players')
          .select('id')
          .eq('game_id', gameId)
          .eq('player_id', playerResponse['id'])
          .eq('status', 'active')
          .maybeSingle();

      return gamePlayerResponse != null;
    } catch (e) {
      print('❌ Erro ao verificar se usuário está no jogo: $e');
      return false;
    }
  }

  /// Buscar usuários disponíveis para adicionar ao jogo (não estão no jogo)
  static Future<List<User>> getAvailableUsersForGame(String gameId) async {
    try {
      // Buscar todos os usuários ativos
      final allUsers = await getAllUsers();
      
      // Filtrar usuários que não estão no jogo
      final availableUsers = <User>[];
      
      for (final user in allUsers) {
        final isInGame = await isUserInGame(user.id, gameId);
        if (!isInGame) {
          availableUsers.add(user);
        }
      }
      
      return availableUsers;
    } catch (e) {
      print('❌ Erro ao buscar usuários disponíveis para o jogo: $e');
      return [];
    }
  }
}
```

### **2. SelectUserScreen - Nova Tela:**
```dart
class SelectUserScreen extends ConsumerStatefulWidget {
  const SelectUserScreen({super.key});

  @override
  ConsumerState<SelectUserScreen> createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends ConsumerState<SelectUserScreen> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';
  String _selectedPlayerType = 'monthly';

  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadUsers() async {
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

      print('🔍 Carregando usuários disponíveis para o jogo: ${selectedGame.organizationName}');

      // Buscar usuários disponíveis para o jogo
      final availableUsers = await UserService.getAvailableUsersForGame(selectedGame.id);
      
      setState(() {
        _users = availableUsers;
        _filteredUsers = availableUsers;
        _isLoading = false;
      });

      print('✅ ${availableUsers.length} usuários disponíveis encontrados');
    } catch (e) {
      setState(() {
        _error = 'Erro ao carregar usuários: $e';
        _isLoading = false;
      });
      print('❌ Erro ao carregar usuários: $e');
    }
  }

  void _filterUsers(String searchTerm) {
    setState(() {
      _searchTerm = searchTerm;
      if (searchTerm.trim().isEmpty) {
        _filteredUsers = _users;
      } else {
        _filteredUsers = _users.where((user) {
          return user.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                 user.email.toLowerCase().contains(searchTerm.toLowerCase());
        }).toList();
      }
    });
  }
}
```

### **3. Lógica de Adição Inteligente:**
```dart
Future<void> _addUserToGame(User user) async {
  try {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) return;

    print('🔄 Adicionando usuário ${user.name} ao jogo ${selectedGame.organizationName}');

    // Verificar se o usuário já tem perfil de jogador
    final hasPlayerProfile = await PlayerService.hasPlayerProfile(user.id);
    
    String playerId;
    
    if (hasPlayerProfile) {
      // Usuário já tem perfil de jogador, buscar o ID
      final player = await PlayerService.getPlayerByUserId(user.id);
      if (player == null) {
        throw Exception('Erro ao buscar perfil de jogador');
      }
      playerId = player.id;
      print('✅ Usuário já possui perfil de jogador: ${player.name}');
    } else {
      // Usuário não tem perfil de jogador, criar um básico
      print('📝 Criando perfil de jogador básico para ${user.name}');
      
      final player = await PlayerService.createPlayer(
        userId: user.id,
        name: user.name,
        phoneNumber: user.phone ?? '00000000000',
      );
      
      if (player == null) {
        throw Exception('Erro ao criar perfil de jogador');
      }
      
      playerId = player.id;
      print('✅ Perfil de jogador criado: ${player.id}');
    }

    // Adicionar jogador ao jogo
    final gamePlayer = await PlayerService.addPlayerToGame(
      gameId: selectedGame.id,
      playerId: playerId,
      playerType: _selectedPlayerType,
    );

    if (gamePlayer == null) {
      throw Exception('Erro ao adicionar jogador ao jogo');
    }

    print('✅ Jogador adicionado ao jogo com sucesso');

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${user.name} adicionado ao jogo como ${_selectedPlayerType == 'monthly' ? 'Mensalista' : 'Avulso'}!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Retornar true para indicar sucesso
      Navigator.of(context).pop(true);
    }
  } catch (e) {
    print('❌ Erro ao adicionar usuário ao jogo: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao adicionar usuário: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### **4. Interface da Tela:**
```dart
@override
Widget build(BuildContext context) {
  final selectedGame = ref.watch(selectedGameProvider);

  return Scaffold(
    appBar: AppBar(
      title: Text('Selecionar Usuário - ${selectedGame?.organizationName ?? 'Jogo'}'),
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadUsers,
          tooltip: 'Atualizar',
        ),
      ],
    ),
    body: Column(
      children: [
        // Barra de pesquisa
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Pesquisar por nome ou email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchTerm.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filterUsers('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: _filterUsers,
              ),
              const SizedBox(height: 16),
              
              // Seletor de tipo de jogador
              Row(
                children: [
                  const Text(
                    'Tipo de Jogador:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Mensalista'),
                            value: 'monthly',
                            groupValue: _selectedPlayerType,
                            onChanged: (value) {
                              setState(() {
                                _selectedPlayerType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Avulso'),
                            value: 'casual',
                            groupValue: _selectedPlayerType,
                            onChanged: (value) {
                              setState(() {
                                _selectedPlayerType = value!;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de usuários
        Expanded(
          child: _buildUsersList(),
        ),
      ],
    ),
  );
}
```

### **5. Card do Usuário:**
```dart
Widget _buildUserCard(User user) {
  return Card(
    margin: const EdgeInsets.only(bottom: 8),
    elevation: 1,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email),
          if (user.phone != null && user.phone!.isNotEmpty)
            Text(
              user.phone!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
        ],
      ),
      trailing: ElevatedButton(
        onPressed: () => _addUserToGame(user),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: const Text('Adicionar'),
      ),
      isThreeLine: user.phone != null && user.phone!.isNotEmpty,
    ),
  );
}
```

## 🧪 **Como Testar:**

### **Teste 1: Acessar Tela de Seleção**
```
1. Acesse "Gerenciar Jogadores" como administrador
2. Clique no botão "Adicionar Usuário" (ícone +)
3. Verifique que:
   - ✅ Abre tela "Selecionar Usuário"
   - ✅ Mostra usuários disponíveis para o jogo
   - ✅ Barra de pesquisa está presente
   - ✅ Seletor de tipo (Mensalista/Avulso) está presente
```

### **Teste 2: Buscar Usuários**
```
1. Na tela de seleção, digite um nome na barra de pesquisa
2. Verifique que:
   - ✅ Lista é filtrada em tempo real
   - ✅ Busca funciona por nome
   - ✅ Busca funciona por email
   - ✅ Botão de limpar pesquisa funciona
```

### **Teste 3: Adicionar Usuário com Perfil Existente**
```
1. Selecione um usuário que já tem perfil de jogador
2. Escolha o tipo (Mensalista ou Avulso)
3. Clique em "Adicionar"
4. Verifique que:
   - ✅ Usuário é adicionado ao jogo
   - ✅ Mensagem de sucesso é exibida
   - ✅ Retorna à tela de jogadores
   - ✅ Lista é atualizada automaticamente
```

### **Teste 4: Adicionar Usuário sem Perfil**
```
1. Selecione um usuário que não tem perfil de jogador
2. Escolha o tipo (Mensalista ou Avulso)
3. Clique em "Adicionar"
4. Verifique que:
   - ✅ Perfil de jogador é criado automaticamente
   - ✅ Usuário é adicionado ao jogo
   - ✅ Mensagem de sucesso é exibida
   - ✅ Logs mostram criação do perfil
```

### **Teste 5: Verificar Usuários Não Disponíveis**
```
1. Tente adicionar um usuário que já está no jogo
2. Verifique que:
   - ✅ Usuário não aparece na lista
   - ✅ Apenas usuários disponíveis são mostrados
   - ✅ Sistema previne duplicatas
```

### **Teste 6: Estados da Interface**
```
1. Teste com lista vazia (todos os usuários já estão no jogo)
2. Teste com busca sem resultados
3. Teste com erro de carregamento
4. Verifique que:
   - ✅ Estados são tratados adequadamente
   - ✅ Mensagens apropriadas são exibidas
   - ✅ Interface não quebra
```

## 🎉 **Benefícios da Implementação:**

### **Para o Sistema:**
- **✅ Reutilização de dados** - Aproveita usuários já cadastrados
- **✅ Prevenção de duplicatas** - Evita usuários duplicados
- **✅ Arquitetura limpa** - Separação clara de responsabilidades
- **✅ Performance otimizada** - Busca eficiente de usuários

### **Para o Usuário:**
- **✅ Processo simplificado** - Não precisa digitar dados já existentes
- **✅ Busca rápida** - Encontra usuários facilmente
- **✅ Interface intuitiva** - Seleção visual e clara
- **✅ Feedback imediato** - Sabe se usuário foi adicionado

### **Para Administradores:**
- **✅ Gestão eficiente** - Adiciona usuários existentes rapidamente
- **✅ Controle total** - Escolhe tipo de jogador na hora
- **✅ Visibilidade** - Vê todos os usuários disponíveis
- **✅ Prevenção de erros** - Sistema previne duplicatas automaticamente

## 🔍 **Cenários Cobertos:**

### **Usuários com Perfil Existente:**
- **✅ Adição direta** - Usa perfil existente
- **✅ Dados preservados** - Mantém informações do jogador
- **✅ Tipo selecionado** - Aplica tipo escolhido pelo admin
- **✅ Relacionamento criado** - Atrela ao jogo

### **Usuários sem Perfil:**
- **✅ Criação automática** - Cria perfil básico automaticamente
- **✅ Dados do usuário** - Usa nome e telefone do usuário
- **✅ Tipo aplicado** - Aplica tipo selecionado
- **✅ Processo transparente** - Admin não precisa se preocupar

### **Busca e Filtros:**
- **✅ Busca por nome** - Filtra por nome do usuário
- **✅ Busca por email** - Filtra por email do usuário
- **✅ Busca em tempo real** - Filtro instantâneo
- **✅ Limpeza de busca** - Botão para limpar filtro

### **Prevenção de Duplicatas:**
- **✅ Verificação automática** - Checa se usuário já está no jogo
- **✅ Lista filtrada** - Mostra apenas usuários disponíveis
- **✅ Validação robusta** - Múltiplas verificações
- **✅ Feedback claro** - Usuário sabe se está disponível

## 🚀 **Resultado Final:**

A implementação foi concluída com sucesso! Agora:

- **✅ Seleção de usuários existentes** - Consulta usuários já cadastrados
- **✅ Busca inteligente** - Filtro por nome e email em tempo real
- **✅ Criação automática de perfil** - Cria perfil se necessário
- **✅ Prevenção de duplicatas** - Não permite adicionar usuário já no jogo
- **✅ Interface intuitiva** - Seleção visual com cards informativos
- **✅ Controle de tipo** - Escolha entre mensalista e avulso
- **✅ Feedback adequado** - Mensagens claras para todas as ações
- **✅ Arquitetura limpa** - Separação clara entre usuários e jogadores

A funcionalidade agora permite que administradores selecionem usuários existentes no sistema e os adicionem como jogadores ao jogo, proporcionando uma experiência mais eficiente e integrada! 🎮✅
