-- =====================================================
-- MIGRAÇÃO: MOVER TIPO DE JOGADOR PARA game_players
-- Sistema: VaiDarJogo Flutter
-- Data: $(date)
-- =====================================================
-- 
-- OBJETIVO: Mover o atributo "type" (mensalista/avulso) da tabela 'players'
-- para a tabela 'game_players', permitindo que um jogador seja mensalista
-- em um jogo e avulso em outro.
--
-- MUDANÇAS:
-- 1. Adicionar coluna 'player_type' na tabela 'game_players'
-- 2. Migrar dados existentes da tabela 'players' para 'game_players'
-- 3. Remover coluna 'type' da tabela 'players'
-- 4. Atualizar políticas RLS se necessário
-- =====================================================

-- Verificar estrutura atual
DO $$
DECLARE
    players_has_type boolean;
    game_players_has_player_type boolean;
BEGIN
    RAISE NOTICE '=== VERIFICANDO ESTRUTURA ATUAL ===';
    
    -- Verificar se tabela players tem coluna type
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' 
        AND column_name = 'type'
        AND table_schema = 'public'
    ) INTO players_has_type;
    
    -- Verificar se tabela game_players tem coluna player_type
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'game_players' 
        AND column_name = 'player_type'
        AND table_schema = 'public'
    ) INTO game_players_has_player_type;
    
    RAISE NOTICE 'Tabela players tem coluna type: %', players_has_type;
    RAISE NOTICE 'Tabela game_players tem coluna player_type: %', game_players_has_player_type;
END $$;

-- =====================================================
-- PASSO 1: ADICIONAR COLUNA player_type NA TABELA game_players
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== PASSO 1: ADICIONANDO COLUNA player_type ===';
    
    -- Adicionar coluna player_type se não existir
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'game_players' 
        AND column_name = 'player_type'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE game_players 
        ADD COLUMN player_type VARCHAR(20) DEFAULT 'casual' 
        CHECK (player_type IN ('monthly', 'casual'));
        
        RAISE NOTICE '✅ Coluna player_type adicionada à tabela game_players';
    ELSE
        RAISE NOTICE 'ℹ️ Coluna player_type já existe na tabela game_players';
    END IF;
END $$;

-- =====================================================
-- PASSO 2: MIGRAR DADOS EXISTENTES
-- =====================================================

DO $$
DECLARE
    migrated_count integer := 0;
    total_relations integer := 0;
BEGIN
    RAISE NOTICE '=== PASSO 2: MIGRANDO DADOS EXISTENTES ===';
    
    -- Contar total de relacionamentos
    SELECT COUNT(*) INTO total_relations FROM game_players;
    RAISE NOTICE 'Total de relacionamentos game_players: %', total_relations;
    
    -- Migrar dados da tabela players para game_players
    -- Atualizar game_players com o tipo do jogador correspondente
    UPDATE game_players 
    SET player_type = players.type
    FROM players 
    WHERE game_players.player_id = players.id
    AND game_players.player_type IS NULL;
    
    GET DIAGNOSTICS migrated_count = ROW_COUNT;
    RAISE NOTICE '✅ Dados migrados: % relacionamentos atualizados', migrated_count;
    
    -- Verificar se ainda há registros sem player_type
    SELECT COUNT(*) INTO total_relations 
    FROM game_players 
    WHERE player_type IS NULL;
    
    IF total_relations > 0 THEN
        RAISE NOTICE '⚠️ Ainda existem % registros sem player_type, definindo como casual', total_relations;
        UPDATE game_players 
        SET player_type = 'casual' 
        WHERE player_type IS NULL;
    END IF;
END $$;

-- =====================================================
-- PASSO 3: DEFINIR VALOR PADRÃO E NOT NULL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== PASSO 3: CONFIGURANDO CONSTRAINTS ===';
    
    -- Alterar coluna para NOT NULL com valor padrão
    ALTER TABLE game_players 
    ALTER COLUMN player_type SET NOT NULL,
    ALTER COLUMN player_type SET DEFAULT 'casual';
    
    RAISE NOTICE '✅ Coluna player_type configurada como NOT NULL com padrão casual';
END $$;

-- =====================================================
-- PASSO 4: CRIAR ÍNDICE PARA PERFORMANCE
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== PASSO 4: CRIANDO ÍNDICES ===';
    
    -- Criar índice para consultas por tipo de jogador
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'game_players' 
        AND indexname = 'idx_game_players_player_type'
    ) THEN
        CREATE INDEX idx_game_players_player_type ON game_players(player_type);
        RAISE NOTICE '✅ Índice idx_game_players_player_type criado';
    ELSE
        RAISE NOTICE 'ℹ️ Índice idx_game_players_player_type já existe';
    END IF;
    
    -- Criar índice composto para consultas por jogo e tipo
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes 
        WHERE tablename = 'game_players' 
        AND indexname = 'idx_game_players_game_type'
    ) THEN
        CREATE INDEX idx_game_players_game_type ON game_players(game_id, player_type);
        RAISE NOTICE '✅ Índice idx_game_players_game_type criado';
    ELSE
        RAISE NOTICE 'ℹ️ Índice idx_game_players_game_type já existe';
    END IF;
END $$;

-- =====================================================
-- PASSO 5: ATUALIZAR POLÍTICAS RLS (SE NECESSÁRIO)
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== PASSO 5: VERIFICANDO POLÍTICAS RLS ===';
    
    -- Verificar se RLS está habilitado
    IF EXISTS (
        SELECT 1 FROM pg_class 
        WHERE relname = 'game_players' 
        AND relrowsecurity = true
    ) THEN
        RAISE NOTICE '✅ RLS já está habilitado na tabela game_players';
        
        -- Listar políticas existentes
        RAISE NOTICE 'Políticas RLS existentes:';
        FOR rec IN 
            SELECT policyname, cmd, permissive 
            FROM pg_policies 
            WHERE tablename = 'game_players'
        LOOP
            RAISE NOTICE '- %: % (%)', rec.policyname, rec.cmd, rec.permissive;
        END LOOP;
    ELSE
        RAISE NOTICE '⚠️ RLS não está habilitado na tabela game_players';
    END IF;
END $$;

-- =====================================================
-- PASSO 6: VERIFICAÇÃO FINAL
-- =====================================================

DO $$
DECLARE
    total_relations integer;
    monthly_count integer;
    casual_count integer;
    null_count integer;
BEGIN
    RAISE NOTICE '=== PASSO 6: VERIFICAÇÃO FINAL ===';
    
    -- Contar total de relacionamentos
    SELECT COUNT(*) INTO total_relations FROM game_players;
    
    -- Contar por tipo
    SELECT COUNT(*) INTO monthly_count 
    FROM game_players 
    WHERE player_type = 'monthly';
    
    SELECT COUNT(*) INTO casual_count 
    FROM game_players 
    WHERE player_type = 'casual';
    
    SELECT COUNT(*) INTO null_count 
    FROM game_players 
    WHERE player_type IS NULL;
    
    RAISE NOTICE '📊 ESTATÍSTICAS FINAIS:';
    RAISE NOTICE 'Total de relacionamentos: %', total_relations;
    RAISE NOTICE 'Jogadores mensalistas: %', monthly_count;
    RAISE NOTICE 'Jogadores avulsos: %', casual_count;
    RAISE NOTICE 'Registros nulos: %', null_count;
    
    IF null_count = 0 THEN
        RAISE NOTICE '✅ MIGRAÇÃO CONCLUÍDA COM SUCESSO!';
    ELSE
        RAISE NOTICE '⚠️ Ainda existem registros nulos - verificar migração';
    END IF;
END $$;

-- =====================================================
-- PASSO 7: REMOVER COLUNA type DA TABELA players (OPCIONAL)
-- =====================================================
-- 
-- ATENÇÃO: Este passo é OPCIONAL e deve ser executado apenas
-- após confirmar que a migração foi bem-sucedida e que o
-- código da aplicação foi atualizado para usar a nova estrutura.
--
-- Para executar este passo, descomente as linhas abaixo:
--
-- DO $$
-- BEGIN
--     RAISE NOTICE '=== PASSO 7: REMOVENDO COLUNA type DA TABELA players ===';
--     
--     -- Verificar se coluna type existe
--     IF EXISTS (
--         SELECT 1 FROM information_schema.columns 
--         WHERE table_name = 'players' 
--         AND column_name = 'type'
--         AND table_schema = 'public'
--     ) THEN
--         ALTER TABLE players DROP COLUMN type;
--         RAISE NOTICE '✅ Coluna type removida da tabela players';
--     ELSE
--         RAISE NOTICE 'ℹ️ Coluna type não existe na tabela players';
--     END IF;
-- END $$;

-- =====================================================
-- SCRIPT CONCLUÍDO
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== MIGRAÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'O tipo de jogador (mensalista/avulso) agora é armazenado na tabela game_players.';
    RAISE NOTICE 'Cada relacionamento jogador-jogo pode ter seu próprio tipo.';
    RAISE NOTICE '=====================================';
END $$;
