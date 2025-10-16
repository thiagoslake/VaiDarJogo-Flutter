-- =====================================================
-- 🛠️ Adicionar Coluna Status na Tabela game_sessions
-- =====================================================
-- Script para adicionar a coluna 'status' na tabela 'game_sessions'
-- para suportar funcionalidades de pausar/reativar/cancelar sessões
-- =====================================================

-- 1. Adicionar coluna 'status' se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 2. Adicionar constraint para valores válidos
DO $$ 
BEGIN
    -- Verificar se a constraint já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'game_sessions_status_check' 
        AND table_name = 'game_sessions'
    ) THEN
        ALTER TABLE public.game_sessions 
        ADD CONSTRAINT game_sessions_status_check 
        CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));
        
        RAISE NOTICE '✅ Constraint game_sessions_status_check adicionada com sucesso';
    ELSE
        RAISE NOTICE 'ℹ️ Constraint game_sessions_status_check já existe';
    END IF;
END $$;

-- 3. Atualizar sessões existentes para 'active' se status for NULL
UPDATE public.game_sessions 
SET status = 'active' 
WHERE status IS NULL;

-- 4. Verificar se a coluna foi adicionada corretamente
SELECT 
    '✅ Verificação final' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions'
  AND column_name = 'status';

-- 5. Verificar constraint
SELECT 
    '✅ Verificação da constraint' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_sessions'
  AND tc.constraint_name = 'game_sessions_status_check';

-- 6. Verificar dados atualizados
SELECT 
    '✅ Verificação dos dados' as info,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_sessions,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as paused_sessions,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled_sessions,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_sessions,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status_sessions
FROM public.game_sessions;

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Confirme que a coluna 'status' foi adicionada
-- 4. Teste as funcionalidades de pausar/reativar sessões

-- =====================================================
-- 🎯 VALORES DE STATUS SUPORTADOS
-- =====================================================

-- 'active'     - Sessão ativa e disponível (padrão)
-- 'paused'     - Sessão pausada temporariamente
-- 'cancelled'  - Sessão cancelada
-- 'completed'  - Sessão concluída

-- =====================================================
-- 🔍 FUNCIONALIDADES IMPLEMENTADAS
-- =====================================================

-- ✅ Pausar jogo: pausa todas as sessões ativas
-- ✅ Reativar jogo: reativa todas as sessões pausadas
-- ✅ Cancelar sessão: marca sessão como cancelada
-- ✅ Completar sessão: marca sessão como concluída
-- ✅ Verificar permissões de administrador

-- =====================================================
