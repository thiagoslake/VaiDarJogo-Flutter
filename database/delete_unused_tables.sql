-- =====================================================
-- SCRIPT PARA DELETAR TABELAS NÃO UTILIZADAS
-- Sistema: VaiDarJogo Flutter
-- Data: $(date)
-- =====================================================
-- 
-- ATENÇÃO: Este script irá DELETAR PERMANENTEMENTE as tabelas listadas abaixo.
-- Certifique-se de fazer um BACKUP do banco de dados antes de executar!
--
-- TABELAS QUE SERÃO DELETADAS:
-- 1. api_keys
-- 2. app_users  
-- 3. audit_logs
-- 4. device_tokens
-- 5. participation_confirmations
-- 6. participations
-- 7. payments
-- 8. team_players
-- 9. teams
-- 10. waiting_list
--
-- TABELAS QUE SERÃO MANTIDAS (UTILIZADAS PELO SISTEMA):
-- - games
-- - players
-- - users
-- - game_players
-- - game_sessions
-- - participation_requests
-- - notification_configs
-- - notifications
-- =====================================================

-- Verificar se as tabelas existem antes de deletar
DO $$
DECLARE
    table_exists boolean;
    tables_to_delete text[] := ARRAY[
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
    table_name text;
BEGIN
    RAISE NOTICE '=== INICIANDO VERIFICAÇÃO DE TABELAS ===';
    
    -- Verificar cada tabela
    FOREACH table_name IN ARRAY tables_to_delete
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            RAISE NOTICE 'Tabela "%" EXISTE e será deletada', table_name;
        ELSE
            RAISE NOTICE 'Tabela "%" NÃO EXISTE (já foi deletada ou nunca existiu)', table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== VERIFICAÇÃO CONCLUÍDA ===';
END $$;

-- =====================================================
-- DELETAR TABELAS NÃO UTILIZADAS
-- =====================================================

-- 1. Deletar tabela api_keys (se existir)
DROP TABLE IF EXISTS public.api_keys CASCADE;
RAISE NOTICE 'Tabela api_keys deletada (se existia)';

-- 2. Deletar tabela app_users (se existir)
DROP TABLE IF EXISTS public.app_users CASCADE;
RAISE NOTICE 'Tabela app_users deletada (se existia)';

-- 3. Deletar tabela audit_logs (se existir)
DROP TABLE IF EXISTS public.audit_logs CASCADE;
RAISE NOTICE 'Tabela audit_logs deletada (se existia)';

-- 4. Deletar tabela device_tokens (se existir)
DROP TABLE IF EXISTS public.device_tokens CASCADE;
RAISE NOTICE 'Tabela device_tokens deletada (se existia)';

-- 5. Deletar tabela participation_confirmations (se existir)
DROP TABLE IF EXISTS public.participation_confirmations CASCADE;
RAISE NOTICE 'Tabela participation_confirmations deletada (se existia)';

-- 6. Deletar tabela participations (se existir)
DROP TABLE IF EXISTS public.participations CASCADE;
RAISE NOTICE 'Tabela participations deletada (se existia)';

-- 7. Deletar tabela payments (se existir)
DROP TABLE IF EXISTS public.payments CASCADE;
RAISE NOTICE 'Tabela payments deletada (se existia)';

-- 8. Deletar tabela team_players (se existir)
DROP TABLE IF EXISTS public.team_players CASCADE;
RAISE NOTICE 'Tabela team_players deletada (se existia)';

-- 9. Deletar tabela teams (se existir)
DROP TABLE IF EXISTS public.teams CASCADE;
RAISE NOTICE 'Tabela teams deletada (se existia)';

-- 10. Deletar tabela waiting_list (se existir)
DROP TABLE IF EXISTS public.waiting_list CASCADE;
RAISE NOTICE 'Tabela waiting_list deletada (se existia)';

-- =====================================================
-- VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se as tabelas foram deletadas com sucesso
DO $$
DECLARE
    table_exists boolean;
    tables_to_delete text[] := ARRAY[
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
    table_name text;
    deleted_count integer := 0;
    not_found_count integer := 0;
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    -- Verificar cada tabela
    FOREACH table_name IN ARRAY tables_to_delete
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            RAISE NOTICE 'ERRO: Tabela "%" ainda existe!', table_name;
        ELSE
            RAISE NOTICE 'OK: Tabela "%" foi deletada com sucesso', table_name;
            deleted_count := deleted_count + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== RESUMO ===';
    RAISE NOTICE 'Tabelas deletadas: %', deleted_count;
    RAISE NOTICE 'Tabelas não encontradas: %', array_length(tables_to_delete, 1) - deleted_count;
    RAISE NOTICE 'Total processado: %', array_length(tables_to_delete, 1);
    
    IF deleted_count = array_length(tables_to_delete, 1) THEN
        RAISE NOTICE 'SUCESSO: Todas as tabelas não utilizadas foram removidas!';
    ELSE
        RAISE NOTICE 'ATENÇÃO: Algumas tabelas podem não ter sido deletadas.';
    END IF;
END $$;

-- =====================================================
-- VERIFICAR TABELAS RESTANTES (UTILIZADAS PELO SISTEMA)
-- =====================================================

-- Verificar se as tabelas utilizadas ainda existem
DO $$
DECLARE
    table_exists boolean;
    tables_to_keep text[] := ARRAY[
        'games',
        'players',
        'users',
        'game_players',
        'game_sessions',
        'participation_requests',
        'notification_configs',
        'notifications'
    ];
    table_name text;
    existing_count integer := 0;
BEGIN
    RAISE NOTICE '=== VERIFICANDO TABELAS UTILIZADAS ===';
    
    -- Verificar cada tabela
    FOREACH table_name IN ARRAY tables_to_keep
    LOOP
        SELECT EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = table_name
        ) INTO table_exists;
        
        IF table_exists THEN
            RAISE NOTICE 'OK: Tabela "%" existe e está sendo utilizada', table_name;
            existing_count := existing_count + 1;
        ELSE
            RAISE NOTICE 'ERRO: Tabela "%" NÃO EXISTE! Sistema pode não funcionar!', table_name;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== RESUMO TABELAS UTILIZADAS ===';
    RAISE NOTICE 'Tabelas utilizadas encontradas: %', existing_count;
    RAISE NOTICE 'Total de tabelas utilizadas: %', array_length(tables_to_keep, 1);
    
    IF existing_count = array_length(tables_to_keep, 1) THEN
        RAISE NOTICE 'SUCESSO: Todas as tabelas utilizadas estão presentes!';
    ELSE
        RAISE NOTICE 'ATENÇÃO: Algumas tabelas utilizadas estão faltando!';
    END IF;
END $$;

-- =====================================================
-- LIMPEZA DE POLÍTICAS RLS (se existirem)
-- =====================================================

-- Deletar políticas RLS das tabelas deletadas (se existirem)
DO $$
DECLARE
    policy_name text;
    table_name text;
    tables_to_delete text[] := ARRAY[
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
    RAISE NOTICE '=== LIMPANDO POLÍTICAS RLS ===';
    
    -- Deletar políticas RLS para cada tabela
    FOREACH table_name IN ARRAY tables_to_delete
    LOOP
        -- Deletar todas as políticas da tabela
        FOR policy_name IN 
            SELECT policyname 
            FROM pg_policies 
            WHERE schemaname = 'public' 
            AND tablename = table_name
        LOOP
            EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I CASCADE', policy_name, table_name);
            RAISE NOTICE 'Política RLS "%" deletada da tabela "%"', policy_name, table_name;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Limpeza de políticas RLS concluída';
END $$;

-- =====================================================
-- LIMPEZA DE ÍNDICES (se existirem)
-- =====================================================

-- Deletar índices das tabelas deletadas (se existirem)
DO $$
DECLARE
    index_name text;
    table_name text;
    tables_to_delete text[] := ARRAY[
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
    RAISE NOTICE '=== LIMPANDO ÍNDICES ===';
    
    -- Deletar índices para cada tabela
    FOREACH table_name IN ARRAY tables_to_delete
    LOOP
        -- Deletar todos os índices da tabela
        FOR index_name IN 
            SELECT indexname 
            FROM pg_indexes 
            WHERE schemaname = 'public' 
            AND tablename = table_name
        LOOP
            EXECUTE format('DROP INDEX IF EXISTS public.%I CASCADE', index_name);
            RAISE NOTICE 'Índice "%" deletado da tabela "%"', index_name, table_name;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Limpeza de índices concluída';
END $$;

-- =====================================================
-- LIMPEZA DE SEQUÊNCIAS (se existirem)
-- =====================================================

-- Deletar sequências das tabelas deletadas (se existirem)
DO $$
DECLARE
    sequence_name text;
    table_name text;
    tables_to_delete text[] := ARRAY[
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
    RAISE NOTICE '=== LIMPANDO SEQUÊNCIAS ===';
    
    -- Deletar sequências para cada tabela
    FOREACH table_name IN ARRAY tables_to_delete
    LOOP
        -- Deletar sequências relacionadas à tabela
        FOR sequence_name IN 
            SELECT sequencename 
            FROM pg_sequences 
            WHERE schemaname = 'public' 
            AND sequencename LIKE table_name || '%'
        LOOP
            EXECUTE format('DROP SEQUENCE IF EXISTS public.%I CASCADE', sequence_name);
            RAISE NOTICE 'Sequência "%" deletada (relacionada à tabela "%")', sequence_name, table_name;
        END LOOP;
    END LOOP;
    
    RAISE NOTICE 'Limpeza de sequências concluída';
END $$;

-- =====================================================
-- SCRIPT CONCLUÍDO
-- =====================================================

RAISE NOTICE '=== SCRIPT DE LIMPEZA CONCLUÍDO ===';
RAISE NOTICE 'Todas as tabelas não utilizadas foram removidas do banco de dados.';
RAISE NOTICE 'O sistema VaiDarJogo Flutter agora está otimizado!';
RAISE NOTICE '=====================================';

