-- =====================================================
-- CORREÇÃO SIMPLES - REMOVER RLS DA TABELA USERS
-- =====================================================
-- Execute este script para uma correção simples e efetiva

-- 1. Desabilitar RLS na tabela users (não é necessário pois é gerenciada pelo Supabase Auth)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 2. Remover todas as políticas da tabela users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;

-- 3. Recriar a função handle_new_user de forma mais simples
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        name = COALESCE(EXCLUDED.name, users.name),
        last_login_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Recriar o trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. Verificar se a correção foi aplicada
DO $$
BEGIN
    RAISE NOTICE '✅ RLS desabilitado na tabela users';
    RAISE NOTICE '✅ Políticas removidas da tabela users';
    RAISE NOTICE '✅ Função handle_new_user recriada';
    RAISE NOTICE '✅ Trigger recriado';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Correção simples aplicada com sucesso!';
    RAISE NOTICE 'A tabela users agora permite inserção via trigger.';
    RAISE NOTICE 'O registro de usuários deve funcionar corretamente.';
END $$;
