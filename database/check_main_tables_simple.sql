-- =====================================================
-- VERIFICAÇÃO SIMPLES DAS TABELAS PRINCIPAIS
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
-- 6. VERIFICAR RLS (ROW LEVEL SECURITY) - VERSÃO SIMPLES
-- =====================================================

SELECT 
    'RLS STATUS' as categoria,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY tablename;

-- =====================================================
-- 7. VERIFICAR POLÍTICAS RLS
-- =====================================================

SELECT 
    'RLS POLICIES' as categoria,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests')
ORDER BY tablename, policyname;

-- =====================================================
-- 8. CONTAGEM DE REGISTROS (DEVE SER 0 APÓS RESET)
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




