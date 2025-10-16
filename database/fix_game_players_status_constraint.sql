-- =====================================================
-- CORRIGIR CONSTRAINT DE STATUS NA TABELA GAME_PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir constraint de status que está causando erro
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para corrigir constraint de status
-- 2. Permite valores corretos para status
-- 3. Atualiza registros existentes se necessário
-- =====================================================

-- =====================================================
-- 1. REMOVER CONSTRAINT EXISTENTE (SE HOUVER)
-- =====================================================

DO $$
DECLARE
    constraint_name TEXT;
BEGIN
    -- Buscar nome da constraint de status
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'public.game_players'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%status%';
    
    IF constraint_name IS NOT NULL THEN
        -- Remover constraint existente
        EXECUTE 'ALTER TABLE public.game_players DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE '✅ Constraint % removida', constraint_name;
    ELSE
        RAISE NOTICE 'ℹ️ Nenhuma constraint de status encontrada';
    END IF;
END
$$;

-- =====================================================
-- 2. CRIAR NOVA CONSTRAINT CORRETA
-- =====================================================

DO $$
BEGIN
    -- Criar nova constraint que permite valores corretos
    ALTER TABLE public.game_players 
    ADD CONSTRAINT game_players_status_check 
    CHECK (status IN ('active', 'inactive', 'pending', 'confirmed', 'rejected'));
    
    RAISE NOTICE '✅ Nova constraint de status criada';
EXCEPTION
    WHEN duplicate_object THEN
        RAISE NOTICE 'ℹ️ Constraint já existe';
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Erro ao criar constraint: %', SQLERRM;
END
$$;

-- =====================================================
-- 3. ATUALIZAR REGISTROS COM STATUS INVÁLIDO
-- =====================================================

DO $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== ATUALIZANDO REGISTROS COM STATUS INVÁLIDO ===';
    
    -- Atualizar registros com status inválido para 'active'
    UPDATE public.game_players 
    SET status = 'active'
    WHERE status NOT IN ('active', 'inactive', 'pending', 'confirmed', 'rejected')
       OR status IS NULL;
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ % registros atualizados para status válido', updated_count;
END
$$;

-- =====================================================
-- 4. VERIFICAR RESULTADO
-- =====================================================

SELECT 
    'Total de registros' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
UNION ALL
SELECT 
    'Registros com status válido' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status IN ('active', 'inactive', 'pending', 'confirmed', 'rejected')
UNION ALL
SELECT 
    'Registros com status inválido' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE status NOT IN ('active', 'inactive', 'pending', 'confirmed', 'rejected')
   OR status IS NULL;

-- =====================================================
-- 5. MOSTRAR DISTRIBUIÇÃO DE STATUS
-- =====================================================

SELECT 
    status,
    COUNT(*) as quantidade,
    CASE 
        WHEN status = 'active' THEN '✅ Ativo'
        WHEN status = 'inactive' THEN '❌ Inativo'
        WHEN status = 'pending' THEN '⏳ Pendente'
        WHEN status = 'confirmed' THEN '✅ Confirmado'
        WHEN status = 'rejected' THEN '❌ Rejeitado'
        ELSE '❓ Desconhecido'
    END as descricao
FROM public.game_players
GROUP BY status
ORDER BY quantidade DESC;

-- =====================================================
-- 6. VERIFICAR CONSTRAINT CRIADA
-- =====================================================

SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.game_players'::regclass
  AND contype = 'c'
  AND conname = 'game_players_status_check';




