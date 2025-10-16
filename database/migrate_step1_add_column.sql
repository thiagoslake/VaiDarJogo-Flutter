-- =====================================================
-- MIGRAÇÃO PASSO 1: ADICIONAR COLUNA player_type
-- =====================================================

-- Adicionar coluna player_type na tabela game_players
ALTER TABLE game_players 
ADD COLUMN IF NOT EXISTS player_type VARCHAR(20) DEFAULT 'casual' 
CHECK (player_type IN ('monthly', 'casual'));

-- Verificar se a coluna foi adicionada
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'game_players' 
AND column_name = 'player_type';

