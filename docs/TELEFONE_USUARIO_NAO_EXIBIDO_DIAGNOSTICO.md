# 📱 Telefone do Usuário Não Exibido - Diagnóstico e Solução

## ❌ **Problema Identificado:**

O telefone do usuário não está sendo exibido na tela "Meu Perfil", mesmo quando o campo está preenchido no banco de dados.

## 🔍 **Análise do Problema:**

### **1. Código da Interface:**
```dart
// user_profile_screen.dart - linha 632
_buildInfoRow('Telefone', currentUser?.phone ?? 'N/A'),
```

### **2. Fluxo de Dados:**
```
Tela "Meu Perfil" 
    ↓
currentUserProvider (Riverpod)
    ↓
AuthService.getCurrentUser()
    ↓
SELECT * FROM users WHERE id = session.user.id
    ↓
User.fromMap(userData)
    ↓
currentUser.phone
```

### **3. Possíveis Causas:**
- ❌ **Campo phone não existe** na tabela `users`
- ❌ **Dados não estão sendo salvos** no campo `phone`
- ❌ **Consulta SQL não retorna** o campo `phone`
- ❌ **Mapeamento incorreto** no modelo `User`
- ❌ **Dados estão em `null`** ou vazios

## 🔧 **Soluções Implementadas:**

### **1. Logs de Debug Adicionados:**

#### **AuthService.getCurrentUser():**
```dart
print('🔍 DEBUG - Dados do usuário carregados: $userData');
print('🔍 DEBUG - Telefone do usuário: ${userData['phone']}');
```

#### **User.fromMap():**
```dart
print('🔍 DEBUG - User.fromMap - Telefone recebido: ${map['phone']}');
```

#### **UserProfileScreen._buildProfileContent():**
```dart
print('🔍 DEBUG - _buildProfileContent - currentUser: ${currentUser?.email}');
print('🔍 DEBUG - _buildProfileContent - telefone: ${currentUser?.phone}');
```

### **2. Scripts SQL de Diagnóstico:**

#### **check_user_phone_field.sql:**
- ✅ Verifica estrutura da tabela `users`
- ✅ Lista dados dos usuários
- ✅ Conta usuários com/sem telefone
- ✅ Verifica metadados do Auth

#### **fix_user_phone_field.sql:**
- ✅ Cria coluna `phone` se não existir
- ✅ Atualiza telefones dos metadados
- ✅ Verifica resultado final

## 🎯 **Como Diagnosticar:**

### **1. Executar Script de Verificação:**
```sql
-- Executar no Supabase SQL Editor
-- Arquivo: check_user_phone_field.sql
```

### **2. Verificar Logs do Flutter:**
```
🔍 DEBUG - Dados do usuário carregados: {id: xxx, email: xxx, phone: xxx}
🔍 DEBUG - Telefone do usuário: xxx
🔍 DEBUG - User.fromMap - Telefone recebido: xxx
🔍 DEBUG - _buildProfileContent - telefone: xxx
```

### **3. Verificar Estrutura da Tabela:**
```sql
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'phone';
```

## 🚀 **Soluções por Cenário:**

### **Cenário 1: Campo phone não existe**
```sql
-- Executar fix_user_phone_field.sql
ALTER TABLE public.users ADD COLUMN phone VARCHAR(20);
```

### **Cenário 2: Dados não estão sendo salvos**
- ✅ Verificar processo de registro
- ✅ Verificar se telefone está sendo passado no `signUp`
- ✅ Verificar se está sendo salvo na tabela `users`

### **Cenário 3: Dados estão em null/vazios**
```sql
-- Atualizar telefones dos metadados
UPDATE public.users 
SET phone = au.raw_user_meta_data->>'phone'
FROM auth.users au 
WHERE public.users.id = au.id 
  AND (public.users.phone IS NULL OR public.users.phone = '')
  AND au.raw_user_meta_data->>'phone' IS NOT NULL;
```

### **Cenário 4: Problema no mapeamento**
- ✅ Verificar se `User.fromMap()` está correto
- ✅ Verificar se `currentUser?.phone` está sendo acessado corretamente

## 📊 **Estrutura Esperada:**

### **Tabela users:**
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),  -- ← Campo deve existir
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);
```

### **Dados de Exemplo:**
```sql
INSERT INTO users (id, email, name, phone) VALUES 
('uuid-123', 'usuario@email.com', 'Nome Usuário', '11999999999');
```

## 🔄 **Fluxo de Correção:**

### **1. Diagnóstico:**
```bash
# 1. Executar aplicativo
flutter run

# 2. Navegar para "Meu Perfil"
# 3. Verificar logs no console
# 4. Executar check_user_phone_field.sql
```

### **2. Correção:**
```bash
# 1. Executar fix_user_phone_field.sql
# 2. Verificar se telefones foram atualizados
# 3. Testar novamente a tela "Meu Perfil"
```

### **3. Validação:**
```bash
# 1. Verificar se telefone aparece na interface
# 2. Verificar se logs mostram dados corretos
# 3. Testar edição do telefone
```

## 🎉 **Status:**

- ✅ **Logs de debug adicionados** - Para identificar onde está o problema
- ✅ **Scripts SQL criados** - Para diagnosticar e corrigir
- ✅ **Estrutura verificada** - Código da interface está correto
- ⏳ **Aguardando diagnóstico** - Executar scripts e verificar logs

**Execute os scripts SQL e verifique os logs para identificar a causa exata do problema!** 🔍✅



