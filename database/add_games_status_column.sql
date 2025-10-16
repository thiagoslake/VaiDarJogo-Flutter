-- =====================================================
-- 🛠️ Adicionar Coluna Status na Tabela Games
-- =====================================================
-- Script para adicionar a coluna 'status' na tabela 'games'
-- para suportar funcionalidades de pausar/reativar/deletar jogos
-- =====================================================

-- 1. Adicionar coluna 'status' se não existir
ALTER TABLE public.games 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 2. Adicionar constraint para valores válidos
DO $$ 
BEGIN
    -- Verificar se a constraint já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'games_status_check' 
        AND table_name = 'games'
    ) THEN
        ALTER TABLE public.games 
        ADD CONSTRAINT games_status_check 
        CHECK (status IN ('active', 'paused', 'deleted'));
        
        RAISE NOTICE '✅ Constraint games_status_check adicionada com sucesso';
    ELSE
        RAISE NOTICE 'ℹ️ Constraint games_status_check já existe';
    END IF;
END $$;

-- 3. Atualizar jogos existentes para 'active' se status for NULL
UPDATE public.games 
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
  AND table_name = 'games'
  AND column_name = 'status';

-- 5. Verificar constraint
SELECT 
    '✅ Verificação da constraint' as info,
    constraint_name,
    constraint_type,
    check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'games'
  AND tc.constraint_name = 'games_status_check';

-- 6. Verificar dados atualizados
SELECT 
    '✅ Verificação dos dados' as info,
    COUNT(*) as total_games,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as active_games,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as paused_games,
    COUNT(CASE WHEN status = 'deleted' THEN 1 END) as deleted_games,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as null_status_games
FROM public.games;

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se não há erros na execução
-- 3. Confirme que a coluna 'status' foi adicionada
-- 4. Teste as funcionalidades de pausar/deletar jogos

-- =====================================================
-- 🎯 VALORES DE STATUS SUPORTADOS
-- =====================================================

-- 'active'   - Jogo ativo e disponível (padrão)
-- 'paused'   - Jogo pausado temporariamente
-- 'deleted'  - Jogo deletado (soft delete)

-- =====================================================
-- 🔍 FUNCIONALIDADES IMPLEMENTADAS
-- =====================================================

-- ✅ Pausar jogo: status = 'paused'
-- ✅ Reativar jogo: status = 'active'  
-- ✅ Deletar jogo: remove completamente do banco
-- ✅ Verificar permissões de administrador
-- ✅ Interface com confirmações de segurança

-- =====================================================




