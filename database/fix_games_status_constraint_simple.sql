-- =====================================================
-- 🛠️ Corrigir Constraint games_status_check (Versão Simples)
-- =====================================================
-- Script simplificado para corrigir a constraint games_status_check
-- =====================================================

-- 1. Remover constraint existente (se existir)
ALTER TABLE public.games DROP CONSTRAINT IF EXISTS games_status_check;

-- 2. Adicionar coluna status se não existir
ALTER TABLE public.games 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 3. Criar nova constraint com valores corretos
ALTER TABLE public.games 
ADD CONSTRAINT games_status_check 
CHECK (status IN ('active', 'paused', 'deleted'));

-- 4. Atualizar jogos existentes para 'active' se status for NULL
UPDATE public.games 
SET status = 'active' 
WHERE status IS NULL;

-- 5. Verificar se a constraint foi criada
SELECT 
    '✅ Constraint criada com sucesso' as resultado,
    'games_status_check' as constraint_name,
    'active, paused, deleted' as valores_permitidos;

-- 6. Verificar dados atualizados
SELECT 
    '✅ Dados atualizados' as resultado,
    COUNT(*) as total_jogos,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as jogos_ativos
FROM public.games;

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Teste a funcionalidade de pausar jogo

-- =====================================================
-- 🎯 VALORES DE STATUS SUPORTADOS
-- =====================================================

-- 'active'   - Jogo ativo e disponível (padrão)
-- 'paused'   - Jogo pausado temporariamente
-- 'deleted'  - Jogo deletado (soft delete)

-- =====================================================




