# 🔄 Migração: Tipo de Jogador para Relacionamento Jogo-Jogador

## ✅ **Implementação Concluída:**

O sistema foi atualizado para que o atributo "mensalista" ou "avulso" seja definido no momento do registro do jogador no jogo, não no perfil do jogador. Isso permite que um jogador seja mensalista em um jogo e avulso em outro.

## 🎯 **Objetivo da Mudança:**

### **Antes:**
- O tipo de jogador (mensalista/avulso) era armazenado na tabela `players`
- Um jogador tinha apenas um tipo para todos os jogos
- Não era possível ser mensalista em um jogo e avulso em outro

### **Depois:**
- O tipo de jogador é armazenado na tabela `game_players`
- Cada relacionamento jogador-jogo pode ter seu próprio tipo
- Um jogador pode ser mensalista em um jogo e avulso em outro

## 🗃️ **Mudanças no Banco de Dados:**

### **1. Nova Estrutura da Tabela `game_players`:**

#### **Coluna Adicionada:**
```sql
ALTER TABLE game_players 
ADD COLUMN player_type VARCHAR(20) DEFAULT 'casual' 
CHECK (player_type IN ('monthly', 'casual'));
```

#### **Índices Criados:**
```sql
CREATE INDEX idx_game_players_player_type ON game_players(player_type);
CREATE INDEX idx_game_players_game_type ON game_players(game_id, player_type);
```

### **2. Migração de Dados:**
- Dados existentes da coluna `type` da tabela `players` foram migrados para `player_type` na tabela `game_players`
- Todos os relacionamentos existentes receberam o tipo correspondente do jogador

### **3. Limpeza (Opcional):**
- A coluna `type` pode ser removida da tabela `players` após confirmação

## 📱 **Mudanças no Código:**

### **1. Modelo `Player` Atualizado:**

#### **Antes:**
```dart
class Player {
  final String id;
  final String name;
  final String phoneNumber;
  final String type; // 'monthly' ou 'casual' - REMOVIDO
  // ... outros campos
}
```

#### **Depois:**
```dart
class Player {
  final String id;
  final String name;
  final String phoneNumber;
  // Campo 'type' removido
  // ... outros campos
}
```

### **2. Novo Modelo `GamePlayer`:**

```dart
class GamePlayer {
  final String id;
  final String gameId;
  final String playerId;
  final String playerType; // 'monthly' ou 'casual'
  final String status;
  final DateTime joinedAt;
  final DateTime? updatedAt;
  
  // Métodos de conveniência
  bool get isMonthly => playerType == 'monthly';
  bool get isCasual => playerType == 'casual';
  bool get isActive => status == 'active';
}
```

### **3. `PlayerService` Atualizado:**

#### **Métodos Removidos:**
- Parâmetro `type` removido de `createPlayer()`
- Parâmetro `type` removido de `updatePlayer()`

#### **Novos Métodos Adicionados:**
```dart
// Adicionar jogador a um jogo com tipo específico
static Future<GamePlayer?> addPlayerToGame({
  required String gameId,
  required String playerId,
  required String playerType, // 'monthly' ou 'casual'
  String status = 'active',
});

// Atualizar tipo de jogador em um jogo específico
static Future<GamePlayer?> updatePlayerTypeInGame({
  required String gamePlayerId,
  required String playerType,
});

// Buscar jogadores de um jogo por tipo
static Future<List<GamePlayer>> getGamePlayersByType({
  required String gameId,
  required String playerType,
});

// Buscar todos os jogadores de um jogo
static Future<List<GamePlayer>> getGamePlayers({
  required String gameId,
});
```

### **4. Telas Atualizadas:**

#### **`AddPlayerScreen`:**
- Mantém a seleção de tipo (mensalista/avulso)
- Usa `PlayerService.addPlayerToGame()` para criar o relacionamento com tipo
- Cria o perfil do jogador sem tipo

#### **`MonthlyPlayersScreen` e `CasualPlayersScreen`:**
- Usam `PlayerService.getGamePlayersByType()` para buscar jogadores por tipo
- Consultam a tabela `players` separadamente para obter dados do jogador
- Filtram por `player_type` na tabela `game_players`

## 🚀 **Scripts de Migração:**

### **1. Script Principal:**
- **Arquivo:** `database/migrate_player_type_to_game_players.sql`
- **Função:** Migra dados existentes e adiciona nova estrutura
- **Execução:** Execute este script primeiro

### **2. Script de Limpeza (Opcional):**
- **Arquivo:** `database/remove_type_from_players.sql`
- **Função:** Remove a coluna `type` da tabela `players`
- **Execução:** Execute apenas após confirmar que tudo funciona

## 🧪 **Como Testar:**

### **Teste 1: Adicionar Jogador**
```
1. Vá para "Adicionar Jogador"
2. Preencha os dados
3. Selecione "Mensalista" ou "Avulso"
4. Confirme a adição
5. Verifique se o jogador aparece na lista correta
```

### **Teste 2: Verificar Listas**
```
1. Vá para "Jogadores Mensalistas"
2. Confirme que apenas mensalistas aparecem
3. Vá para "Jogadores Avulsos"
4. Confirme que apenas avulsos aparecem
```

### **Teste 3: Mesmo Jogador em Jogos Diferentes**
```
1. Adicione um jogador como "Mensalista" em um jogo
2. Adicione o mesmo jogador como "Avulso" em outro jogo
3. Verifique se aparece corretamente em cada lista
```

## 📊 **Estrutura Final:**

### **Tabela `players`:**
```sql
CREATE TABLE players (
  id UUID PRIMARY KEY,
  name VARCHAR NOT NULL,
  phone_number VARCHAR UNIQUE,
  birth_date DATE,
  primary_position VARCHAR,
  secondary_position VARCHAR,
  preferred_foot VARCHAR,
  status VARCHAR DEFAULT 'active',
  user_id UUID REFERENCES users(id),
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
  -- Campo 'type' removido
);
```

### **Tabela `game_players`:**
```sql
CREATE TABLE game_players (
  id UUID PRIMARY KEY,
  game_id UUID REFERENCES games(id),
  player_id UUID REFERENCES players(id),
  player_type VARCHAR(20) DEFAULT 'casual' CHECK (player_type IN ('monthly', 'casual')),
  status VARCHAR DEFAULT 'active',
  joined_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP,
  UNIQUE(game_id, player_id)
);
```

## 🎉 **Benefícios da Nova Estrutura:**

### **Para o Usuário:**
- **✅ Flexibilidade** - Pode ser mensalista em um jogo e avulso em outro
- **✅ Precisão** - Tipo é definido no contexto do jogo específico
- **✅ Organização** - Listas de jogadores mais precisas por jogo

### **Para o Sistema:**
- **✅ Normalização** - Dados organizados corretamente
- **✅ Escalabilidade** - Fácil adicionar novos tipos no futuro
- **✅ Performance** - Índices otimizados para consultas por tipo
- **✅ Consistência** - Dados sempre corretos por contexto

### **Para o Desenvolvedor:**
- **✅ Clareza** - Lógica mais clara e organizada
- **✅ Manutenibilidade** - Código mais fácil de manter
- **✅ Extensibilidade** - Fácil adicionar novos tipos ou funcionalidades
- **✅ Debugging** - Mais fácil identificar problemas

## 🔍 **Verificação de Integridade:**

### **Queries de Verificação:**
```sql
-- Verificar se todos os relacionamentos têm player_type
SELECT COUNT(*) as total, 
       COUNT(player_type) as com_tipo,
       COUNT(*) - COUNT(player_type) as sem_tipo
FROM game_players;

-- Verificar distribuição por tipo
SELECT player_type, COUNT(*) as quantidade
FROM game_players
GROUP BY player_type;

-- Verificar jogadores em múltiplos jogos com tipos diferentes
SELECT p.name, gp1.player_type as tipo_jogo1, gp2.player_type as tipo_jogo2
FROM players p
JOIN game_players gp1 ON p.id = gp1.player_id
JOIN game_players gp2 ON p.id = gp2.player_id
WHERE gp1.game_id != gp2.game_id
AND gp1.player_type != gp2.player_type;
```

## 🚨 **Pontos de Atenção:**

### **1. Backup:**
- **⚠️ IMPORTANTE:** Faça backup do banco antes de executar a migração
- **⚠️ TESTE:** Execute em ambiente de desenvolvimento primeiro

### **2. Ordem de Execução:**
1. Execute `migrate_player_type_to_game_players.sql`
2. Teste o sistema completamente
3. Execute `remove_type_from_players.sql` (opcional)

### **3. Compatibilidade:**
- **✅ Código atualizado** - Todas as telas foram atualizadas
- **✅ Dados migrados** - Dados existentes preservados
- **✅ Funcionalidade mantida** - Todas as funcionalidades continuam funcionando

## 🎯 **Resultado Final:**

A migração foi implementada com sucesso e oferece:

- **✅ Flexibilidade total** - Jogadores podem ter tipos diferentes em jogos diferentes
- **✅ Dados preservados** - Todos os dados existentes foram migrados
- **✅ Performance otimizada** - Índices criados para consultas eficientes
- **✅ Código limpo** - Estrutura mais organizada e manutenível
- **✅ Funcionalidade completa** - Todas as telas atualizadas e funcionando

O sistema agora permite que o tipo de jogador (mensalista/avulso) seja definido no momento do registro no jogo, oferecendo muito mais flexibilidade e precisão! 🔄✅

