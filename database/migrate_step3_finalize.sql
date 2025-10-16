-- =====================================================
-- MIGRAÇÃO PASSO 3: FINALIZAR ESTRUTURA
-- =====================================================

-- Alterar coluna para NOT NULL
ALTER TABLE game_players 
ALTER COLUMN player_type SET NOT NULL;

-- Criar índices para performance
CREATE INDEX IF NOT EXISTS idx_game_players_player_type ON game_players(player_type);
CREATE INDEX IF NOT EXISTS idx_game_players_game_type ON game_players(game_id, player_type);

-- Verificação final
SELECT 
    'MIGRAÇÃO CONCLUÍDA' as status,
    COUNT(*) as total_relacionamentos,
    SUM(CASE WHEN player_type = 'monthly' THEN 1 ELSE 0 END) as mensalistas,
    SUM(CASE WHEN player_type = 'casual' THEN 1 ELSE 0 END) as avulsos
FROM game_players;

