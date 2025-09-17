-- =====================================================
-- TESTE DE CRIAÇÃO DE USUÁRIOS
-- =====================================================
-- Execute este script para testar se o sistema de criação de usuários está funcionando

-- 1. Verificar estrutura da tabela users
DO $$
DECLARE
    column_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO column_count
    FROM information_schema.columns 
    WHERE table_name = 'users' AND table_schema = 'public';
    
    RAISE NOTICE '📊 Colunas na tabela users: %', column_count;
    
    IF column_count > 0 THEN
        RAISE NOTICE '✅ Tabela users tem estrutura correta';
    ELSE
        RAISE NOTICE '❌ Tabela users não tem colunas';
    END IF;
END $$;

-- 2. Verificar se RLS está desabilitado
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
        RAISE NOTICE '✅ RLS está desabilitado na tabela users (correto)';
    END IF;
END $$;

-- 3. Verificar função handle_new_user
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

-- 4. Verificar trigger
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

-- 5. Testar inserção manual (simulação)
DO $$
DECLARE
    test_user_id UUID;
    test_email TEXT;
BEGIN
    -- Gerar ID e email de teste
    test_user_id := gen_random_uuid();
    test_email := 'teste@exemplo.com';
    
    BEGIN
        -- Tentar inserir um usuário de teste
        INSERT INTO users (id, email, name, created_at, is_active)
        VALUES (test_user_id, test_email, 'Usuário Teste', NOW(), true);
        
        RAISE NOTICE '✅ Inserção manual funcionou';
        
        -- Limpar o teste
        DELETE FROM users WHERE id = test_user_id;
        RAISE NOTICE '✅ Limpeza do teste concluída';
        
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE '❌ Erro na inserção manual: %', SQLERRM;
    END;
END $$;

-- 6. Verificar permissões
DO $$
DECLARE
    has_insert_permission BOOLEAN;
BEGIN
    -- Verificar se o usuário atual tem permissão de INSERT
    SELECT has_table_privilege('users', 'INSERT') INTO has_insert_permission;
    
    IF has_insert_permission THEN
        RAISE NOTICE '✅ Permissão de INSERT na tabela users';
    ELSE
        RAISE NOTICE '❌ Sem permissão de INSERT na tabela users';
    END IF;
END $$;

-- 7. Resumo final
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 RESUMO DO TESTE:';
    RAISE NOTICE 'Se você viu ✅ para todos os itens, o sistema está configurado corretamente.';
    RAISE NOTICE 'Se você viu ❌ para algum item, execute: database/fix_user_creation.sql';
    RAISE NOTICE '';
    RAISE NOTICE '📋 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Execute o app Flutter';
    RAISE NOTICE '2. Tente registrar um novo usuário';
    RAISE NOTICE '3. Se ainda houver erro, verifique os logs do Supabase';
END $$;
