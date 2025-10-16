# 🧹 Guia de Execução da Limpeza - Remover Coluna type

## ✅ **Script Corrigido e Versão Simples:**

O script original tinha o mesmo erro de sintaxe. Agora você tem duas opções.

## 📋 **Opções de Execução:**

### **OPÇÃO 1: Script Original Corrigido**
- **Arquivo:** `database/remove_type_from_players.sql`
- **Status:** ✅ Corrigido (comandos `RAISE NOTICE` agora dentro de `DO $$`)

### **OPÇÃO 2: Script Simples (Recomendado)**
- **Arquivo:** `database/remove_type_simple.sql`
- **Vantagem:** Sem blocos `DO $$` complexos, mais compatível

## ⚠️ **IMPORTANTE - Execute APENAS Após:**

1. ✅ **Migração concluída** - Execute `migrate_player_type_simple.sql` primeiro
2. ✅ **Código atualizado** - Confirme que o código foi atualizado
3. ✅ **Sistema testado** - Teste todas as funcionalidades
4. ✅ **Dados verificados** - Confirme que os dados foram migrados corretamente

## 🚀 **Como Executar:**

### **Método 1: Script Simples (Recomendado)**
Execute no Supabase SQL Editor:
```sql
-- Execute o arquivo: remove_type_simple.sql
```

### **Método 2: Script Original Corrigido**
Execute no Supabase SQL Editor:
```sql
-- Execute o arquivo: remove_type_from_players.sql
```

## ✅ **Verificações de Segurança:**

### **Antes de Executar:**
```sql
-- Verificar se a migração foi bem-sucedida
SELECT 
    'Total de relacionamentos' as descricao,
    COUNT(*) as quantidade
FROM game_players
UNION ALL
SELECT 
    'Relacionamentos com player_type' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type IS NOT NULL;
```

**Resultado esperado:**
```
descricao                        | quantidade
Total de relacionamentos         | X
Relacionamentos com player_type  | X (deve ser igual ao total)
```

### **Após Executar:**
```sql
-- Verificar se a coluna foi removida
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'players' 
            AND column_name = 'type'
            AND table_schema = 'public'
        ) THEN 'ERRO: Coluna type ainda existe'
        ELSE 'SUCESSO: Coluna type foi removida'
    END as resultado_final;
```

**Resultado esperado:**
```
resultado_final
SUCESSO: Coluna type foi removida
```

## 🧪 **Teste Pós-Limpeza:**

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

## 🚨 **Se Houver Problemas:**

### **Erro: "column does not exist"**
- **Causa:** Coluna já foi removida
- **Solução:** ✅ Tudo certo, continue

### **Erro: "permission denied"**
- **Causa:** Sem permissão para alterar tabelas
- **Solução:** Execute como superuser ou com permissões adequadas

### **Sistema não funciona após limpeza:**
- **Causa:** Código não foi atualizado
- **Solução:** Verifique se todas as alterações de código foram aplicadas

## 🔄 **Ordem Completa de Execução:**

### **1. Migração (Obrigatório):**
```sql
-- Execute primeiro
\i migrate_player_type_simple.sql
```

### **2. Teste do Sistema:**
- Teste todas as funcionalidades
- Confirme que tudo funciona

### **3. Limpeza (Opcional):**
```sql
-- Execute apenas após confirmar que tudo funciona
\i remove_type_simple.sql
```

## 📊 **Estrutura Final Esperada:**

### **Tabela `players` (após limpeza):**
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
  -- Campo 'type' REMOVIDO
);
```

### **Tabela `game_players` (com tipo):**
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

## 🎯 **Resultado Esperado:**

Após a limpeza bem-sucedida:

- **✅ Coluna `type` removida** da tabela `players`
- **✅ Coluna `player_type` mantida** na tabela `game_players`
- **✅ Sistema funcionando** com nova estrutura
- **✅ Dados preservados** e organizados corretamente
- **✅ Performance otimizada** com índices adequados

## 🆘 **Suporte:**

Se encontrar problemas:

1. **Verifique os logs** do Supabase para erros específicos
2. **Execute o script simples** como alternativa
3. **Verifique permissões** do usuário do banco
4. **Confirme que a migração** foi executada primeiro

A limpeza está pronta para execução! 🧹✅

