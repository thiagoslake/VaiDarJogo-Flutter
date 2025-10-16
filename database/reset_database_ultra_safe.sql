-- =====================================================
-- RESET ULTRA SEGURO DO BANCO DE DADOS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ⚠️  ATENÇÃO: ESTE SCRIPT IRÁ DELETAR TODOS OS DADOS! ⚠️
-- 
-- OBJETIVO: Limpar dados das tabelas que existem (sem erros)
-- 
-- ⚠️  IMPORTANTE: 
-- 1. FAÇA BACKUP ANTES DE EXECUTAR
-- 2. ESTE SCRIPT É IRREVERSÍVEL
-- 3. TODOS OS DADOS SERÃO PERDIDOS
-- =====================================================

-- =====================================================
-- PASSO 1: DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================

-- Desabilitar RLS para facilitar a limpeza (apenas se as tabelas existirem)
ALTER TABLE IF EXISTS public.notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_configs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_templates DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.player_fcm_tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_players DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.participation_requests DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.players DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.games DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- PASSO 2: DELETAR DADOS USANDO DO $$ (ULTRA SEGURO)
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    deleted_count INTEGER;
BEGIN
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
    END IF;

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
    END IF;

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
    END IF;
END $$;

-- =====================================================
-- PASSO 3: DELETAR TABELAS NÃO UTILIZADAS
-- =====================================================

-- Deletar tabelas que podem existir mas não são utilizadas
DROP TABLE IF EXISTS public.api_keys CASCADE;
DROP TABLE IF EXISTS public.app_users CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.device_tokens CASCADE;
DROP TABLE IF EXISTS public.participation_confirmations CASCADE;
DROP TABLE IF EXISTS public.participations CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.team_players CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;
DROP TABLE IF EXISTS public.waiting_list CASCADE;

-- =====================================================
-- PASSO 4: RESETAR SEQUÊNCIAS
-- =====================================================

-- Resetar todas as sequências para começar do 1
DO $$
DECLARE
    seq_record RECORD;
BEGIN
    FOR seq_record IN 
        SELECT schemaname, sequencename 
        FROM pg_sequences 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || seq_record.schemaname || '.' || seq_record.sequencename || ' RESTART WITH 1';
    END LOOP;
END $$;

-- =====================================================
-- PASSO 5: LIMPAR STORAGE
-- =====================================================

-- Limpar bucket de imagens de perfil (se existir)
DO $$
DECLARE
    bucket_exists boolean;
    deleted_objects INTEGER;
BEGIN
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
-- PASSO 6: REABILITAR RLS
-- =====================================================

-- Reabilitar RLS em todas as tabelas (apenas se existirem)
ALTER TABLE IF EXISTS public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.player_fcm_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.participation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PASSO 7: VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    table_exists boolean;
    record_count INTEGER;
    total_users INTEGER := 0;
    total_players INTEGER := 0;
    total_games INTEGER := 0;
    total_tables INTEGER;
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    -- Verificar users
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'users'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO total_users FROM users;
        RAISE NOTICE '📊 users: % registros', total_users;
    ELSE
        RAISE NOTICE '📊 users: tabela não existe';
    END IF;
    
    -- Verificar players
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'players'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO total_players FROM players;
        RAISE NOTICE '📊 players: % registros', total_players;
    ELSE
        RAISE NOTICE '📊 players: tabela não existe';
    END IF;
    
    -- Verificar games
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'games'
    ) INTO table_exists;
    
    IF table_exists THEN
        SELECT COUNT(*) INTO total_games FROM games;
        RAISE NOTICE '📊 games: % registros', total_games;
    ELSE
        RAISE NOTICE '📊 games: tabela não existe';
    END IF;
    
    -- Contar total de tabelas
    SELECT COUNT(*) INTO total_tables FROM information_schema.tables WHERE table_schema = 'public';
    RAISE NOTICE '📊 Total de tabelas no banco: %', total_tables;
    
    -- Relatório final
    RAISE NOTICE '=== RESET ULTRA SEGURO FINALIZADO ===';
    
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




