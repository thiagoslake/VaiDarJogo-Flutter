-- =====================================================
-- SCRIPT DE TESTE SIMPLES PARA VERIFICAR TABELAS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- Este script testa se a correção do erro de ambiguidade funcionou
-- Execute este script para verificar se não há mais erros
-- =====================================================

-- Teste 1: Verificar tabelas não utilizadas (que serão deletadas)
SELECT 
    'TABELAS NÃO UTILIZADAS' as categoria,
    t.table_name,
    CASE 
        WHEN it.table_name IS NOT NULL THEN 'EXISTE'
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

-- Teste 2: Verificar tabelas utilizadas (que serão mantidas)
SELECT 
    'TABELAS UTILIZADAS' as categoria,
    t.table_name,
    CASE 
        WHEN it.table_name IS NOT NULL THEN 'EXISTE'
        ELSE 'NÃO EXISTE'
    END as status
FROM (
    SELECT unnest(ARRAY[
        'games',
        'players',
        'users',
        'game_players',
        'game_sessions',
        'participation_requests',
        'notification_configs',
        'notifications'
    ]) as table_name
) t
LEFT JOIN information_schema.tables it 
    ON it.table_name = t.table_name 
    AND it.table_schema = 'public'
ORDER BY t.table_name;

-- Teste 3: Contar total de tabelas
SELECT 
    'RESUMO' as categoria,
    COUNT(*) as total_tabelas
FROM information_schema.tables 
WHERE table_schema = 'public';

