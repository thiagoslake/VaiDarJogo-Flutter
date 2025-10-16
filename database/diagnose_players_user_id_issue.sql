-- =====================================================
-- DIAGNÓSTICO: PROBLEMA DE USER_ID EM PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Diagnosticar problemas com user_id na tabela players
-- antes de aplicar correções
-- =====================================================

-- =====================================================
-- 1. VERIFICAÇÃO GERAL DA ESTRUTURA
-- =====================================================

-- Verificar se as tabelas existem
SELECT 
    'VERIFICAÇÃO DE EXISTÊNCIA DAS TABELAS' as categoria,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'users') 
        THEN '✅ Tabela users existe'
        ELSE '❌ Tabela users NÃO existe'
    END as status_users,
    CASE 
        WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'players') 
        THEN '✅ Tabela players existe'
        ELSE '❌ Tabela players NÃO existe'
    END as status_players;

-- Verificar estrutura da tabela players
SELECT 
    'ESTRUTURA DA TABELA PLAYERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'players' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Verificar estrutura da tabela users
SELECT 
    'ESTRUTURA DA TABELA USERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- 2. ANÁLISE DOS DADOS
-- =====================================================

-- Contar registros em cada tabela
SELECT 
    'CONTAGEM DE REGISTROS' as categoria,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM game_players) as total_game_players;

-- Analisar players com e sem user_id
SELECT 
    'ANÁLISE DE PLAYERS POR USER_ID' as categoria,
    CASE 
        WHEN user_id IS NULL THEN 'SEM USER_ID'
        ELSE 'COM USER_ID'
    END as status,
    COUNT(*) as quantidade,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM players), 2) as percentual
FROM players
GROUP BY (user_id IS NULL)
ORDER BY quantidade DESC;

-- =====================================================
-- 3. DETALHES DOS PLAYERS SEM USER_ID
-- =====================================================

-- Listar players sem user_id com detalhes
SELECT 
    'DETALHES DOS PLAYERS SEM USER_ID' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.phone_number,
    p.birth_date,
    p.primary_position,
    p.status as player_status,
    p.created_at as player_created_at,
    COUNT(gp.id) as relacionamentos_game_players
FROM players p
LEFT JOIN game_players gp ON p.id = gp.player_id
WHERE p.user_id IS NULL
GROUP BY p.id, p.name, p.phone_number, p.birth_date, p.primary_position, p.status, p.created_at
ORDER BY p.created_at DESC;

-- =====================================================
-- 4. ANÁLISE DE POSSÍVEIS MATCHES
-- =====================================================

-- Verificar se há telefones que podem ser usados para matching
SELECT 
    'POSSÍVEIS MATCHES POR TELEFONE' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.phone_number as player_phone,
    u.id as user_id,
    u.email as user_email,
    u.name as user_name,
    u.phone as user_phone
FROM players p
LEFT JOIN users u ON p.phone_number = u.phone
WHERE p.user_id IS NULL 
AND p.phone_number IS NOT NULL
AND p.phone_number != '00000000000'
ORDER BY p.phone_number;

-- Verificar telefones duplicados entre players
SELECT 
    'TELEFONES DUPLICADOS ENTRE PLAYERS' as categoria,
    phone_number,
    COUNT(*) as quantidade_players,
    STRING_AGG(name, ', ') as nomes_players,
    STRING_AGG(id::text, ', ') as ids_players
FROM players
WHERE phone_number IS NOT NULL 
AND phone_number != '00000000000'
GROUP BY phone_number
HAVING COUNT(*) > 1
ORDER BY quantidade_players DESC;

-- Verificar telefones duplicados entre users
SELECT 
    'TELEFONES DUPLICADOS ENTRE USERS' as categoria,
    phone,
    COUNT(*) as quantidade_users,
    STRING_AGG(name, ', ') as nomes_users,
    STRING_AGG(id::text, ', ') as ids_users
FROM users
WHERE phone IS NOT NULL
GROUP BY phone
HAVING COUNT(*) > 1
ORDER BY quantidade_users DESC;

-- =====================================================
-- 5. ANÁLISE DE RELACIONAMENTOS
-- =====================================================

-- Verificar relacionamentos game_players com players sem user_id
SELECT 
    'RELACIONAMENTOS GAME_PLAYERS COM PLAYERS SEM USER_ID' as categoria,
    gp.id as game_player_id,
    gp.game_id,
    gp.player_id,
    gp.player_type,
    gp.status as game_player_status,
    p.name as player_name,
    p.phone_number as player_phone
FROM game_players gp
JOIN players p ON gp.player_id = p.id
WHERE p.user_id IS NULL
ORDER BY gp.created_at DESC;

-- Verificar jogos que têm players sem user_id
SELECT 
    'JOGOS COM PLAYERS SEM USER_ID' as categoria,
    g.id as game_id,
    g.organization_name as game_name,
    COUNT(gp.id) as players_sem_user_id
FROM games g
JOIN game_players gp ON g.id = gp.game_id
JOIN players p ON gp.player_id = p.id
WHERE p.user_id IS NULL
GROUP BY g.id, g.organization_name
ORDER BY players_sem_user_id DESC;

-- =====================================================
-- 6. ANÁLISE DE INTEGRIDADE
-- =====================================================

-- Verificar se há users órfãos (sem player)
SELECT 
    'USERS SEM PERFIL DE PLAYER' as categoria,
    u.id as user_id,
    u.email,
    u.name as user_name,
    u.phone,
    u.created_at as user_created_at
FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM players p WHERE p.user_id = u.id
)
ORDER BY u.created_at DESC;

-- Verificar se há players com user_id inválido
SELECT 
    'PLAYERS COM USER_ID INVÁLIDO' as categoria,
    p.id as player_id,
    p.name as player_name,
    p.user_id,
    u.id as user_exists,
    u.email as user_email
FROM players p
LEFT JOIN users u ON p.user_id = u.id
WHERE p.user_id IS NOT NULL
AND u.id IS NULL
ORDER BY p.created_at DESC;

-- =====================================================
-- 7. ESTATÍSTICAS RESUMIDAS
-- =====================================================

-- Estatísticas gerais
SELECT 
    'ESTATÍSTICAS RESUMIDAS' as categoria,
    (SELECT COUNT(*) FROM users) as total_users,
    (SELECT COUNT(*) FROM players) as total_players,
    (SELECT COUNT(*) FROM players WHERE user_id IS NOT NULL) as players_com_user_id,
    (SELECT COUNT(*) FROM players WHERE user_id IS NULL) as players_sem_user_id,
    (SELECT COUNT(*) FROM game_players) as total_game_players,
    (SELECT COUNT(*) FROM game_players gp JOIN players p ON gp.player_id = p.id WHERE p.user_id IS NULL) as game_players_com_players_sem_user_id;

-- Percentual de integridade
SELECT 
    'PERCENTUAL DE INTEGRIDADE' as categoria,
    ROUND(
        (SELECT COUNT(*) FROM players WHERE user_id IS NOT NULL) * 100.0 / 
        (SELECT COUNT(*) FROM players), 2
    ) as percentual_players_com_user_id,
    ROUND(
        (SELECT COUNT(*) FROM game_players gp JOIN players p ON gp.player_id = p.id WHERE p.user_id IS NOT NULL) * 100.0 / 
        (SELECT COUNT(*) FROM game_players), 2
    ) as percentual_game_players_integrity;

-- =====================================================
-- 8. RECOMENDAÇÕES
-- =====================================================

DO $$
DECLARE
    players_sem_user_id INTEGER;
    possiveis_matches INTEGER;
    users_orfos INTEGER;
    telefones_duplicados INTEGER;
BEGIN
    -- Contar problemas
    SELECT COUNT(*) INTO players_sem_user_id FROM players WHERE user_id IS NULL;
    SELECT COUNT(*) INTO possiveis_matches FROM players p JOIN users u ON p.phone_number = u.phone WHERE p.user_id IS NULL AND p.phone_number IS NOT NULL AND p.phone_number != '00000000000';
    SELECT COUNT(*) INTO users_orfos FROM users u WHERE NOT EXISTS (SELECT 1 FROM players p WHERE p.user_id = u.id);
    SELECT COUNT(*) INTO telefones_duplicados FROM (SELECT phone_number FROM players WHERE phone_number IS NOT NULL AND phone_number != '00000000000' GROUP BY phone_number HAVING COUNT(*) > 1) as duplicados;
    
    RAISE NOTICE '=== RECOMENDAÇÕES ===';
    RAISE NOTICE '📊 Players sem user_id: %', players_sem_user_id;
    RAISE NOTICE '📊 Possíveis matches por telefone: %', possiveis_matches;
    RAISE NOTICE '📊 Users órfãos: %', users_orfos;
    RAISE NOTICE '📊 Telefones duplicados entre players: %', telefones_duplicados;
    
    IF players_sem_user_id = 0 THEN
        RAISE NOTICE '✅ SITUAÇÃO: Todos os players têm user_id - Nenhuma correção necessária';
    ELSIF possiveis_matches > 0 THEN
        RAISE NOTICE '💡 RECOMENDAÇÃO: Execute correção automática - há % possíveis matches', possiveis_matches;
    ELSE
        RAISE NOTICE '⚠️ RECOMENDAÇÃO: Análise manual necessária - criar usuários para players restantes';
    END IF;
    
    IF telefones_duplicados > 0 THEN
        RAISE NOTICE '⚠️ ATENÇÃO: Há % telefones duplicados - verificar antes de corrigir', telefones_duplicados;
    END IF;
    
    IF users_orfos > 0 THEN
        RAISE NOTICE 'ℹ️ INFO: Há % users órfãos - considerar limpeza', users_orfos;
    END IF;
END $$;
