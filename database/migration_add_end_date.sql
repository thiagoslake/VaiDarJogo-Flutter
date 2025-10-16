-- =====================================================
-- 🛠️ Migração: Adicionar Coluna end_date na Tabela Games
-- =====================================================
-- Script de migração para adicionar a coluna 'end_date' na tabela 'games'
-- Execute este script no Supabase SQL Editor
-- =====================================================

-- 1. Verificar se a coluna já existe
DO $$ 
BEGIN
    -- Verificar se a coluna end_date já existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'games' 
        AND column_name = 'end_date'
    ) THEN
        -- Adicionar coluna end_date
        ALTER TABLE public.games 
        ADD COLUMN end_date DATE;
        
        -- Adicionar comentário
        COMMENT ON COLUMN public.games.end_date IS 'Data limite para jogos recorrentes (opcional)';
        
        RAISE NOTICE '✅ Coluna end_date adicionada com sucesso na tabela games';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna end_date já existe na tabela games';
    END IF;
END $$;

-- 2. Verificar se a coluna start_time existe (caso não exista)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'games' 
        AND column_name = 'start_time'
    ) THEN
        ALTER TABLE public.games 
        ADD COLUMN start_time TIME;
        
        RAISE NOTICE '✅ Coluna start_time adicionada com sucesso na tabela games';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna start_time já existe na tabela games';
    END IF;
END $$;

-- 3. Verificar se a coluna end_time existe (caso não exista)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'games' 
        AND column_name = 'end_time'
    ) THEN
        ALTER TABLE public.games 
        ADD COLUMN end_time TIME;
        
        RAISE NOTICE '✅ Coluna end_time adicionada com sucesso na tabela games';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna end_time já existe na tabela games';
    END IF;
END $$;

-- 4. Verificar estrutura final da tabela games
SELECT 
    '🏗️ Estrutura final da tabela games' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'games'
ORDER BY ordinal_position;

-- 5. Verificar se todas as colunas necessárias existem
SELECT 
    '✅ Verificação de colunas necessárias' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'end_date') 
        THEN '✅ end_date existe' 
        ELSE '❌ end_date NÃO existe' 
    END as end_date_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'start_time') 
        THEN '✅ start_time existe' 
        ELSE '❌ start_time NÃO existe' 
    END as start_time_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'games' AND column_name = 'end_time') 
        THEN '✅ end_time existe' 
        ELSE '❌ end_time NÃO existe' 
    END as end_time_status;


