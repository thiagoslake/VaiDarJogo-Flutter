# 🚀 Guia de Execução da Migração do Tipo de Jogador

## ✅ **Script Corrigido e Dividido em Partes:**

O script original tinha um erro de sintaxe. Agora está dividido em 3 partes menores e mais seguras.

## 📋 **Ordem de Execução:**

### **PASSO 1: Adicionar Coluna**
Execute o arquivo: `database/migrate_step1_add_column.sql`

```sql
-- Adicionar coluna player_type na tabela game_players
ALTER TABLE game_players 
ADD COLUMN IF NOT EXISTS player_type VARCHAR(20) DEFAULT 'casual' 
CHECK (player_type IN ('monthly', 'casual'));
```

**Resultado esperado:**
- Coluna `player_type` adicionada à tabela `game_players`
- Verificação da estrutura da coluna

### **PASSO 2: Migrar Dados**
Execute o arquivo: `database/migrate_step2_migrate_data.sql`

```sql
-- Migrar dados existentes da tabela players para game_players
UPDATE game_players 
SET player_type = players.type
FROM players 
WHERE game_players.player_id = players.id
AND game_players.player_type IS NULL;
```

**Resultado esperado:**
- Dados migrados da tabela `players` para `game_players`
- Estatísticas da migração

### **PASSO 3: Finalizar Estrutura**
Execute o arquivo: `database/migrate_step3_finalize.sql`

```sql
-- Alterar coluna para NOT NULL
ALTER TABLE game_players 
ALTER COLUMN player_type SET NOT NULL;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_game_players_player_type ON game_players(player_type);
CREATE INDEX IF NOT EXISTS idx_game_players_game_type ON game_players(game_id, player_type);
```

**Resultado esperado:**
- Coluna configurada como NOT NULL
- Índices criados para performance
- Verificação final da migração

## 🧪 **Como Executar no Supabase:**

### **Método 1: SQL Editor (Recomendado)**
1. Abra o Supabase Dashboard
2. Vá para "SQL Editor"
3. Execute cada arquivo separadamente na ordem:
   - `migrate_step1_add_column.sql`
   - `migrate_step2_migrate_data.sql`
   - `migrate_step3_finalize.sql`

### **Método 2: Via CLI (se disponível)**
```bash
# Execute cada arquivo separadamente
psql -h your-host -U postgres -d postgres -f migrate_step1_add_column.sql
psql -h your-host -U postgres -d postgres -f migrate_step2_migrate_data.sql
psql -h your-host -U postgres -d postgres -f migrate_step3_finalize.sql
```

## ✅ **Verificações de Sucesso:**

### **Após PASSO 1:**
```sql
-- Verificar se a coluna foi adicionada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'game_players' 
AND column_name = 'player_type';
```

**Resultado esperado:**
```
column_name  | data_type | is_nullable | column_default
player_type  | character varying(20) | YES | 'casual'
```

### **Após PASSO 2:**
```sql
-- Verificar migração de dados
SELECT 
    'Total de relacionamentos' as descricao,
    COUNT(*) as quantidade
FROM game_players
UNION ALL
SELECT 
    'Jogadores mensalistas' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type = 'monthly'
UNION ALL
SELECT 
    'Jogadores avulsos' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type = 'casual';
```

**Resultado esperado:**
```
descricao                    | quantidade
Total de relacionamentos     | X
Jogadores mensalistas        | Y
Jogadores avulsos           | Z
```

### **Após PASSO 3:**
```sql
-- Verificação final
SELECT 
    'MIGRAÇÃO CONCLUÍDA' as status,
    COUNT(*) as total_relacionamentos,
    SUM(CASE WHEN player_type = 'monthly' THEN 1 ELSE 0 END) as mensalistas,
    SUM(CASE WHEN player_type = 'casual' THEN 1 ELSE 0 END) as avulsos
FROM game_players;
```

**Resultado esperado:**
```
status                | total_relacionamentos | mensalistas | avulsos
MIGRAÇÃO CONCLUÍDA    | X                     | Y           | Z
```

## 🚨 **Se Houver Erros:**

### **Erro: "column already exists"**
- **Causa:** Coluna já foi adicionada
- **Solução:** Continue para o PASSO 2

### **Erro: "relation does not exist"**
- **Causa:** Tabela não existe
- **Solução:** Verifique se as tabelas `game_players` e `players` existem

### **Erro: "permission denied"**
- **Causa:** Sem permissão para alterar tabelas
- **Solução:** Execute como superuser ou com permissões adequadas

## 🔄 **Script Alternativo (Mais Simples):**

Se ainda houver problemas, use o script mais simples:

**Arquivo:** `database/migrate_player_type_simple.sql`

Este script executa todas as operações em sequência sem blocos `DO $$`.

## 📱 **Após a Migração:**

### **1. Teste o Sistema:**
- Adicione um jogador como "Mensalista"
- Adicione um jogador como "Avulso"
- Verifique as listas de jogadores

### **2. Verifique as Telas:**
- `AddPlayerScreen` - Deve funcionar normalmente
- `MonthlyPlayersScreen` - Deve mostrar apenas mensalistas
- `CasualPlayersScreen` - Deve mostrar apenas avulsos

### **3. Teste Flexibilidade:**
- Adicione o mesmo jogador em dois jogos diferentes
- Defina tipos diferentes para cada jogo
- Verifique se aparece corretamente em cada lista

## 🎯 **Resultado Esperado:**

Após a migração bem-sucedida:

- **✅ Coluna `player_type`** adicionada à tabela `game_players`
- **✅ Dados migrados** da tabela `players` para `game_players`
- **✅ Índices criados** para performance
- **✅ Sistema funcionando** com nova estrutura
- **✅ Flexibilidade total** - jogadores podem ter tipos diferentes em jogos diferentes

## 🆘 **Suporte:**

Se encontrar problemas:

1. **Verifique os logs** do Supabase para erros específicos
2. **Execute os passos separadamente** para identificar onde está o problema
3. **Use o script simples** como alternativa
4. **Verifique permissões** do usuário do banco

A migração está pronta para execução! 🚀✅

