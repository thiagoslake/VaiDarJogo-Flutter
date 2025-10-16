-- =====================================================
-- VERIFICAR CAMPO PHONE NA TABELA USERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se o campo phone existe e tem dados
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para diagnosticar problema do telefone
-- 2. Verifica estrutura da tabela users
-- 3. Lista dados dos usuários
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA USERS
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
ORDER BY ordinal_position;

-- =====================================================
-- 2. VERIFICAR DADOS DOS USUÁRIOS
-- =====================================================

SELECT 
    id,
    email,
    name,
    phone,
    created_at,
    is_active
FROM public.users
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- 3. CONTAR USUÁRIOS COM E SEM TELEFONE
-- =====================================================

SELECT 
    'Total de usuários' as categoria,
    COUNT(*) as quantidade
FROM public.users
UNION ALL
SELECT 
    'Usuários com telefone' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NOT NULL AND phone != ''
UNION ALL
SELECT 
    'Usuários sem telefone' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NULL OR phone = '';

-- =====================================================
-- 4. VERIFICAR SE HÁ DADOS DE METADATA NO AUTH
-- =====================================================

SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    pu.phone as phone_from_users_table
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at DESC
LIMIT 5;




