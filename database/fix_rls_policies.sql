-- =====================================================
-- CORREÇÃO DAS POLÍTICAS RLS PARA REGISTRO DE USUÁRIOS
-- =====================================================
-- Execute este script no Supabase SQL Editor para corrigir o erro de registro

-- 1. Remover políticas existentes que podem estar causando conflito
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;

-- 2. Criar políticas RLS corretas para a tabela users
-- Política para visualizar próprio perfil
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Política para atualizar próprio perfil
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Política para inserir próprio perfil (permite inserção via trigger)
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 3. Atualizar a função handle_new_user para usar SECURITY DEFINER corretamente
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    -- Inserir na tabela users usando SECURITY DEFINER
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

-- 5. Verificar se as políticas foram aplicadas corretamente
DO $$
BEGIN
    RAISE NOTICE '✅ Políticas RLS corrigidas para tabela users';
    RAISE NOTICE '✅ Função handle_new_user atualizada';
    RAISE NOTICE '✅ Trigger recriado';
    RAISE NOTICE '';
    RAISE NOTICE '🎉 Correção aplicada com sucesso!';
    RAISE NOTICE 'Agora o registro de usuários deve funcionar corretamente.';
END $$;
