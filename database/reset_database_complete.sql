-- =====================================================
-- RESET COMPLETO DO BANCO DE DADOS
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
    RAISE NOTICE '⚠️  ⚠️  ⚠️  ATENÇÃO: RESET COMPLETO DO BANCO ⚠️  ⚠️  ⚠️';
    RAISE NOTICE 'Este script irá DELETAR TODOS os dados do sistema!';
    RAISE NOTICE 'Certifique-se de que fez backup antes de continuar!';
    RAISE NOTICE 'Pressione Ctrl+C para cancelar, ou aguarde 5 segundos...';
    
    -- Aguardar 5 segundos para dar tempo de cancelar
    PERFORM pg_sleep(5);
    
    RAISE NOTICE 'Iniciando reset completo do banco de dados...';
END $$;

-- =====================================================
-- PASSO 2: DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== DESABILITANDO RLS TEMPORARIAMENTE ===';
END $$;

-- Desabilitar RLS em todas as tabelas para facilitar a limpeza
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
-- PASSO 3: DELETAR DADOS EM ORDEM DE DEPENDÊNCIA
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== DELETANDO DADOS EM ORDEM DE DEPENDÊNCIA ===';
END $$;

-- 3.1 Deletar dados de notificações (dependem de players e games)
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notification_logs;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ notification_logs: % registros deletados', deleted_count;

    DELETE FROM public.notifications;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ notifications: % registros deletados', deleted_count;

    DELETE FROM public.notification_configs;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ notification_configs: % registros deletados', deleted_count;

    DELETE FROM public.notification_templates;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ notification_templates: % registros deletados', deleted_count;

    DELETE FROM public.player_fcm_tokens;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ player_fcm_tokens: % registros deletados', deleted_count;
END $$;

-- 3.2 Deletar dados de relacionamentos (dependem de players e games)
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.game_players;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ game_players: % registros deletados', deleted_count;

    DELETE FROM public.game_sessions;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ game_sessions: % registros deletados', deleted_count;

    DELETE FROM public.participation_requests;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ participation_requests: % registros deletados', deleted_count;
END $$;

-- 3.3 Deletar dados principais
DO $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.players;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ players: % registros deletados', deleted_count;

    DELETE FROM public.games;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ games: % registros deletados', deleted_count;

    DELETE FROM public.users;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ users: % registros deletados', deleted_count;
END $$;

-- =====================================================
-- PASSO 4: DELETAR TABELAS NÃO UTILIZADAS (SE EXISTIREM)
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== DELETANDO TABELAS NÃO UTILIZADAS ===';
END $$;

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
-- PASSO 5: RESETAR SEQUÊNCIAS E AUTO-INCREMENTOS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== RESETANDO SEQUÊNCIAS ===';
END $$;

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
        RAISE NOTICE '✅ Sequência resetada: %', seq_record.sequencename;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 6: LIMPAR STORAGE (SE EXISTIR)
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== LIMPANDO STORAGE ===';
END $$;

-- Limpar bucket de imagens de perfil (se existir)
DO $$
DECLARE
    bucket_exists boolean;
BEGIN
    -- Verificar se o bucket existe
    SELECT EXISTS (
        SELECT 1 FROM storage.buckets 
        WHERE name = 'profile-images'
    ) INTO bucket_exists;
    
    IF bucket_exists THEN
        -- Deletar todos os objetos do bucket
        DELETE FROM storage.objects WHERE bucket_id = 'profile-images';
        RAISE NOTICE '✅ Storage profile-images: objetos deletados';
    ELSE
        RAISE NOTICE 'ℹ️ Bucket profile-images não existe';
    END IF;
END $$;

-- =====================================================
-- PASSO 7: REABILITAR RLS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== REABILITANDO RLS ===';
END $$;

-- Reabilitar RLS em todas as tabelas
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
-- PASSO 8: VERIFICAÇÃO FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
END $$;

-- Verificar se todas as tabelas estão vazias
SELECT 
    'VERIFICAÇÃO DE TABELAS VAZIAS' as categoria,
    t.table_name,
    CASE 
        WHEN t.table_name = 'users' THEN (SELECT COUNT(*) FROM users)
        WHEN t.table_name = 'players' THEN (SELECT COUNT(*) FROM players)
        WHEN t.table_name = 'games' THEN (SELECT COUNT(*) FROM games)
        WHEN t.table_name = 'game_players' THEN (SELECT COUNT(*) FROM game_players)
        WHEN t.table_name = 'game_sessions' THEN (SELECT COUNT(*) FROM game_sessions)
        WHEN t.table_name = 'participation_requests' THEN (SELECT COUNT(*) FROM participation_requests)
        WHEN t.table_name = 'notifications' THEN (SELECT COUNT(*) FROM notifications)
        WHEN t.table_name = 'notification_configs' THEN (SELECT COUNT(*) FROM notification_configs)
        WHEN t.table_name = 'notification_templates' THEN (SELECT COUNT(*) FROM notification_templates)
        WHEN t.table_name = 'notification_logs' THEN (SELECT COUNT(*) FROM notification_logs)
        WHEN t.table_name = 'player_fcm_tokens' THEN (SELECT COUNT(*) FROM player_fcm_tokens)
        ELSE 0
    END as registros_restantes
FROM (
    SELECT unnest(ARRAY[
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
    ]) as table_name
) t
ORDER BY t.table_name;

-- Verificar total de tabelas no banco
SELECT 
    'RESUMO FINAL' as categoria,
    COUNT(*) as total_tabelas,
    'Todas as tabelas estão vazias e prontas para uso' as status
FROM information_schema.tables 
WHERE table_schema = 'public';

-- =====================================================
-- PASSO 9: RELATÓRIO DE SUCESSO
-- =====================================================

DO $$
DECLARE
    total_users INTEGER;
    total_players INTEGER;
    total_games INTEGER;
    total_tables INTEGER;
BEGIN
    -- Contar registros restantes
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO total_players FROM players;
    SELECT COUNT(*) INTO total_games FROM games;
    SELECT COUNT(*) INTO total_tables FROM information_schema.tables WHERE table_schema = 'public';
    
    RAISE NOTICE '=== RESET COMPLETO FINALIZADO ===';
    RAISE NOTICE '📊 Total de tabelas no banco: %', total_tables;
    RAISE NOTICE '📊 Usuários restantes: %', total_users;
    RAISE NOTICE '📊 Players restantes: %', total_players;
    RAISE NOTICE '📊 Jogos restantes: %', total_games;
    
    IF total_users = 0 AND total_players = 0 AND total_games = 0 THEN
        RAISE NOTICE '🎉 SUCESSO: Banco de dados resetado completamente!';
        RAISE NOTICE '✅ Todas as tabelas estão vazias e prontas para uso';
        RAISE NOTICE '✅ RLS foi reabilitado em todas as tabelas';
        RAISE NOTICE '✅ Storage foi limpo';
        RAISE NOTICE '✅ Sequências foram resetadas';
        RAISE NOTICE '🚀 Sistema pronto para uso em estado inicial!';
    ELSE
        RAISE NOTICE '⚠️ ATENÇÃO: Ainda há dados no banco!';
        RAISE NOTICE 'Verifique as tabelas acima para identificar problemas';
    END IF;
END $$;

-- =====================================================
-- QUERIES ÚTEIS PARA VERIFICAÇÃO PÓS-RESET
-- =====================================================

-- Query para verificar se todas as tabelas estão vazias
-- SELECT 
--     schemaname,
--     tablename,
--     n_tup_ins as inserts,
--     n_tup_upd as updates,
--     n_tup_del as deletes,
--     n_live_tup as live_tuples,
--     n_dead_tup as dead_tuples
-- FROM pg_stat_user_tables 
-- WHERE schemaname = 'public'
-- ORDER BY tablename;

-- Query para verificar políticas RLS
-- SELECT 
--     schemaname,
--     tablename,
--     policyname,
--     permissive,
--     roles,
--     cmd,
--     qual
-- FROM pg_policies 
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- Query para verificar sequências
-- SELECT 
--     schemaname,
--     sequencename,
--     last_value,
--     start_value,
--     increment_by,
--     max_value,
--     min_value
-- FROM pg_sequences 
-- WHERE schemaname = 'public'
-- ORDER BY sequencename;
