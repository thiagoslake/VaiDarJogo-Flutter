-- =====================================================
-- CORREÇÃO SIMPLES: Política RLS para Administradores
-- VaiDarJogo Flutter App
-- =====================================================
-- 
-- PROBLEMA: Administradores não conseguem confirmar/declinar presença de outros jogadores
-- CAUSA: Falta política RLS que permita admins gerenciarem confirmações de outros players
-- SOLUÇÃO: Adicionar política que permite admins fazer INSERT/UPDATE/DELETE em player_confirmations
-- =====================================================

-- =====================================================
-- 1. ADICIONAR POLÍTICA RLS FALTANTE
-- =====================================================

-- Política para administradores gerenciarem confirmações de outros jogadores
CREATE POLICY "Admins can manage confirmations for their games" ON player_confirmations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = player_confirmations.game_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );

-- =====================================================
-- 2. VERIFICAR SE A POLÍTICA FOI CRIADA
-- =====================================================

-- Listar todas as políticas da tabela player_confirmations
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN cmd = 'r' THEN 'SELECT'
        WHEN cmd = 'a' THEN 'INSERT'
        WHEN cmd = 'w' THEN 'UPDATE'
        WHEN cmd = 'd' THEN 'DELETE'
        WHEN cmd = '*' THEN 'ALL'
        ELSE cmd::text
    END as operation
FROM pg_policies 
WHERE tablename = 'player_confirmations'
ORDER BY policyname;

-- =====================================================
-- 3. CONFIRMAÇÃO DE SUCESSO
-- =====================================================

SELECT 'Política RLS "Admins can manage confirmations for their games" adicionada com sucesso!' as status;

-- =====================================================
-- INSTRUÇÕES DE USO
-- =====================================================
-- 
-- 1. Execute este script no Supabase SQL Editor
-- 2. Verifique se a política foi criada com sucesso
-- 3. Teste a funcionalidade de confirmação manual
-- 4. Se ainda houver problemas, verifique se o usuário é admin do jogo
-- 
-- =====================================================
