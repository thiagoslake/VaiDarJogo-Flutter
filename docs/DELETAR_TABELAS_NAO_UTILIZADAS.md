# 🗑️ Deletar Tabelas Não Utilizadas

## 📋 **Resumo:**

Este documento contém scripts SQL para deletar as tabelas não utilizadas pelo sistema VaiDarJogo Flutter do banco de dados Supabase.

## 🎯 **Tabelas que serão deletadas:**

### **❌ Tabelas NÃO utilizadas (10 tabelas):**
1. **`api_keys`** - Chaves de API não utilizadas
2. **`app_users`** - Usuários de aplicação não utilizados
3. **`audit_logs`** - Logs de auditoria não utilizados
4. **`device_tokens`** - Tokens de dispositivo não utilizados
5. **`participation_confirmations`** - Confirmações de participação não utilizadas
6. **`participations`** - Participações não utilizadas
7. **`payments`** - Pagamentos não utilizados
8. **`team_players`** - Jogadores de time não utilizados
9. **`teams`** - Times não utilizados
10. **`waiting_list`** - Lista de espera não utilizada

### **✅ Tabelas que serão mantidas (8 tabelas):**
1. **`games`** - Jogos (utilizada em 13 arquivos)
2. **`players`** - Jogadores (utilizada em 12 arquivos)
3. **`users`** - Usuários (utilizada em 18 arquivos)
4. **`game_players`** - Relacionamento jogos-jogadores (utilizada em 7 arquivos)
5. **`game_sessions`** - Sessões dos jogos (utilizada em 7 arquivos)
6. **`participation_requests`** - Solicitações de participação (utilizada em 3 arquivos)
7. **`notification_configs`** - Configurações de notificação (utilizada em 6 arquivos)
8. **`notifications`** - Notificações do sistema (utilizada em 5 arquivos)

## 📁 **Arquivos disponíveis:**

### **1. `check_tables_before_delete.sql`**
- **✅ RECOMENDADO:** Execute este script PRIMEIRO
- **🎯 Função:** Verifica quais tabelas existem antes de deletar
- **📊 Resultado:** Mostra status de cada tabela (existe/não existe)
- **🔍 Inclui:** Verificação de políticas RLS e índices

### **2. `delete_unused_tables_simple.sql`**
- **✅ RECOMENDADO:** Script simples e direto
- **🎯 Função:** Deleta as tabelas não utilizadas
- **⚡ Características:** Rápido, sem verificações complexas
- **🔧 Comando:** `DROP TABLE IF EXISTS ... CASCADE`

### **3. `delete_unused_tables.sql`**
- **⚠️ AVANÇADO:** Script completo com verificações
- **🎯 Função:** Deleta tabelas com verificações detalhadas
- **📊 Inclui:** Logs detalhados, verificações de segurança
- **🔧 Recursos:** Limpeza de políticas RLS, índices e sequências

## 🚀 **Como executar:**

### **Passo 1: Verificação (OBRIGATÓRIO)**
```sql
-- Execute no Supabase SQL Editor
-- Arquivo: check_tables_before_delete.sql
```

### **Passo 2: Backup (RECOMENDADO)**
```bash
# Faça backup do banco de dados antes de executar
# Use o comando de backup do Supabase ou exporte os dados
```

### **Passo 3: Execução**
```sql
-- Opção 1: Script simples (RECOMENDADO)
-- Arquivo: delete_unused_tables_simple.sql

-- Opção 2: Script completo (AVANÇADO)
-- Arquivo: delete_unused_tables.sql
```

### **Passo 4: Verificação final**
```sql
-- Execute novamente o check_tables_before_delete.sql
-- Para confirmar que as tabelas foram deletadas
```

## ⚠️ **Avisos importantes:**

### **🔴 ANTES de executar:**
- **✅ Faça backup** do banco de dados
- **✅ Execute o script de verificação** primeiro
- **✅ Confirme** que as tabelas listadas realmente não são utilizadas
- **✅ Teste** em ambiente de desenvolvimento primeiro

### **🔴 DURANTE a execução:**
- **✅ Monitore** os logs de execução
- **✅ Verifique** se não há erros
- **✅ Confirme** que as tabelas utilizadas não foram afetadas

### **🔴 APÓS a execução:**
- **✅ Teste** a aplicação para garantir que funciona
- **✅ Verifique** se todas as funcionalidades estão operacionais
- **✅ Monitore** por alguns dias para detectar problemas

## 🧪 **Teste de funcionamento:**

### **Verificar se a aplicação funciona:**
```
1. Abra o app VaiDarJogo Flutter
2. Teste o login
3. Navegue pelas telas principais
4. Teste funcionalidades de jogos
5. Teste notificações
6. Verifique se não há erros no console
```

### **Verificar tabelas restantes:**
```sql
-- Execute no Supabase SQL Editor
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;
```

## 📊 **Resultado esperado:**

### **Antes da execução:**
- **Total de tabelas:** ~17-20 tabelas
- **Tabelas utilizadas:** 8 tabelas
- **Tabelas não utilizadas:** 9-12 tabelas

### **Após a execução:**
- **Total de tabelas:** ~8-10 tabelas
- **Tabelas utilizadas:** 8 tabelas (mantidas)
- **Tabelas não utilizadas:** 0 tabelas (deletadas)

## 🎉 **Benefícios:**

### **Performance:**
- **✅ Menos tabelas** para o banco gerenciar
- **✅ Consultas mais rápidas** (menos tabelas para verificar)
- **✅ Backup mais rápido** (menos dados para processar)

### **Manutenção:**
- **✅ Banco mais limpo** e organizado
- **✅ Menos confusão** sobre quais tabelas usar
- **✅ Manutenção mais fácil** (menos tabelas para gerenciar)

### **Segurança:**
- **✅ Menos superfície de ataque** (menos tabelas expostas)
- **✅ Políticas RLS mais simples** (menos tabelas para proteger)
- **✅ Auditoria mais fácil** (menos tabelas para monitorar)

## 🆘 **Em caso de problemas:**

### **Se a aplicação parar de funcionar:**
1. **Restaure o backup** imediatamente
2. **Verifique os logs** de erro
3. **Identifique** qual tabela foi deletada por engano
4. **Recrie a tabela** se necessário

### **Se alguma tabela foi deletada por engano:**
1. **Pare a aplicação** imediatamente
2. **Restaure o backup** do banco
3. **Analise** qual tabela foi deletada incorretamente
4. **Recrie a tabela** com a estrutura correta

## 📞 **Suporte:**

Se encontrar problemas durante a execução:

1. **Verifique os logs** de erro do Supabase
2. **Consulte a documentação** do Supabase
3. **Teste em ambiente** de desenvolvimento primeiro
4. **Faça backup** antes de qualquer alteração

## 🎯 **Conclusão:**

A execução deste script irá:
- **✅ Otimizar** o banco de dados
- **✅ Remover** tabelas desnecessárias
- **✅ Melhorar** a performance
- **✅ Simplificar** a manutenção

**Lembre-se:** Sempre faça backup antes de executar scripts de alteração no banco de dados!

