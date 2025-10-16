-- =====================================================
-- 🔍 Verificar Coluna Status na Tabela Games
-- =====================================================
-- Script para verificar se a coluna 'status' existe na tabela 'games'
-- e criar se necessário para suportar pausar/reativar jogos
-- =====================================================

-- 1. Verificar se a coluna 'status' existe na tabela 'games'
SELECT 
    '📋 Verificação da coluna status' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
  AND column_name = 'status';

-- 2. Verificar estrutura completa da tabela 'games'
SELECT 
    '🏗️ Estrutura completa da tabela games' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
ORDER BY ordinal_position;

-- 3. Verificar constraints da tabela 'games'
SELECT 
    '🔒 Constraints da tabela games' as info,
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.check_constraints cc ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
  AND tc.table_name = 'games';

-- 4. Verificar dados atuais na tabela 'games'
SELECT 
    '📊 Dados atuais na tabela games' as info,
    id,
    organization_name,
    status,
    created_at,
    updated_at
FROM public.games
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 🛠️ SCRIPT PARA ADICIONAR COLUNA STATUS (se necessário)
-- =====================================================

-- Execute apenas se a coluna 'status' não existir
-- ALTER TABLE public.games 
-- ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'active' NOT NULL;

-- Adicionar constraint para valores válidos
-- ALTER TABLE public.games 
-- ADD CONSTRAINT games_status_check 
-- CHECK (status IN ('active', 'paused', 'deleted'));

-- Atualizar jogos existentes para 'active'
-- UPDATE public.games 
-- SET status = 'active' 
-- WHERE status IS NULL;

-- =====================================================
-- 📝 INSTRUÇÕES DE USO
-- =====================================================

-- 1. Execute as queries de verificação primeiro
-- 2. Se a coluna 'status' não existir, execute o script de criação
-- 3. Verifique se os dados foram atualizados corretamente

-- =====================================================
-- 🎯 VALORES DE STATUS SUPORTADOS
-- =====================================================

-- 'active'   - Jogo ativo e disponível
-- 'paused'   - Jogo pausado temporariamente
-- 'deleted'  - Jogo deletado (soft delete)

-- =====================================================

