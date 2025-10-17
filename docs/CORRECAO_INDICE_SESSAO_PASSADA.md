# Correção: Índice de Sessão Passada

## 🎯 **Problema Identificado**

O usuário reportou que o botão "Ver Jogadores Confirmados" estava aparecendo em uma sessão passada.

## 🔍 **Causa Raiz**

O problema estava na inconsistência entre os índices:

### **Problema:**
```dart
// ListView.builder
itemBuilder: (context, index) {
  final session = _sessions[index];
  return _buildSessionCard(session, index + 1); // ❌ Passando index + 1
},

// _buildSessionCard
Widget _buildSessionCard(Map<String, dynamic> session, int index) {
  // index aqui era index + 1 do ListView
  final isNextSession = _isNextSession(session, index); // ❌ Índice errado
}

// _isNextSession
bool _isNextSession(Map<String, dynamic> currentSession, int currentIndex) {
  // currentIndex aqui era index + 1, não o índice real do array
  for (int i = 0; i < _sessions.length; i++) {
    if (sessionDateOnly.isAfter(todayDate)) {
      if (i == currentIndex) { // ❌ Comparação com índice errado
        return true;
      }
    }
  }
}
```

## 🔧 **Correção Implementada**

### **1. Corrigir o índice passado para _buildSessionCard:**
```dart
// ✅ ANTES: index + 1
return _buildSessionCard(session, index + 1);

// ✅ DEPOIS: index (índice real do array)
return _buildSessionCard(session, index);
```

### **2. Ajustar a exibição do número da sessão:**
```dart
// ✅ Para exibição, usar index + 1
child: Text(
  '${index + 1}', // Exibe 1, 2, 3... (números de sessão)
  style: TextStyle(
    fontWeight: FontWeight.bold,
    color: isPastSession ? Colors.grey : Colors.purple,
  ),
),
```

## 📊 **Diferença na Lógica**

### **Antes (❌):**
- **ListView index:** 0, 1, 2, 3
- **Passado para _buildSessionCard:** 1, 2, 3, 4
- **Comparação em _isNextSession:** 1, 2, 3, 4
- **Resultado:** Comparação incorreta, botão aparecia em sessão errada

### **Depois (✅):**
- **ListView index:** 0, 1, 2, 3
- **Passado para _buildSessionCard:** 0, 1, 2, 3
- **Comparação em _isNextSession:** 0, 1, 2, 3
- **Resultado:** Comparação correta, botão aparece na sessão certa

## 🧪 **Exemplo de Funcionamento**

### **Cenário:**
- **Data de hoje:** 2025-10-17
- **Sessões:** 14/10, 17/10, 21/10, 28/10
- **Índices do array:** 0, 1, 2, 3

### **Execução Corrigida:**

#### **Sessão 0 (14/10) - PASSADA:**
```
🎯 _buildSessionCard - Índice: 0, Data: 2025-10-14, isPastSession: true
🔍 Debug _isNextSession:
   Índice: 0
   Data da sessão: 2025-10-14
   Data de hoje: 2025-10-17
   🔍 Procurando primeira sessão futura...
     Sessão 0: 2025-10-14 - É futura? false
     Sessão 1: 2025-10-17 - É futura? false
     Sessão 2: 2025-10-21 - É futura? true
   🎯 Primeira sessão futura encontrada no índice: 2
   ❌ Não é a próxima sessão (próxima é índice: 2)
🎯 _buildSessionCard - Índice: 0, isNextSession: false
```

#### **Sessão 2 (21/10) - FUTURA:**
```
🎯 _buildSessionCard - Índice: 2, Data: 2025-10-21, isPastSession: false
🔍 Debug _isNextSession:
   Índice: 2
   Data da sessão: 2025-10-21
   Data de hoje: 2025-10-17
   🔍 Procurando primeira sessão futura...
     Sessão 0: 2025-10-14 - É futura? false
     Sessão 1: 2025-10-17 - É futura? false
     Sessão 2: 2025-10-21 - É futura? true
   🎯 Primeira sessão futura encontrada no índice: 2
   ✅ É a próxima sessão!
🎯 _buildSessionCard - Índice: 2, isNextSession: true
```

## 🎯 **Resultado**

- **Sessão 0 (14/10)** → **Botão NÃO aparece** ❌ (passada)
- **Sessão 1 (17/10)** → **Botão NÃO aparece** ❌ (hoje)
- **Sessão 2 (21/10)** → **Botão aparece** ✅ (primeira futura)
- **Sessão 3 (28/10)** → **Botão NÃO aparece** ❌ (não é a primeira futura)

## 🚀 **Vantagens da Correção**

1. **✅ Índices consistentes:** Array index = ListView index = _isNextSession index
2. **✅ Comparação correta:** `i == currentIndex` funciona corretamente
3. **✅ Exibição correta:** Números de sessão 1, 2, 3... (index + 1)
4. **✅ Lógica correta:** Botão aparece apenas na primeira sessão futura

## 📁 **Arquivos Modificados**

- **`lib/screens/upcoming_sessions_screen.dart`**
  - Linha 246: `_buildSessionCard(session, index)` (removido +1)
  - Linha 300: `'${index + 1}'` (ajustado para exibição)

---

**Status:** ✅ **CORRIGIDO**  
**Data:** 2025-01-27  
**Impacto:** Botão aparece corretamente apenas na primeira sessão futura
