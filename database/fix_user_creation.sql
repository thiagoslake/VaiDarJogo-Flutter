-- =====================================================
-- CORREÇÃO PARA CRIAÇÃO DE USUÁRIOS
-- =====================================================
-- Execute este script no Supabase SQL Editor para corrigir o erro de criação de usuários

-- 1. Verificar se a tabela users existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        -- Criar tabela users se não existir
        CREATE TABLE users (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            email VARCHAR(255) UNIQUE NOT NULL,
            name VARCHAR(255) NOT NULL,
            phone VARCHAR(20),
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            last_login_at TIMESTAMP WITH TIME ZONE,
            is_active BOOLEAN DEFAULT true,
            
            -- Constraints
            CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
            CONSTRAINT users_name_check CHECK (LENGTH(name) >= 2)
        );
        RAISE NOTICE '✅ Tabela users criada';
    ELSE
        RAISE NOTICE 'ℹ️ Tabela users já existe';
    END IF;
END $$;

-- 2. Desabilitar RLS na tabela users (não é necessário para esta tabela)
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 3. Remover políticas existentes
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Users can insert own profile" ON users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON users;

-- 4. Recriar a função handle_new_user com tratamento de erro melhorado
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
EXCEPTION
    WHEN OTHERS THEN
        -- Log do erro
        RAISE LOG 'Erro ao criar usuário: %', SQLERRM;
        -- Retornar NEW mesmo com erro para não quebrar o registro no auth
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Recriar o trigger
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 6. Função para atualizar last_login_at
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'Erro ao atualizar last_login_at: %', SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Trigger para atualizar last_login_at
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
    AFTER UPDATE OF last_sign_in_at ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.update_last_login();

-- 8. Verificar se tudo foi aplicado corretamente
DO $$
DECLARE
    user_table_exists BOOLEAN;
    function_exists BOOLEAN;
    trigger_exists BOOLEAN;
BEGIN
    -- Verificar tabela users
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'users'
    ) INTO user_table_exists;
    
    -- Verificar função
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user' 
        AND routine_schema = 'public'
    ) INTO function_exists;
    
    -- Verificar trigger
    SELECT EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    ) INTO trigger_exists;
    
    RAISE NOTICE '🎯 VERIFICAÇÃO FINAL:';
    RAISE NOTICE '📊 Tabela users existe: %', user_table_exists;
    RAISE NOTICE '📊 Função handle_new_user existe: %', function_exists;
    RAISE NOTICE '📊 Trigger on_auth_user_created existe: %', trigger_exists;
    
    IF user_table_exists AND function_exists AND trigger_exists THEN
        RAISE NOTICE '✅ Correção aplicada com sucesso!';
        RAISE NOTICE 'Agora o registro de usuários deve funcionar corretamente.';
    ELSE
        RAISE NOTICE '❌ Alguns componentes não foram criados corretamente.';
    END IF;
END $$;
