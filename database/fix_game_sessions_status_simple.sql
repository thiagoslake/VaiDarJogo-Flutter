-- =====================================================
-- 🔧 Correção Simples: Status das Sessões
-- =====================================================
-- Script simplificado para corrigir o problema de status das sessões
-- =====================================================

-- 1. Verificar valores atuais de status
SELECT 
    '📊 Valores atuais de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
GROUP BY status
ORDER BY status;

-- 2. Remover a constraint existente
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 3. Atualizar todos os valores inválidos para 'active'
UPDATE public.game_sessions 
SET status = 'active'
WHERE status IS NULL 
   OR status NOT IN ('active', 'paused', 'cancelled', 'completed');

-- 4. Adicionar a coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 5. Criar a constraint novamente
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 6. Verificação final
SELECT 
    '✅ Correção concluída' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as sessoes_ativas,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as sessoes_pausadas,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as sessoes_canceladas,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as sessoes_concluidas
FROM public.game_sessions;

-- =====================================================




