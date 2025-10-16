-- =====================================================
-- 🔍 DEBUG: Remoção de Administrador
-- =====================================================
-- Script para debugar o problema de remoção de administrador
-- =====================================================

-- 1. Verificar todos os administradores de um jogo específico
-- Substitua 'GAME_ID_AQUI' pelo ID do jogo que está apresentando problema
SELECT 
    '📋 Todos os administradores do jogo' as info,
    gp.id as game_player_id,
    gp.player_id,
    gp.game_id,
    gp.is_admin,
    gp.status,
    gp.joined_at,
    p.name as player_name
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
WHERE gp.game_id = 'GAME_ID_AQUI'  -- ← Substitua pelo ID do jogo
  AND gp.is_admin = true
ORDER BY gp.joined_at;

-- 2. Verificar administradores ativos/confirmados
SELECT 
    '✅ Administradores ativos/confirmados' as info,
    gp.id as game_player_id,
    gp.player_id,
    gp.is_admin,
    gp.status,
    p.name as player_name
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
WHERE gp.game_id = 'GAME_ID_AQUI'  -- ← Substitua pelo ID do jogo
  AND gp.is_admin = true
  AND gp.status IN ('active', 'confirmed')
ORDER BY gp.joined_at;

-- 3. Simular a query que está sendo executada no código
-- Substitua 'PLAYER_ID_AQUI' pelo ID do jogador que está sendo removido
SELECT 
    '🔍 Query do código (excluindo jogador específico)' as info,
    gp.id as game_player_id,
    gp.player_id,
    gp.is_admin,
    gp.status,
    p.name as player_name
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
WHERE gp.game_id = 'GAME_ID_AQUI'  -- ← Substitua pelo ID do jogo
  AND gp.is_admin = true
  AND gp.status IN ('active', 'confirmed')
  AND gp.player_id != 'PLAYER_ID_AQUI'  -- ← Substitua pelo ID do jogador
ORDER BY gp.joined_at;

-- 4. Contar administradores (simulação da lógica)
SELECT 
    '📊 Contagem de administradores' as info,
    COUNT(*) as total_admins,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_admins,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed_admins,
    COUNT(CASE WHEN status IN ('active', 'confirmed') THEN 1 END) as active_or_confirmed_admins
FROM public.game_players gp
WHERE gp.game_id = 'GAME_ID_AQUI'  -- ← Substitua pelo ID do jogo
  AND gp.is_admin = true;

-- 5. Contar outros administradores (excluindo um específico)
SELECT 
    '📊 Contagem de outros administradores' as info,
    COUNT(*) as other_admins_count
FROM public.game_players gp
WHERE gp.game_id = 'GAME_ID_AQUI'  -- ← Substitua pelo ID do jogo
  AND gp.is_admin = true
  AND gp.status IN ('active', 'confirmed')
  AND gp.player_id != 'PLAYER_ID_AQUI';  -- ← Substitua pelo ID do jogador

-- 6. Verificar estrutura da tabela game_players
SELECT 
    '🏗️ Estrutura da tabela game_players' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_players'
ORDER BY ordinal_position;

-- 7. Verificar constraints da tabela
SELECT 
    '🔒 Constraints da tabela game_players' as info,
    constraint_name,
    constraint_type,
    check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_players';

-- 8. Verificar índices da tabela
SELECT 
    '📇 Índices da tabela game_players' as info,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND tablename = 'game_players';

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Substitua 'GAME_ID_AQUI' pelo ID do jogo que está apresentando problema
-- 2. Substitua 'PLAYER_ID_AQUI' pelo ID do jogador que está sendo removido
-- 3. Execute as queries para verificar os dados
-- 4. Compare os resultados com os logs de debug do Flutter

-- =====================================================
-- 🔍 POSSÍVEIS PROBLEMAS
-- =====================================================

-- PROBLEMA 1: Status incorreto
-- SOLUÇÃO: Verificar se os administradores têm status 'active' ou 'confirmed'

-- PROBLEMA 2: is_admin não está sendo definido corretamente
-- SOLUÇÃO: Verificar se a coluna is_admin está sendo atualizada

-- PROBLEMA 3: player_id não está sendo passado corretamente
-- SOLUÇÃO: Verificar se o player_id está correto nos logs

-- PROBLEMA 4: game_id não está sendo passado corretamente
-- SOLUÇÃO: Verificar se o game_id está correto nos logs

-- =====================================================




