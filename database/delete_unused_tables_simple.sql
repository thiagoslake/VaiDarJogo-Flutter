-- =====================================================
-- SCRIPT SIMPLES PARA DELETAR TABELAS NÃO UTILIZADAS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ATENÇÃO: Este script irá DELETAR PERMANENTEMENTE as tabelas listadas.
-- Certifique-se de fazer um BACKUP do banco de dados antes de executar!
--
-- TABELAS QUE SERÃO DELETADAS:
-- 1. api_keys
-- 2. app_users  
-- 3. audit_logs
-- 4. device_tokens
-- 5. participation_confirmations
-- 6. participations
-- 7. payments
-- 8. team_players
-- 9. teams
-- 10. waiting_list
-- =====================================================

-- Deletar tabelas não utilizadas
DROP TABLE IF EXISTS public.api_keys CASCADE;
DROP TABLE IF EXISTS public.app_users CASCADE;
DROP TABLE IF EXISTS public.audit_logs CASCADE;
DROP TABLE IF EXISTS public.device_tokens CASCADE;
DROP TABLE IF EXISTS public.participation_confirmations CASCADE;
DROP TABLE IF EXISTS public.participations CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.team_players CASCADE;
DROP TABLE IF EXISTS public.teams CASCADE;
DROP TABLE IF EXISTS public.waiting_list CASCADE;

-- Verificar se as tabelas foram deletadas
SELECT 
    'TABELAS DELETADAS' as status,
    table_name
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'api_keys',
    'app_users',
    'audit_logs',
    'device_tokens',
    'participation_confirmations',
    'participations',
    'payments',
    'team_players',
    'teams',
    'waiting_list'
);

-- Se não retornar nenhuma linha, significa que todas foram deletadas com sucesso
-- Se retornar linhas, significa que algumas tabelas ainda existem

