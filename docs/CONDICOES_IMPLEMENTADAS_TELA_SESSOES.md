# Condições Implementadas na Tela de Consulta das Sessões

## ✅ **Status: JÁ IMPLEMENTADO**

As condições solicitadas já estão implementadas na tela de consulta das sessões (`upcoming_sessions_screen.dart`).

## 🎯 **Condições Implementadas**

### **1. Botão "Ver Jogadores Confirmados"**
- **Localização:** `_buildSessionCard()` método
- **Condição:** `if (isNextSession)`
- **Comportamento:** Aparece apenas na primeira sessão futura

### **2. Lógica de Identificação da Próxima Sessão**
- **Método:** `_isNextSession()`
- **Condição:** `sessionDateOnly.isAfter(todayDate)`
- **Comportamento:** Identifica a primeira sessão que é maior que hoje

## 📊 **Fluxo de Execução**

### **1. Construção do Card da Sessão:**
```dart
Widget _buildSessionCard(Map<String, dynamic> session, int index) {
  // ... código de formatação ...
  
  // Verificar se é a próxima sessão (primeira sessão futura)
  final isNextSession = _isNextSession(session, index);
  
  // ... resto do código ...
  
  // Botão para ver jogadores confirmados (apenas para a próxima sessão)
  if (isNextSession) ...[
    // Botão aparece aqui
  ] else ...[
    // Debug: mostrar quando o botão NÃO aparece
  ]
}
```

### **2. Identificação da Próxima Sessão:**
```dart
bool _isNextSession(Map<String, dynamic> currentSession, int currentIndex) {
  // LÓGICA SIMPLES: Validar cada sessão se é maior que a data de hoje (futura)
  // A primeira vez que isso for verdade, escolher essa sessão
  
  for (int i = 0; i < _sessions.length; i++) {
    final session = _sessions[i];
    final sessionDate = DateTime.parse(session['session_date']);
    final sessionDateOnly = DateTime(
      sessionDate.year,
      sessionDate.month,
      sessionDate.day,
    );

    // Se encontrou a primeira sessão que é maior que hoje (futura)
    if (sessionDateOnly.isAfter(todayDate)) {
      // Se é a sessão atual, então é a próxima
      if (i == currentIndex) {
        return true;
      } else {
        return false;
      }
    }
  }
  
  return false; // Nenhuma sessão futura encontrada
}
```

## 🧪 **Exemplo de Funcionamento**

### **Cenário:**
- **Data de hoje:** 2025-10-17
- **Sessões:** 14/10, 17/10, 21/10, 28/10

### **Resultado:**
- **Sessão 0 (14/10)** → **Botão NÃO aparece** ❌ (passada)
- **Sessão 1 (17/10)** → **Botão NÃO aparece** ❌ (hoje)
- **Sessão 2 (21/10)** → **Botão aparece** ✅ (primeira futura)
- **Sessão 3 (28/10)** → **Botão NÃO aparece** ❌ (não é a primeira futura)

## 🔍 **Logs de Debug**

### **Logs Esperados:**
```
🎯 _buildSessionCard - Índice: 2, Data: 2025-10-21, isPastSession: false
🎯 _buildSessionCard - Índice: 2, isNextSession: true

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
```

## 🎨 **Elementos Visuais**

### **1. Indicadores de Debug:**
- **Verde:** Quando o botão DEVE aparecer
- **Laranja:** Quando o botão NÃO aparece

### **2. Estilo do Botão:**
```dart
ElevatedButton.icon(
  onPressed: () => _showConfirmedPlayers(context, session),
  icon: const Icon(Icons.people, size: 18),
  label: const Text('Ver Jogadores Confirmados'),
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
)
```

## 📁 **Arquivos Envolvidos**

- **`lib/screens/upcoming_sessions_screen.dart`**
  - `_buildSessionCard()` - Construção do card da sessão
  - `_isNextSession()` - Lógica de identificação da próxima sessão
  - `_showConfirmedPlayers()` - Exibição dos jogadores confirmados

## 🚀 **Funcionalidades**

1. **✅ Identificação automática** da primeira sessão futura
2. **✅ Exibição condicional** do botão apenas na próxima sessão
3. **✅ Logs de debug** para acompanhar o funcionamento
4. **✅ Indicadores visuais** para facilitar o teste
5. **✅ Exclusão de sessões passadas** e de hoje

---

**Status:** ✅ **IMPLEMENTADO**  
**Data:** 2025-01-27  
**Funcionalidade:** Botão aparece apenas na primeira sessão futura
