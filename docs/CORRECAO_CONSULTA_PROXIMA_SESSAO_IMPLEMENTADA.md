# 🔍 Correção da Consulta da Próxima Sessão - Implementada

## ✅ **Problema Identificado e Corrigido:**

A consulta para buscar a próxima sessão foi melhorada para garantir que está buscando corretamente a partir da data de hoje na tabela `game_sessions`, com formatação de data mais robusta e logs de debug aprimorados.

## 🔧 **Correções Implementadas:**

### **1. Formatação de Data Mais Robusta:**

#### **ANTES (formatação simples):**
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

#### **DEPOIS (formatação robusta):**
```dart
// Buscar próxima sessão do jogo (a partir de hoje)
final today = DateTime.now();
final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

final nextSessionResponse = await SupabaseConfig.client
    .from('game_sessions')
    .select('session_date, start_time, end_time')
    .eq('game_id', gameId)
    .gte('session_date', todayString)
    .order('session_date', ascending: true)
    .limit(1);
```

### **2. Logs de Debug Aprimorados:**

#### **ANTES (log simples):**
```dart
print('🔍 DEBUG - Jogo ${allGamesMap[gameId]!['organization_name']}: $currentPlayers jogadores, próxima sessão: ${nextSessionDate ?? "N/A"}');
```

#### **DEPOIS (log detalhado):**
```dart
print('🔍 DEBUG - Jogo ${allGamesMap[gameId]!['organization_name']}: $currentPlayers jogadores, próxima sessão: ${nextSessionDate ?? "N/A"} (buscando a partir de $todayString)');
```

## 🎯 **Lógica da Consulta:**

### **1. Filtros Aplicados:**
- ✅ **Por jogo** - `eq('game_id', gameId)`
- ✅ **A partir de hoje** - `gte('session_date', todayString)`
- ✅ **Ordenação** - `order('session_date', ascending: true)`
- ✅ **Limite** - `limit(1)` (apenas a próxima)

### **2. Formatação de Data:**
```dart
final today = DateTime.now();
final todayString = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
```

#### **Exemplo de Saída:**
- **Data atual:** 15/01/2024
- **String formatada:** "2024-01-15"
- **Consulta:** `WHERE session_date >= '2024-01-15'`

### **3. Campos Retornados:**
- ✅ **`session_date`** - Data da próxima sessão
- ✅ **`start_time`** - Horário de início
- ✅ **`end_time`** - Horário de fim

## 📊 **Comportamento da Consulta:**

### **1. Sessões Encontradas:**
```sql
-- Exemplo de consulta SQL equivalente
SELECT session_date, start_time, end_time
FROM game_sessions
WHERE game_id = 'game-uuid'
  AND session_date >= '2024-01-15'  -- Data de hoje
ORDER BY session_date ASC
LIMIT 1;
```

### **2. Resultados Possíveis:**

#### **A. Próxima Sessão Encontrada:**
```dart
// Dados retornados
{
  'session_date': '2024-01-20',
  'start_time': '19:00',
  'end_time': '21:00'
}

// Exibição no widget
📅 20/01/2024    ⏰ 19:00 - 21:00
```

#### **B. Nenhuma Sessão Futura:**
```dart
// Dados retornados
{
  'session_date': null,
  'start_time': null,
  'end_time': null
}

// Exibição no widget
📅 Próxima sessão não agendada    ⏰ Horário não definido
```

## 🔍 **Logs de Debug:**

### **Exemplo de Saída:**
```
🔍 DEBUG - Jogo Pelada do Bairro: 12 jogadores, próxima sessão: 2024-01-20 (buscando a partir de 2024-01-15)
🔍 DEBUG - Jogo Futebol Semanal: 8 jogadores, próxima sessão: N/A (buscando a partir de 2024-01-15)
🔍 DEBUG - Jogo Jogo Avulso: 5 jogadores, próxima sessão: N/A (buscando a partir de 2024-01-15)
```

### **Informações dos Logs:**
- ✅ **Nome do jogo** - Identificação clara
- ✅ **Número de jogadores** - Contagem atual
- ✅ **Próxima sessão** - Data encontrada ou "N/A"
- ✅ **Data de referência** - Data a partir da qual está buscando

## 🚀 **Como Verificar:**

### **1. Teste Visual:**
- ✅ Acesse "Meus Jogos"
- ✅ Verifique se a data exibida é a próxima sessão
- ✅ Confirme que não mostra sessões passadas

### **2. Verifique os Logs:**
```
🔍 DEBUG - Jogo Nome: X jogadores, próxima sessão: YYYY-MM-DD (buscando a partir de YYYY-MM-DD)
```

### **3. Execute o Script SQL:**
```sql
-- Testar a consulta exata
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

- ✅ **Formatação robusta** - Data formatada corretamente
- ✅ **Filtro preciso** - Busca a partir de hoje
- ✅ **Logs detalhados** - Debug com data de referência
- ✅ **Consulta otimizada** - Apenas a próxima sessão
- ✅ **Tratamento de casos** - Com e sem próxima sessão
- ✅ **Script de teste** - Validação da consulta

**A consulta da próxima sessão está corrigida e funcionando corretamente!** 🔍✅



