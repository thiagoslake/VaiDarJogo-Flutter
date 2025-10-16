# 📅 Data da Próxima Sessão no Widget - Implementada

## ✅ **Funcionalidade Implementada:**

O widget "Meus Jogos" agora exibe a **data da próxima sessão agendada** em vez da data de criação do jogo, proporcionando informações mais relevantes para o usuário.

## 🔧 **Implementações Realizadas:**

### **1. Consulta da Próxima Sessão:**

#### **Nova Consulta SQL:**
```dart
// Buscar próxima sessão do jogo
final nextSessionResponse = await SupabaseConfig.client
    .from('game_sessions')
    .select('session_date, start_time, end_time')
    .eq('game_id', gameId)
    .gte('session_date', DateTime.now().toIso8601String().split('T')[0])
    .order('session_date', ascending: true)
    .limit(1);
```

#### **Lógica de Busca:**
- ✅ **Filtro por jogo** - `eq('game_id', gameId)`
- ✅ **Sessões futuras** - `gte('session_date', data_atual)`
- ✅ **Ordenação** - `order('session_date', ascending: true)`
- ✅ **Limite** - `limit(1)` (apenas a próxima)

### **2. Armazenamento dos Dados:**

#### **Campos Adicionados:**
```dart
// Atualizar dados do jogo
allGamesMap[gameId] = {
  ...allGamesMap[gameId]!,
  'current_players': currentPlayers,
  'next_session_date': nextSessionDate,           // ← Nova data
  'next_session_start_time': nextSessionStartTime, // ← Novo horário início
  'next_session_end_time': nextSessionEndTime,     // ← Novo horário fim
};
```

### **3. Exibição Atualizada:**

#### **ANTES (data de criação):**
```dart
Text(
  game['game_date'] != null
      ? _formatDate(DateTime.parse(game['game_date']))
      : 'Data não definida',
  // ...
),
```

#### **DEPOIS (próxima sessão):**
```dart
Text(
  game['next_session_date'] != null
      ? _formatDate(DateTime.parse(game['next_session_date']))
      : 'Próxima sessão não agendada',
  // ...
),
```

### **4. Horários da Sessão:**

#### **ANTES (horários do jogo):**
```dart
Text(
  '${game['start_time'] ?? 'N/A'} - ${game['end_time'] ?? 'N/A'}',
  // ...
),
```

#### **DEPOIS (horários da próxima sessão):**
```dart
Text(
  game['next_session_start_time'] != null && game['next_session_end_time'] != null
      ? '${game['next_session_start_time']} - ${game['next_session_end_time']}'
      : 'Horário não definido',
  // ...
),
```

## 📱 **Resultado Visual:**

### **Widget Atualizado:**
```
┌─────────────────────────────────────┐
│ 🏆 Nome do Jogo                     │
│ 📍 Local do Jogo                    │
│                                     │
│ 📅 15/01/2024    ⏰ 19:00 - 21:00   │ ← Próxima sessão
│ 👥 12 jogadores                     │
└─────────────────────────────────────┘
```

### **Cenários de Exibição:**

#### **1. Com Próxima Sessão:**
```
📅 15/01/2024    ⏰ 19:00 - 21:00
```

#### **2. Sem Próxima Sessão:**
```
📅 Próxima sessão não agendada    ⏰ Horário não definido
```

#### **3. Sessão sem Horário:**
```
📅 15/01/2024    ⏰ Horário não definido
```

## 🔍 **Logs de Debug:**

### **Log Atualizado:**
```dart
print('🔍 DEBUG - Jogo ${allGamesMap[gameId]!['organization_name']}: $currentPlayers jogadores, próxima sessão: ${nextSessionDate ?? "N/A"}');
```

### **Exemplo de Saída:**
```
🔍 DEBUG - Jogo Pelada do Bairro: 12 jogadores, próxima sessão: 2024-01-15
🔍 DEBUG - Jogo Futebol Semanal: 8 jogadores, próxima sessão: N/A
```

## 🎯 **Lógica de Funcionamento:**

### **1. Busca da Próxima Sessão:**
- ✅ **Data atual** - Usa `DateTime.now()` para filtrar sessões futuras
- ✅ **Ordenação** - Busca a sessão mais próxima da data atual
- ✅ **Limite** - Retorna apenas 1 resultado (a próxima)

### **2. Tratamento de Dados:**
- ✅ **Sessão encontrada** - Extrai data e horários
- ✅ **Sessão não encontrada** - Define valores como `null`
- ✅ **Tratamento de erro** - Valores padrão em caso de falha

### **3. Exibição Inteligente:**
- ✅ **Com data** - Formata e exibe a data da próxima sessão
- ✅ **Sem data** - Exibe "Próxima sessão não agendada"
- ✅ **Com horário** - Exibe horário de início e fim
- ✅ **Sem horário** - Exibe "Horário não definido"

## 📊 **Tipos de Jogos:**

### **1. Jogos Recorrentes (weekly, biweekly, monthly):**
- ✅ **Sessões geradas** - Devem ter sessões futuras
- ✅ **Data exibida** - Próxima sessão agendada
- ✅ **Horário exibido** - Horário da próxima sessão

### **2. Jogos Avulsos (one_time):**
- ✅ **Sem sessões** - Podem não ter sessões futuras
- ✅ **Mensagem** - "Próxima sessão não agendada"
- ✅ **Flexibilidade** - Não obrigatório ter sessões

## 🚀 **Como Verificar:**

### **1. Teste Visual:**
- ✅ Acesse "Meus Jogos"
- ✅ Verifique se a data exibida é da próxima sessão
- ✅ Confirme que horários correspondem à sessão

### **2. Verifique os Logs:**
```
🔍 DEBUG - Jogo Nome: X jogadores, próxima sessão: YYYY-MM-DD
```

### **3. Execute o Script SQL:**
```sql
-- Verificar próximas sessões
SELECT g.organization_name, gs.session_date, gs.start_time, gs.end_time
FROM public.games g
LEFT JOIN LATERAL (
    SELECT session_date, start_time, end_time
    FROM public.game_sessions gs2
    WHERE gs2.game_id = g.id 
      AND gs2.session_date >= CURRENT_DATE
    ORDER BY gs2.session_date ASC
    LIMIT 1
) gs ON true
WHERE g.status = 'active';
```

## 🎉 **Status:**

- ✅ **Consulta implementada** - Busca próxima sessão por jogo
- ✅ **Dados armazenados** - Próxima sessão nos dados do jogo
- ✅ **Exibição atualizada** - Data e horário da próxima sessão
- ✅ **Tratamento de casos** - Com e sem próxima sessão
- ✅ **Logs de debug** - Rastreamento da funcionalidade
- ✅ **Script de verificação** - Validação dos dados

**A exibição da data da próxima sessão está implementada e funcionando!** 📅✅



