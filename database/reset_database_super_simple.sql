-- =====================================================
-- RESET SUPER SIMPLES DO BANCO DE DADOS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- ⚠️  ATENÇÃO: ESTE SCRIPT IRÁ DELETAR TODOS OS DADOS! ⚠️
-- 
-- OBJETIVO: Limpar dados das tabelas principais
-- 
-- ⚠️  IMPORTANTE: 
-- 1. FAÇA BACKUP ANTES DE EXECUTAR
-- 2. ESTE SCRIPT É IRREVERSÍVEL
-- 3. TODOS OS DADOS SERÃO PERDIDOS
-- =====================================================

-- =====================================================
-- PASSO 1: DESABILITAR RLS TEMPORARIAMENTE
-- =====================================================

-- Desabilitar RLS para facilitar a limpeza
ALTER TABLE IF EXISTS public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.players DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.games DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_players DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_sessions DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.participation_requests DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- PASSO 2: DELETAR DADOS USANDO DELETE (MAIS SEGURO)
-- =====================================================

-- Deletar dados em ordem de dependência
-- (Execute apenas se as tabelas existirem)

-- Primeiro: Dados dependentes
DELETE FROM public.game_players;
DELETE FROM public.game_sessions;
DELETE FROM public.participation_requests;

-- Depois: Dados principais
DELETE FROM public.players;
DELETE FROM public.games;
DELETE FROM public.users;

-- =====================================================
-- PASSO 3: DELETAR TABELAS NÃO UTILIZADAS
-- =====================================================

-- Deletar tabelas que podem existir mas não são utilizadas
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

-- =====================================================
-- PASSO 4: RESETAR SEQUÊNCIAS
-- =====================================================

-- Resetar todas as sequências para começar do 1
DO $$
DECLARE
    seq_record RECORD;
BEGIN
    FOR seq_record IN 
        SELECT schemaname, sequencename 
        FROM pg_sequences 
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'ALTER SEQUENCE ' || seq_record.schemaname || '.' || seq_record.sequencename || ' RESTART WITH 1';
    END LOOP;
END $$;

-- =====================================================
-- PASSO 5: LIMPAR STORAGE
-- =====================================================

-- Limpar bucket de imagens de perfil (se existir)
DELETE FROM storage.objects WHERE bucket_id = 'profile-images';

-- =====================================================
-- PASSO 6: REABILITAR RLS
-- =====================================================

-- Reabilitar RLS em todas as tabelas
ALTER TABLE IF EXISTS public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.participation_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- PASSO 7: VERIFICAÇÃO FINAL
-- =====================================================

-- Verificar se todas as tabelas estão vazias
SELECT 
    'VERIFICAÇÃO FINAL' as status,
    (SELECT COUNT(*) FROM users) as users,
    (SELECT COUNT(*) FROM players) as players,
    (SELECT COUNT(*) FROM games) as games,
    (SELECT COUNT(*) FROM game_players) as game_players,
    (SELECT COUNT(*) FROM game_sessions) as game_sessions,
    (SELECT COUNT(*) FROM participation_requests) as participation_requests;

-- Se todos os valores forem 0, o reset foi bem-sucedido




