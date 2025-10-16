-- =====================================================
-- VERIFICAR CÁLCULO DO CONTADOR DE JOGADORES
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se o cálculo do contador de jogadores está correto
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para verificar dados dos jogos
-- 2. Confirma cálculo de jogadores atuais vs máximo
-- 3. Verifica configurações dos jogos
-- =====================================================

-- =====================================================
-- 1. VERIFICAR JOGOS E SUAS CONFIGURAÇÕES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    g.players_per_team,
    g.substitutes_per_team,
    g.number_of_teams,
    (g.players_per_team + g.substitutes_per_team) * g.number_of_teams as max_players_calculated
FROM public.games g
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 2. VERIFICAR JOGADORES ATUAIS POR JOGO
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    COUNT(gp.id) as current_players,
    (g.players_per_team + g.substitutes_per_team) * g.number_of_teams as max_players,
    ROUND(
        (COUNT(gp.id)::decimal / ((g.players_per_team + g.substitutes_per_team) * g.number_of_teams)) * 100, 
        2
    ) as percentage_filled
FROM public.games g
LEFT JOIN public.game_players gp ON g.id = gp.game_id 
    AND gp.status IN ('active', 'confirmed')
GROUP BY g.id, g.organization_name, g.location, g.players_per_team, g.substitutes_per_team, g.number_of_teams
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 3. VERIFICAR DISTRIBUIÇÃO DE STATUS DOS JOGADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    COUNT(CASE WHEN gp.status = 'active' THEN 1 END) as jogadores_ativos,
    COUNT(CASE WHEN gp.status = 'confirmed' THEN 1 END) as jogadores_confirmados,
    COUNT(CASE WHEN gp.status = 'pending' THEN 1 END) as jogadores_pendentes,
    COUNT(CASE WHEN gp.status = 'inactive' THEN 1 END) as jogadores_inativos,
    COUNT(gp.id) as total_jogadores
FROM public.games g
LEFT JOIN public.game_players gp ON g.id = gp.game_id
GROUP BY g.id, g.organization_name
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 4. VERIFICAR JOGO MAIS RECENTE E SEUS JOGADORES
-- =====================================================

WITH latest_game AS (
    SELECT 
        id, 
        organization_name, 
        location,
        players_per_team,
        substitutes_per_team,
        number_of_teams,
        (players_per_team + substitutes_per_team) * number_of_teams as max_players
    FROM public.games
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    'JOGO MAIS RECENTE' as tipo,
    lg.organization_name,
    lg.location,
    lg.players_per_team,
    lg.substitutes_per_team,
    lg.number_of_teams,
    lg.max_players,
    COUNT(gp.id) as current_players,
    CASE 
        WHEN COUNT(gp.id) = 0 THEN '❌ Nenhum jogador'
        WHEN COUNT(gp.id) < lg.max_players * 0.5 THEN '⚠️ Poucos jogadores'
        WHEN COUNT(gp.id) < lg.max_players * 0.8 THEN '✅ Bom número de jogadores'
        WHEN COUNT(gp.id) >= lg.max_players THEN '🔥 Jogo lotado'
        ELSE '✅ Jogo bem preenchido'
    END as status_jogo
FROM latest_game lg
LEFT JOIN public.game_players gp ON lg.id = gp.game_id 
    AND gp.status IN ('active', 'confirmed')
GROUP BY lg.id, lg.organization_name, lg.location, lg.players_per_team, lg.substitutes_per_team, lg.number_of_teams, lg.max_players;

-- =====================================================
-- 5. VERIFICAR JOGADORES DO JOGO MAIS RECENTE
-- =====================================================

WITH latest_game AS (
    SELECT id, organization_name
    FROM public.games
    ORDER BY created_at DESC
    LIMIT 1
)
SELECT 
    'JOGADORES DO JOGO MAIS RECENTE' as tipo,
    p.name as player_name,
    p.phone_number,
    gp.player_type,
    gp.status,
    gp.is_admin,
    gp.joined_at
FROM latest_game lg
JOIN public.game_players gp ON lg.id = gp.game_id
JOIN public.players p ON gp.player_id = p.id
ORDER BY gp.joined_at DESC;

-- =====================================================
-- 6. ESTATÍSTICAS GERAIS
-- =====================================================

SELECT 
    'Total de jogos' as categoria,
    COUNT(*) as quantidade
FROM public.games
UNION ALL
SELECT 
    'Jogos com jogadores' as categoria,
    COUNT(DISTINCT gp.game_id) as quantidade
FROM public.game_players gp
WHERE gp.status IN ('active', 'confirmed')
UNION ALL
SELECT 
    'Total de jogadores ativos' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status IN ('active', 'confirmed')
UNION ALL
SELECT 
    'Jogos lotados (100% preenchidos)' as categoria,
    COUNT(*) as quantidade
FROM (
    SELECT 
        g.id,
        COUNT(gp.id) as current_players,
        (g.players_per_team + g.substitutes_per_team) * g.number_of_teams as max_players
    FROM public.games g
    LEFT JOIN public.game_players gp ON g.id = gp.game_id 
        AND gp.status IN ('active', 'confirmed')
    GROUP BY g.id, g.players_per_team, g.substitutes_per_team, g.number_of_teams
    HAVING COUNT(gp.id) >= (g.players_per_team + g.substitutes_per_team) * g.number_of_teams
) as full_games;




