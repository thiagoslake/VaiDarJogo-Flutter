# 🔧 Corrigir Erro na Criação de Conta Após Reset

## ❌ **Problema Identificado:**

Após executar o script de reset do banco de dados, ao tentar criar uma nova conta no sistema, está ocorrendo um erro. Isso pode acontecer por alguns motivos:

1. **Tabelas principais foram deletadas** durante o reset
2. **Estrutura das tabelas está incompleta**
3. **Políticas RLS estão faltando**
4. **Triggers ou funções foram removidos**

## 🔍 **Diagnóstico:**

### **Passo 1: Verificar Estrutura das Tabelas**

Execute o script de diagnóstico para verificar o estado atual do banco:

```sql
-- Opção 1: Verificação completa (pode ter erro de coluna)
-- Arquivo: check_tables_after_reset.sql

-- Opção 2: Verificação simples (recomendado)
-- Arquivo: check_main_tables_simple.sql

-- Opção 3: Verificação básica (apenas existência)
-- Arquivo: check_tables_exist.sql
```

**O que verificar:**
- ✅ Se as tabelas principais existem (`users`, `players`, `games`, `game_players`, `game_sessions`, `participation_requests`)
- ✅ Se as colunas estão corretas
- ✅ Se as constraints e chaves estrangeiras estão funcionando
- ✅ Se o RLS está habilitado
- ✅ Se as políticas RLS existem
- ✅ Se os triggers estão funcionando

### **Passo 2: Verificar Logs do Terminal**

Execute o app e tente criar uma conta para ver o erro específico:

```bash
# No terminal do projeto
flutter run --verbose
```

**Procure por erros como:**
- `relation "public.users" does not exist`
- `relation "public.players" does not exist`
- `permission denied for table users`
- `column "user_id" does not exist`

## ✅ **Soluções:**

### **Solução 1: Recriar Tabelas Principais (Recomendado)**

Se as tabelas principais estão faltando ou com estrutura incompleta:

```sql
-- Opção 1: Script básico (recomendado)
-- Arquivo: create_basic_tables.sql

-- Opção 2: Script completo com verificação
-- Arquivo: recreate_main_tables_fixed.sql

-- Opção 3: Script original (pode ter erros)
-- Arquivo: recreate_main_tables.sql
```

**Script Básico (`create_basic_tables.sql`):**
- ✅ Criar todas as tabelas principais
- ✅ Habilitar RLS (Row Level Security)
- ✅ Criar políticas RLS básicas
- ✅ Sem índices complexos ou triggers
- ✅ **Mais seguro e simples**

**Script Completo (`recreate_main_tables_fixed.sql`):**
- ✅ Criar todas as tabelas principais
- ✅ Criar índices com verificação de existência
- ✅ Habilitar RLS (Row Level Security)
- ✅ Criar políticas RLS básicas
- ✅ Criar triggers para `updated_at`
- ✅ Verificação de existência de tabelas

### **Solução 2: Verificar Configuração do Supabase**

Se as tabelas existem mas há problemas de permissão:

1. **Verificar RLS:**
```sql
-- Verificar se RLS está habilitado
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'players', 'games');
```

2. **Verificar Políticas:**
```sql
-- Verificar políticas RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'players', 'games');
```

### **Solução 3: Reset Completo com Recriação**

Se nada funcionar, execute um reset completo seguido da recriação:

```sql
-- 1. Primeiro, execute o reset
-- Arquivo: reset_database_super_simple.sql

-- 2. Depois, recrie as tabelas (escolha uma opção)
-- Opção A: Script básico (recomendado)
-- Arquivo: create_basic_tables.sql

-- Opção B: Script completo
-- Arquivo: recreate_main_tables_fixed.sql
```

## 🧪 **Teste da Solução:**

### **Teste 1: Verificar Estrutura**
```sql
-- Opção 1: Verificação básica (recomendado)
-- Arquivo: check_tables_exist.sql

-- Opção 2: Verificação manual
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests');
```

### **Teste 2: Tentar Criar Conta**
1. Execute o app: `flutter run`
2. Tente criar uma nova conta
3. Verifique se não há erros no terminal

### **Teste 3: Verificar Logs**
```bash
# No terminal, procure por:
# ✅ "Perfil de jogador criado com sucesso"
# ❌ "Erro ao criar perfil de jogador"
# ❌ "relation does not exist"
# ❌ "permission denied"
```

## 📋 **Checklist de Verificação:**

- [ ] **Tabelas principais existem** (`users`, `players`, `games`, `game_players`, `game_sessions`, `participation_requests`)
- [ ] **Estrutura das tabelas está correta** (colunas, tipos, constraints)
- [ ] **RLS está habilitado** em todas as tabelas
- [ ] **Políticas RLS existem** e estão funcionando
- [ ] **Triggers estão funcionando** (especialmente `updated_at`)
- [ ] **Índices foram criados** para performance
- [ ] **Chaves estrangeiras estão funcionando**
- [ ] **App consegue conectar** ao Supabase
- [ ] **Criação de conta funciona** sem erros

## 🚨 **Erros Comuns e Soluções:**

### **Erro: "relation 'public.users' does not exist"**
**Solução:** Execute `create_basic_tables.sql` (recomendado) ou `recreate_main_tables_fixed.sql`

### **Erro: "column 'player_id' does not exist"**
**Solução:** Execute `create_basic_tables.sql` (script básico sem índices complexos)

### **Erro: "permission denied for table users"**
**Solução:** Verifique se as políticas RLS estão corretas

### **Erro: "column 'user_id' does not exist"**
**Solução:** Verifique se a estrutura da tabela está correta

### **Erro: "duplicate key value violates unique constraint"**
**Solução:** Verifique se há dados duplicados ou constraints incorretas

### **Erro: "function update_updated_at_column() does not exist"**
**Solução:** Execute `recreate_main_tables_fixed.sql` para recriar a função

## 🎯 **Recomendação Final:**

1. **Execute o diagnóstico** primeiro (`check_tables_exist.sql`)
2. **Se as tabelas estão faltando**, execute `create_basic_tables.sql` (recomendado)
3. **Teste a criação de conta** no app
4. **Verifique os logs** para confirmar que está funcionando

## 📞 **Suporte:**

Se ainda encontrar problemas:

1. **Execute o diagnóstico** e compartilhe os resultados
2. **Verifique os logs** do terminal e compartilhe os erros
3. **Teste em ambiente** de desenvolvimento primeiro
4. **Verifique permissões** do usuário no Supabase

## 🏆 **Resultado Esperado:**

Após aplicar a solução:

- ✅ **Todas as tabelas principais** existem e estão funcionando
- ✅ **Estrutura das tabelas** está correta
- ✅ **RLS e políticas** estão funcionando
- ✅ **Criação de conta** funciona sem erros
- ✅ **Perfil de jogador** é criado automaticamente
- ✅ **Sistema está pronto** para uso

**Execute `recreate_main_tables.sql` e o problema será resolvido!** 🚀✅
