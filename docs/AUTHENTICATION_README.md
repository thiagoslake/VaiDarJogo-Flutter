# 🔐 Sistema de Autenticação - VaiDarJogo

Este documento explica como o sistema de autenticação foi implementado no VaiDarJogo App.

## 📋 Visão Geral

O sistema agora suporta:
- ✅ Login/Registro de usuários
- ✅ Segregação completa de dados por usuário
- ✅ Proteção de rotas com AuthGuard
- ✅ Gerenciamento de estado com Riverpod
- ✅ Sincronização automática com Supabase Auth

## 🏗️ Arquitetura

### Modelos
- **`User`**: Modelo de usuário com informações básicas
- **`AuthState`**: Estado de autenticação (loading, error, user)

### Serviços
- **`AuthService`**: Serviço para operações de autenticação
  - Login/Logout
  - Registro de usuários
  - Redefinição de senha
  - Atualização de perfil

### Providers (Riverpod)
- **`authStateProvider`**: Estado global de autenticação
- **`currentUserProvider`**: Usuário atual
- **`isAuthenticatedProvider`**: Status de autenticação
- **`isLoadingProvider`**: Status de carregamento
- **`authErrorProvider`**: Erros de autenticação

### Telas
- **`LoginScreen`**: Tela de login com validação
- **`RegisterScreen`**: Tela de registro de usuário
- **`MainMenuScreen`**: Tela principal (protegida)

### Widgets
- **`AuthGuard`**: Proteção de rotas
- **`AuthRequired`**: Verificação de autenticação
- **`AuthCheck`**: Hook para verificar autenticação

## 🗄️ Banco de Dados

### Tabela `users`
```sql
CREATE TABLE users (
    id UUID PRIMARY KEY,           -- Mesmo ID do Supabase Auth
    email VARCHAR(255) UNIQUE,     -- Email do usuário
    name VARCHAR(255),             -- Nome completo
    phone VARCHAR(20),             -- Telefone (opcional)
    created_at TIMESTAMP,          -- Data de criação
    last_login_at TIMESTAMP,       -- Último login
    is_active BOOLEAN              -- Status ativo
);
```

### Segregação por Usuário
Todas as tabelas principais agora incluem `user_id`:
- `games.user_id`
- `players.user_id`
- `game_players.user_id`
- `payments.user_id`
- `consolidation_saves.user_id`

### Row Level Security (RLS)
- ✅ Habilitado em todas as tabelas
- ✅ Políticas para segregação automática por usuário
- ✅ Usuários só veem seus próprios dados

## 🚀 Como Usar

### 1. Aplicar Migração do Banco

**IMPORTANTE**: Execute a migração no Supabase SQL Editor.

**Opção 1 - Script Seguro (Recomendado):**
```sql
-- Execute o arquivo: database/auth_migration_safe.sql
-- Este script verifica se as tabelas existem antes de modificá-las
```

**Opção 2 - Passo a Passo:**
```sql
-- Execute o arquivo: database/step_by_step_migration.sql
-- Execute cada seção separadamente para maior controle
```

**Opção 3 - Manual (se houver problemas):**
1. Crie a tabela `users` primeiro
2. Adicione `user_id` nas tabelas existentes (`games`, `players`)
3. Configure RLS e políticas
4. Crie triggers para Supabase Auth

### 2. Configurar Supabase Auth
No painel do Supabase:
1. Vá em Authentication > Settings
2. Configure as URLs de redirecionamento
3. Ative o registro por email

### 3. Usar no App

#### Proteger uma Tela
```dart
class MinhaTela extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthGuard(
      child: Scaffold(
        // Sua tela aqui
      ),
    );
  }
}
```

#### Verificar Autenticação
```dart
// Verificar se está logado
final isAuthenticated = ref.watch(isAuthenticatedProvider);

// Obter usuário atual
final currentUser = ref.watch(currentUserProvider);

// Fazer login
await ref.read(authStateProvider.notifier).signIn(email, password);

// Fazer logout
await ref.read(authStateProvider.notifier).signOut();
```

#### Criar Dados Segregados
```dart
// Sempre incluir user_id ao criar dados
final currentUser = ref.read(currentUserProvider);
final gameData = {
  'user_id': currentUser!.id,
  'organization_name': 'Meu Jogo',
  // ... outros campos
};
```

## 🔒 Segurança

### Row Level Security (RLS)
- Todas as consultas são automaticamente filtradas por usuário
- Impossível acessar dados de outros usuários
- Políticas aplicadas automaticamente

### Validação
- Email válido obrigatório
- Senha mínima de 6 caracteres
- Nome obrigatório no registro
- Validação de telefone opcional

### Tokens
- Tokens JWT gerenciados pelo Supabase
- Renovação automática
- Logout invalida tokens

## 📱 Fluxo de Uso

1. **Primeiro Acesso**
   - Usuário abre o app
   - `AuthGuard` verifica autenticação
   - Redireciona para `LoginScreen`

2. **Registro**
   - Usuário clica em "Criar conta"
   - Preenche formulário de registro
   - Conta criada no Supabase Auth
   - Trigger cria registro na tabela `users`
   - Redireciona para `MainMenuScreen`

3. **Login**
   - Usuário insere email/senha
   - `AuthService.signInWithEmail()` valida credenciais
   - Estado atualizado com dados do usuário
   - Redireciona para `MainMenuScreen`

4. **Uso do App**
   - Todas as operações incluem `user_id`
   - RLS filtra dados automaticamente
   - Usuário só vê seus próprios jogos/dados

5. **Logout**
   - Usuário clica no avatar no AppBar
   - Seleciona "Sair"
   - `AuthService.signOut()` limpa sessão
   - Redireciona para `LoginScreen`

## 🛠️ Manutenção

### Adicionar Nova Tabela
1. Adicionar coluna `user_id UUID`
2. Criar foreign key para `users(id)`
3. Habilitar RLS
4. Criar políticas de acesso
5. Adicionar índice para performance

### Atualizar Políticas
```sql
-- Exemplo: Nova política para tabela
CREATE POLICY "Users can view own data" ON minha_tabela
    FOR SELECT USING (auth.uid() = user_id);
```

## 🐛 Troubleshooting

### Erro: "PostgrestException: new row violates row-level security policy for table 'users'"
**Solução:** Execute o script de correção:
```sql
-- Execute: database/fix_rls_simple.sql
-- Este script desabilita RLS na tabela users para permitir registro
```

### Erro: "PostgrestException: Cannot coerce the result to a single JSON object, code: PGRST116"
**Solução:** Execute o script de correção:
```sql
-- Execute: database/fix_user_creation.sql
-- Este script corrige a criação de usuários e triggers
```

### Erro: "AuthApiException: Email not confirmed, statusCode: 400, code: email_not_confirmed"
**Solução:** Execute o script de correção:
```sql
-- Execute: database/confirm_emails_simple.sql
-- Este script confirma emails existentes
```

**Alternativa:** Desabilitar confirmação de email no painel do Supabase:
1. Vá para o painel do Supabase
2. Acesse Authentication > Settings
3. Desabilite "Email Confirmation"
4. Salve as configurações

### Erro: "User not authenticated"
- Verificar se o usuário fez login
- Verificar se o token não expirou
- Verificar configuração do Supabase

### Erro: "Row Level Security"
- Verificar se RLS está habilitado
- Verificar se as políticas estão corretas
- Verificar se `user_id` está sendo incluído

### Dados não aparecem
- Verificar se `user_id` está correto
- Verificar políticas de RLS
- Verificar se o usuário está logado

### Testar o Sistema
Execute o script de teste para verificar se tudo está funcionando:
```sql
-- Execute: database/test_auth_system.sql
-- Este script verifica todas as configurações
```

## 📚 Recursos Adicionais

- [Documentação Supabase Auth](https://supabase.com/docs/guides/auth)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)
- [Flutter Riverpod](https://riverpod.dev/)
- [Flutter Supabase](https://supabase.com/docs/guides/getting-started/flutter)

## ✅ Checklist de Implementação

- [x] Modelos de usuário criados
- [x] Serviço de autenticação implementado
- [x] Providers Riverpod configurados
- [x] Telas de login/registro criadas
- [x] AuthGuard implementado
- [x] Main.dart atualizado
- [x] Banco de dados migrado
- [x] RLS configurado
- [x] Triggers criados
- [x] Índices adicionados
- [x] Documentação criada

---

**🎉 Sistema de autenticação implementado com sucesso!**

Agora cada usuário tem seus próprios jogos e dados completamente segregados.
