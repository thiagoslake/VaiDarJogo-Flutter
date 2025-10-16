-- =====================================================
-- 🛠️ Adicionar Coluna Status na Tabela game_sessions (Versão Simples)
-- =====================================================
-- Script simplificado para adicionar a coluna 'status' na tabela 'game_sessions'
-- =====================================================

-- 1. Remover constraint existente (se existir)
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 2. Adicionar coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 3. Criar nova constraint com valores corretos
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 4. Atualizar sessões existentes para 'active' se status for NULL
UPDATE public.game_sessions 
SET status = 'active' 
WHERE status IS NULL;

-- 5. Verificar se a constraint foi criada
SELECT 
    '✅ Constraint criada com sucesso' as resultado,
    'game_sessions_status_check' as constraint_name,
    'active, paused, cancelled, completed' as valores_permitidos;

-- 6. Verificar dados atualizados
SELECT 
    '✅ Dados atualizados' as resultado,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as sessoes_ativas
FROM public.game_sessions;

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Teste as funcionalidades de pausar/reativar sessões

-- =====================================================
-- 🎯 VALORES DE STATUS SUPORTADOS
-- =====================================================

-- 'active'     - Sessão ativa e disponível (padrão)
-- 'paused'     - Sessão pausada temporariamente
-- 'cancelled'  - Sessão cancelada
-- 'completed'  - Sessão concluída

-- =====================================================




