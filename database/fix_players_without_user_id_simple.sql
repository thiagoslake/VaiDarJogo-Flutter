-- =====================================================
-- CORREÇÃO SIMPLES: JOGADORES SEM USER_ID
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir jogadores que estão sem user_id
-- de forma simples e direta
-- =====================================================

-- =====================================================
-- PASSO 1: VERIFICAR SITUAÇÃO ATUAL
-- =====================================================

-- Verificar quantos jogadores estão sem user_id
SELECT 
    'JOGADORES SEM USER_ID' as status,
    COUNT(*) as quantidade
FROM players 
WHERE user_id IS NULL;

-- Listar jogadores sem user_id
SELECT 
    id,
    name,
    phone_number,
    created_at,
    status
FROM players 
WHERE user_id IS NULL
ORDER BY created_at DESC;

-- =====================================================
-- PASSO 2: ASSOCIAR POR TELEFONE (SE POSSÍVEL)
-- =====================================================

-- Atualizar players que têm telefone correspondente a um user existente
UPDATE players 
SET user_id = u.id,
    updated_at = now()
FROM users u
WHERE players.user_id IS NULL 
AND players.phone_number = u.phone
AND players.phone_number IS NOT NULL
AND players.phone_number != '00000000000';

-- Verificar quantos foram associados
SELECT 
    'JOGADORES ASSOCIADOS POR TELEFONE' as status,
    COUNT(*) as quantidade
FROM players 
WHERE user_id IS NOT NULL;

-- =====================================================
-- PASSO 3: CRIAR USUÁRIOS PARA PLAYERS RESTANTES
-- =====================================================

-- Para cada player sem user_id, criar um usuário correspondente
DO $$
DECLARE
    player_record RECORD;
    new_user_id UUID;
    new_email TEXT;
    email_counter INTEGER := 1;
BEGIN
    FOR player_record IN 
        SELECT id, name, phone_number, created_at
        FROM players 
        WHERE user_id IS NULL
        AND phone_number IS NOT NULL
        AND phone_number != '00000000000'
    LOOP
        -- Gerar email único
        new_email := LOWER(REPLACE(player_record.name, ' ', '.')) || 
                     '.' || 
                     SUBSTRING(player_record.phone_number, -4) || 
                     '.' || email_counter || 
                     '@vaidarjogo.local';
        
        -- Criar novo usuário
        INSERT INTO users (
            id,
            email,
            name,
            phone,
            created_at,
            updated_at
        ) VALUES (
            gen_random_uuid(),
            new_email,
            player_record.name,
            player_record.phone_number,
            player_record.created_at,
            now()
        ) RETURNING id INTO new_user_id;
        
        -- Atualizar o player com o novo user_id
        UPDATE players 
        SET user_id = new_user_id,
            updated_at = now()
        WHERE id = player_record.id;
        
        email_counter := email_counter + 1;
        
        RAISE NOTICE 'Criado usuário % para player %', new_email, player_record.name;
    END LOOP;
END $$;

-- =====================================================
-- PASSO 4: LIMPEZA DE PLAYERS ÓRFÃOS
-- =====================================================

-- Remover players que não têm user_id e não têm relacionamentos importantes
DELETE FROM players 
WHERE user_id IS NULL
AND (phone_number IS NULL OR phone_number = '00000000000')
AND NOT EXISTS (
    SELECT 1 FROM game_players WHERE player_id = players.id
);

-- =====================================================
-- PASSO 5: VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar resultado final
SELECT 
    'RESULTADO FINAL' as status,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM players WHERE user_id IS NOT NULL) as players_com_user_id,
    (SELECT COUNT(*) FROM players WHERE user_id IS NULL) as players_sem_user_id;

-- Listar players que ainda estão sem user_id (se houver)
SELECT 
    'PLAYERS AINDA SEM USER_ID' as status,
    id,
    name,
    phone_number,
    created_at
FROM players 
WHERE user_id IS NULL
ORDER BY created_at DESC;
