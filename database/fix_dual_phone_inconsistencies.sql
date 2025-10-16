-- =====================================================
-- CORRIGIR INCONSISTÊNCIAS DE INSERÇÃO DUPLA DO TELEFONE
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir problemas na inserção dupla do telefone
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se houver inconsistências
-- 2. Prioriza dados da tabela players
-- 3. Garante consistência entre as tabelas
-- =====================================================

-- =====================================================
-- 1. CORRIGIR USERS.PHONE A PARTIR DE PLAYERS.PHONE_NUMBER
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== CORRIGINDO TELEFONES NA TABELA USERS ===';
    
    -- Para cada usuário que tem telefone em players mas não em users
    FOR user_record IN 
        SELECT 
            u.id,
            u.email,
            p.phone_number
        FROM public.users u
        JOIN public.players p ON u.id = p.user_id
        WHERE (u.phone IS NULL OR u.phone = '')
          AND p.phone_number IS NOT NULL 
          AND p.phone_number != ''
          AND p.phone_number != '00000000000'
    LOOP
        -- Atualizar telefone na tabela users
        UPDATE public.users 
        SET phone = user_record.phone_number,
            updated_at = NOW()
        WHERE id = user_record.id;
        
        updated_count := updated_count + 1;
        RAISE NOTICE '✅ Telefone atualizado para usuário %: %', user_record.email, user_record.phone_number;
    END LOOP;
    
    RAISE NOTICE '=== CORREÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'Total de usuários atualizados: %', updated_count;
END
$$;

-- =====================================================
-- 2. CORRIGIR PLAYERS.PHONE_NUMBER A PARTIR DE USERS.PHONE
-- =====================================================

DO $$
DECLARE
    player_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== CORRIGINDO TELEFONES NA TABELA PLAYERS ===';
    
    -- Para cada jogador que tem telefone em users mas não em players
    FOR player_record IN 
        SELECT 
            p.id,
            p.user_id,
            u.email,
            u.phone
        FROM public.players p
        JOIN public.users u ON p.user_id = u.id
        WHERE (p.phone_number IS NULL OR p.phone_number = '' OR p.phone_number = '00000000000')
          AND u.phone IS NOT NULL 
          AND u.phone != ''
    LOOP
        -- Verificar se o telefone já está sendo usado por outro jogador
        IF NOT EXISTS (
            SELECT 1 FROM public.players 
            WHERE phone_number = player_record.phone 
              AND id != player_record.id
        ) THEN
            -- Atualizar telefone na tabela players
            UPDATE public.players 
            SET phone_number = player_record.phone,
                updated_at = NOW()
            WHERE id = player_record.id;
            
            updated_count := updated_count + 1;
            RAISE NOTICE '✅ Telefone atualizado para jogador %: %', player_record.email, player_record.phone;
        ELSE
            RAISE NOTICE '⚠️ Telefone % já está sendo usado por outro jogador, mantendo telefone atual para %', player_record.phone, player_record.email;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== CORREÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'Total de jogadores atualizados: %', updated_count;
END
$$;

-- =====================================================
-- 3. VERIFICAR RESULTADO FINAL
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
    'Jogadores com telefone' as categoria,
    COUNT(*) as quantidade
FROM public.players
WHERE phone_number IS NOT NULL AND phone_number != '' AND phone_number != '00000000000'
UNION ALL
SELECT 
    'Telefones consistentes (users = players)' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone = p.phone_number;

-- =====================================================
-- 4. MOSTRAR DADOS CORRIGIDOS
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.name,
    u.phone as phone_users,
    p.phone_number as phone_players,
    CASE 
        WHEN u.phone = p.phone_number THEN '✅ CONSISTENTE'
        ELSE '❌ AINDA INCONSISTENTE'
    END as status
FROM public.users u
JOIN public.players p ON u.id = p.user_id
ORDER BY u.created_at DESC
LIMIT 10;




