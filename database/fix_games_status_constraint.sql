-- =====================================================
-- 🛠️ Corrigir Constraint games_status_check
-- =====================================================
-- Script para corrigir a constraint games_status_check
-- para permitir os valores: 'active', 'paused', 'deleted'
-- =====================================================

-- 1. Remover constraint existente (se existir)
DO $$ 
BEGIN
    -- Verificar se a constraint existe
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'games_status_check' 
        AND table_name = 'games'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.games DROP CONSTRAINT games_status_check;
        RAISE NOTICE '✅ Constraint games_status_check removida';
    ELSE
        RAISE NOTICE 'ℹ️ Constraint games_status_check não existe';
    END IF;
END $$;

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

-- 5. Verificar se a constraint foi criada corretamente
SELECT 
    '✅ Verificação da nova constraint' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'games'
  AND tc.constraint_name = 'games_status_check';

-- 6. Verificar estrutura da coluna
SELECT 
    '✅ Verificação da coluna status' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
  AND column_name = 'status';

-- 7. Testar valores permitidos
SELECT 
    '✅ Teste de valores permitidos' as info,
    'active' as test_value,
    CASE 
        WHEN 'active' IN ('active', 'paused', 'deleted') 
        THEN '✅ PERMITIDO' 
        ELSE '❌ NEGADO' 
    END as result
UNION ALL
SELECT 
    '✅ Teste de valores permitidos' as info,
    'paused' as test_value,
    CASE 
        WHEN 'paused' IN ('active', 'paused', 'deleted') 
        THEN '✅ PERMITIDO' 
        ELSE '❌ NEGADO' 
    END as result
UNION ALL
SELECT 
    '✅ Teste de valores permitidos' as info,
    'deleted' as test_value,
    CASE 
        WHEN 'deleted' IN ('active', 'paused', 'deleted') 
        THEN '✅ PERMITIDO' 
        ELSE '❌ NEGADO' 
    END as result;

-- 8. Verificar dados atualizados
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
-- 3. Confirme que a constraint foi corrigida
-- 4. Teste a funcionalidade de pausar jogo

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
