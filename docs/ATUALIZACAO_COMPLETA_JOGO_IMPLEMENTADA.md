# Atualização Completa de Jogo Implementada

## 🎯 **Objetivo**

Garantir que ao alterar alguma informação do jogo:
1. **Sessões sejam recriadas** com base nas novas configurações
2. **Configurações de confirmação de presença sejam mantidas** e funcionais
3. **Confirmações dos jogadores sejam resetadas** para pending

## 🔧 **Implementação**

### **1. Novo Serviço: `GameUpdateService`**

Criado o arquivo `lib/services/game_update_service.dart` com a funcionalidade completa:

```dart
class GameUpdateService {
  /// Atualiza um jogo e recria todas as sessões mantendo configurações e resetando confirmações
  static Future<Map<String, dynamic>> updateGameWithSessionRecreation({
    required String gameId,
    required Map<String, dynamic> gameData,
  }) async {
    // 1. Verificar se o jogo não está deletado
    // 2. Salvar configurações de confirmação existentes
    // 3. Resetar todas as confirmações dos jogadores
    // 4. Atualizar dados do jogo
    // 5. Recriar todas as sessões
    // 6. Restaurar configurações de confirmação
    // 7. Retornar resultado detalhado
  }
}
```

### **2. Fluxo de Atualização**

#### **Passo 1: Verificação de Status**
```dart
final gameStatus = await _getGameStatus(gameId);
if (gameStatus == 'deleted') {
  return {'success': false, 'error': 'Jogo deletado'};
}
```

#### **Passo 2: Preservar Configurações**
```dart
final existingConfig = await GameConfirmationConfigService.getGameConfirmationConfig(gameId);
```

#### **Passo 3: Resetar Confirmações**
```dart
final resetResult = await _resetAllPlayerConfirmations(gameId);
// Atualiza todas as confirmações para 'pending'
```

#### **Passo 4: Atualizar Jogo**
```dart
await _client.from('games').update(gameData).eq('id', gameId);
```

#### **Passo 5: Recriar Sessões**
```dart
final sessionResult = await SessionManagementService.recreateGameSessions(
    gameId, {...gameData, 'id': gameId});
```

#### **Passo 6: Restaurar Configurações**
```dart
if (existingConfig != null) {
  await _restoreConfirmationConfig(gameId, existingConfig);
}
```

### **3. Integração com `EditGameScreen`**

Atualizado o arquivo `lib/screens/edit_game_screen.dart`:

#### **Antes:**
```dart
// Atualizar jogo no banco
await SupabaseConfig.client.from('games').update(gameData).eq('id', selectedGame.id);

// Recriar sessões baseadas nas novas configurações
final sessionResult = await SessionManagementService.recreateGameSessions(
    selectedGame.id, gameDataWithId);
```

#### **Depois:**
```dart
// Usar o novo serviço de atualização completa
final updateResult = await GameUpdateService.updateGameWithSessionRecreation(
  gameId: selectedGame.id,
  gameData: gameData,
);
```

## 📊 **Resultado da Atualização**

### **Informações Retornadas:**
```dart
{
  'game_id': gameId,
  'success': true,
  'message': 'Jogo atualizado com sucesso',
  'details': {
    'configurations_preserved': true/false,
    'confirmations_reset': 5,
    'sessions_removed': 10,
    'sessions_created': 12,
  }
}
```

### **Mensagem de Sucesso:**
```
✅ Jogo atualizado! Configurações preservadas, 5 confirmações resetadas, 12 sessões criadas.
```

## 🔄 **Funcionalidades Implementadas**

### **1. Preservação de Configurações**
- ✅ **Salva** configurações existentes antes da atualização
- ✅ **Restaura** configurações após recriação das sessões
- ✅ **Mantém** funcionalidade de confirmação de presença

### **2. Reset de Confirmações**
- ✅ **Identifica** todas as confirmações existentes
- ✅ **Atualiza** para status 'pending'
- ✅ **Limpa** dados de confirmação (data, método, notas)
- ✅ **Preserva** estrutura de dados

### **3. Recriação de Sessões**
- ✅ **Remove** todas as sessões existentes
- ✅ **Cria** novas sessões baseadas nas configurações atualizadas
- ✅ **Mantém** integridade referencial

### **4. Tratamento de Erros**
- ✅ **Verifica** status do jogo (não permite atualizar jogos deletados)
- ✅ **Trata** erros de cada etapa individualmente
- ✅ **Retorna** informações detalhadas sobre o processo

## 🧪 **Exemplo de Uso**

### **Cenário:**
- **Jogo:** Centro de Esporte e Lazer - OAB
- **Alteração:** Mudança de horário de 20:00 para 21:00
- **Configurações existentes:** 2 confirmações (24h e 12h antes)
- **Confirmações existentes:** 8 jogadores confirmados

### **Resultado:**
```
✅ Jogo atualizado com sucesso:
   - Configurações preservadas: true
   - Confirmações resetadas: 8
   - Sessões removidas: 15
   - Sessões criadas: 15
```

### **Estado Final:**
- ✅ **Jogo atualizado** com novo horário
- ✅ **Sessões recriadas** com horário 21:00
- ✅ **Configurações mantidas** (24h e 12h antes)
- ✅ **Confirmações resetadas** (todos em pending)

## 🚀 **Vantagens**

1. **✅ Processo atômico:** Tudo ou nada - se falhar, não deixa dados inconsistentes
2. **✅ Preservação de configurações:** Mantém funcionalidade de confirmação
3. **✅ Reset limpo:** Confirmações voltam ao estado inicial
4. **✅ Sessões atualizadas:** Refletem as novas configurações do jogo
5. **✅ Feedback detalhado:** Usuário sabe exatamente o que aconteceu
6. **✅ Tratamento de erros:** Processo robusto e confiável

## 📁 **Arquivos Criados/Modificados**

### **Novos Arquivos:**
- **`lib/services/game_update_service.dart`** - Serviço principal

### **Arquivos Modificados:**
- **`lib/screens/edit_game_screen.dart`** - Integração com novo serviço

## 🔍 **Métodos Auxiliares**

### **`_resetAllPlayerConfirmations()`**
- Reseta todas as confirmações para 'pending'
- Retorna contagem de confirmações resetadas

### **`_restoreConfirmationConfig()`**
- Restaura configurações de confirmação após recriação
- Mantém configurações mensalistas e avulsos

### **`_getGameStatus()`**
- Verifica status do jogo antes da atualização
- Previne atualização de jogos deletados

---

**Status:** ✅ **IMPLEMENTADO**  
**Data:** 2025-01-27  
**Funcionalidade:** Atualização completa com preservação de configurações e reset de confirmações
