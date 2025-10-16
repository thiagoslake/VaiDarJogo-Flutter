-- =====================================================
-- REMOVER COLUNA type DA TABELA players
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ATENÇÃO: Execute este script APENAS após:
-- 1. Executar migrate_player_type_to_game_players.sql
-- 2. Atualizar o código da aplicação
-- 3. Testar completamente o sistema
-- 4. Confirmar que tudo está funcionando
--
-- Este script remove a coluna 'type' da tabela 'players'
-- pois agora o tipo é armazenado na tabela 'game_players'
-- =====================================================

-- Verificar se a coluna type existe na tabela players
DO $$
DECLARE
    type_column_exists boolean;
BEGIN
    RAISE NOTICE '=== VERIFICANDO COLUNA type NA TABELA players ===';
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' 
        AND column_name = 'type'
        AND table_schema = 'public'
    ) INTO type_column_exists;
    
    IF type_column_exists THEN
        RAISE NOTICE '✅ Coluna type encontrada na tabela players';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna type não existe na tabela players';
    END IF;
END $$;

-- Verificar se a coluna player_type existe na tabela game_players
DO $$
DECLARE
    player_type_column_exists boolean;
BEGIN
    RAISE NOTICE '=== VERIFICANDO COLUNA player_type NA TABELA game_players ===';
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'game_players' 
        AND column_name = 'player_type'
        AND table_schema = 'public'
    ) INTO player_type_column_exists;
    
    IF player_type_column_exists THEN
        RAISE NOTICE '✅ Coluna player_type encontrada na tabela game_players';
    ELSE
        RAISE NOTICE '❌ Coluna player_type NÃO encontrada na tabela game_players';
        RAISE NOTICE '⚠️ NÃO execute este script até que a migração seja concluída!';
        RETURN;
    END IF;
END $$;

-- Verificar se há dados na tabela game_players
DO $$
DECLARE
    total_relations integer;
    relations_with_type integer;
BEGIN
    RAISE NOTICE '=== VERIFICANDO DADOS NA TABELA game_players ===';
    
    SELECT COUNT(*) INTO total_relations FROM game_players;
    SELECT COUNT(*) INTO relations_with_type 
    FROM game_players 
    WHERE player_type IS NOT NULL;
    
    RAISE NOTICE 'Total de relacionamentos: %', total_relations;
    RAISE NOTICE 'Relacionamentos com player_type: %', relations_with_type;
    
    IF total_relations > 0 AND relations_with_type = 0 THEN
        RAISE NOTICE '❌ Nenhum relacionamento tem player_type definido!';
        RAISE NOTICE '⚠️ Execute primeiro o script de migração!';
        RETURN;
    END IF;
END $$;

-- Remover a coluna type da tabela players
DO $$
BEGIN
    RAISE NOTICE '=== REMOVENDO COLUNA type DA TABELA players ===';
    
    -- Verificar se coluna type existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' 
        AND column_name = 'type'
        AND table_schema = 'public'
    ) THEN
        -- Remover a coluna
        ALTER TABLE players DROP COLUMN type;
        RAISE NOTICE '✅ Coluna type removida da tabela players';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna type não existe na tabela players';
    END IF;
END $$;

-- Verificação final
DO $$
DECLARE
    type_column_exists boolean;
    player_type_column_exists boolean;
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    
    -- Verificar se coluna type foi removida
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' 
        AND column_name = 'type'
        AND table_schema = 'public'
    ) INTO type_column_exists;
    
    -- Verificar se coluna player_type existe
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'game_players' 
        AND column_name = 'player_type'
        AND table_schema = 'public'
    ) INTO player_type_column_exists;
    
    IF NOT type_column_exists AND player_type_column_exists THEN
        RAISE NOTICE '✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!';
        RAISE NOTICE '✅ Coluna type removida da tabela players';
        RAISE NOTICE '✅ Coluna player_type disponível na tabela game_players';
    ELSE
        RAISE NOTICE '❌ ERRO NA MIGRAÇÃO!';
        RAISE NOTICE 'Coluna type ainda existe em players: %', type_column_exists;
        RAISE NOTICE 'Coluna player_type existe em game_players: %', player_type_column_exists;
    END IF;
END $$;

-- =====================================================
-- SCRIPT CONCLUÍDO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== LIMPEZA CONCLUÍDA ===';
    RAISE NOTICE 'A coluna type foi removida da tabela players.';
    RAISE NOTICE 'O tipo de jogador agora é armazenado apenas em game_players.';
    RAISE NOTICE '=====================================';
END $$;
