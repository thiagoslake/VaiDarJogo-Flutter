-- =====================================================
-- 🔍 Verificar Constraint games_status_check
-- =====================================================
-- Script para verificar a definição atual da constraint games_status_check
-- =====================================================

-- 1. Verificar se a constraint existe
SELECT 
    '📋 Verificação da constraint games_status_check' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
  AND table_name = 'games'
  AND constraint_name = 'games_status_check';

-- 2. Verificar a definição da constraint
SELECT 
    '🔍 Definição da constraint' as info,
    constraint_name,
    check_clause
FROM information_schema.check_constraints 
WHERE constraint_schema = 'public' 
  AND constraint_name = 'games_status_check';

-- 3. Verificar estrutura da coluna status
SELECT 
    '🏗️ Estrutura da coluna status' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
  AND column_name = 'status';

-- 4. Verificar dados atuais na tabela
SELECT 
    '📊 Dados atuais na tabela games' as info,
    id,
    organization_name,
    status,
    created_at
FROM public.games
ORDER BY created_at DESC
LIMIT 5;

-- 5. Verificar valores únicos de status
SELECT 
    '📈 Valores únicos de status' as info,
    status,
    COUNT(*) as count
FROM public.games
GROUP BY status
ORDER BY status;

-- =====================================================
-- 🎯 VALORES ESPERADOS
-- =====================================================

-- A constraint deve permitir:
-- 'active'   - Jogo ativo e disponível
-- 'paused'   - Jogo pausado temporariamente
-- 'deleted'  - Jogo deletado (soft delete)

-- =====================================================




