-- =====================================================
-- ADICIONAR COLUNA IS_ADMIN À TABELA GAME_PLAYERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Adicionar coluna is_admin se não existir
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para adicionar coluna is_admin
-- 2. Define valor padrão como false
-- 3. Atualiza registros existentes
-- =====================================================

-- =====================================================
-- 1. VERIFICAR SE COLUNA JÁ EXISTE
-- =====================================================

DO $$
BEGIN
    -- Verificar se a coluna is_admin existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'game_players' 
          AND column_name = 'is_admin'
    ) THEN
        -- Adicionar coluna is_admin
        ALTER TABLE public.game_players 
        ADD COLUMN is_admin BOOLEAN DEFAULT false;
        
        RAISE NOTICE '✅ Coluna is_admin adicionada à tabela game_players';
    ELSE
        RAISE NOTICE '✅ Coluna is_admin já existe na tabela game_players';
    END IF;
END
$$;

-- =====================================================
-- 2. ATUALIZAR REGISTROS EXISTENTES
-- =====================================================

DO $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== ATUALIZANDO REGISTROS EXISTENTES ===';
    
    -- Para jogadores que são criadores de jogos, definir como administradores
    UPDATE public.game_players 
    SET is_admin = true
    WHERE id IN (
        SELECT gp.id
        FROM public.game_players gp
        JOIN public.players p ON gp.player_id = p.id
        JOIN public.games g ON gp.game_id = g.id
        WHERE p.user_id = g.user_id
          AND (gp.is_admin IS NULL OR gp.is_admin = false)
    );
    
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    RAISE NOTICE '✅ % registros atualizados para administradores', updated_count;
END
$$;

-- =====================================================
-- 3. VERIFICAR RESULTADO
-- =====================================================

SELECT 
    'Total de registros' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
UNION ALL
SELECT 
    'Administradores (is_admin = true)' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE is_admin = true
UNION ALL
SELECT 
    'Não administradores (is_admin = false)' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE is_admin = false
UNION ALL
SELECT 
    'Indefinidos (is_admin IS NULL)' as categoria,
    COUNT(*) as quantidade
FROM public.game_players
WHERE is_admin IS NULL;

-- =====================================================
-- 4. MOSTRAR REGISTROS ATUALIZADOS
-- =====================================================

SELECT 
    gp.id,
    g.organization_name,
    p.name as player_name,
    u.email as player_email,
    gp.player_type,
    gp.is_admin,
    gp.joined_at
FROM public.game_players gp
JOIN public.players p ON gp.player_id = p.id
JOIN public.users u ON p.user_id = u.id
JOIN public.games g ON gp.game_id = g.id
WHERE gp.is_admin = true
ORDER BY gp.joined_at DESC
LIMIT 10;




