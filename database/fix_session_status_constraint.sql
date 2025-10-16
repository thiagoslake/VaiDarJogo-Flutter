-- =====================================================
-- 🔧 Correção: Constraint de Status das Sessões
-- =====================================================
-- Script para corrigir a constraint game_sessions_status_check
-- e garantir que apenas valores válidos sejam aceitos
-- =====================================================

-- 1. Verificar valores atuais de status na tabela game_sessions
SELECT 
    '📊 Valores atuais de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
GROUP BY status
ORDER BY status;

-- 2. Verificar se há valores inválidos
SELECT 
    '❌ Valores inválidos de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
WHERE status NOT IN ('active', 'paused', 'cancelled', 'completed')
   OR status IS NULL
GROUP BY status
ORDER BY status;

-- 3. Verificar a constraint atual
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

-- 4. Remover a constraint existente (se existir)
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 5. Atualizar valores inválidos para 'active'
UPDATE public.game_sessions 
SET status = 'active'
WHERE status NOT IN ('active', 'paused', 'cancelled', 'completed')
   OR status IS NULL;

-- 6. Adicionar coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 7. Criar a constraint com valores corretos
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 8. Verificar se a constraint foi criada com sucesso
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

-- 9. Verificação final dos dados
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
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Confirme que a constraint foi criada corretamente
-- 4. Teste a criação de sessões no app

-- =====================================================


