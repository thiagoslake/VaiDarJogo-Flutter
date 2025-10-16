-- =====================================================
-- VERIFICAR ESTRUTURA DAS TABELAS APÓS RESET
-- Sistema: VaiDarJogo Flutter
-- =====================================================

-- =====================================================
-- 1. VERIFICAR EXISTÊNCIA DAS TABELAS PRINCIPAIS
-- =====================================================

SELECT 
    'TABELAS PRINCIPAIS' as categoria,
    table_name,
    CASE 
        WHEN table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests') 
        THEN '✅ OBRIGATÓRIA'
        ELSE 'ℹ️ OPCIONAL'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'users', 'players', 'games', 'game_players', 'game_sessions', 
    'participation_requests', 'notifications', 'notification_configs', 
    'notification_templates', 'notification_logs', 'player_fcm_tokens'
)
ORDER BY 
    CASE 
        WHEN table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests') 
        THEN 1 
        ELSE 2 
    END,
    table_name;

-- =====================================================
-- 2. VERIFICAR ESTRUTURA DA TABELA USERS
-- =====================================================

SELECT 
    'ESTRUTURA USERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- =====================================================
-- 3. VERIFICAR ESTRUTURA DA TABELA PLAYERS
-- =====================================================

SELECT 
    'ESTRUTURA PLAYERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'players'
ORDER BY ordinal_position;

-- =====================================================
-- 4. VERIFICAR ESTRUTURA DA TABELA GAMES
-- =====================================================

SELECT 
    'ESTRUTURA GAMES' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'games'
ORDER BY ordinal_position;

-- =====================================================
-- 5. VERIFICAR ESTRUTURA DA TABELA GAME_PLAYERS
-- =====================================================

SELECT 
    'ESTRUTURA GAME_PLAYERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'game_players'
ORDER BY ordinal_position;

-- =====================================================
-- 6. VERIFICAR CONSTRAINTS E CHAVES ESTRANGEIRAS
-- =====================================================

SELECT 
    'CONSTRAINTS' as categoria,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY tc.table_name, tc.constraint_type;

-- =====================================================
-- 7. VERIFICAR SEQUÊNCIAS
-- =====================================================

SELECT 
    'SEQUÊNCIAS' as categoria,
    schemaname,
    sequencename,
    last_value,
    start_value,
    increment_by
FROM pg_sequences 
WHERE schemaname = 'public'
ORDER BY sequencename;

-- =====================================================
-- 8. VERIFICAR RLS (ROW LEVEL SECURITY)
-- =====================================================

SELECT 
    'RLS STATUS' as categoria,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    hasrules as has_rules
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY tablename;

-- =====================================================
-- 9. VERIFICAR POLÍTICAS RLS
-- =====================================================

SELECT 
    'RLS POLICIES' as categoria,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY tablename, policyname;

-- =====================================================
-- 10. VERIFICAR TRIGGERS
-- =====================================================

SELECT 
    'TRIGGERS' as categoria,
    trigger_schema,
    trigger_name,
    event_manipulation,
    event_object_table,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY event_object_table, trigger_name;

-- =====================================================
-- 11. VERIFICAR FUNÇÕES
-- =====================================================

SELECT 
    'FUNÇÕES' as categoria,
    routine_schema,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%user%' OR routine_name LIKE '%player%' OR routine_name LIKE '%game%'
ORDER BY routine_name;

-- =====================================================
-- 12. CONTAGEM DE REGISTROS (DEVE SER 0 APÓS RESET)
-- =====================================================

SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'users' as tabela,
    COUNT(*) as total_registros
FROM users
UNION ALL
SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'players' as tabela,
    COUNT(*) as total_registros
FROM players
UNION ALL
SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'games' as tabela,
    COUNT(*) as total_registros
FROM games
UNION ALL
SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'game_players' as tabela,
    COUNT(*) as total_registros
FROM game_players
UNION ALL
SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'game_sessions' as tabela,
    COUNT(*) as total_registros
FROM game_sessions
UNION ALL
SELECT 
    'CONTAGEM REGISTROS' as categoria,
    'participation_requests' as tabela,
    COUNT(*) as total_registros
FROM participation_requests
ORDER BY tabela;
