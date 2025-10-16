-- =====================================================
-- SCRIPT DE VERIFICAÇÃO ANTES DE DELETAR TABELAS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- Este script verifica quais tabelas existem antes de deletar
-- Execute este script ANTES de executar o delete_unused_tables.sql
-- =====================================================

-- Verificar tabelas não utilizadas (que serão deletadas)
SELECT 
    'TABELAS NÃO UTILIZADAS (SERÃO DELETADAS)' as categoria,
    t.table_name,
    CASE 
        WHEN it.table_name IS NOT NULL THEN 'EXISTE - será deletada'
        ELSE 'NÃO EXISTE - já foi deletada ou nunca existiu'
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

-- Verificar tabelas utilizadas (que serão mantidas)
SELECT 
    'TABELAS UTILIZADAS (SERÃO MANTIDAS)' as categoria,
    t.table_name,
    CASE 
        WHEN it.table_name IS NOT NULL THEN 'EXISTE - será mantida'
        ELSE 'NÃO EXISTE - ERRO! Sistema pode não funcionar'
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

-- Contar total de tabelas
SELECT 
    'RESUMO' as categoria,
    'Total de tabelas no banco' as descricao,
    COUNT(*) as quantidade
FROM information_schema.tables 
WHERE table_schema = 'public';

-- Verificar políticas RLS das tabelas que serão deletadas
SELECT 
    'POLÍTICAS RLS' as categoria,
    tablename as tabela,
    policyname as politica,
    'Será deletada' as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN (
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
)
ORDER BY tablename, policyname;

-- Verificar índices das tabelas que serão deletadas
SELECT 
    'ÍNDICES' as categoria,
    tablename as tabela,
    indexname as indice,
    'Será deletado' as status
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN (
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
)
ORDER BY tablename, indexname;
