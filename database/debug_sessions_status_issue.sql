-- =====================================================
-- 🔍 Debug: Verificar Problema com Status das Sessões
-- =====================================================
-- Script para diagnosticar por que as sessões não estão sendo pausadas
-- =====================================================

-- 1. Verificar se a coluna 'status' existe na tabela 'game_sessions'
SELECT 
    '📋 Verificação da coluna status' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions'
  AND column_name = 'status';

-- 2. Verificar estrutura completa da tabela 'game_sessions'
SELECT 
    '🏗️ Estrutura completa da tabela game_sessions' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions'
ORDER BY ordinal_position;

-- 3. Verificar constraints da tabela 'game_sessions'
SELECT 
    '🔒 Constraints da tabela game_sessions' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_sessions';

-- 4. Verificar dados atuais na tabela 'game_sessions'
SELECT 
    '📊 Dados atuais na tabela game_sessions' as info,
    id,
    game_id,
    session_date,
    start_time,
    end_time,
    status,
    created_at
FROM public.game_sessions
ORDER BY created_at DESC
LIMIT 10;

-- 5. Verificar valores únicos de status (se a coluna existir)
SELECT 
    '📈 Valores únicos de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
WHERE status IS NOT NULL
GROUP BY status
ORDER BY status;

-- 6. Verificar sessões por jogo específico (usar um jogo real se existir)
SELECT 
    '🎮 Sessões de um jogo específico' as info,
    id,
    game_id,
    session_date,
    start_time,
    status,
    created_at
FROM public.game_sessions
WHERE game_id IN (
    SELECT id FROM public.games LIMIT 1
)  -- Usa o primeiro jogo disponível
ORDER BY session_date;

-- 7. Verificar se há sessões ativas que deveriam ser pausadas
SELECT 
    '⏸️ Sessões ativas que deveriam ser pausadas' as info,
    gs.id,
    gs.game_id,
    gs.session_date,
    gs.start_time,
    gs.status as session_status,
    g.status as game_status
FROM public.game_sessions gs
JOIN public.games g ON gs.game_id = g.id
WHERE g.status = 'paused' 
  AND gs.status = 'active'
ORDER BY gs.session_date;

-- =====================================================
-- 🎯 DIAGNÓSTICO ESPERADO
-- =====================================================

-- Se a coluna 'status' não existir:
-- - Resultado da query 1 será vazio
-- - Resultado da query 2 não mostrará a coluna 'status'
-- - Resultado da query 3 não mostrará constraint de status

-- Se a coluna 'status' existir mas não estiver sendo atualizada:
-- - Resultado da query 4 mostrará status NULL ou 'active'
-- - Resultado da query 7 mostrará sessões ativas em jogos pausados

-- =====================================================
