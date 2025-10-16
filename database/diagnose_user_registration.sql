-- =====================================================
-- DIAGNÓSTICO DE PROBLEMAS DE REGISTRO DE USUÁRIO
-- Sistema: VaiDarJogo Flutter
-- =====================================================

-- =====================================================
-- 1. VERIFICAR USUÁRIOS NO SUPABASE AUTH
-- =====================================================

SELECT 
    'SUPABASE AUTH USERS' as categoria,
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    raw_user_meta_data
FROM auth.users
ORDER BY created_at DESC;

-- =====================================================
-- 2. VERIFICAR USUÁRIOS NA TABELA USERS
-- =====================================================

SELECT 
    'TABELA USERS' as categoria,
    id,
    email,
    name,
    phone,
    created_at,
    last_login_at,
    is_active
FROM public.users
ORDER BY created_at DESC;

-- =====================================================
-- 3. COMPARAR USUÁRIOS (AUTH vs TABELA USERS)
-- =====================================================

-- Usuários que estão no Auth mas não na tabela users
SELECT 
    'USUÁRIOS FALTANDO NA TABELA USERS' as categoria,
    au.id as auth_id,
    au.email as auth_email,
    au.created_at as auth_created_at,
    'FALTANDO' as status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC;

-- Usuários que estão na tabela users mas não no Auth
SELECT 
    'USUÁRIOS FALTANDO NO AUTH' as categoria,
    pu.id as user_id,
    pu.email as user_email,
    pu.created_at as user_created_at,
    'FALTANDO' as status
FROM public.users pu
LEFT JOIN auth.users au ON pu.id = au.id
WHERE au.id IS NULL
ORDER BY pu.created_at DESC;

-- =====================================================
-- 4. VERIFICAR JOGADORES ASSOCIADOS
-- =====================================================

SELECT 
    'JOGADORES ASSOCIADOS' as categoria,
    p.id as player_id,
    p.user_id,
    p.name as player_name,
    p.phone_number,
    p.status as player_status,
    u.email as user_email,
    u.name as user_name
FROM public.players p
LEFT JOIN public.users u ON p.user_id = u.id
ORDER BY p.created_at DESC;

-- =====================================================
-- 5. VERIFICAR JOGADORES SEM USUÁRIO ASSOCIADO
-- =====================================================

SELECT 
    'JOGADORES SEM USUÁRIO' as categoria,
    p.id as player_id,
    p.user_id,
    p.name as player_name,
    p.phone_number,
    p.status as player_status,
    'SEM USUÁRIO' as status
FROM public.players p
LEFT JOIN public.users u ON p.user_id = u.id
WHERE u.id IS NULL
ORDER BY p.created_at DESC;

-- =====================================================
-- 6. CONTAGEM GERAL
-- =====================================================

SELECT 
    'CONTAGEM GERAL' as categoria,
    'auth.users' as tabela,
    COUNT(*) as total
FROM auth.users
UNION ALL
SELECT 
    'CONTAGEM GERAL' as categoria,
    'public.users' as tabela,
    COUNT(*) as total
FROM public.users
UNION ALL
SELECT 
    'CONTAGEM GERAL' as categoria,
    'public.players' as tabela,
    COUNT(*) as total
FROM public.players
ORDER BY tabela;




