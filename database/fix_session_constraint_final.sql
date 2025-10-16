-- =====================================================
-- 🔧 Correção Final: Constraint de Sessões
-- =====================================================
-- Script final para corrigir definitivamente a constraint game_sessions_status_check
-- =====================================================

-- 1. Verificar se a tabela game_sessions existe
SELECT 
    '📋 Verificação da tabela game_sessions' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions';

-- 2. Verificar estrutura da tabela game_sessions
SELECT 
    '🏗️ Estrutura da tabela game_sessions' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions'
ORDER BY ordinal_position;

-- 3. Verificar constraints existentes
SELECT 
    '🔒 Constraints existentes' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'game_sessions';

-- 4. Verificar dados atuais
SELECT 
    '📊 Dados atuais' as info,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as status_active,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as status_paused,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as status_cancelled,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as status_completed,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as status_null,
    COUNT(CASE WHEN status NOT IN ('active', 'paused', 'cancelled', 'completed') THEN 1 END) as status_invalid
FROM public.game_sessions;

-- 5. Verificar valores únicos de status
SELECT 
    '🎯 Valores únicos de status' as info,
    status,
    COUNT(*) as count
FROM public.game_sessions
GROUP BY status
ORDER BY status;

-- 6. Verificar registros com valores inválidos
SELECT 
    '❌ Registros com valores inválidos' as info,
    id,
    game_id,
    session_date,
    status,
    created_at
FROM public.game_sessions
WHERE status NOT IN ('active', 'paused', 'cancelled', 'completed')
   OR status IS NULL
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 🛠️ CORREÇÃO AUTOMÁTICA
-- =====================================================

-- 7. Remover constraint existente
ALTER TABLE public.game_sessions DROP CONSTRAINT IF EXISTS game_sessions_status_check;

-- 8. Atualizar valores inválidos para 'active'
UPDATE public.game_sessions 
SET status = 'active'
WHERE status IS NULL 
   OR status NOT IN ('active', 'paused', 'cancelled', 'completed');

-- 9. Adicionar coluna status se não existir
ALTER TABLE public.game_sessions 
ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- 10. Criar constraint com valores corretos
ALTER TABLE public.game_sessions 
ADD CONSTRAINT game_sessions_status_check 
CHECK (status IN ('active', 'paused', 'cancelled', 'completed'));

-- 11. Verificação final
SELECT 
    '🎯 Verificação final' as info,
    COUNT(*) as total_registros,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as status_active,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as status_paused,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as status_cancelled,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as status_completed,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as status_null
FROM public.game_sessions;

-- 12. Verificar se a constraint foi criada corretamente
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

-- =====================================================
-- 📝 INSTRUÇÕES
-- =====================================================

-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique os resultados de cada seção
-- 3. Se houver valores inválidos, eles serão corrigidos automaticamente
-- 4. Teste a criação de sessões no app após executar este script

-- =====================================================


