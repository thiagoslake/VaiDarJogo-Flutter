-- =====================================================
-- VERIFICAR ESTRUTURA DA TABELA GAME_PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se a tabela game_players tem a coluna is_admin
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para verificar estrutura da tabela
-- 2. Confirma se coluna is_admin existe
-- 3. Verifica tipos de dados e constraints
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA GAME_PLAYERS
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_players'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VERIFICAR SE COLUNA IS_ADMIN EXISTE
-- =====================================================

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = 'game_players' 
              AND column_name = 'is_admin'
        ) THEN '✅ Coluna is_admin EXISTE'
        ELSE '❌ Coluna is_admin NÃO EXISTE'
    END as status_coluna_is_admin;

-- =====================================================
-- 3. VERIFICAR CONSTRAINTS E ÍNDICES
-- =====================================================

SELECT 
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
WHERE tc.table_name = 'game_players'
  AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, tc.constraint_name;

-- =====================================================
-- 4. VERIFICAR DADOS ATUAIS NA TABELA
-- =====================================================

SELECT 
    COUNT(*) as total_registros,
    COUNT(CASE WHEN is_admin = true THEN 1 END) as administradores,
    COUNT(CASE WHEN is_admin = false THEN 1 END) as nao_administradores,
    COUNT(CASE WHEN is_admin IS NULL THEN 1 END) as indefinidos
FROM public.game_players;

-- =====================================================
-- 5. MOSTRAR REGISTROS RECENTES
-- =====================================================

SELECT 
    id,
    game_id,
    player_id,
    player_type,
    status,
    is_admin,
    joined_at,
    created_at
FROM public.game_players
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 6. VERIFICAR JOGOS E SEUS ADMINISTRADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    p.name as player_name,
    gp.player_type,
    gp.is_admin,
    gp.joined_at
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
LEFT JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
ORDER BY g.created_at DESC
LIMIT 10;




