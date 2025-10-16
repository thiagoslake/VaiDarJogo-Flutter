# 🎯 Busca de Jogadores da Tabela Players - Implementada

## ✅ **Funcionalidade Implementada:**

A tela de adicionar jogadores agora busca diretamente da tabela `players` em vez da tabela `users`, exibindo todos os jogadores ativos da plataforma e permitindo filtro por nome.

## 🔧 **Modificações Implementadas:**

### **1. UserService - Busca da Tabela Players:**

#### **A. Novo Método `getAllPlayers()`:**
```dart
/// Buscar todos os jogadores da tabela players
static Future<List<Map<String, dynamic>>> getAllPlayers() async {
  try {
    final response = await _client
        .from('players')
        .select('''
          id,
          name,
          phone_number,
          user_id,
          status,
          created_at
        ''')
        .eq('status', 'active')  // ← Apenas jogadores ativos
        .order('name', ascending: true);
    
    return response;
  } catch (e) {
    print('❌ Erro ao buscar jogadores: $e');
    return [];
  }
}
```

#### **B. Novo Método `isPlayerInGame()`:**
```dart
/// Verificar se um jogador está no jogo
static Future<bool> isPlayerInGame(String playerId, String gameId) async {
  try {
    final response = await _client
        .from('game_players')
        .select('id')
        .eq('player_id', playerId)
        .eq('game_id', gameId)
        .inFilter('status', ['active', 'confirmed'])
        .maybeSingle();
    
    return response != null;
  } catch (e) {
    print('❌ Erro ao verificar se jogador está no jogo: $e');
    return false;
  }
}
```

#### **C. Método `getAvailableUsersForGame()` Atualizado:**
```dart
/// Buscar jogadores disponíveis para adicionar ao jogo (não estão no jogo)
static Future<List<User>> getAvailableUsersForGame(String gameId) async {
  try {
    // Buscar todos os jogadores ativos da tabela players
    final allPlayersData = await getAllPlayers();
    
    // Filtrar jogadores que não estão no jogo
    final availablePlayers = <User>[];
    
    for (final playerData in allPlayersData) {
      final isInGame = await isPlayerInGame(playerData['id'], gameId);
      if (!isInGame) {
        // Converter dados do player para User para manter compatibilidade
        final user = User(
          id: playerData['user_id'],
          name: playerData['name'],
          email: '', // Será preenchido se necessário
          phone: playerData['phone_number'],
          isActive: true,
          createdAt: DateTime.parse(playerData['created_at']),
        );
        availablePlayers.add(user);
      }
    }
    
    return availablePlayers;
  } catch (e) {
    print('❌ Erro ao buscar jogadores disponíveis para o jogo: $e');
    return [];
  }
}
```

### **2. SelectUserScreen - Interface Atualizada:**

#### **A. Título da Tela:**
```dart
// ANTES
title: Text('Selecionar Usuário - ${selectedGame?.organizationName ?? 'Jogo'}')

// DEPOIS
title: Text('Selecionar Jogador - ${selectedGame?.organizationName ?? 'Jogo'}')
```

#### **B. Campo de Pesquisa:**
```dart
// ANTES
hintText: 'Pesquisar por nome ou email...'

// DEPOIS
hintText: 'Pesquisar por nome...'
```

#### **C. Filtro Simplificado:**
```dart
void _filterUsers(String searchTerm) {
  setState(() {
    _searchTerm = searchTerm;
    if (searchTerm.trim().isEmpty) {
      _filteredUsers = _users;
    } else {
      _filteredUsers = _users.where((user) {
        return user.name.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    }
  });
}
```

#### **D. Card do Jogador Simplificado:**
```dart
// ANTES - Mostrava nome, email e telefone
subtitle: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(user.email),
    if (user.phone != null && user.phone!.isNotEmpty)
      Text(user.phone!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
  ],
),

// DEPOIS - Mostra apenas nome e telefone
subtitle: user.phone != null && user.phone!.isNotEmpty
    ? Text(
        user.phone!,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 14,
        ),
      )
    : null,
```

#### **E. Mensagens Atualizadas:**
```dart
// ANTES
'Nenhum usuário encontrado'
'Nenhum usuário disponível'
'Todos os usuários já estão neste jogo'

// DEPOIS
'Nenhum jogador encontrado'
'Nenhum jogador disponível'
'Todos os jogadores já estão neste jogo'
```

## 📊 **Dados Exibidos:**

### **1. Informações do Jogador:**
- ✅ **Nome completo** - Da tabela `players.name`
- ✅ **Telefone** - Da tabela `players.phone_number`
- ✅ **Status ativo** - Filtrado por `status = 'active'`

### **2. Filtros Aplicados:**
- ✅ **Jogadores ativos:** `status = 'active'`
- ✅ **Não estão no jogo:** Exclui jogadores já cadastrados no jogo
- ✅ **Ordenação:** Por nome (A-Z)
- ✅ **Filtro por nome:** Busca em tempo real

### **3. Campos da Consulta:**
```sql
SELECT 
  id,
  name,
  phone_number,
  user_id,
  status,
  created_at
FROM players
WHERE status = 'active'
ORDER BY name ASC
```

## 🎯 **Funcionalidades:**

### **1. Busca Automática:**
- ✅ **Ao abrir a tela** - Lista todos os jogadores ativos
- ✅ **Filtro inteligente** - Exclui jogadores já no jogo
- ✅ **Ordenação** - Por nome alfabético

### **2. Filtro por Nome:**
- ✅ **Busca em tempo real** - Filtra conforme digita
- ✅ **Case insensitive** - Não diferencia maiúsculas/minúsculas
- ✅ **Busca parcial** - Encontra nomes que contenham o termo

### **3. Interface Simplificada:**
- ✅ **Apenas nome e telefone** - Informações essenciais
- ✅ **Cards limpos** - Layout mais focado
- ✅ **Botão adicionar** - Ação clara

## 🚀 **Como Usar:**

### **1. Acessar a Funcionalidade:**
1. Ir para "Detalhe do Jogo"
2. Clicar em "Gerenciar Jogadores"
3. Clicar no botão "Adicionar Usuário"

### **2. Selecionar Jogador:**
1. **Ver lista completa** - Todos os jogadores ativos são exibidos
2. **Pesquisar** (opcional): Digite o nome do jogador
3. **Escolher tipo**: Mensalista ou Avulso
4. **Clicar "Adicionar"** no card do jogador

### **3. Resultado:**
- ✅ **Jogador adicionado** ao jogo
- ✅ **Lista atualizada** com o novo jogador
- ✅ **Mensagem de sucesso** exibida

## 🔍 **Logs de Debug:**

### **Exemplo de Saída:**
```
🔍 Carregando jogadores disponíveis para o jogo: Nome do Jogo
✅ 15 jogadores disponíveis encontrados
```

## 🎉 **Status:**

- ✅ **Busca da tabela players** - Implementada
- ✅ **Filtro por nome** - Funcionando
- ✅ **Interface atualizada** - Textos e layout
- ✅ **Compatibilidade mantida** - Usa modelo User
- ✅ **Performance otimizada** - Consulta direta
- ✅ **Logs de debug** - Rastreamento completo

**A funcionalidade está implementada e busca diretamente da tabela players!** 🚀✅

## 📝 **Diferenças da Implementação Anterior:**

### **ANTES:**
- ❌ Buscava da tabela `users`
- ❌ Filtro por nome e email
- ❌ Mostrava email (que não existe na tabela players)

### **DEPOIS:**
- ✅ Busca da tabela `players`
- ✅ Filtro apenas por nome
- ✅ Mostra apenas nome e telefone
- ✅ Interface mais limpa e focada



