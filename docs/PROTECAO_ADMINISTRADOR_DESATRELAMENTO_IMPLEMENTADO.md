# 🔧 Proteção de Administrador e Desatrelamento de Jogadores - Implementado

## ✅ **Funcionalidades Implementadas:**

Duas funcionalidades importantes foram implementadas para proteger administradores e preservar dados de usuários:

1. **Proteção de Administrador** - Não é possível remover o administrador do jogo
2. **Desatrelamento Seguro** - Remoção apenas desatrela o jogador do jogo, preservando dados

## 🎯 **Problemas Identificados:**

### **Situação Anterior:**
- **❌ Administrador removível** - Era possível remover o administrador do jogo
- **❌ Exclusão de dados** - Remoção deletava completamente o relacionamento
- **❌ Perda de informações** - Dados do jogador eram perdidos
- **❌ Falta de proteção** - Sem validação de permissões especiais

### **Causa Raiz:**
- **Falta de verificação** - Não verificava se jogador era administrador
- **Método inadequado** - Usava `DELETE` em vez de `UPDATE`
- **Sem validação** - Não havia proteção contra remoção de admin
- **Interface confusa** - Botão de remover aparecia para todos

## ✅ **Solução Implementada:**

### **1. Proteção de Administrador:**
- **✅ Verificação automática** - Checa se jogador é administrador antes de remover
- **✅ Bloqueio na interface** - Botão de remover não aparece para administradores
- **✅ Badge visual** - Administradores têm badge "Admin" verde
- **✅ Validação dupla** - Verificação tanto na UI quanto no serviço

### **2. Desatrelamento Seguro:**
- **✅ Preservação de dados** - Apenas marca como `inactive` em vez de deletar
- **✅ Relacionamento mantido** - `user_id` do jogador é preservado
- **✅ Possibilidade de reativação** - Jogador pode ser reativado no futuro
- **✅ Histórico preservado** - Mantém histórico de participação

### **3. Interface Melhorada:**
- **✅ Badge de administrador** - Identificação visual clara
- **✅ Botão condicional** - Remover só aparece para não-administradores
- **✅ Mensagens claras** - Feedback específico para cada situação
- **✅ Tratamento de erros** - Mensagens apropriadas para cada erro

## 🔧 **Implementação Técnica:**

### **1. PlayerService - Verificação de Administrador:**
```dart
/// Verificar se um jogador é administrador de um jogo
static Future<bool> isPlayerGameAdmin({
  required String gameId,
  required String playerId,
}) async {
  try {
    // Buscar o user_id do jogador
    final playerResponse = await _client
        .from('players')
        .select('user_id')
        .eq('id', playerId)
        .maybeSingle();

    if (playerResponse == null) {
      return false;
    }

    final userId = playerResponse['user_id'];

    // Verificar se o user_id é o administrador do jogo
    final gameResponse = await _client
        .from('games')
        .select('user_id')
        .eq('id', gameId)
        .maybeSingle();

    if (gameResponse == null) {
      return false;
    }

    final gameAdminId = gameResponse['user_id'];
    final isAdmin = userId == gameAdminId;

    print('🔍 Verificação de administrador:');
    print('   - Jogador user_id: $userId');
    print('   - Jogo admin user_id: $gameAdminId');
    print('   - É administrador: $isAdmin');

    return isAdmin;
  } catch (e) {
    print('❌ Erro ao verificar se jogador é administrador: $e');
    return false;
  }
}
```

### **2. PlayerService - Desatrelamento Seguro:**
```dart
/// Remover jogador de um jogo (apenas desatrelar, não deletar)
static Future<bool> removePlayerFromGame({
  required String gameId,
  required String playerId,
}) async {
  try {
    // Verificar se o jogador é administrador do jogo
    final isAdmin = await isPlayerGameAdmin(
      gameId: gameId,
      playerId: playerId,
    );

    if (isAdmin) {
      print('❌ Não é possível remover o administrador do jogo');
      throw Exception('Não é possível remover o administrador do jogo');
    }

    // Apenas desatrelar o jogador do jogo (marcar como inativo)
    await _client
        .from('game_players')
        .update({'status': 'inactive'})
        .eq('game_id', gameId)
        .eq('player_id', playerId);

    print('✅ Jogador desatrelado do jogo com sucesso (status: inactive)');
    return true;
  } catch (e) {
    print('❌ Erro ao remover jogador do jogo: $e');
    rethrow; // Re-lançar o erro para que a UI possa tratá-lo
  }
}
```

### **3. GamePlayersScreen - Verificação na UI:**
```dart
Future<void> _removePlayerFromGame(Map<String, dynamic> player) async {
  final selectedGame = ref.read(selectedGameProvider);
  if (selectedGame == null) return;

  // Verificar se o jogador é administrador do jogo
  try {
    final isAdmin = await PlayerService.isPlayerGameAdmin(
      gameId: selectedGame.id,
      playerId: player['id'],
    );

    if (isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Não é possível remover o administrador do jogo'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
  } catch (e) {
    print('❌ Erro ao verificar se jogador é administrador: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erro ao verificar permissões: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // Mostrar diálogo de confirmação
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remover Jogador'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tem certeza que deseja remover ${player['name']} do jogo?'),
          const SizedBox(height: 8),
          const Text(
            'O jogador será desatrelado do jogo, mas seus dados serão preservados.',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Remover'),
        ),
      ],
    ),
  );

  if (confirmed != true) return;

  try {
    print('🗑️ Removendo jogador ${player['name']} do jogo ${selectedGame.organizationName}');

    final success = await PlayerService.removePlayerFromGame(
      gameId: selectedGame.id,
      playerId: player['id'],
    );

    if (success) {
      // Recarregar dados
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${player['name']} removido do jogo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      throw Exception('Falha ao remover jogador do jogo');
    }
  } catch (e) {
    print('❌ Erro ao remover jogador: $e');
    if (mounted) {
      String errorMessage = 'Erro ao remover jogador';
      
      // Tratar erros específicos
      if (e.toString().contains('administrador')) {
        errorMessage = 'Não é possível remover o administrador do jogo';
      } else if (e.toString().contains('permissão')) {
        errorMessage = 'Você não tem permissão para esta ação';
      } else {
        errorMessage = 'Erro ao remover jogador: $e';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### **4. Identificação de Administrador na Lista:**
```dart
// Combinar dados dos jogadores com informações do relacionamento
final playersWithGameInfo = response.map<Map<String, dynamic>>((player) {
  final gamePlayer = gamePlayers.firstWhere(
    (gp) => gp.playerId == player['id'],
  );

  // Extrair URL da imagem de perfil do usuário
  final userData = player['users'] as Map<String, dynamic>?;
  final profileImageUrl = userData?['profile_image_url'] as String?;

  // Verificar se o jogador é administrador do jogo
  final isPlayerAdmin = player['user_id'] == selectedGame.userId;

  return {
    ...player,
    'game_player_id': gamePlayer.id,
    'player_type': gamePlayer.playerType,
    'joined_at': gamePlayer.joinedAt.toIso8601String(),
    'status': gamePlayer.status,
    'profile_image_url': profileImageUrl,
    'is_admin': isPlayerAdmin,
  };
}).toList();
```

### **5. Interface Condicional:**
```dart
Widget _buildPlayerCard(Map<String, dynamic> player) {
  final playerType = player['player_type'] as String;
  final isMonthly = playerType == 'monthly';
  final isPlayerAdmin = player['is_admin'] == true;

  return Card(
    // ... outros elementos do card ...
    
    // Controles do administrador
    if (_isAdmin) ...[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switch do tipo
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: isMonthly,
                onChanged: (value) {
                  _updatePlayerType(
                    player['game_player_id'],
                    value ? 'monthly' : 'casual',
                  );
                },
                activeThumbColor: Colors.blue,
                inactiveThumbColor: Colors.orange,
                inactiveTrackColor: Colors.orange[200],
              ),
              const SizedBox(height: 2),
              Text(
                isMonthly ? 'Mensalista' : 'Avulso',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isMonthly ? Colors.blue[700] : Colors.orange[700],
                ),
              ),
            ],
          ),
          // Botão de remover (apenas se não for administrador)
          if (!isPlayerAdmin) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.person_remove, color: Colors.red),
              onPressed: () => _removePlayerFromGame(player),
              tooltip: 'Remover do Jogo',
              iconSize: 20,
            ),
          ] else ...[
            // Badge de administrador
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 14,
                    color: Colors.green[700],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ],
  );
}
```

## 🧪 **Como Testar:**

### **Teste 1: Verificar Badge de Administrador**
```
1. Acesse "Gerenciar Jogadores" como administrador
2. Verifique que:
   - ✅ Administrador tem badge "Admin" verde
   - ✅ Badge tem ícone de admin_panel_settings
   - ✅ Outros jogadores não têm badge de admin
   - ✅ Interface é clara e intuitiva
```

### **Teste 2: Botão de Remover para Administrador**
```
1. Na lista de jogadores, localize o administrador
2. Verifique que:
   - ✅ Botão de remover NÃO aparece para administrador
   - ✅ Apenas badge "Admin" é exibido
   - ✅ Switch de tipo ainda funciona
   - ✅ Interface é consistente
```

### **Teste 3: Botão de Remover para Jogadores Comuns**
```
1. Na lista de jogadores, localize um jogador comum
2. Verifique que:
   - ✅ Botão de remover aparece normalmente
   - ✅ Funcionalidade funciona como esperado
   - ✅ Diálogo de confirmação é exibido
   - ✅ Mensagem explica que dados serão preservados
```

### **Teste 4: Tentativa de Remover Administrador (Via Código)**
```
1. Tente remover administrador através de método direto
2. Verifique que:
   - ✅ Erro é lançado pelo PlayerService
   - ✅ Mensagem "Não é possível remover o administrador" é exibida
   - ✅ Operação é bloqueada com sucesso
   - ✅ Logs mostram a verificação
```

### **Teste 5: Desatrelamento de Jogador Comum**
```
1. Remova um jogador comum do jogo
2. Verifique no banco de dados que:
   - ✅ Registro em game_players tem status = 'inactive'
   - ✅ user_id do jogador é preservado
   - ✅ Dados do jogador na tabela players são mantidos
   - ✅ Relacionamento não é deletado
```

### **Teste 6: Verificação de Lista Atualizada**
```
1. Após remover um jogador, verifique a lista
2. Verifique que:
   - ✅ Jogador removido não aparece mais na lista
   - ✅ Apenas jogadores com status = 'active' são exibidos
   - ✅ Contador de jogadores é atualizado
   - ✅ Interface reflete as mudanças
```

### **Teste 7: Tratamento de Erros**
```
1. Teste cenários de erro (sem conexão, etc.)
2. Verifique que:
   - ✅ Erros são tratados adequadamente
   - ✅ Mensagens específicas são exibidas
   - ✅ Interface não quebra
   - ✅ Logs mostram detalhes do erro
```

## 🎉 **Benefícios da Implementação:**

### **Para o Sistema:**
- **✅ Proteção de integridade** - Administrador não pode ser removido acidentalmente
- **✅ Preservação de dados** - Informações de usuários são mantidas
- **✅ Flexibilidade** - Jogadores podem ser reativados no futuro
- **✅ Auditoria** - Histórico de participação é preservado

### **Para o Usuário:**
- **✅ Segurança** - Administrador está protegido contra remoção
- **✅ Clareza visual** - Badge identifica administradores claramente
- **✅ Interface intuitiva** - Botões aparecem apenas quando apropriado
- **✅ Feedback claro** - Mensagens explicam o que acontece

### **Para Administradores:**
- **✅ Proteção automática** - Não precisam se preocupar com remoção acidental
- **✅ Identificação visual** - Sabem quem são os administradores
- **✅ Controle granular** - Podem gerenciar outros jogadores normalmente
- **✅ Dados preservados** - Informações importantes não são perdidas

## 🔍 **Cenários Cobertos:**

### **Proteção de Administrador:**
- **✅ Verificação automática** - Checa se jogador é admin antes de remover
- **✅ Bloqueio na interface** - Botão não aparece para administradores
- **✅ Validação dupla** - Verificação tanto na UI quanto no serviço
- **✅ Mensagens específicas** - Feedback claro sobre restrições

### **Desatrelamento Seguro:**
- **✅ Preservação de dados** - user_id e informações são mantidas
- **✅ Status inativo** - Marca como inactive em vez de deletar
- **✅ Possibilidade de reativação** - Pode ser reativado no futuro
- **✅ Histórico preservado** - Mantém registro de participação

### **Interface Intuitiva:**
- **✅ Badge de administrador** - Identificação visual clara
- **✅ Botões condicionais** - Aparecem apenas quando apropriado
- **✅ Mensagens explicativas** - Diálogo explica o que acontece
- **✅ Tratamento de erros** - Feedback específico para cada situação

### **Validação Robusta:**
- **✅ Verificação de permissões** - Checa se jogador é administrador
- **✅ Tratamento de exceções** - Lida com erros de forma adequada
- **✅ Logs detalhados** - Facilita debugging e monitoramento
- **✅ Mensagens específicas** - Feedback claro para cada cenário

## 🚀 **Resultado Final:**

A implementação foi concluída com sucesso! Agora:

- **✅ Administrador protegido** - Não pode ser removido do jogo
- **✅ Badge visual** - Administradores são identificados claramente
- **✅ Desatrelamento seguro** - Dados são preservados ao remover jogador
- **✅ Interface condicional** - Botões aparecem apenas quando apropriado
- **✅ Validação dupla** - Verificação tanto na UI quanto no serviço
- **✅ Mensagens claras** - Feedback específico para cada situação
- **✅ Tratamento de erros** - Lida com todos os cenários possíveis
- **✅ Preservação de dados** - Histórico e informações são mantidos

As funcionalidades garantem que administradores estejam protegidos contra remoção acidental e que dados de usuários sejam preservados durante operações de remoção, proporcionando maior segurança e integridade ao sistema! 🎮✅
