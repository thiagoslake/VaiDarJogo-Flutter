-- =====================================================
-- VERIFICAR CRIADOR DO JOGO COMO ADMINISTRADOR
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se o criador do jogo foi inserido como mensalista e administrador
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute após criar um novo jogo
-- 2. Verifica se criador está na tabela game_players
-- 3. Confirma se é mensalista e administrador
-- =====================================================

-- =====================================================
-- 1. VERIFICAR JOGOS RECENTES E SEUS CRIADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    g.user_id as creator_user_id,
    u.email as creator_email,
    u.name as creator_name,
    g.created_at as game_created_at
FROM public.games g
JOIN public.users u ON g.user_id = u.id
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 2. VERIFICAR SE CRIADORES ESTÃO COMO JOGADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    u.name as creator_name,
    p.id as player_id,
    p.name as player_name,
    gp.player_type,
    gp.status,
    gp.is_admin,
    gp.joined_at,
    CASE 
        WHEN gp.is_admin = true THEN '✅ ADMINISTRADOR'
        WHEN gp.is_admin = false THEN '❌ NÃO ADMINISTRADOR'
        WHEN gp.is_admin IS NULL THEN '❓ INDEFINIDO'
    END as admin_status,
    CASE 
        WHEN gp.player_type = 'monthly' THEN '✅ MENSALISTA'
        WHEN gp.player_type = 'casual' THEN '❌ AVULSO'
        ELSE '❓ INDEFINIDO'
    END as player_type_status
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
LEFT JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
ORDER BY g.created_at DESC
LIMIT 10;

-- =====================================================
-- 3. VERIFICAR JOGOS SEM CRIADOR COMO JOGADOR
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    u.name as creator_name,
    '❌ CRIADOR NÃO ENCONTRADO COMO JOGADOR' as status
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
LEFT JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
WHERE gp.id IS NULL
ORDER BY g.created_at DESC;

-- =====================================================
-- 4. VERIFICAR CRIADORES QUE NÃO SÃO ADMINISTRADORES
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    u.name as creator_name,
    gp.player_type,
    gp.is_admin,
    '⚠️ CRIADOR NÃO É ADMINISTRADOR' as status
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
WHERE gp.is_admin != true
ORDER BY g.created_at DESC;

-- =====================================================
-- 5. VERIFICAR CRIADORES QUE NÃO SÃO MENSALISTAS
-- =====================================================

SELECT 
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    u.name as creator_name,
    gp.player_type,
    gp.is_admin,
    '⚠️ CRIADOR NÃO É MENSALISTA' as status
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
WHERE gp.player_type != 'monthly'
ORDER BY g.created_at DESC;

-- =====================================================
-- 6. ESTATÍSTICAS GERAIS
-- =====================================================

SELECT 
    'Total de jogos' as categoria,
    COUNT(*) as quantidade
FROM public.games
UNION ALL
SELECT 
    'Jogos com criador como jogador' as categoria,
    COUNT(*) as quantidade
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
UNION ALL
SELECT 
    'Criadores como administradores' as categoria,
    COUNT(*) as quantidade
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
WHERE gp.is_admin = true
UNION ALL
SELECT 
    'Criadores como mensalistas' as categoria,
    COUNT(*) as quantidade
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
WHERE gp.player_type = 'monthly';

-- =====================================================
-- 7. VERIFICAR JOGO MAIS RECENTE (PARA TESTE)
-- =====================================================

SELECT 
    'JOGO MAIS RECENTE' as tipo,
    g.id as game_id,
    g.organization_name,
    g.location,
    u.email as creator_email,
    u.name as creator_name,
    p.id as player_id,
    p.name as player_name,
    gp.player_type,
    gp.status,
    gp.is_admin,
    gp.joined_at,
    CASE 
        WHEN gp.is_admin = true AND gp.player_type = 'monthly' THEN '✅ PERFEITO'
        WHEN gp.is_admin = true AND gp.player_type != 'monthly' THEN '⚠️ ADMIN MAS NÃO MENSALISTA'
        WHEN gp.is_admin != true AND gp.player_type = 'monthly' THEN '⚠️ MENSALISTA MAS NÃO ADMIN'
        WHEN gp.id IS NULL THEN '❌ NÃO ENCONTRADO COMO JOGADOR'
        ELSE '❌ PROBLEMA'
    END as status_final
FROM public.games g
JOIN public.users u ON g.user_id = u.id
JOIN public.players p ON u.id = p.user_id
LEFT JOIN public.game_players gp ON g.id = gp.game_id AND p.id = gp.player_id
ORDER BY g.created_at DESC
LIMIT 1;




