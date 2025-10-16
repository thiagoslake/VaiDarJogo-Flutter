-- =====================================================
-- MIGRAÇÃO PASSO 2: MIGRAR DADOS EXISTENTES
-- =====================================================

-- Migrar dados existentes da tabela players para game_players
UPDATE game_players 
SET player_type = players.type
FROM players 
WHERE game_players.player_id = players.id
AND game_players.player_type IS NULL;

-- Definir valores padrão para registros sem tipo
UPDATE game_players 
SET player_type = 'casual' 
WHERE player_type IS NULL;

-- Verificar migração
SELECT 
    'Total de relacionamentos' as descricao,
    COUNT(*) as quantidade
FROM game_players
UNION ALL
SELECT 
    'Jogadores mensalistas' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type = 'monthly'
UNION ALL
SELECT 
    'Jogadores avulsos' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type = 'casual';

