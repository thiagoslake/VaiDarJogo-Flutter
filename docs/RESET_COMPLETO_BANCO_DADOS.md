# 🗑️ Reset Completo do Banco de Dados

## 📋 **Resumo:**

Este documento contém scripts SQL para resetar completamente o banco de dados do sistema VaiDarJogo Flutter, removendo todos os dados e voltando ao estado inicial.

## ⚠️ **ATENÇÃO CRÍTICA:**

### **🚨 ESTE PROCESSO É IRREVERSÍVEL!**
- **TODOS os dados serão perdidos permanentemente**
- **Não há como recuperar após a execução**
- **Execute APENAS em ambiente de desenvolvimento/teste**
- **NUNCA execute em produção sem backup**

## 📁 **Scripts Disponíveis:**

### **1. Script de Diagnóstico:**
- **Arquivo:** `database/diagnose_database_before_reset.sql`
- **Função:** Analisar o estado atual do banco antes do reset
- **Uso:** Execute PRIMEIRO para entender o que será perdido

### **2. Script de Reset Completo:**
- **Arquivo:** `database/reset_database_complete.sql`
- **Função:** Reset completo com logs detalhados e verificações
- **Uso:** Para reset com relatórios detalhados e confirmações

### **3. Script de Reset Simples:**
- **Arquivo:** `database/reset_database_simple.sql`
- **Função:** Reset direto e rápido
- **Uso:** Para reset rápido sem muitos logs

## 🚀 **Como Executar:**

### **Passo 1: Diagnóstico (OBRIGATÓRIO)**
```sql
-- Execute no Supabase SQL Editor
-- Arquivo: diagnose_database_before_reset.sql
```

**O que este script faz:**
- ✅ Verifica estrutura das tabelas
- ✅ Conta registros em cada tabela
- ✅ Analisa relacionamentos
- ✅ Verifica integridade dos dados
- ✅ Identifica problemas
- ✅ Verifica storage e RLS
- ✅ Fornece recomendações

### **Passo 2: Backup (OBRIGATÓRIO)**
```bash
# Faça backup completo do banco
pg_dump -h [HOST] -U [USER] -d [DATABASE] > backup_antes_reset.sql

# OU use o export do Supabase Dashboard
# Settings > Database > Backups > Download backup
```

### **Passo 3: Reset**
```sql
-- Execute no Supabase SQL Editor
-- Arquivo: reset_database_simple.sql (recomendado)
-- OU
-- Arquivo: reset_database_complete.sql (completo)
```

## 🎯 **O que será Removido:**

### **📊 Dados Principais:**
- **Users** - Todos os usuários do sistema
- **Players** - Todos os perfis de jogadores
- **Games** - Todos os jogos criados
- **Game Players** - Todos os relacionamentos jogador-jogo
- **Game Sessions** - Todas as sessões dos jogos
- **Participation Requests** - Todas as solicitações de participação

### **📱 Sistema de Notificações:**
- **Notifications** - Todas as notificações
- **Notification Configs** - Todas as configurações
- **Notification Templates** - Todos os templates
- **Notification Logs** - Todos os logs
- **Player FCM Tokens** - Todos os tokens de push

### **🗂️ Storage:**
- **Profile Images** - Todas as imagens de perfil
- **Arquivos** - Todos os arquivos armazenados

### **🗑️ Tabelas Não Utilizadas:**
- **api_keys, app_users, audit_logs**
- **device_tokens, participation_confirmations**
- **participations, payments, team_players**
- **teams, waiting_list**

## 🔧 **Processo de Reset:**

### **1. Desabilitação Temporária do RLS:**
```sql
-- RLS é desabilitado temporariamente para facilitar a limpeza
ALTER TABLE public.notifications DISABLE ROW LEVEL SECURITY;
-- ... outras tabelas
```

### **2. Deleção em Ordem de Dependência:**
```sql
-- Primeiro: Dados dependentes
DELETE FROM notification_logs;
DELETE FROM notifications;
DELETE FROM notification_configs;
-- ... outros dados dependentes

-- Depois: Dados principais
DELETE FROM game_players;
DELETE FROM game_sessions;
DELETE FROM players;
DELETE FROM games;
DELETE FROM users;
```

### **3. Limpeza de Tabelas Não Utilizadas:**
```sql
-- Remove tabelas que não são usadas pelo sistema
DROP TABLE IF EXISTS api_keys CASCADE;
DROP TABLE IF EXISTS app_users CASCADE;
-- ... outras tabelas não utilizadas
```

### **4. Reset de Sequências:**
```sql
-- Reseta todas as sequências para começar do 1
ALTER SEQUENCE [sequence_name] RESTART WITH 1;
```

### **5. Limpeza do Storage:**
```sql
-- Remove todos os objetos do bucket de imagens
DELETE FROM storage.objects WHERE bucket_id = 'profile-images';
```

### **6. Reabilitação do RLS:**
```sql
-- RLS é reabilitado em todas as tabelas
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
-- ... outras tabelas
```

## 📊 **Exemplo de Execução:**

### **Antes do Reset:**
```
📊 Total de tabelas: 15
📊 Usuários: 25
📊 Players: 30
📊 Jogos: 8
📊 Relacionamentos: 45
📊 Notificações: 120
```

### **Após o Reset:**
```
📊 Total de tabelas: 11
📊 Usuários: 0
📊 Players: 0
📊 Jogos: 0
📊 Relacionamentos: 0
📊 Notificações: 0
```

## ⚠️ **Pontos de Atenção:**

### **1. Backup Obrigatório:**
- **SEMPRE** faça backup antes de executar
- Use `pg_dump` ou export do Supabase
- Teste o backup antes de prosseguir

### **2. Ambiente:**
- Execute **APENAS** em desenvolvimento/teste
- **NUNCA** em produção sem autorização
- Verifique se está no banco correto

### **3. RLS (Row Level Security):**
- RLS é desabilitado temporariamente
- É reabilitado automaticamente no final
- Verifique se as políticas estão corretas

### **4. Storage:**
- Imagens de perfil são removidas
- Outros arquivos podem ser afetados
- Verifique buckets importantes

### **5. Sequências:**
- Todas as sequências são resetadas
- IDs voltam a começar do 1
- Pode afetar referências externas

## 🧪 **Como Testar Após o Reset:**

### **Teste 1: Verificar Tabelas Vazias**
```sql
-- Todas devem retornar 0
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM players;
SELECT COUNT(*) FROM games;
SELECT COUNT(*) FROM game_players;
SELECT COUNT(*) FROM notifications;
```

### **Teste 2: Verificar RLS**
```sql
-- Verificar se RLS está ativo
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND rowsecurity = true;
```

### **Teste 3: Verificar Storage**
```sql
-- Verificar se bucket está vazio
SELECT COUNT(*) FROM storage.objects 
WHERE bucket_id = 'profile-images';
```

### **Teste 4: Testar Aplicação**
```
1. Abra o app
2. Tente fazer login (deve falhar - não há usuários)
3. Tente criar conta (deve funcionar)
4. Teste funcionalidades básicas
```

## 🆘 **Solução de Problemas:**

### **Problema 1: Erro de Permissão**
```
Erro: permission denied for table [table_name]
```
**Solução:**
- Verifique permissões do usuário
- Execute como superuser se necessário
- Verifique políticas RLS

### **Problema 2: Erro de Foreign Key**
```
Erro: update or delete on table violates foreign key constraint
```
**Solução:**
- RLS pode estar bloqueando
- Execute com RLS desabilitado
- Verifique ordem de deleção

### **Problema 3: Erro de Storage**
```
Erro: permission denied for storage.objects
```
**Solução:**
- Verifique permissões do storage
- Execute como usuário com permissões
- Ou pule a limpeza do storage

### **Problema 4: RLS Não Reabilitado**
```
Problema: RLS não foi reabilitado
```
**Solução:**
- Execute manualmente:
```sql
ALTER TABLE public.[table_name] ENABLE ROW LEVEL SECURITY;
```

## 📈 **Monitoramento Pós-Reset:**

### **Queries de Verificação:**
```sql
-- Verificar se todas as tabelas estão vazias
SELECT 
    schemaname,
    tablename,
    n_live_tup as live_tuples
FROM pg_stat_user_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar políticas RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename;

-- Verificar sequências
SELECT 
    schemaname,
    sequencename,
    last_value
FROM pg_sequences 
WHERE schemaname = 'public'
ORDER BY sequencename;
```

## 🎉 **Resultado Esperado:**

Após a execução bem-sucedida:

- **✅ Todas as tabelas estão vazias** - Prontas para novos dados
- **✅ RLS reabilitado** - Segurança mantida
- **✅ Storage limpo** - Sem arquivos antigos
- **✅ Sequências resetadas** - IDs começam do 1
- **✅ Tabelas não utilizadas removidas** - Banco limpo
- **✅ Sistema pronto** - Estado inicial restaurado

## 📞 **Suporte:**

Se encontrar problemas:

1. **Execute o diagnóstico** primeiro
2. **Verifique os logs** do Supabase
3. **Confirme o backup** foi feito
4. **Execute reset simples** se completo falhar
5. **Verifique permissões** do usuário
6. **Teste em ambiente** de desenvolvimento primeiro

O reset está pronto para execução! 🚀✅

## 🔄 **Próximos Passos:**

Após o reset bem-sucedido:

1. **Teste o sistema** - Verifique se tudo funciona
2. **Crie dados de teste** - Para desenvolvimento
3. **Configure usuários** - Para testes
4. **Verifique funcionalidades** - Todas as features
5. **Documente problemas** - Se houver algum

O banco estará limpo e pronto para uso! 🎮✨

