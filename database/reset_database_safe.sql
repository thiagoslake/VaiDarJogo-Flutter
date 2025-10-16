-- =====================================================
-- RESET SEGURO DO BANCO DE DADOS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ⚠️  ATENÇÃO: ESTE SCRIPT IRÁ DELETAR TODOS OS DADOS DO SISTEMA! ⚠️
-- 
-- OBJETIVO: Limpar completamente o banco de dados e voltar ao estado inicial
-- 
-- ⚠️  IMPORTANTE: 
-- 1. FAÇA BACKUP COMPLETO ANTES DE EXECUTAR
-- 2. ESTE SCRIPT É IRREVERSÍVEL
-- 3. TODOS OS DADOS SERÃO PERDIDOS PERMANENTEMENTE
-- 4. EXECUTE APENAS EM AMBIENTE DE DESENVOLVIMENTO/TESTE
-- =====================================================

-- =====================================================
-- PASSO 1: CONFIRMAÇÃO DE SEGURANÇA
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '⚠️  ⚠️  ⚠️  ATENÇÃO: RESET SEGURO DO BANCO ⚠️  ⚠️  ⚠️';
    RAISE NOTICE 'Este script irá DELETAR TODOS os dados do sistema!';
    RAISE NOTICE 'Certifique-se de que fez backup antes de continuar!';
    RAISE NOTICE 'Pressione Ctrl+C para cancelar, ou aguarde 3 segundos...';
    
    -- Aguardar 3 segundos para dar tempo de cancelar
    PERFORM pg_sleep(3);
    
    RAISE NOTICE 'Iniciando reset seguro do banco de dados...';
END $$;

-- =====================================================
-- PASSO 2: VERIFICAR ESTRUTURA DO BANCO
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    table_name text;
    tables_to_check text[] := ARRAY[
        'notifications',
        'notification_configs', 
        'notification_templates',
        'notification_logs',
        'player_fcm_tokens',
        'game_players',
        'game_sessions',
        'participation_requests',
        'players',
        'games',
        'users'
    ];
BEGIN
    RAISE NOTICE '=== VERIFICANDO ESTRUTURA DO BANCO ===';
    
    FOREACH table_name IN ARRAY tables_to_check
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            RAISE NOTICE '✅ Tabela "%" existe', table_name;
        ELSE
            RAISE NOTICE 'ℹ️ Tabela "%" não existe (será ignorada)', table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 3: DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    table_name text;
    tables_to_disable text[] := ARRAY[
        'notifications',
        'notification_configs', 
        'notification_templates',
        'notification_logs',
        'player_fcm_tokens',
        'game_players',
        'game_sessions',
        'participation_requests',
        'players',
        'games',
        'users'
    ];
BEGIN
    RAISE NOTICE '=== DESABILITANDO RLS TEMPORARIAMENTE ===';
    
    FOREACH table_name IN ARRAY tables_to_disable
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            EXECUTE 'ALTER TABLE public.' || table_name || ' DISABLE ROW LEVEL SECURITY';
            RAISE NOTICE '✅ RLS desabilitado em "%"', table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 4: DELETAR DADOS EM ORDEM DE DEPENDÊNCIA
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    deleted_count INTEGER;
BEGIN
    RAISE NOTICE '=== DELETANDO DADOS EM ORDEM DE DEPENDÊNCIA ===';
    
    -- 4.1 Deletar dados de notificações (dependem de players e games)
    
    -- notification_logs
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notification_logs'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.notification_logs;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ notification_logs: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ notification_logs: tabela não existe (ignorada)';
    END IF;

    -- notifications
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notifications'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.notifications;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ notifications: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ notifications: tabela não existe (ignorada)';
    END IF;

    -- notification_configs
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notification_configs'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.notification_configs;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ notification_configs: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ notification_configs: tabela não existe (ignorada)';
    END IF;

    -- notification_templates
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'notification_templates'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.notification_templates;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ notification_templates: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ notification_templates: tabela não existe (ignorada)';
    END IF;

    -- player_fcm_tokens
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'player_fcm_tokens'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.player_fcm_tokens;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ player_fcm_tokens: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ player_fcm_tokens: tabela não existe (ignorada)';
    END IF;

    -- 4.2 Deletar dados de relacionamentos (dependem de players e games)
    
    -- game_players
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'game_players'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.game_players;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ game_players: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ game_players: tabela não existe (ignorada)';
    END IF;

    -- game_sessions
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'game_sessions'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.game_sessions;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ game_sessions: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ game_sessions: tabela não existe (ignorada)';
    END IF;

    -- participation_requests
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'participation_requests'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.participation_requests;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ participation_requests: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ participation_requests: tabela não existe (ignorada)';
    END IF;

    -- 4.3 Deletar dados principais
    
    -- players
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'players'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.players;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ players: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ players: tabela não existe (ignorada)';
    END IF;

    -- games
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'games'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.games;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ games: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ games: tabela não existe (ignorada)';
    END IF;

    -- users
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ) INTO table_exists;
    
    IF table_exists THEN
        DELETE FROM public.users;
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ users: % registros deletados', deleted_count;
    ELSE
        RAISE NOTICE 'ℹ️ users: tabela não existe (ignorada)';
    END IF;
END $$;

-- =====================================================
-- PASSO 5: DELETAR TABELAS NÃO UTILIZADAS (SE EXISTIREM)
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    table_name text;
    tables_to_drop text[] := ARRAY[
        'api_keys',
        'app_users',
        'audit_logs',
        'device_tokens',
        'participation_confirmations',
        'participations',
        'payments',
        'team_players',
        'teams',
        'waiting_list'
    ];
BEGIN
    RAISE NOTICE '=== DELETANDO TABELAS NÃO UTILIZADAS ===';
    
    FOREACH table_name IN ARRAY tables_to_drop
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            EXECUTE 'DROP TABLE public.' || table_name || ' CASCADE';
            RAISE NOTICE '✅ Tabela "%" deletada', table_name;
        ELSE
            RAISE NOTICE 'ℹ️ Tabela "%" não existe (ignorada)', table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 6: RESETAR SEQUÊNCIAS E AUTO-INCREMENTOS
-- =====================================================

DO $$
DECLARE
    seq_record RECORD;
BEGIN
    RAISE NOTICE '=== RESETANDO SEQUÊNCIAS ===';
    
    FOR seq_record IN 
        SELECT schemaname, sequencename 
        FROM pg_sequences 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || seq_record.schemaname || '.' || seq_record.sequencename || ' RESTART WITH 1';
        RAISE NOTICE '✅ Sequência resetada: %', seq_record.sequencename;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 7: LIMPAR STORAGE (SE EXISTIR)
-- =====================================================

DO $$
DECLARE
    bucket_exists boolean;
    deleted_objects INTEGER;
BEGIN
    RAISE NOTICE '=== LIMPANDO STORAGE ===';
    
    -- Verificar se o bucket existe
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets 
        WHERE name = 'profile-images'
    ) INTO bucket_exists;
    
    IF bucket_exists THEN
        -- Deletar todos os objetos do bucket
        DELETE FROM storage.objects WHERE bucket_id = 'profile-images';
        GET DIAGNOSTICS deleted_objects = ROW_COUNT;
        RAISE NOTICE '✅ Storage profile-images: % objetos deletados', deleted_objects;
    ELSE
        RAISE NOTICE 'ℹ️ Bucket profile-images não existe';
    END IF;
END $$;

-- =====================================================
-- PASSO 8: REABILITAR RLS
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    table_name text;
    tables_to_enable text[] := ARRAY[
        'notifications',
        'notification_configs', 
        'notification_templates',
        'notification_logs',
        'player_fcm_tokens',
        'game_players',
        'game_sessions',
        'participation_requests',
        'players',
        'games',
        'users'
    ];
BEGIN
    RAISE NOTICE '=== REABILITANDO RLS ===';
    
    FOREACH table_name IN ARRAY tables_to_enable
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            EXECUTE 'ALTER TABLE public.' || table_name || ' ENABLE ROW LEVEL SECURITY';
            RAISE NOTICE '✅ RLS reabilitado em "%"', table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 9: VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    table_name text;
    record_count INTEGER;
    tables_to_check text[] := ARRAY[
        'users',
        'players', 
        'games',
        'game_players',
        'game_sessions',
        'participation_requests',
        'notifications',
        'notification_configs',
        'notification_templates',
        'notification_logs',
        'player_fcm_tokens'
    ];
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    FOREACH table_name IN ARRAY tables_to_check
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            EXECUTE 'SELECT COUNT(*) FROM public.' || table_name INTO record_count;
            RAISE NOTICE '📊 %: % registros', table_name, record_count;
        ELSE
            RAISE NOTICE '📊 %: tabela não existe', table_name;
        END IF;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 10: RELATÓRIO DE SUCESSO
-- =====================================================

DO $$
DECLARE
    total_users INTEGER := 0;
    total_players INTEGER := 0;
    total_games INTEGER := 0;
    total_tables INTEGER;
    table_exists boolean;
BEGIN
    -- Contar registros restantes (apenas se as tabelas existirem)
    
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ) INTO table_exists;
    IF table_exists THEN
        SELECT COUNT(*) INTO total_users FROM users;
    END IF;
    
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'players'
    ) INTO table_exists;
    IF table_exists THEN
        SELECT COUNT(*) INTO total_players FROM players;
    END IF;
    
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'games'
    ) INTO table_exists;
    IF table_exists THEN
        SELECT COUNT(*) INTO total_games FROM games;
    END IF;
    
    SELECT COUNT(*) INTO total_tables FROM information_schema.tables WHERE table_schema = 'public';
    
    RAISE NOTICE '=== RESET SEGURO FINALIZADO ===';
    RAISE NOTICE '📊 Total de tabelas no banco: %', total_tables;
    RAISE NOTICE '📊 Usuários restantes: %', total_users;
    RAISE NOTICE '📊 Players restantes: %', total_players;
    RAISE NOTICE '📊 Jogos restantes: %', total_games;
    
    IF total_users = 0 AND total_players = 0 AND total_games = 0 THEN
        RAISE NOTICE '🎉 SUCESSO: Banco de dados resetado completamente!';
        RAISE NOTICE '✅ Todas as tabelas existentes estão vazias e prontas para uso';
        RAISE NOTICE '✅ RLS foi reabilitado em todas as tabelas existentes';
        RAISE NOTICE '✅ Storage foi limpo';
        RAISE NOTICE '✅ Sequências foram resetadas';
        RAISE NOTICE '🚀 Sistema pronto para uso em estado inicial!';
    ELSE
        RAISE NOTICE '⚠️ ATENÇÃO: Ainda há dados no banco!';
        RAISE NOTICE 'Verifique as tabelas acima para identificar problemas';
    END IF;
END $$;

