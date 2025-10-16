-- =====================================================
-- 🔧 Correção Simples: Constraint de Sessões
-- =====================================================
-- Script simples para corrigir a constraint game_sessions_status_check
-- =====================================================

-- 1. Remover constraint existente
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 2. Atualizar todos os valores inválidos para 'active'
UPDATE public.game_sessions 
SET status = 'active'
WHERE status IS NULL 
   OR status NOT IN ('active', 'paused', 'cancelled', 'completed');

-- 3. Adicionar coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 4. Criar constraint com valores corretos
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 5. Verificar se funcionou
SELECT 
    '✅ Correção concluída' as resultado,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as sessoes_ativas
FROM public.game_sessions;


