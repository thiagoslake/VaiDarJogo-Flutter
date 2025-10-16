-- =====================================================
-- 🔧 Correção: Violação da Constraint de Status das Sessões
-- =====================================================
-- Script para corrigir violações da constraint game_sessions_status_check
-- =====================================================

-- 1. Verificar valores atuais de status na tabela game_sessions
SELECT 
    '📊 Valores atuais de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
GROUP BY status
ORDER BY status;

-- 2. Verificar se há valores NULL
SELECT 
    '🔍 Verificação de valores NULL' as info,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as registros_null,
    COUNT(CASE WHEN status IS NOT NULL THEN 1 END) as registros_com_status
FROM public.game_sessions;

-- 3. Verificar valores inválidos (que não estão na constraint)
SELECT 
    '❌ Valores inválidos de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
WHERE status NOT IN ('active', 'paused', 'cancelled', 'completed')
   OR status IS NULL
GROUP BY status
ORDER BY status;

-- 4. Verificar a constraint atual
SELECT 
    '🔒 Constraint atual' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_sessions'
  AND tc.constraint_name = 'game_sessions_status_check';

-- 5. Remover a constraint existente
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 6. Atualizar valores inválidos para 'active'
UPDATE public.game_sessions 
SET status = 'active'
WHERE status NOT IN ('active', 'paused', 'cancelled', 'completed')
   OR status IS NULL;

-- 7. Verificar se ainda há valores inválidos
SELECT 
    '✅ Verificação após correção' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
GROUP BY status
ORDER BY status;

-- 8. Adicionar a coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 9. Criar a constraint novamente
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 10. Verificar se a constraint foi criada com sucesso
SELECT 
    '✅ Constraint criada com sucesso' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_sessions'
  AND tc.constraint_name = 'game_sessions_status_check';

-- 11. Verificação final dos dados
SELECT 
    '🎯 Verificação final' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as sessoes_ativas,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as sessoes_pausadas,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as sessoes_canceladas,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as sessoes_concluidas,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as sessoes_sem_status
FROM public.game_sessions;

-- =====================================================
-- 🎯 VALORES PERMITIDOS PELA CONSTRAINT
-- =====================================================

-- 'active'     - Sessão ativa e disponível (padrão)
-- 'paused'     - Sessão pausada temporariamente
-- 'cancelled'  - Sessão cancelada
-- 'completed'  - Sessão concluída

-- =====================================================




