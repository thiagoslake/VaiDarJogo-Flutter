-- =====================================================
-- TESTE DO SISTEMA DE AUTENTICAÇÃO
-- =====================================================
-- Execute este script para verificar se tudo está funcionando

-- 1. Verificar se a tabela users existe e tem a estrutura correta
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        RAISE NOTICE '✅ Tabela users existe';
        
        -- Verificar colunas
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'id') THEN
            RAISE NOTICE '✅ Coluna id existe';
        ELSE
            RAISE NOTICE '❌ Coluna id não encontrada';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') THEN
            RAISE NOTICE '✅ Coluna email existe';
        ELSE
            RAISE NOTICE '❌ Coluna email não encontrada';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'name') THEN
            RAISE NOTICE '✅ Coluna name existe';
        ELSE
            RAISE NOTICE '❌ Coluna name não encontrada';
        END IF;
    ELSE
        RAISE NOTICE '❌ Tabela users não existe';
    END IF;
END $$;

-- 2. Verificar se a função handle_new_user existe
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.routines 
        WHERE routine_name = 'handle_new_user' 
        AND routine_schema = 'public'
    ) THEN
        RAISE NOTICE '✅ Função handle_new_user existe';
    ELSE
        RAISE NOTICE '❌ Função handle_new_user não encontrada';
    END IF;
END $$;

-- 3. Verificar se o trigger existe
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'on_auth_user_created'
    ) THEN
        RAISE NOTICE '✅ Trigger on_auth_user_created existe';
    ELSE
        RAISE NOTICE '❌ Trigger on_auth_user_created não encontrado';
    END IF;
END $$;

-- 4. Verificar RLS na tabela users
DO $$
DECLARE
    rls_enabled BOOLEAN;
BEGIN
    SELECT row_security INTO rls_enabled
    FROM pg_tables 
    WHERE tablename = 'users' AND schemaname = 'public';
    
    IF rls_enabled THEN
        RAISE NOTICE '⚠️ RLS está habilitado na tabela users';
    ELSE
        RAISE NOTICE '✅ RLS está desabilitado na tabela users (correto para registro)';
    END IF;
END $$;

-- 5. Verificar se a tabela games tem user_id
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'games' AND column_name = 'user_id') THEN
            RAISE NOTICE '✅ Tabela games tem coluna user_id';
        ELSE
            RAISE NOTICE '❌ Tabela games não tem coluna user_id';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela games não existe';
    END IF;
END $$;

-- 6. Verificar se a tabela players tem user_id
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'players' AND column_name = 'user_id') THEN
            RAISE NOTICE '✅ Tabela players tem coluna user_id';
        ELSE
            RAISE NOTICE '❌ Tabela players não tem coluna user_id';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela players não existe';
    END IF;
END $$;

-- 7. Resumo final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 RESUMO DO TESTE:';
    RAISE NOTICE 'Se você viu ✅ para todos os itens, o sistema está configurado corretamente.';
    RAISE NOTICE 'Se você viu ❌ para algum item, execute o script de correção correspondente.';
    RAISE NOTICE 'Se você viu ⚠️, isso é normal se a tabela não existir ainda.';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Execute o app Flutter';
    RAISE NOTICE '2. Tente registrar um novo usuário';
    RAISE NOTICE '3. Se houver erro, execute: database/fix_rls_simple.sql';
END $$;
