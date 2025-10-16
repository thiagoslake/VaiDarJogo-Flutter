-- =====================================================
-- CRIAR TRIGGER PARA INSERÇÃO AUTOMÁTICA NA TABELA USERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Criar trigger que insere automaticamente na tabela users
-- quando um usuário se registra no Supabase Auth
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para criar o trigger automático
-- 2. Garante que telefone seja salvo na tabela users
-- 3. Funciona com o processo de registro atual
-- =====================================================

-- =====================================================
-- 1. CRIAR FUNÇÃO PARA INSERIR USUÁRIO NA TABELA USERS
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (
    id,
    email,
    name,
    phone,
    created_at,
    updated_at,
    is_active
  ) VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', 'Usuário'),
    NEW.raw_user_meta_data->>'phone',
    NEW.created_at,
    NOW(),
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 2. CRIAR TRIGGER NO AUTH.USERS
-- =====================================================

-- Remover trigger existente se houver
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Criar novo trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 3. VERIFICAR SE TRIGGER FOI CRIADO
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- 4. TESTAR TRIGGER (OPCIONAL)
-- =====================================================

-- Para testar, você pode criar um usuário de teste:
-- INSERT INTO auth.users (id, email, raw_user_meta_data) VALUES 
-- (gen_random_uuid(), 'teste@email.com', '{"name": "Usuário Teste", "phone": "11999999999"}');

-- =====================================================
-- 5. VERIFICAR DADOS INSERIDOS
-- =====================================================

-- Verificar se há usuários na tabela users
SELECT 
    id,
    email,
    name,
    phone,
    created_at
FROM public.users
ORDER BY created_at DESC
LIMIT 5;




