-- =====================================================
-- 🛠️ Adicionar Coluna end_date na Tabela Games
-- =====================================================
-- Script para adicionar a coluna 'end_date' na tabela 'games'
-- para suportar funcionalidades de data limite de recorrência
-- =====================================================

-- 1. Adicionar coluna 'end_date' se não existir
ALTER TABLE public.games 
ADD COLUMN IF NOT EXISTS end_date DATE;

-- 2. Adicionar comentário na coluna
COMMENT ON COLUMN public.games.end_date IS 'Data limite para jogos recorrentes (opcional)';

-- 3. Verificar se a coluna foi adicionada corretamente
SELECT 
    '✅ Verificação da coluna end_date' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
  AND column_name = 'end_date';

-- 4. Verificar estrutura completa da tabela games
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

-- 5. Verificar dados atuais na tabela games
SELECT 
    '📊 Dados atuais na tabela games' as info,
    id,
    organization_name,
    frequency,
    end_date,
    created_at
FROM public.games
ORDER BY created_at DESC
LIMIT 10;


