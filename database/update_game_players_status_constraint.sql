-- =====================================================
-- ATUALIZAR CONSTRAINT DE STATUS PARA PERMITIR 'CONFIRMED'
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Atualizar constraint para permitir valor 'confirmed'
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para permitir status 'confirmed'
-- 2. Mantém compatibilidade com valores existentes
-- 3. Permite uso de 'confirmed' no código
-- =====================================================

-- =====================================================
-- 1. REMOVER CONSTRAINT EXISTENTE
-- =====================================================

DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Buscar e remover constraint existente
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'public.game_players'::regclass
      AND contype = 'c'
      AND (conname LIKE '%status%' OR pg_get_constraintdef(oid) LIKE '%status%');
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.game_players DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE '✅ Constraint % removida', constraint_name;
    ELSE
        RAISE NOTICE 'ℹ️ Nenhuma constraint de status encontrada';
    END IF;
END
$$;

-- =====================================================
-- 2. CRIAR NOVA CONSTRAINT COM VALORES COMPLETOS
-- =====================================================

DO $$
BEGIN
    -- Criar constraint que permite todos os valores necessários
    ALTER TABLE public.game_players 
    ADD CONSTRAINT game_players_status_check 
    CHECK (status IN (
        'active',      -- Jogador ativo no jogo
        'inactive',    -- Jogador inativo
        'pending',     -- Aguardando confirmação
        'confirmed',   -- Jogador confirmado (para criadores)
        'rejected',    -- Jogador rejeitado
        'suspended'    -- Jogador suspenso
    ));
    
    RAISE NOTICE '✅ Nova constraint de status criada com valores completos';
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'ℹ️ Constraint já existe';
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Erro ao criar constraint: %', SQLERRM;
END
$$;

-- =====================================================
-- 3. VERIFICAR CONSTRAINT CRIADA
-- =====================================================

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.game_players'::regclass
  AND contype = 'c'
  AND conname = 'game_players_status_check';

-- =====================================================
-- 4. TESTAR INSERÇÃO COM DIFERENTES STATUS
-- =====================================================

-- Este é apenas um teste - não será executado automaticamente
-- Para testar, execute manualmente:

/*
-- Teste 1: Status 'active'
INSERT INTO public.game_players (game_id, player_id, player_type, status, is_admin) 
VALUES ('test-game-id', 'test-player-id', 'monthly', 'active', true);

-- Teste 2: Status 'confirmed'  
INSERT INTO public.game_players (game_id, player_id, player_type, status, is_admin) 
VALUES ('test-game-id', 'test-player-id', 'monthly', 'confirmed', true);

-- Teste 3: Status 'pending'
INSERT INTO public.game_players (game_id, player_id, player_type, status, is_admin) 
VALUES ('test-game-id', 'test-player-id', 'monthly', 'pending', false);
*/

-- =====================================================
-- 5. MOSTRAR VALORES PERMITIDOS
-- =====================================================

SELECT 
    'Valores permitidos para status:' as info,
    'active, inactive, pending, confirmed, rejected, suspended' as valores;




