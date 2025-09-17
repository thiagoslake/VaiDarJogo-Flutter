-- =====================================================
-- CORREÇÃO SIMPLES PARA EMAIL NÃO CONFIRMADO
-- =====================================================
-- Execute este script no Supabase SQL Editor

-- 1. Confirmar todos os emails existentes
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 2. Verificar quantos usuários foram atualizados
DO $$
DECLARE
    updated_count INTEGER;
    total_users INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM auth.users 
    WHERE email_confirmed_at IS NOT NULL;
    
    SELECT COUNT(*) INTO total_users
    FROM auth.users;
    
    RAISE NOTICE '✅ Usuários com email confirmado: % de %', updated_count, total_users;
END $$;

-- 3. Criar função para confirmar email automaticamente em novos registros
CREATE OR REPLACE FUNCTION public.auto_confirm_new_users()
RETURNS TRIGGER AS $$
BEGIN
    -- Confirmar email automaticamente para novos usuários
    NEW.email_confirmed_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Criar trigger para confirmar email automaticamente
DROP TRIGGER IF EXISTS auto_confirm_new_users_trigger ON auth.users;
CREATE TRIGGER auto_confirm_new_users_trigger
    BEFORE INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_new_users();

-- 5. Verificar se o trigger foi criado
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'auto_confirm_new_users_trigger'
    ) THEN
        RAISE NOTICE '✅ Trigger de confirmação automática criado';
    ELSE
        RAISE NOTICE '❌ Erro ao criar trigger de confirmação automática';
    END IF;
END $$;

-- 6. Instruções finais
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 CORREÇÃO APLICADA COM SUCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 O QUE FOI FEITO:';
    RAISE NOTICE '✅ Todos os emails existentes foram confirmados';
    RAISE NOTICE '✅ Trigger criado para confirmar emails automaticamente';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Teste o login no app Flutter';
    RAISE NOTICE '2. Se ainda houver erro, vá para o painel do Supabase';
    RAISE NOTICE '3. Authentication > Settings > Email Confirmation: OFF';
    RAISE NOTICE '';
    RAISE NOTICE '💡 DICA: Para desenvolvimento, é recomendado desabilitar';
    RAISE NOTICE '   a confirmação de email no painel do Supabase.';
END $$;
