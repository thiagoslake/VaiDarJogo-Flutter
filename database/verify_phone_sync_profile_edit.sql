-- =====================================================
-- VERIFICAR SINCRONIZAÇÃO DO TELEFONE NA EDIÇÃO DE PERFIL
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Verificar se o telefone está sincronizado entre users e players
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute após editar um perfil
-- 2. Verifica consistência entre users.phone e players.phone_number
-- 3. Identifica problemas de sincronização
-- =====================================================

-- =====================================================
-- 1. VERIFICAR DADOS DOS USUÁRIOS RECENTES
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.name,
    u.phone as phone_users,
    u.updated_at as user_updated_at,
    p.phone_number as phone_players,
    p.updated_at as player_updated_at,
    CASE 
        WHEN u.phone = p.phone_number THEN '✅ SINCRONIZADO'
        WHEN u.phone IS NULL AND p.phone_number IS NOT NULL THEN '⚠️ USERS NULL'
        WHEN u.phone IS NOT NULL AND p.phone_number IS NULL THEN '⚠️ PLAYERS NULL'
        WHEN u.phone != p.phone_number THEN '❌ DIFERENTE'
        ELSE '❓ INDEFINIDO'
    END as status_sincronizacao
FROM public.users u
LEFT JOIN public.players p ON u.id = p.user_id
ORDER BY u.updated_at DESC
LIMIT 10;

-- =====================================================
-- 2. CONTAR PROBLEMAS DE SINCRONIZAÇÃO
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
    'Telefones sincronizados (users = players)' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone = p.phone_number
UNION ALL
SELECT 
    'Telefones não sincronizados' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone != p.phone_number OR u.phone IS NULL OR p.phone_number IS NULL;

-- =====================================================
-- 3. VERIFICAR USUÁRIOS COM PROBLEMAS DE SINCRONIZAÇÃO
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.name,
    u.phone as phone_users,
    p.phone_number as phone_players,
    u.updated_at as user_updated_at,
    p.updated_at as player_updated_at,
    CASE 
        WHEN u.updated_at > p.updated_at THEN 'Usuário atualizado mais recentemente'
        WHEN p.updated_at > u.updated_at THEN 'Jogador atualizado mais recentemente'
        ELSE 'Atualizações simultâneas'
    END as ultima_atualizacao
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone != p.phone_number 
   OR (u.phone IS NULL AND p.phone_number IS NOT NULL)
   OR (u.phone IS NOT NULL AND p.phone_number IS NULL)
ORDER BY GREATEST(u.updated_at, p.updated_at) DESC
LIMIT 10;

-- =====================================================
-- 4. VERIFICAR TELEFONES DUPLICADOS
-- =====================================================

SELECT 
    phone_number,
    COUNT(*) as quantidade_jogadores,
    STRING_AGG(p.name, ', ') as nomes_jogadores
FROM public.players
WHERE phone_number IS NOT NULL 
  AND phone_number != '' 
  AND phone_number != '00000000000'
GROUP BY phone_number
HAVING COUNT(*) > 1
ORDER BY quantidade_jogadores DESC;

-- =====================================================
-- 5. VERIFICAR TELEFONES RECENTEMENTE ATUALIZADOS
-- =====================================================

SELECT 
    'Usuários atualizados recentemente' as tipo,
    u.id,
    u.email,
    u.phone,
    u.updated_at
FROM public.users u
WHERE u.updated_at > NOW() - INTERVAL '1 hour'
UNION ALL
SELECT 
    'Jogadores atualizados recentemente' as tipo,
    p.user_id::text as id,
    u.email,
    p.phone_number as phone,
    p.updated_at
FROM public.players p
JOIN public.users u ON p.user_id = u.id
WHERE p.updated_at > NOW() - INTERVAL '1 hour'
ORDER BY updated_at DESC;




