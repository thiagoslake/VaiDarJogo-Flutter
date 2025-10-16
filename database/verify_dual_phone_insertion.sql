-- =====================================================
-- VERIFICAR INSERÇÃO DUPLA DO TELEFONE
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se o telefone está sendo salvo em ambas as tabelas
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute após criar uma nova conta
-- 2. Verifica users.phone e players.phone_number
-- 3. Identifica problemas na inserção dupla
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DAS TABELAS
-- =====================================================

SELECT 
    'users' as tabela,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name IN ('phone', 'id', 'email', 'name')
UNION ALL
SELECT 
    'players' as tabela,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'players'
  AND column_name IN ('phone_number', 'user_id', 'name')
ORDER BY tabela, column_name;

-- =====================================================
-- 2. VERIFICAR DADOS DOS USUÁRIOS RECENTES
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.name,
    u.phone as phone_users,
    u.created_at as user_created_at,
    p.phone_number as phone_players,
    p.created_at as player_created_at,
    CASE 
        WHEN u.phone = p.phone_number THEN '✅ CONSISTENTE'
        WHEN u.phone IS NULL AND p.phone_number IS NOT NULL THEN '⚠️ USERS NULL'
        WHEN u.phone IS NOT NULL AND p.phone_number IS NULL THEN '⚠️ PLAYERS NULL'
        WHEN u.phone != p.phone_number THEN '❌ DIFERENTE'
        ELSE '❓ INDEFINIDO'
    END as status_telefone
FROM public.users u
LEFT JOIN public.players p ON u.id = p.user_id
ORDER BY u.created_at DESC
LIMIT 10;

-- =====================================================
-- 3. CONTAR INCONSISTÊNCIAS
-- =====================================================

SELECT 
    'Total de usuários' as categoria,
    COUNT(*) as quantidade
FROM public.users
UNION ALL
SELECT 
    'Usuários com telefone em users' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NOT NULL AND phone != ''
UNION ALL
SELECT 
    'Jogadores com telefone em players' as categoria,
    COUNT(*) as quantidade
FROM public.players
WHERE phone_number IS NOT NULL AND phone_number != '' AND phone_number != '00000000000'
UNION ALL
SELECT 
    'Telefones consistentes (users = players)' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone = p.phone_number
UNION ALL
SELECT 
    'Telefones inconsistentes' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone != p.phone_number OR u.phone IS NULL OR p.phone_number IS NULL;

-- =====================================================
-- 4. VERIFICAR TRIGGER
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- 5. VERIFICAR METADADOS DO AUTH
-- =====================================================

SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'name' as name_metadata,
    au.raw_user_meta_data->>'phone' as phone_metadata,
    pu.phone as phone_users_table,
    pp.phone_number as phone_players_table
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
LEFT JOIN public.players pp ON au.id = pp.user_id
ORDER BY au.created_at DESC
LIMIT 5;

-- =====================================================
-- 6. VERIFICAR USUÁRIOS SEM TELEFONE
-- =====================================================

SELECT 
    'Usuários sem telefone em users' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NULL OR phone = ''
UNION ALL
SELECT 
    'Jogadores sem telefone em players' as categoria,
    COUNT(*) as quantidade
FROM public.players
WHERE phone_number IS NULL OR phone_number = '' OR phone_number = '00000000000';




