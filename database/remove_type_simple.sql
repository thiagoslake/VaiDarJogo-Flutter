-- =====================================================
-- REMOVER COLUNA type DA TABELA players (VERSÃO SIMPLES)
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ATENÇÃO: Execute este script APENAS após:
-- 1. Executar migrate_player_type_simple.sql
-- 2. Atualizar o código da aplicação
-- 3. Testar completamente o sistema
-- 4. Confirmar que tudo está funcionando
-- =====================================================

-- Verificar se a coluna type existe na tabela players
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'players' 
            AND column_name = 'type'
            AND table_schema = 'public'
        ) THEN 'Coluna type EXISTE na tabela players'
        ELSE 'Coluna type NÃO EXISTE na tabela players'
    END as status_coluna_type;

-- Verificar se a coluna player_type existe na tabela game_players
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'game_players' 
            AND column_name = 'player_type'
            AND table_schema = 'public'
        ) THEN 'Coluna player_type EXISTE na tabela game_players'
        ELSE 'Coluna player_type NÃO EXISTE na tabela game_players'
    END as status_coluna_player_type;

-- Verificar se há dados na tabela game_players
SELECT 
    'Total de relacionamentos' as descricao,
    COUNT(*) as quantidade
FROM game_players
UNION ALL
SELECT 
    'Relacionamentos com player_type' as descricao,
    COUNT(*) as quantidade
FROM game_players 
WHERE player_type IS NOT NULL;

-- Remover a coluna type da tabela players (se existir)
ALTER TABLE players DROP COLUMN IF EXISTS type;

-- Verificação final
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'players' 
            AND column_name = 'type'
            AND table_schema = 'public'
        ) THEN 'ERRO: Coluna type ainda existe'
        ELSE 'SUCESSO: Coluna type foi removida'
    END as resultado_final;

