-- =====================================================
-- SUPORTE A MÚLTIPLOS ADMINISTRADORES POR JOGO
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- Este script adiciona suporte para múltiplos administradores
-- em um jogo, permitindo que qualquer administrador possa
-- promover outros jogadores a administradores
-- =====================================================

-- 1. Adicionar coluna is_admin na tabela game_players
ALTER TABLE public.game_players 
ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;

-- 2. Adicionar comentário para documentação
COMMENT ON COLUMN public.game_players.is_admin IS 'Indica se o jogador é administrador do jogo';

-- 3. Criar índice para consultas de administradores
CREATE INDEX IF NOT EXISTS idx_game_players_is_admin 
ON public.game_players(game_id, is_admin) 
WHERE is_admin = TRUE;

-- 4. Atualizar jogadores existentes que são administradores do jogo
-- (baseado na coluna user_id da tabela games)
UPDATE public.game_players 
SET is_admin = TRUE
WHERE EXISTS (
    SELECT 1 
    FROM public.games g
    JOIN public.players p ON p.user_id = g.user_id
    WHERE g.id = game_players.game_id 
    AND p.id = game_players.player_id
);

-- 5. Verificar quantos administradores foram atualizados
SELECT 
    'ADMINISTRADORES ATUALIZADOS' as categoria,
    COUNT(*) as total_administradores,
    COUNT(DISTINCT game_id) as jogos_com_administradores
FROM public.game_players 
WHERE is_admin = TRUE;

-- 6. Listar jogos e seus administradores
SELECT 
    'JOGOS E ADMINISTRADORES' as categoria,
    g.organization_name as nome_jogo,
    g.location as local,
    COUNT(gp.id) as total_administradores,
    STRING_AGG(p.name, ', ') as nomes_administradores
FROM public.games g
LEFT JOIN public.game_players gp ON g.id = gp.game_id AND gp.is_admin = TRUE
LEFT JOIN public.players p ON gp.player_id = p.id
GROUP BY g.id, g.organization_name, g.location
ORDER BY g.organization_name;

-- 7. Verificar estrutura final da tabela
SELECT 
    'ESTRUTURA FINAL GAME_PLAYERS' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'game_players' 
AND table_schema = 'public'
ORDER BY ordinal_position;




