-- =====================================================
-- DIAGNÓSTICO ANTES DO RESET DO BANCO
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Analisar o estado atual do banco antes de fazer reset
-- =====================================================

-- =====================================================
-- 1. VERIFICAÇÃO GERAL DA ESTRUTURA
-- =====================================================

-- Verificar se as tabelas principais existem
SELECT 
    'VERIFICAÇÃO DE EXISTÊNCIA DAS TABELAS' as categoria,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') 
        THEN '✅ Tabela users existe'
        ELSE '❌ Tabela users NÃO existe'
    END as status_users,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'players') 
        THEN '✅ Tabela players existe'
        ELSE '❌ Tabela players NÃO existe'
    END as status_players,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'games') 
        THEN '✅ Tabela games existe'
        ELSE '❌ Tabela games NÃO existe'
    END as status_games;

-- =====================================================
-- 2. CONTAGEM DE REGISTROS EM CADA TABELA
-- =====================================================

-- Contar registros em cada tabela principal
SELECT 
    'CONTAGEM DE REGISTROS' as categoria,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM games) as total_games,
    (SELECT COUNT(*) FROM game_players) as total_game_players,
    (SELECT COUNT(*) FROM game_sessions) as total_game_sessions,
    (SELECT COUNT(*) FROM participation_requests) as total_participation_requests,
    (SELECT COUNT(*) FROM notifications) as total_notifications,
    (SELECT COUNT(*) FROM notification_configs) as total_notification_configs,
    (SELECT COUNT(*) FROM notification_templates) as total_notification_templates,
    (SELECT COUNT(*) FROM notification_logs) as total_notification_logs,
    (SELECT COUNT(*) FROM player_fcm_tokens) as total_player_fcm_tokens;

-- =====================================================
-- 3. ANÁLISE DE RELACIONAMENTOS
-- =====================================================

-- Verificar relacionamentos entre tabelas
SELECT 
    'ANÁLISE DE RELACIONAMENTOS' as categoria,
    (SELECT COUNT(*) FROM game_players gp JOIN players p ON gp.player_id = p.id) as game_players_com_players,
    (SELECT COUNT(*) FROM game_players gp JOIN games g ON gp.game_id = g.id) as game_players_com_games,
    (SELECT COUNT(*) FROM game_sessions gs JOIN games g ON gs.game_id = g.id) as game_sessions_com_games,
    (SELECT COUNT(*) FROM players p JOIN users u ON p.user_id = u.id) as players_com_users,
    (SELECT COUNT(*) FROM notifications n JOIN players p ON n.player_id = p.id) as notifications_com_players,
    (SELECT COUNT(*) FROM notifications n JOIN games g ON n.game_id = g.id) as notifications_com_games;

-- =====================================================
-- 4. VERIFICAÇÃO DE INTEGRIDADE
-- =====================================================

-- Verificar players sem user_id
SELECT 
    'PLAYERS SEM USER_ID' as categoria,
    COUNT(*) as quantidade
FROM players 
WHERE user_id IS NULL;

-- Verificar game_players órfãos
SELECT 
    'GAME_PLAYERS ÓRFÃOS' as categoria,
    COUNT(*) as quantidade
FROM game_players gp
LEFT JOIN players p ON gp.player_id = p.id
WHERE p.id IS NULL;

-- Verificar game_sessions órfãs
SELECT 
    'GAME_SESSIONS ÓRFÃS' as categoria,
    COUNT(*) as quantidade
FROM game_sessions gs
LEFT JOIN games g ON gs.game_id = g.id
WHERE g.id IS NULL;

-- Verificar notifications órfãs
SELECT 
    'NOTIFICATIONS ÓRFÃS' as categoria,
    COUNT(*) as quantidade
FROM notifications n
LEFT JOIN players p ON n.player_id = p.id
WHERE p.id IS NULL;

-- =====================================================
-- 5. ANÁLISE DE DADOS ESPECÍFICOS
-- =====================================================

-- Verificar distribuição de tipos de jogador
SELECT 
    'DISTRIBUIÇÃO DE TIPOS DE JOGADOR' as categoria,
    player_type,
    COUNT(*) as quantidade
FROM game_players
GROUP BY player_type
ORDER BY quantidade DESC;

-- Verificar status dos jogos
SELECT 
    'STATUS DOS JOGOS' as categoria,
    CASE 
        WHEN frequency = 'one_time' THEN 'Jogo Avulso'
        WHEN frequency = 'weekly' THEN 'Semanal'
        WHEN frequency = 'biweekly' THEN 'Quinzenal'
        WHEN frequency = 'monthly' THEN 'Mensal'
        ELSE frequency
    END as tipo_frequencia,
    COUNT(*) as quantidade
FROM games
GROUP BY frequency
ORDER BY quantidade DESC;

-- Verificar status das notificações
SELECT 
    'STATUS DAS NOTIFICAÇÕES' as categoria,
    status,
    COUNT(*) as quantidade
FROM notifications
GROUP BY status
ORDER BY quantidade DESC;

-- =====================================================
-- 6. VERIFICAÇÃO DE STORAGE
-- =====================================================

-- Verificar bucket de imagens de perfil
SELECT 
    'STORAGE - BUCKET PROFILE-IMAGES' as categoria,
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE name = 'profile-images') 
        THEN '✅ Bucket existe'
        ELSE '❌ Bucket não existe'
    END as status_bucket,
    (SELECT COUNT(*) FROM storage.objects WHERE bucket_id = 'profile-images') as total_objetos;

-- =====================================================
-- 7. VERIFICAÇÃO DE POLÍTICAS RLS
-- =====================================================

-- Verificar políticas RLS ativas
SELECT 
    'POLÍTICAS RLS ATIVAS' as categoria,
    tablename,
    COUNT(*) as total_politicas
FROM pg_policies 
WHERE schemaname = 'public'
GROUP BY tablename
ORDER BY tablename;

-- =====================================================
-- 8. VERIFICAÇÃO DE SEQUÊNCIAS
-- =====================================================

-- Verificar sequências
SELECT 
    'SEQUÊNCIAS' as categoria,
    sequencename,
    last_value,
    start_value
FROM pg_sequences 
WHERE schemaname = 'public'
ORDER BY sequencename;

-- =====================================================
-- 9. VERIFICAÇÃO DE TABELAS NÃO UTILIZADAS
-- =====================================================

-- Verificar se existem tabelas não utilizadas
SELECT 
    'TABELAS NÃO UTILIZADAS' as categoria,
    t.table_name,
    CASE 
        WHEN it.table_name IS NOT NULL THEN 'EXISTE - será deletada no reset'
        ELSE 'NÃO EXISTE'
    END as status
FROM (
    SELECT unnest(ARRAY[
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
    ]) as table_name
) t
LEFT JOIN information_schema.tables it 
    ON it.table_name = t.table_name 
    AND it.table_schema = 'public'
ORDER BY t.table_name;

-- =====================================================
-- 10. RESUMO E RECOMENDAÇÕES
-- =====================================================

DO $$
DECLARE
    total_users INTEGER;
    total_players INTEGER;
    total_games INTEGER;
    total_game_players INTEGER;
    total_notifications INTEGER;
    players_sem_user_id INTEGER;
    game_players_orfos INTEGER;
    notifications_orfas INTEGER;
    total_tables INTEGER;
    total_sequences INTEGER;
    total_policies INTEGER;
BEGIN
    -- Contar dados
    SELECT COUNT(*) INTO total_users FROM users;
    SELECT COUNT(*) INTO total_players FROM players;
    SELECT COUNT(*) INTO total_games FROM games;
    SELECT COUNT(*) INTO total_game_players FROM game_players;
    SELECT COUNT(*) INTO total_notifications FROM notifications;
    SELECT COUNT(*) INTO players_sem_user_id FROM players WHERE user_id IS NULL;
    SELECT COUNT(*) INTO game_players_orfos FROM game_players gp LEFT JOIN players p ON gp.player_id = p.id WHERE p.id IS NULL;
    SELECT COUNT(*) INTO notifications_orfas FROM notifications n LEFT JOIN players p ON n.player_id = p.id WHERE p.id IS NULL;
    SELECT COUNT(*) INTO total_tables FROM information_schema.tables WHERE table_schema = 'public';
    SELECT COUNT(*) INTO total_sequences FROM pg_sequences WHERE schemaname = 'public';
    SELECT COUNT(*) INTO total_policies FROM pg_policies WHERE schemaname = 'public';
    
    RAISE NOTICE '=== RESUMO DO BANCO DE DADOS ===';
    RAISE NOTICE '📊 Total de tabelas: %', total_tables;
    RAISE NOTICE '📊 Total de sequências: %', total_sequences;
    RAISE NOTICE '📊 Total de políticas RLS: %', total_policies;
    RAISE NOTICE '';
    RAISE NOTICE '📊 DADOS PRINCIPAIS:';
    RAISE NOTICE '   - Usuários: %', total_users;
    RAISE NOTICE '   - Players: %', total_players;
    RAISE NOTICE '   - Jogos: %', total_games;
    RAISE NOTICE '   - Relacionamentos game_players: %', total_game_players;
    RAISE NOTICE '   - Notificações: %', total_notifications;
    RAISE NOTICE '';
    RAISE NOTICE '📊 PROBLEMAS IDENTIFICADOS:';
    RAISE NOTICE '   - Players sem user_id: %', players_sem_user_id;
    RAISE NOTICE '   - Game_players órfãos: %', game_players_orfos;
    RAISE NOTICE '   - Notifications órfãs: %', notifications_orfas;
    RAISE NOTICE '';
    
    IF total_users = 0 AND total_players = 0 AND total_games = 0 THEN
        RAISE NOTICE '✅ BANCO JÁ ESTÁ VAZIO - Reset não é necessário';
    ELSIF players_sem_user_id > 0 OR game_players_orfos > 0 OR notifications_orfas > 0 THEN
        RAISE NOTICE '⚠️ BANCO TEM PROBLEMAS DE INTEGRIDADE - Reset recomendado';
    ELSE
        RAISE NOTICE 'ℹ️ BANCO TEM DADOS VÁLIDOS - Reset opcional';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '💡 RECOMENDAÇÕES:';
    IF total_users > 0 OR total_players > 0 OR total_games > 0 THEN
        RAISE NOTICE '   1. Faça backup antes do reset';
        RAISE NOTICE '   2. Execute reset_database_simple.sql para limpeza rápida';
        RAISE NOTICE '   3. Ou execute reset_database_complete.sql para limpeza detalhada';
    ELSE
        RAISE NOTICE '   1. Banco já está limpo';
        RAISE NOTICE '   2. Pode começar a usar o sistema normalmente';
    END IF;
END $$;

