-- =====================================================
-- LIMPAR USUÁRIOS DUPLICADOS OU PROBLEMÁTICOS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Limpar usuários duplicados ou com problemas
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se houver problemas de duplicação
-- 2. Este script remove usuários problemáticos
-- 3. FAÇA BACKUP ANTES DE EXECUTAR
-- =====================================================

-- =====================================================
-- 1. IDENTIFICAR USUÁRIOS DUPLICADOS POR EMAIL
-- =====================================================

SELECT 
    'USUÁRIOS DUPLICADOS POR EMAIL' as categoria,
    email,
    COUNT(*) as total,
    STRING_AGG(id::text, ', ') as user_ids
FROM public.users
GROUP BY email
HAVING COUNT(*) > 1
ORDER BY total DESC;

-- =====================================================
-- 2. IDENTIFICAR JOGADORES DUPLICADOS POR TELEFONE
-- =====================================================

SELECT 
    'JOGADORES DUPLICADOS POR TELEFONE' as categoria,
    phone_number,
    COUNT(*) as total,
    STRING_AGG(id::text, ', ') as player_ids
FROM public.players
GROUP BY phone_number
HAVING COUNT(*) > 1
ORDER BY total DESC;

-- =====================================================
-- 3. IDENTIFICAR USUÁRIOS SEM EMAIL VÁLIDO
-- =====================================================

SELECT 
    'USUÁRIOS SEM EMAIL VÁLIDO' as categoria,
    id,
    email,
    name,
    created_at
FROM public.users
WHERE email IS NULL 
   OR email = '' 
   OR email NOT LIKE '%@%'
ORDER BY created_at DESC;

-- =====================================================
-- 4. IDENTIFICAR JOGADORES SEM TELEFONE VÁLIDO
-- =====================================================

SELECT 
    'JOGADORES SEM TELEFONE VÁLIDO' as categoria,
    id,
    user_id,
    name,
    phone_number,
    created_at
FROM public.players
WHERE phone_number IS NULL 
   OR phone_number = '' 
   OR phone_number = '00000000000'
ORDER BY created_at DESC;

-- =====================================================
-- 5. IDENTIFICAR USUÁRIOS ÓRFÃOS (SEM JOGADOR)
-- =====================================================

SELECT 
    'USUÁRIOS ÓRFÃOS (SEM JOGADOR)' as categoria,
    u.id,
    u.email,
    u.name,
    u.created_at
FROM public.users u
LEFT JOIN public.players p ON u.id = p.user_id
WHERE p.user_id IS NULL
ORDER BY u.created_at DESC;

-- =====================================================
-- 6. IDENTIFICAR JOGADORES ÓRFÃOS (SEM USUÁRIO)
-- =====================================================

SELECT 
    'JOGADORES ÓRFÃOS (SEM USUÁRIO)' as categoria,
    p.id,
    p.user_id,
    p.name,
    p.phone_number,
    p.created_at
FROM public.players p
LEFT JOIN public.users u ON p.user_id = u.id
WHERE u.id IS NULL
ORDER BY p.created_at DESC;

-- =====================================================
-- 7. LIMPAR USUÁRIOS DUPLICADOS (MANTER O MAIS RECENTE)
-- =====================================================

DO $$
DECLARE
    duplicate_record RECORD;
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== LIMPANDO USUÁRIOS DUPLICADOS ===';
    
    -- Para cada email duplicado, manter apenas o mais recente
    FOR duplicate_record IN 
        SELECT 
            email,
            MIN(created_at) as oldest_created_at
        FROM public.users
        GROUP BY email
        HAVING COUNT(*) > 1
    LOOP
        -- Deletar usuários duplicados (manter o mais recente)
        DELETE FROM public.users 
        WHERE email = duplicate_record.email 
        AND created_at = duplicate_record.oldest_created_at;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ Usuários duplicados removidos para email: % (removidos: %)', duplicate_record.email, deleted_count;
    END LOOP;
    
    RAISE NOTICE '=== LIMPEZA DE DUPLICADOS CONCLUÍDA ===';
END $$;

-- =====================================================
-- 8. LIMPAR JOGADORES DUPLICADOS (MANTER O MAIS RECENTE)
-- =====================================================

DO $$
DECLARE
    duplicate_record RECORD;
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== LIMPANDO JOGADORES DUPLICADOS ===';
    
    -- Para cada telefone duplicado, manter apenas o mais recente
    FOR duplicate_record IN 
        SELECT 
            phone_number,
            MIN(created_at) as oldest_created_at
        FROM public.players
        WHERE phone_number != '00000000000'
        GROUP BY phone_number
        HAVING COUNT(*) > 1
    LOOP
        -- Deletar jogadores duplicados (manter o mais recente)
        DELETE FROM public.players 
        WHERE phone_number = duplicate_record.phone_number 
        AND created_at = duplicate_record.oldest_created_at;
        
        GET DIAGNOSTICS deleted_count = ROW_COUNT;
        RAISE NOTICE '✅ Jogadores duplicados removidos para telefone: % (removidos: %)', duplicate_record.phone_number, deleted_count;
    END LOOP;
    
    RAISE NOTICE '=== LIMPEZA DE DUPLICADOS CONCLUÍDA ===';
END $$;

-- =====================================================
-- 9. LIMPAR JOGADORES ÓRFÃOS (SEM USUÁRIO)
-- =====================================================

DO $$
DECLARE
    deleted_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== LIMPANDO JOGADORES ÓRFÃOS ===';
    
    -- Deletar jogadores que não têm usuário associado
    DELETE FROM public.players 
    WHERE user_id NOT IN (SELECT id FROM public.users);
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RAISE NOTICE '✅ Jogadores órfãos removidos: %', deleted_count;
END $$;

-- =====================================================
-- 10. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    users_count INTEGER;
    players_count INTEGER;
    duplicate_users INTEGER;
    duplicate_players INTEGER;
    orphan_players INTEGER;
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    -- Contar registros
    SELECT COUNT(*) INTO users_count FROM public.users;
    SELECT COUNT(*) INTO players_count FROM public.players;
    
    -- Contar duplicados
    SELECT COUNT(*) INTO duplicate_users
    FROM (
        SELECT email FROM public.users GROUP BY email HAVING COUNT(*) > 1
    ) as duplicates;
    
    SELECT COUNT(*) INTO duplicate_players
    FROM (
        SELECT phone_number FROM public.players 
        WHERE phone_number != '00000000000'
        GROUP BY phone_number HAVING COUNT(*) > 1
    ) as duplicates;
    
    -- Contar órfãos
    SELECT COUNT(*) INTO orphan_players
    FROM public.players p
    LEFT JOIN public.users u ON p.user_id = u.id
    WHERE u.id IS NULL;
    
    RAISE NOTICE '📊 Total de usuários: %', users_count;
    RAISE NOTICE '📊 Total de jogadores: %', players_count;
    RAISE NOTICE '📊 Emails duplicados: %', duplicate_users;
    RAISE NOTICE '📊 Telefones duplicados: %', duplicate_players;
    RAISE NOTICE '📊 Jogadores órfãos: %', orphan_players;
    
    IF duplicate_users = 0 AND duplicate_players = 0 AND orphan_players = 0 THEN
        RAISE NOTICE '🎉 SUCESSO: Dados limpos e organizados!';
    ELSE
        RAISE NOTICE '⚠️ ATENÇÃO: Ainda há dados duplicados ou órfãos';
    END IF;
END $$;




