-- =====================================================
-- VERIFICAR CONSTRAINT DE STATUS NA TABELA GAME_PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar constraint de status que está causando erro
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para verificar constraint de status
-- 2. Identifica valores permitidos
-- 3. Corrige problema de inserção
-- =====================================================

-- =====================================================
-- 1. VERIFICAR CONSTRAINTS DA TABELA GAME_PLAYERS
-- =====================================================

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc 
  ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'game_players'
  AND tc.table_schema = 'public'
  AND tc.constraint_type = 'CHECK';

-- =====================================================
-- 2. VERIFICAR ESTRUTURA DA COLUNA STATUS
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_players'
  AND column_name = 'status';

-- =====================================================
-- 3. VERIFICAR VALORES ATUAIS DE STATUS
-- =====================================================

SELECT 
    status,
    COUNT(*) as quantidade
FROM public.game_players
GROUP BY status
ORDER BY quantidade DESC;

-- =====================================================
-- 4. VERIFICAR SE EXISTE CONSTRAINT ESPECÍFICA PARA STATUS
-- =====================================================

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.game_players'::regclass
  AND contype = 'c'
  AND pg_get_constraintdef(oid) LIKE '%status%';

-- =====================================================
-- 5. VERIFICAR DADOS RECENTES PARA IDENTIFICAR PADRÃO
-- =====================================================

SELECT 
    id,
    game_id,
    player_id,
    player_type,
    status,
    is_admin,
    joined_at,
    created_at
FROM public.game_players
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 6. VERIFICAR SE HÁ ENUM OU DOMAIN PARA STATUS
-- =====================================================

SELECT 
    t.typname as type_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname LIKE '%status%'
ORDER BY t.typname, e.enumsortorder;




