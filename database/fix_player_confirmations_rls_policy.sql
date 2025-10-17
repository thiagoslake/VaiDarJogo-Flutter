-- =====================================================
-- CORREÇÃO: Política RLS para Administradores Gerenciarem Confirmações
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
-- 2. VERIFICAR POLÍTICAS EXISTENTES
-- =====================================================

-- Listar todas as políticas da tabela player_confirmations
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'player_confirmations'
ORDER BY policyname;

-- =====================================================
-- 3. TESTE DA POLÍTICA (OPCIONAL)
-- =====================================================

-- Verificar se o usuário atual é admin de algum jogo
-- (Execute como o usuário logado)
SELECT 
    g.id as game_id,
    g.organization_name,
    gp.is_admin,
    p.name as player_name
FROM games g
JOIN game_players gp ON g.id = gp.game_id
JOIN players p ON gp.player_id = p.id
WHERE p.user_id = auth.uid()
AND gp.is_admin = true;

-- =====================================================
-- 4. VERIFICAÇÃO DE INTEGRIDADE
-- =====================================================

-- Verificar se há jogadores sem user_id (que podem causar problemas)
SELECT 
    p.id as player_id,
    p.name as player_name,
    p.user_id,
    CASE 
        WHEN p.user_id IS NULL THEN '❌ SEM USER_ID'
        WHEN u.id IS NULL THEN '❌ USER_ID INEXISTENTE'
        ELSE '✅ USER_ID VÁLIDO'
    END as status_user
FROM players p
LEFT JOIN users u ON p.user_id = u.id
WHERE p.user_id IS NULL OR u.id IS NULL;

-- =====================================================
-- 5. LOG DE EXECUÇÃO
-- =====================================================

-- Log da correção aplicada (comentado pois tabela system_logs não existe)
-- INSERT INTO public.system_logs (
--     action,
--     table_name,
--     details,
--     created_at
-- ) VALUES (
--     'RLS_POLICY_ADDED',
--     'player_confirmations',
--     'Adicionada política "Admins can manage confirmations for their games" para permitir que administradores gerenciem confirmações de outros jogadores',
--     NOW()
-- ) ON CONFLICT DO NOTHING;

-- Log manual da correção aplicada
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
