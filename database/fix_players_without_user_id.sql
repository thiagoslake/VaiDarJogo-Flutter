-- =====================================================
-- CORREÇÃO: JOGADORES SEM USER_ID
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Identificar e corrigir jogadores que estão sem user_id
-- na tabela players, criando usuários correspondentes quando necessário
-- =====================================================

-- =====================================================
-- PASSO 1: DIAGNÓSTICO - IDENTIFICAR PROBLEMAS
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== DIAGNÓSTICO: JOGADORES SEM USER_ID ===';
END $$;

-- 1.1 Verificar quantos jogadores estão sem user_id
SELECT 
    'JOGADORES SEM USER_ID' as categoria,
    COUNT(*) as quantidade
FROM players 
WHERE user_id IS NULL;

-- 1.2 Listar jogadores sem user_id com detalhes
SELECT 
    'DETALHES DOS JOGADORES SEM USER_ID' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.phone_number,
    p.created_at as player_created_at,
    p.status as player_status
FROM players p
WHERE p.user_id IS NULL
ORDER BY p.created_at DESC;

-- 1.3 Verificar se há usuários órfãos (sem player)
SELECT 
    'USUÁRIOS SEM PERFIL DE JOGADOR' as categoria,
    COUNT(*) as quantidade
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM players p WHERE p.user_id = u.id
);

-- 1.4 Verificar relacionamentos game_players com jogadores sem user_id
SELECT 
    'RELACIONAMENTOS GAME_PLAYERS COM JOGADORES SEM USER_ID' as categoria,
    COUNT(*) as quantidade
FROM game_players gp
JOIN players p ON gp.player_id = p.id
WHERE p.user_id IS NULL;

-- =====================================================
-- PASSO 2: ANÁLISE DE DADOS PARA CORREÇÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== ANÁLISE: DADOS PARA CORREÇÃO ===';
END $$;

-- 2.1 Verificar se há telefones duplicados entre players e users
SELECT 
    'TELEFONES DUPLICADOS ENTRE PLAYERS E USERS' as categoria,
    p.phone_number,
    COUNT(*) as quantidade_players,
    (SELECT COUNT(*) FROM users u WHERE u.phone = p.phone_number) as quantidade_users
FROM players p
WHERE p.user_id IS NULL 
AND p.phone_number IS NOT NULL
AND p.phone_number != '00000000000'
GROUP BY p.phone_number
HAVING COUNT(*) > 1 OR (SELECT COUNT(*) FROM users u WHERE u.phone = p.phone_number) > 0;

-- 2.2 Verificar se há emails que podem ser usados para matching
SELECT 
    'POSSÍVEIS MATCHES POR TELEFONE' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.phone_number as player_phone,
    u.id as user_id,
    u.email as user_email,
    u.name as user_name
FROM players p
LEFT JOIN users u ON p.phone_number = u.phone
WHERE p.user_id IS NULL 
AND p.phone_number IS NOT NULL
AND p.phone_number != '00000000000'
AND u.id IS NOT NULL;

-- =====================================================
-- PASSO 3: ESTRATÉGIAS DE CORREÇÃO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== ESTRATÉGIAS DE CORREÇÃO ===';
    RAISE NOTICE '1. MATCH POR TELEFONE: Associar players com users existentes pelo telefone';
    RAISE NOTICE '2. CRIAR USUÁRIOS: Criar novos usuários para players sem match';
    RAISE NOTICE '3. LIMPEZA: Remover players órfãos se necessário';
END $$;

-- =====================================================
-- PASSO 4: CORREÇÃO AUTOMÁTICA - MATCH POR TELEFONE
-- =====================================================

DO $$
DECLARE
    updated_count INTEGER := 0;
    player_record RECORD;
BEGIN
    RAISE NOTICE '=== CORREÇÃO: MATCH POR TELEFONE ===';
    
    -- Atualizar players que têm telefone correspondente a um user existente
    FOR player_record IN 
        SELECT p.id as player_id, u.id as user_id, p.name as player_name, u.name as user_name
        FROM players p
        JOIN users u ON p.phone_number = u.phone
        WHERE p.user_id IS NULL 
        AND p.phone_number IS NOT NULL
        AND p.phone_number != '00000000000'
    LOOP
        -- Atualizar o player com o user_id correspondente
        UPDATE players 
        SET user_id = player_record.user_id,
            updated_at = now()
        WHERE id = player_record.player_id;
        
        updated_count := updated_count + 1;
        
        RAISE NOTICE '✅ Associado: Player "%" (ID: %) -> User "%" (ID: %)', 
            player_record.player_name, 
            player_record.player_id,
            player_record.user_name,
            player_record.user_id;
    END LOOP;
    
    RAISE NOTICE '📊 Total de players associados por telefone: %', updated_count;
END $$;

-- =====================================================
-- PASSO 5: CORREÇÃO AUTOMÁTICA - CRIAR USUÁRIOS
-- =====================================================

DO $$
DECLARE
    created_count INTEGER := 0;
    player_record RECORD;
    new_user_id UUID;
    new_email TEXT;
BEGIN
    RAISE NOTICE '=== CORREÇÃO: CRIAR USUÁRIOS PARA PLAYERS RESTANTES ===';
    
    -- Para players que ainda não têm user_id, criar usuários correspondentes
    FOR player_record IN 
        SELECT id, name, phone_number, created_at
        FROM players 
        WHERE user_id IS NULL
        AND phone_number IS NOT NULL
        AND phone_number != '00000000000'
    LOOP
        -- Gerar email baseado no nome e telefone
        new_email := LOWER(REPLACE(player_record.name, ' ', '.')) || 
                     '.' || 
                     SUBSTRING(player_record.phone_number, -4) || 
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
        
        created_count := created_count + 1;
        
        RAISE NOTICE '✅ Criado: User "%" (ID: %) para Player "%" (ID: %)', 
            new_email,
            new_user_id,
            player_record.name,
            player_record.id;
    END LOOP;
    
    RAISE NOTICE '📊 Total de usuários criados: %', created_count;
END $$;

-- =====================================================
-- PASSO 6: LIMPEZA - REMOVER PLAYERS ÓRFÃOS
-- =====================================================

DO $$
DECLARE
    deleted_count INTEGER := 0;
    player_record RECORD;
BEGIN
    RAISE NOTICE '=== LIMPEZA: REMOVER PLAYERS ÓRFÃOS ===';
    
    -- Para players que ainda não têm user_id e têm telefone inválido
    FOR player_record IN 
        SELECT id, name, phone_number
        FROM players 
        WHERE user_id IS NULL
        AND (phone_number IS NULL OR phone_number = '00000000000')
    LOOP
        -- Verificar se o player tem relacionamentos em game_players
        IF NOT EXISTS (SELECT 1 FROM game_players WHERE player_id = player_record.id) THEN
            -- Deletar o player órfão
            DELETE FROM players WHERE id = player_record.id;
            
            deleted_count := deleted_count + 1;
            
            RAISE NOTICE '🗑️ Removido: Player órfão "%" (ID: %)', 
                player_record.name,
                player_record.id;
        ELSE
            RAISE NOTICE '⚠️ Mantido: Player "%" (ID: %) tem relacionamentos em game_players', 
                player_record.name,
                player_record.id;
        END IF;
    END LOOP;
    
    RAISE NOTICE '📊 Total de players órfãos removidos: %', deleted_count;
END $$;

-- =====================================================
-- PASSO 7: VERIFICAÇÃO FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
END $$;

-- 7.1 Verificar se ainda há jogadores sem user_id
SELECT 
    'JOGADORES SEM USER_ID (APÓS CORREÇÃO)' as categoria,
    COUNT(*) as quantidade
FROM players 
WHERE user_id IS NULL;

-- 7.2 Verificar integridade dos relacionamentos
SELECT 
    'INTEGRIDADE DOS RELACIONAMENTOS' as categoria,
    COUNT(*) as total_game_players,
    COUNT(CASE WHEN p.user_id IS NOT NULL THEN 1 END) as com_user_id,
    COUNT(CASE WHEN p.user_id IS NULL THEN 1 END) as sem_user_id
FROM game_players gp
JOIN players p ON gp.player_id = p.id;

-- 7.3 Estatísticas finais
SELECT 
    'ESTATÍSTICAS FINAIS' as categoria,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM players WHERE user_id IS NOT NULL) as players_com_user_id,
    (SELECT COUNT(*) FROM players WHERE user_id IS NULL) as players_sem_user_id,
    (SELECT COUNT(*) FROM game_players) as total_game_players;

-- 7.4 Listar players que ainda estão sem user_id (se houver)
SELECT 
    'PLAYERS AINDA SEM USER_ID' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.phone_number,
    p.created_at,
    COUNT(gp.id) as relacionamentos_game_players
FROM players p
LEFT JOIN game_players gp ON p.id = gp.player_id
WHERE p.user_id IS NULL
GROUP BY p.id, p.name, p.phone_number, p.created_at
ORDER BY p.created_at DESC;

-- =====================================================
-- PASSO 8: RELATÓRIO DE SUCESSO
-- =====================================================

DO $$
DECLARE
    players_sem_user_id INTEGER;
    total_players INTEGER;
    total_users INTEGER;
BEGIN
    -- Contar resultados finais
    SELECT COUNT(*) INTO players_sem_user_id FROM players WHERE user_id IS NULL;
    SELECT COUNT(*) INTO total_players FROM players;
    SELECT COUNT(*) INTO total_users FROM users;
    
    RAISE NOTICE '=== RELATÓRIO DE SUCESSO ===';
    RAISE NOTICE '📊 Total de usuários: %', total_users;
    RAISE NOTICE '📊 Total de players: %', total_players;
    RAISE NOTICE '📊 Players com user_id: %', (total_players - players_sem_user_id);
    RAISE NOTICE '📊 Players sem user_id: %', players_sem_user_id;
    
    IF players_sem_user_id = 0 THEN
        RAISE NOTICE '🎉 SUCESSO: Todos os players agora têm user_id associado!';
    ELSE
        RAISE NOTICE '⚠️ ATENÇÃO: Ainda há % players sem user_id', players_sem_user_id;
        RAISE NOTICE '💡 Verifique a lista acima para análise manual';
    END IF;
END $$;

-- =====================================================
-- QUERIES ÚTEIS PARA VERIFICAÇÃO MANUAL
-- =====================================================

-- Query para verificar players com telefones duplicados
-- SELECT p1.id, p1.name, p1.phone_number, p1.user_id, p2.id, p2.name, p2.phone_number, p2.user_id
-- FROM players p1
-- JOIN players p2 ON p1.phone_number = p2.phone_number AND p1.id != p2.id
-- WHERE p1.phone_number IS NOT NULL AND p1.phone_number != '00000000000';

-- Query para verificar users com telefones duplicados
-- SELECT u1.id, u1.name, u1.phone, u2.id, u2.name, u2.phone
-- FROM users u1
-- JOIN users u2 ON u1.phone = u2.phone AND u1.id != u2.id
-- WHERE u1.phone IS NOT NULL;

-- Query para verificar relacionamentos órfãos
-- SELECT gp.id, gp.game_id, gp.player_id, p.name, p.user_id
-- FROM game_players gp
-- JOIN players p ON gp.player_id = p.id
-- WHERE p.user_id IS NULL;
