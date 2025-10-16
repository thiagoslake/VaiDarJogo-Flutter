-- =====================================================
-- DEBUG DADOS DA TABELA GAME_PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar dados na tabela game_players para debug
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para verificar dados existentes
-- 2. Identifica problemas de dados
-- 3. Verifica status dos jogadores
-- =====================================================

-- =====================================================
-- 1. VERIFICAR TOTAL DE REGISTROS
-- =====================================================

SELECT 
    'Total de registros' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
UNION ALL
SELECT 
    'Registros com status active' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status = 'active'
UNION ALL
SELECT 
    'Registros com status confirmed' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status = 'confirmed'
UNION ALL
SELECT 
    'Registros com status pending' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status = 'pending'
UNION ALL
SELECT 
    'Registros com status inactive' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status = 'inactive';

-- =====================================================
-- 2. VERIFICAR JOGOS E SEUS JOGADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    COUNT(gp.id) as total_jogadores,
    COUNT(CASE WHEN gp.status = 'active' THEN 1 END) as jogadores_ativos,
    COUNT(CASE WHEN gp.status = 'confirmed' THEN 1 END) as jogadores_confirmados,
    COUNT(CASE WHEN gp.is_admin = true THEN 1 END) as administradores
FROM public.games g
LEFT JOIN public.game_players gp ON g.id = gp.game_id
GROUP BY g.id, g.organization_name, g.location
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 3. VERIFICAR JOGADORES RECENTES
-- =====================================================

SELECT 
    gp.id as game_player_id,
    gp.game_id,
    gp.player_id,
    gp.player_type,
    gp.status,
    gp.is_admin,
    gp.joined_at,
    p.name as player_name,
    g.organization_name as game_name
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
JOIN public.games g ON gp.game_id = g.id
ORDER BY gp.joined_at DESC
LIMIT 10;

-- =====================================================
-- 4. VERIFICAR JOGO MAIS RECENTE E SEUS JOGADORES
-- =====================================================

SELECT 
    'JOGO MAIS RECENTE' as tipo,
    g.id as game_id,
    g.organization_name,
    g.location,
    g.created_at as game_created_at
FROM public.games g
ORDER BY g.created_at DESC
LIMIT 1;

-- =====================================================
-- 5. VERIFICAR JOGADORES DO JOGO MAIS RECENTE
-- =====================================================

WITH latest_game AS (
    SELECT id, organization_name, location
    FROM public.games
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    'JOGADORES DO JOGO MAIS RECENTE' as tipo,
    gp.id as game_player_id,
    gp.player_id,
    gp.player_type,
    gp.status,
    gp.is_admin,
    gp.joined_at,
    p.name as player_name,
    p.phone_number,
    u.email as user_email
FROM latest_game lg
JOIN public.game_players gp ON lg.id = gp.game_id
JOIN public.players p ON gp.player_id = p.id
JOIN public.users u ON p.user_id = u.id
ORDER BY gp.joined_at DESC;

-- =====================================================
-- 6. VERIFICAR PROBLEMAS DE DADOS
-- =====================================================

SELECT 
    'Jogadores sem nome' as problema,
    COUNT(*) as quantidade
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
WHERE p.name IS NULL OR p.name = ''
UNION ALL
SELECT 
    'Jogadores sem telefone' as problema,
    COUNT(*) as quantidade
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
WHERE p.phone_number IS NULL OR p.phone_number = ''
UNION ALL
SELECT 
    'Jogadores com status inválido' as problema,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status NOT IN ('active', 'inactive', 'pending', 'confirmed', 'rejected', 'suspended')
UNION ALL
SELECT 
    'Jogadores sem tipo' as problema,
    COUNT(*) as quantidade
FROM public.game_players
WHERE player_type IS NULL OR player_type NOT IN ('monthly', 'casual');

-- =====================================================
-- 7. VERIFICAR RELACIONAMENTOS
-- =====================================================

SELECT 
    'Jogadores órfãos (sem player)' as problema,
    COUNT(*) as quantidade
FROM public.game_players gp
LEFT JOIN public.players p ON gp.player_id = p.id
WHERE p.id IS NULL
UNION ALL
SELECT 
    'Jogadores órfãos (sem jogo)' as problema,
    COUNT(*) as quantidade
FROM public.game_players gp
LEFT JOIN public.games g ON gp.game_id = g.id
WHERE g.id IS NULL
UNION ALL
SELECT 
    'Players órfãos (sem user)' as problema,
    COUNT(*) as quantidade
FROM public.players p
LEFT JOIN public.users u ON p.user_id = u.id
WHERE u.id IS NULL;




