-- =====================================================
-- GARANTIR TELEFONE NA TABELA USERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Garantir que o telefone seja inserido na tabela users
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute para garantir inserção do telefone
-- 2. Funciona independentemente de triggers
-- 3. Atualiza telefones existentes se necessário
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ESTRUTURA DA TABELA USERS
-- =====================================================

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'users'
  AND column_name = 'phone';

-- =====================================================
-- 2. CRIAR COLUNA PHONE SE NÃO EXISTIR
-- =====================================================

DO $$
BEGIN
    -- Verificar se a coluna phone existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'users' 
          AND column_name = 'phone'
    ) THEN
        -- Criar coluna phone
        ALTER TABLE public.users ADD COLUMN phone VARCHAR(20);
        RAISE NOTICE '✅ Coluna phone criada na tabela users';
    ELSE
        RAISE NOTICE '✅ Coluna phone já existe na tabela users';
    END IF;
END
$$;

-- =====================================================
-- 3. ATUALIZAR TELEFONES DOS USUÁRIOS EXISTENTES
-- =====================================================

DO $$
DECLARE
    user_record RECORD;
    updated_count INTEGER := 0;
BEGIN
    RAISE NOTICE '=== ATUALIZANDO TELEFONES DOS USUÁRIOS ===';
    
    -- Para cada usuário que não tem telefone, tentar buscar dos metadados
    FOR user_record IN 
        SELECT 
            pu.id,
            pu.email,
            au.raw_user_meta_data->>'phone' as phone_from_metadata
        FROM public.users pu
        LEFT JOIN auth.users au ON pu.id = au.id
        WHERE (pu.phone IS NULL OR pu.phone = '')
          AND au.raw_user_meta_data->>'phone' IS NOT NULL
          AND au.raw_user_meta_data->>'phone' != ''
    LOOP
        -- Atualizar telefone na tabela users
        UPDATE public.users 
        SET phone = user_record.phone_from_metadata,
            updated_at = NOW()
        WHERE id = user_record.id;
        
        updated_count := updated_count + 1;
        RAISE NOTICE '✅ Telefone atualizado para usuário %: %', user_record.email, user_record.phone_from_metadata;
    END LOOP;
    
    RAISE NOTICE '=== ATUALIZAÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'Total de usuários atualizados: %', updated_count;
END
$$;

-- =====================================================
-- 4. VERIFICAR RESULTADO FINAL
-- =====================================================

SELECT 
    'Total de usuários' as categoria,
    COUNT(*) as quantidade
FROM public.users
UNION ALL
SELECT 
    'Usuários com telefone' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NOT NULL AND phone != ''
UNION ALL
SELECT 
    'Usuários sem telefone' as categoria,
    COUNT(*) as quantidade
FROM public.users
WHERE phone IS NULL OR phone = '';

-- =====================================================
-- 5. MOSTRAR DADOS ATUALIZADOS
-- =====================================================

SELECT 
    id,
    email,
    name,
    phone,
    created_at
FROM public.users
WHERE phone IS NOT NULL AND phone != ''
ORDER BY created_at DESC
LIMIT 10;




