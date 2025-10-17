# Correção: Botão "Ver Jogadores Confirmados" Apenas na Próxima Sessão

## 📋 **Problema Identificado**

**Erro:** O botão "Ver Jogadores Confirmados" aparecia em todas as sessões futuras, não apenas na próxima sessão.

**Comportamento Anterior:**
- ❌ Botão aparecia em **todas** as sessões futuras
- ❌ Usuário podia ver confirmações de sessões distantes
- ❌ Interface confusa com múltiplos botões

## 🎯 **Objetivo da Correção**

**Comportamento Desejado:**
- ✅ Botão aparece **apenas** na próxima sessão (primeira sessão futura)
- ✅ Interface mais limpa e focada
- ✅ Lógica de negócio mais clara

## 🔧 **Solução Implementada**

### **1. Nova Lógica de Identificação da Próxima Sessão:**

```dart
// Verificar se é a próxima sessão (primeira sessão futura)
final isNextSession = _isNextSession(session, index);
```

### **2. Método `_isNextSession()` Criado:**

```dart
/// Verifica se a sessão atual é a próxima sessão (primeira sessão futura)
bool _isNextSession(Map<String, dynamic> currentSession, int currentIndex) {
  try {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final currentSessionDate = DateTime.parse(currentSession['session_date']);
    final currentSessionDateOnly = DateTime(
      currentSessionDate.year,
      currentSessionDate.month,
      currentSessionDate.day,
    );

    // Se a sessão atual é passada, não é a próxima
    if (currentSessionDateOnly.isBefore(todayDate)) {
      return false;
    }

    // Se a sessão atual é hoje ou futura, verificar se é a primeira
    // Percorrer as sessões anteriores para ver se alguma é futura
    for (int i = 0; i < currentIndex; i++) {
      final previousSession = _sessions[i];
      final previousSessionDate = DateTime.parse(previousSession['session_date']);
      final previousSessionDateOnly = DateTime(
        previousSessionDate.year,
        previousSessionDate.month,
        previousSessionDate.day,
      );

      // Se encontrou uma sessão anterior que também é futura ou hoje,
      // então a sessão atual não é a próxima
      if (!previousSessionDateOnly.isBefore(todayDate)) {
        return false;
      }
    }

    // Se chegou até aqui, é a primeira sessão futura (próxima sessão)
    return true;
  } catch (e) {
    print('❌ Erro ao verificar se é próxima sessão: $e');
    return false;
  }
}
```

### **3. Condição do Botão Atualizada:**

```dart
// ❌ ANTES: Botão para todas as sessões futuras
if (!isPastSession) ...[

// ✅ DEPOIS: Botão apenas para a próxima sessão
if (isNextSession) ...[
```

## 🧠 **Lógica de Funcionamento**

### **Algoritmo da Próxima Sessão:**

1. **Verificar se a sessão é passada:**
   - Se `sessionDate < today` → **Não é próxima sessão**

2. **Verificar se é a primeira sessão futura:**
   - Percorrer todas as sessões anteriores (índices menores)
   - Se alguma sessão anterior também for futura → **Não é próxima sessão**
   - Se nenhuma sessão anterior for futura → **É a próxima sessão**

### **Exemplo Prático:**

**Cenário:** Hoje é 15/01/2025

| Índice | Data da Sessão | Status | É Próxima? |
|--------|----------------|--------|------------|
| 0 | 10/01/2025 | Passada | ❌ |
| 1 | 12/01/2025 | Passada | ❌ |
| 2 | 15/01/2025 | Hoje | ✅ **SIM** |
| 3 | 18/01/2025 | Futura | ❌ |
| 4 | 22/01/2025 | Futura | ❌ |

**Resultado:** Apenas a sessão do dia 15/01/2025 (índice 2) terá o botão.

## 🎨 **Melhorias na Interface**

### **Antes:**
- 🔴 Múltiplos botões "Ver Jogadores Confirmados"
- 🔴 Interface poluída
- 🔴 Confusão sobre qual sessão verificar

### **Depois:**
- ✅ Apenas **um** botão na próxima sessão
- ✅ Interface limpa e focada
- ✅ Lógica clara: "Ver confirmações da próxima sessão"

## 🧪 **Como Testar**

### **1. Cenário com Múltiplas Sessões Futuras:**
- Crie um jogo com várias sessões futuras
- Verifique que apenas a **primeira sessão futura** tem o botão
- Confirme que as outras sessões futuras **não** têm o botão

### **2. Cenário com Sessão Hoje:**
- Crie uma sessão para hoje
- Verifique que ela tem o botão (se for a primeira futura)
- Confirme que sessões futuras não têm o botão

### **3. Cenário com Apenas Sessões Passadas:**
- Crie um jogo com apenas sessões passadas
- Verifique que **nenhuma** sessão tem o botão

## 📁 **Arquivos Modificados**

- **`lib/screens/upcoming_sessions_screen.dart`**
  - Adicionado método `_isNextSession()`
  - Modificada condição do botão de `!isPastSession` para `isNextSession`
  - Atualizado comentário do botão

## 🔄 **Compatibilidade**

- ✅ **Mantém** toda funcionalidade existente
- ✅ **Melhora** a experiência do usuário
- ✅ **Não quebra** nenhuma funcionalidade
- ✅ **Adiciona** lógica mais inteligente

## 📝 **Notas Importantes**

1. **Ordenação das Sessões:** O método assume que as sessões estão ordenadas por data (ascendente)
2. **Tratamento de Erros:** Inclui try-catch para evitar crashes
3. **Performance:** Algoritmo O(n) simples e eficiente
4. **Logs de Debug:** Inclui logs para troubleshooting

---

**Status:** ✅ **CORRIGIDO**  
**Data:** 2025-01-27  
**Impacto:** Interface mais limpa e lógica de negócio mais clara
