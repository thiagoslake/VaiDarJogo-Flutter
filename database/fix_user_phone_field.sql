-- =====================================================
-- CORRIGIR CAMPO PHONE NA TABELA USERS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Corrigir problemas com o campo phone
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se o campo phone não estiver funcionando
-- 2. Este script corrige dados de telefone dos usuários
-- 3. Não afeta dados existentes válidos
-- =====================================================

-- =====================================================
-- 1. VERIFICAR ESTRUTURA ATUAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== VERIFICANDO ESTRUTURA DA TABELA USERS ===';
    
    -- Verificar se a coluna phone existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
          AND table_name = 'users' 
          AND column_name = 'phone'
    ) THEN
        RAISE NOTICE '✅ Coluna phone existe na tabela users';
    ELSE
        RAISE NOTICE '❌ Coluna phone NÃO existe na tabela users';
        RAISE NOTICE 'Criando coluna phone...';
        
        ALTER TABLE public.users ADD COLUMN phone VARCHAR(20);
        RAISE NOTICE '✅ Coluna phone criada';
    END IF;
END
$$;

-- =====================================================
-- 2. ATUALIZAR TELEFONES DOS USUÁRIOS A PARTIR DOS METADADOS
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
        SET phone = user_record.phone_from_metadata
        WHERE id = user_record.id;
        
        updated_count := updated_count + 1;
        RAISE NOTICE '✅ Telefone atualizado para usuário %: %', user_record.email, user_record.phone_from_metadata;
    END LOOP;
    
    RAISE NOTICE '=== ATUALIZAÇÃO CONCLUÍDA ===';
    RAISE NOTICE 'Total de usuários atualizados: %', updated_count;
END
$$;

-- =====================================================
-- 3. VERIFICAR RESULTADO FINAL
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
-- 4. MOSTRAR DADOS ATUALIZADOS
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




