-- =====================================================
-- CORRIGIR SINCRONIZAÇÃO DO TELEFONE NA EDIÇÃO DE PERFIL
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir problemas de sincronização entre users.phone e players.phone_number
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se houver problemas de sincronização
-- 2. Prioriza dados mais recentes
-- 3. Evita conflitos de telefone duplicado
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
            p.phone_number,
            p.updated_at as player_updated_at,
            u.updated_at as user_updated_at
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
            u.phone,
            u.updated_at as user_updated_at,
            p.updated_at as player_updated_at
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
-- 3. SINCRONIZAR BASEADO NA ÚLTIMA ATUALIZAÇÃO
-- =====================================================

DO $$
DECLARE
    sync_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== SINCRONIZANDO BASEADO NA ÚLTIMA ATUALIZAÇÃO ===';
    
    -- Para cada par user/player com telefones diferentes
    FOR sync_record IN 
        SELECT 
            u.id as user_id,
            p.id as player_id,
            u.email,
            u.phone as phone_users,
            p.phone_number as phone_players,
            u.updated_at as user_updated_at,
            p.updated_at as player_updated_at
        FROM public.users u
        JOIN public.players p ON u.id = p.user_id
        WHERE u.phone != p.phone_number
          AND u.phone IS NOT NULL 
          AND u.phone != ''
          AND p.phone_number IS NOT NULL 
          AND p.phone_number != ''
          AND p.phone_number != '00000000000'
    LOOP
        -- Se usuário foi atualizado mais recentemente, usar telefone do usuário
        IF sync_record.user_updated_at > sync_record.player_updated_at THEN
            -- Verificar se telefone do usuário não está em uso por outro jogador
            IF NOT EXISTS (
                SELECT 1 FROM public.players 
                WHERE phone_number = sync_record.phone_users 
                  AND id != sync_record.player_id
            ) THEN
                UPDATE public.players 
                SET phone_number = sync_record.phone_users,
                    updated_at = NOW()
                WHERE id = sync_record.player_id;
                
                updated_count := updated_count + 1;
                RAISE NOTICE '✅ Sincronizado com telefone do usuário para %: %', sync_record.email, sync_record.phone_users;
            END IF;
        -- Se jogador foi atualizado mais recentemente, usar telefone do jogador
        ELSIF sync_record.player_updated_at > sync_record.user_updated_at THEN
            UPDATE public.users 
            SET phone = sync_record.phone_players,
                updated_at = NOW()
            WHERE id = sync_record.user_id;
            
            updated_count := updated_count + 1;
            RAISE NOTICE '✅ Sincronizado com telefone do jogador para %: %', sync_record.email, sync_record.phone_players;
        END IF;
    END LOOP;
    
    RAISE NOTICE '=== SINCRONIZAÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'Total de registros sincronizados: %', updated_count;
END
$$;

-- =====================================================
-- 4. VERIFICAR RESULTADO FINAL
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
    'Telefones sincronizados (users = players)' as categoria,
    COUNT(*) as quantidade
FROM public.users u
JOIN public.players p ON u.id = p.user_id
WHERE u.phone = p.phone_number;

-- =====================================================
-- 5. MOSTRAR DADOS SINCRONIZADOS
-- =====================================================

SELECT 
    u.id,
    u.email,
    u.name,
    u.phone as phone_users,
    p.phone_number as phone_players,
    CASE 
        WHEN u.phone = p.phone_number THEN '✅ SINCRONIZADO'
        ELSE '❌ AINDA NÃO SINCRONIZADO'
    END as status
FROM public.users u
JOIN public.players p ON u.id = p.user_id
ORDER BY u.updated_at DESC
LIMIT 10;




