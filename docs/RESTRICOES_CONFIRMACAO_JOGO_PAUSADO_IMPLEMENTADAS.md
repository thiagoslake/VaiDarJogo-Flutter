# Restrições de Confirmação para Jogos Pausados/Inativados - Implementadas

## 🎯 **Objetivo**

Implementar restrições para que:
1. **Jogos pausados/inativados** não permitam confirmação manual de jogadores
2. **Ao pausar/inativar** um jogo, todas as confirmações sejam removidas

## 🔧 **Implementações**

### **1. Remoção de Confirmações ao Pausar/Inativar**

#### **A. GameService Atualizado:**

**Arquivo:** `lib/services/game_service.dart`

##### **Método `pauseGame()`:**
```dart
static Future<bool> pauseGame({required String gameId}) async {
  try {
    // 1. Pausar o jogo
    final response = await _client.from('games').update({
      'status': 'paused',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', gameId).select();

    // 2. Pausar todas as sessões ativas do jogo
    await _pauseGameSessions(gameId);

    // 3. Remover todas as confirmações dos jogadores
    await _clearGameConfirmations(gameId);

    return true;
  } catch (e) {
    print('❌ Erro ao pausar jogo: $e');
    rethrow;
  }
}
```

##### **Método `deleteGame()`:**
```dart
static Future<bool> deleteGame({required String gameId}) async {
  try {
    // 1. Remover apenas sessões futuras
    // 2. Inativar relacionamentos jogador-jogo
    // 3. Marcar o jogo como deletado
    // 4. Remover todas as confirmações dos jogadores
    await _clearGameConfirmations(gameId);

    return true;
  } catch (e) {
    print('❌ Erro ao inativar jogo: $e');
    rethrow;
  }
}
```

##### **Novo Método `_clearGameConfirmations()`:**
```dart
static Future<void> _clearGameConfirmations(String gameId) async {
  try {
    print('🗑️ Removendo confirmações do jogo: $gameId');

    final deletedCount = await PlayerConfirmationService.deleteAllGameConfirmations(gameId);
    
    if (deletedCount) {
      print('✅ Confirmações removidas com sucesso');
    } else {
      print('ℹ️ Nenhuma confirmação encontrada para remover');
    }
  } catch (e) {
    print('❌ Erro ao remover confirmações: $e');
    // Não falha o processo principal se houver erro na remoção de confirmações
  }
}
```

### **2. Restrições na Tela de Confirmação Manual**

#### **A. ManualPlayerConfirmationScreen Atualizado:**

**Arquivo:** `lib/screens/manual_player_confirmation_screen.dart`

##### **Verificação no Carregamento:**
```dart
Future<void> _loadPlayersWithConfirmations() async {
  try {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) {
      setState(() {
        _error = 'Jogo não selecionado';
        _isLoading = false;
      });
      return;
    }

    // Verificar se o jogo está ativo
    final isGameActive = await GameService.isGameActive(gameId: selectedGame.id);
    if (!isGameActive) {
      setState(() {
        _error = 'Jogo pausado ou inativado. Confirmação manual não disponível.';
        _isLoading = false;
      });
      return;
    }

    // Carregar jogadores com confirmações...
  } catch (e) {
    // Tratamento de erro...
  }
}
```

##### **Verificação em Todas as Ações:**
```dart
Future<void> _confirmPlayer(String playerId, String playerName) async {
  try {
    final selectedGame = ref.read(selectedGameProvider);
    if (selectedGame == null) return;

    // Verificar se o jogo ainda está ativo
    final isGameActive = await GameService.isGameActive(gameId: selectedGame.id);
    if (!isGameActive) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Jogo pausado ou inativado. Confirmação não permitida.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Proceder com a confirmação...
  } catch (e) {
    // Tratamento de erro...
  }
}
```

**Aplicado também em:**
- `_declinePlayer()` - Declinar presença
- `_resetPlayerConfirmation()` - Resetar confirmação

### **3. Mensagens de Aviso Atualizadas**

#### **A. Dialog de Pausar Jogo:**

**Arquivo:** `lib/screens/game_details_screen.dart`

```dart
AlertDialog(
  title: const Text('Pausar Jogo'),
  content: Column(
    children: [
      Text('Tem certeza que deseja pausar o jogo "${game.organizationName}"?'),
      const SizedBox(height: 8),
      const Text(
        'O jogo será temporariamente desativado e não aparecerá nas listagens ativas.',
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      const Text(
        '⚠️ Todas as confirmações de presença serão removidas.',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
      ),
    ],
  ),
  // ... ações
)
```

#### **B. Dialog de Inativar Jogo:**

```dart
AlertDialog(
  title: const Text('Inativar Jogo'),
  content: Column(
    children: [
      Text('Tem certeza que deseja inativar o jogo "${game.organizationName}"?'),
      const SizedBox(height: 8),
      const Text(
        '⚠️ ATENÇÃO: Esta ação não pode ser desfeita!',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      const Text(
        'O que será feito:\n• Jogo será marcado como inativo\n• Sessões futuras serão removidas\n• Histórico de sessões passadas será preservado\n• Relacionamentos com jogadores serão inativados\n• Todas as confirmações de presença serão removidas',
        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
      ),
    ],
  ),
  // ... ações
)
```

## 🧪 **Cenários de Teste**

### **1. Pausar Jogo:**
```
1. Jogo ativo com confirmações
2. Administrador pausa o jogo
3. ✅ Jogo marcado como 'paused'
4. ✅ Sessões pausadas
5. ✅ Confirmações removidas
6. ✅ Tela de confirmação manual mostra erro
```

### **2. Inativar Jogo:**
```
1. Jogo ativo com confirmações
2. Administrador inativa o jogo
3. ✅ Jogo marcado como 'deleted'
4. ✅ Sessões futuras removidas
5. ✅ Relacionamentos inativados
6. ✅ Confirmações removidas
7. ✅ Tela de confirmação manual mostra erro
```

### **3. Tentativa de Confirmação em Jogo Pausado:**
```
1. Jogo pausado
2. Usuário tenta acessar confirmação manual
3. ✅ Tela mostra: "Jogo pausado ou inativado. Confirmação manual não disponível."
4. ✅ Nenhuma ação de confirmação é permitida
```

### **4. Reativar Jogo:**
```
1. Jogo pausado (sem confirmações)
2. Administrador reativa o jogo
3. ✅ Jogo marcado como 'active'
4. ✅ Sessões reativadas
5. ✅ Confirmação manual volta a funcionar
6. ✅ Jogadores podem ser confirmados novamente
```

## 🚀 **Vantagens**

1. **✅ Consistência de dados** - Confirmações não ficam órfãs
2. **✅ UX clara** - Usuário sabe que confirmações serão removidas
3. **✅ Prevenção de erros** - Não permite confirmações em jogos inativos
4. **✅ Feedback imediato** - Mensagens claras sobre restrições
5. **✅ Processo atômico** - Tudo ou nada na pausa/inativação

## 📋 **Fluxo Completo**

### **Pausar Jogo:**
```
1. Usuário clica "Pausar Jogo"
2. Dialog mostra aviso sobre remoção de confirmações
3. Usuário confirma
4. Jogo pausado + Sessões pausadas + Confirmações removidas
5. Tela de confirmação manual bloqueada
```

### **Inativar Jogo:**
```
1. Usuário clica "Inativar Jogo"
2. Dialog mostra aviso sobre remoção de confirmações
3. Usuário confirma
4. Jogo inativado + Sessões futuras removidas + Confirmações removidas
5. Tela de confirmação manual bloqueada
```

### **Tentativa de Confirmação:**
```
1. Usuário acessa confirmação manual
2. Sistema verifica status do jogo
3. Se pausado/inativado: Mostra erro e bloqueia ações
4. Se ativo: Permite confirmações normalmente
```

---

**Status:** ✅ **IMPLEMENTADO**  
**Data:** 2025-01-27  
**Funcionalidade:** Restrições de confirmação para jogos pausados/inativados
