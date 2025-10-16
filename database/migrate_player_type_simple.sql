-- =====================================================
-- MIGRAÇÃO SIMPLES: MOVER TIPO DE JOGADOR PARA game_players
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Mover o atributo "type" (mensalista/avulso) da tabela 'players'
-- para a tabela 'game_players', permitindo que um jogador seja mensalista
-- em um jogo e avulso em outro.
-- =====================================================

-- PASSO 1: Adicionar coluna player_type na tabela game_players
ALTER TABLE game_players 
ADD COLUMN IF NOT EXISTS player_type VARCHAR(20) DEFAULT 'casual' 
CHECK (player_type IN ('monthly', 'casual'));

-- PASSO 2: Migrar dados existentes da tabela players para game_players
UPDATE game_players 
SET player_type = players.type
FROM players 
WHERE game_players.player_id = players.id
AND game_players.player_type IS NULL;

-- PASSO 3: Definir valores padrão para registros sem tipo
UPDATE game_players 
SET player_type = 'casual' 
WHERE player_type IS NULL;

-- PASSO 4: Alterar coluna para NOT NULL
ALTER TABLE game_players 
ALTER COLUMN player_type SET NOT NULL;

-- PASSO 5: Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_game_players_player_type ON game_players(player_type);
CREATE INDEX IF NOT EXISTS idx_game_players_game_type ON game_players(game_id, player_type);

-- PASSO 6: Verificação final
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

