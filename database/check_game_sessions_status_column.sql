-- =====================================================
-- 🔍 Verificar Coluna Status na Tabela game_sessions
-- =====================================================
-- Script para verificar se a coluna 'status' existe na tabela 'game_sessions'
-- e criar se necessário para suportar pausar/reativar sessões
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

-- =====================================================
-- 🎯 VALORES ESPERADOS
-- =====================================================

-- A constraint deve permitir:
-- 'active'   - Sessão ativa e disponível
-- 'paused'   - Sessão pausada temporariamente
-- 'cancelled' - Sessão cancelada
-- 'completed' - Sessão concluída

-- =====================================================

