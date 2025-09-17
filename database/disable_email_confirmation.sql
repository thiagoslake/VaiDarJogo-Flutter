-- =====================================================
-- DESABILITAR CONFIRMAÇÃO DE EMAIL
-- =====================================================
-- Execute este script no Supabase SQL Editor para desabilitar a confirmação de email

-- 1. Verificar configurações atuais de autenticação
DO $$
DECLARE
    email_confirmation_enabled BOOLEAN;
BEGIN
    -- Verificar se a confirmação de email está habilitada
    SELECT COALESCE(
        (SELECT value::boolean FROM auth.config WHERE key = 'email_confirmation_enabled'),
        false
    ) INTO email_confirmation_enabled;
    
    RAISE NOTICE '📧 Confirmação de email atualmente: %', 
        CASE WHEN email_confirmation_enabled THEN 'HABILITADA' ELSE 'DESABILITADA' END;
END $$;

-- 2. Desabilitar confirmação de email
-- Nota: Esta configuração deve ser feita no painel do Supabase
-- Vá em Authentication > Settings > Email Confirmation

-- 3. Atualizar usuários existentes para confirmar emails automaticamente
UPDATE auth.users 
SET email_confirmed_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- 4. Verificar quantos usuários foram atualizados
DO $$
DECLARE
    updated_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM auth.users 
    WHERE email_confirmed_at IS NOT NULL;
    
    RAISE NOTICE '✅ Usuários com email confirmado: %', updated_count;
END $$;

-- 5. Criar função para confirmar email automaticamente
CREATE OR REPLACE FUNCTION public.auto_confirm_email()
RETURNS TRIGGER AS $$
BEGIN
    -- Confirmar email automaticamente
    NEW.email_confirmed_at = NOW();
    NEW.email_confirmed = true;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Criar trigger para confirmar email automaticamente
DROP TRIGGER IF EXISTS auto_confirm_email_trigger ON auth.users;
CREATE TRIGGER auto_confirm_email_trigger
    BEFORE INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_email();

-- 7. Verificar se o trigger foi criado
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.triggers 
        WHERE trigger_name = 'auto_confirm_email_trigger'
    ) THEN
        RAISE NOTICE '✅ Trigger de confirmação automática criado';
    ELSE
        RAISE NOTICE '❌ Erro ao criar trigger de confirmação automática';
    END IF;
END $$;

-- 8. Instruções para o painel do Supabase
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 INSTRUÇÕES IMPORTANTES:';
    RAISE NOTICE '1. Vá para o painel do Supabase';
    RAISE NOTICE '2. Acesse Authentication > Settings';
    RAISE NOTICE '3. Desabilite "Email Confirmation"';
    RAISE NOTICE '4. Salve as configurações';
    RAISE NOTICE '';
    RAISE NOTICE '📋 CONFIGURAÇÕES RECOMENDADAS:';
    RAISE NOTICE '- Email Confirmation: OFF';
    RAISE NOTICE '- Email Change Confirmation: OFF';
    RAISE NOTICE '- Phone Confirmation: OFF';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Após essas configurações, o login funcionará sem confirmação de email';
END $$;






