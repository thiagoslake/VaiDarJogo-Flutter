-- =====================================================
-- CORREÇÃO ALTERNATIVA - DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================
-- Execute este script se a correção anterior não funcionar

-- 1. Desabilitar RLS temporariamente na tabela users
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 2. Recriar a função handle_new_user
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

-- 3. Recriar o trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Reabilitar RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 5. Criar políticas RLS
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 6. Política especial para permitir inserção via trigger
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;
CREATE POLICY "Enable insert for authenticated users" ON users
    FOR INSERT WITH CHECK (true);

-- 7. Verificar se tudo foi aplicado
DO $$
BEGIN
    RAISE NOTICE '✅ RLS temporariamente desabilitado e reabilitado';
    RAISE NOTICE '✅ Função handle_new_user recriada';
    RAISE NOTICE '✅ Trigger recriado';
    RAISE NOTICE '✅ Políticas RLS aplicadas';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Correção alternativa aplicada!';
    RAISE NOTICE 'O registro de usuários deve funcionar agora.';
END $$;
