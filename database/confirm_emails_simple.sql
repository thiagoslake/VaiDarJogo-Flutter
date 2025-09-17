-- =====================================================
-- CONFIRMAR EMAILS EXISTENTES - VERSÃO SIMPLES
-- =====================================================
-- Execute este script no Supabase SQL Editor

-- 1. Verificar usuários com email não confirmado
DO $$
DECLARE
    unconfirmed_count INTEGER;
    total_users INTEGER;
BEGIN
    SELECT COUNT(*) INTO unconfirmed_count
    FROM auth.users 
    WHERE email_confirmed_at IS NULL;
    
    SELECT COUNT(*) INTO total_users
    FROM auth.users;
    
    RAISE NOTICE '📊 Usuários com email não confirmado: % de %', unconfirmed_count, total_users;
END $$;

-- 2. Confirmar todos os emails existentes
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 3. Verificar resultado
DO $$
DECLARE
    confirmed_count INTEGER;
    total_users INTEGER;
BEGIN
    SELECT COUNT(*) INTO confirmed_count
    FROM auth.users 
    WHERE email_confirmed_at IS NOT NULL;
    
    SELECT COUNT(*) INTO total_users
    FROM auth.users;
    
    RAISE NOTICE '✅ Usuários com email confirmado: % de %', confirmed_count, total_users;
END $$;

-- 4. Instruções finais
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 EMAILS CONFIRMADOS COM SUCESSO!';
    RAISE NOTICE '';
    RAISE NOTICE '📋 O QUE FOI FEITO:';
    RAISE NOTICE '✅ Todos os emails existentes foram confirmados';
    RAISE NOTICE '';
    RAISE NOTICE '🚀 PRÓXIMOS PASSOS:';
    RAISE NOTICE '1. Teste o login no app Flutter';
    RAISE NOTICE '2. Se ainda houver erro, vá para o painel do Supabase';
    RAISE NOTICE '3. Authentication > Settings > Email Confirmation: OFF';
    RAISE NOTICE '';
    RAISE NOTICE '💡 DICA: Para desenvolvimento, é recomendado desabilitar';
    RAISE NOTICE '   a confirmação de email no painel do Supabase.';
END $$;






