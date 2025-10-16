-- =====================================================
-- CORRIGIR PROBLEMAS DE REGISTRO DE USUÁRIO
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir usuários que estão no Auth mas não na tabela users
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se houver problemas de registro
-- 2. Este script cria registros na tabela users para usuários do Auth
-- 3. Não afeta dados existentes
-- =====================================================

-- =====================================================
-- 1. CRIAR REGISTROS NA TABELA USERS PARA USUÁRIOS DO AUTH
-- =====================================================

DO $$
DECLARE
    auth_user RECORD;
    created_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== CORRIGINDO REGISTROS DE USUÁRIOS ===';
    
    -- Para cada usuário no Auth que não está na tabela users
    FOR auth_user IN 
        SELECT 
            au.id,
            au.email,
            au.created_at,
            au.raw_user_meta_data,
            au.email_confirmed_at,
            au.last_sign_in_at
        FROM auth.users au
        LEFT JOIN public.users pu ON au.id = pu.id
        WHERE pu.id IS NULL
    LOOP
        -- Inserir na tabela users
        INSERT INTO public.users (
            id,
            email,
            name,
            phone,
            created_at,
            updated_at,
            last_login_at,
            is_active
        ) VALUES (
            auth_user.id,
            auth_user.email,
            COALESCE(auth_user.raw_user_meta_data->>'name', 'Usuário'),
            auth_user.raw_user_meta_data->>'phone',
            auth_user.created_at,
            NOW(),
            auth_user.last_sign_in_at,
            true
        );
        
        created_count := created_count + 1;
        RAISE NOTICE '✅ Usuário criado: % (%)', auth_user.email, auth_user.id;
    END LOOP;
    
    RAISE NOTICE '=== CORREÇÃO CONCLUÍDA ===';
    RAISE NOTICE '✅ Total de usuários criados: %', created_count;
END $$;

-- =====================================================
-- 2. CRIAR PERFIS DE JOGADOR PARA USUÁRIOS SEM PERFIL
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    created_count INTEGER := 0;
    phone_to_use TEXT;
BEGIN
    RAISE NOTICE '=== CRIANDO PERFIS DE JOGADOR ===';
    
    -- Para cada usuário que não tem perfil de jogador
    FOR user_record IN 
        SELECT 
            u.id,
            u.email,
            u.name,
            u.phone
        FROM public.users u
        LEFT JOIN public.players p ON u.id = p.user_id
        WHERE p.user_id IS NULL
    LOOP
        -- Definir telefone para usar
        phone_to_use := COALESCE(user_record.phone, '00000000000');
        
        -- Se telefone foi fornecido, verificar se já está em uso
        IF user_record.phone IS NOT NULL AND user_record.phone != '00000000000' THEN
            IF EXISTS (SELECT 1 FROM public.players WHERE phone_number = user_record.phone) THEN
                phone_to_use := '00000000000';
                RAISE NOTICE '⚠️ Telefone % já está em uso, usando telefone padrão para %', user_record.phone, user_record.email;
            END IF;
        END IF;
        
        -- Inserir perfil de jogador
        INSERT INTO public.players (
            user_id,
            name,
            phone_number,
            status,
            created_at,
            updated_at
        ) VALUES (
            user_record.id,
            user_record.name,
            phone_to_use,
            'active',
            NOW(),
            NOW()
        );
        
        created_count := created_count + 1;
        RAISE NOTICE '✅ Perfil de jogador criado para: % (%)', user_record.email, user_record.id;
    END LOOP;
    
    RAISE NOTICE '=== PERFIS DE JOGADOR CRIADOS ===';
    RAISE NOTICE '✅ Total de perfis criados: %', created_count;
END $$;

-- =====================================================
-- 3. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    auth_count INTEGER;
    users_count INTEGER;
    players_count INTEGER;
    missing_users INTEGER;
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    -- Contar usuários
    SELECT COUNT(*) INTO auth_count FROM auth.users;
    SELECT COUNT(*) INTO users_count FROM public.users;
    SELECT COUNT(*) INTO players_count FROM public.players;
    
    -- Contar usuários faltando
    SELECT COUNT(*) INTO missing_users
    FROM auth.users au
    LEFT JOIN public.users pu ON au.id = pu.id
    WHERE pu.id IS NULL;
    
    RAISE NOTICE '📊 Usuários no Auth: %', auth_count;
    RAISE NOTICE '📊 Usuários na tabela users: %', users_count;
    RAISE NOTICE '📊 Jogadores na tabela players: %', players_count;
    RAISE NOTICE '📊 Usuários faltando na tabela users: %', missing_users;
    
    IF missing_users = 0 THEN
        RAISE NOTICE '🎉 SUCESSO: Todos os usuários do Auth têm registro na tabela users!';
    ELSE
        RAISE NOTICE '⚠️ ATENÇÃO: Ainda há % usuários faltando na tabela users', missing_users;
    END IF;
END $$;




