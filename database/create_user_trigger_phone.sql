-- =====================================================
-- CRIAR TRIGGER PARA SALVAR TELEFONE EM AMBAS AS TABELAS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Garantir que o telefone seja salvo em users.phone e players.phone_number
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para criar o trigger automático
-- 2. Garante inserção dupla do telefone
-- 3. Funciona com o processo de registro atual
-- =====================================================

-- =====================================================
-- 1. REMOVER TRIGGER EXISTENTE (SE HOUVER)
-- =====================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- =====================================================
-- 2. CRIAR FUNÇÃO PARA INSERIR USUÁRIO COM TELEFONE
-- =====================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Inserir na tabela users com telefone dos metadados
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
    NEW.raw_user_meta_data->>'phone',  -- Telefone dos metadados
    NEW.created_at,
    NOW(),
    true
  );
  
  RAISE NOTICE '✅ Usuário criado na tabela users com telefone: %', NEW.raw_user_meta_data->>'phone';
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 3. CRIAR TRIGGER NO AUTH.USERS
-- =====================================================

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =====================================================
-- 4. VERIFICAR SE TRIGGER FOI CRIADO
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- 5. TESTAR TRIGGER (OPCIONAL)
-- =====================================================

-- Para testar, você pode criar um usuário de teste:
-- INSERT INTO auth.users (id, email, raw_user_meta_data) VALUES 
-- (gen_random_uuid(), 'teste@email.com', '{"name": "Usuário Teste", "phone": "11999999999"}');

-- =====================================================
-- 6. VERIFICAR DADOS INSERIDOS
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




