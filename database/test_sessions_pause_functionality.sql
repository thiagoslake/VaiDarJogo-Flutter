-- =====================================================
-- 🧪 Teste: Funcionalidade de Pausar Sessões
-- =====================================================
-- Script para testar se a funcionalidade de pausar sessões está funcionando
-- =====================================================

-- 1. Verificar se a coluna status existe e está funcionando
SELECT 
    '✅ Verificação da coluna status' as teste,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
              AND table_name = 'game_sessions' 
              AND column_name = 'status'
        ) THEN 'Coluna status existe'
        ELSE 'Coluna status NÃO existe'
    END as resultado;

-- 2. Verificar se a constraint existe
SELECT 
    '✅ Verificação da constraint' as teste,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            WHERE tc.table_schema = 'public' 
              AND tc.table_name = 'game_sessions'
              AND tc.constraint_name = 'game_sessions_status_check'
        ) THEN 'Constraint existe'
        ELSE 'Constraint NÃO existe'
    END as resultado;

-- 3. Testar inserção de sessão com status (usar um jogo real se existir)
INSERT INTO public.game_sessions (
    id,
    game_id,
    session_date,
    start_time,
    end_time,
    status,
    created_at,
    updated_at
) 
SELECT 
    gen_random_uuid(),
    g.id,  -- Usa o primeiro jogo disponível
    '2024-12-20',
    '19:00:00',
    '21:00:00',
    'active',
    NOW(),
    NOW()
FROM public.games g
LIMIT 1
ON CONFLICT DO NOTHING;

-- 4. Verificar se a inserção funcionou
SELECT 
    '✅ Teste de inserção' as teste,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.game_sessions 
            WHERE session_date = '2024-12-20'
              AND start_time = '19:00:00'
        ) THEN 'Inserção funcionou'
        ELSE 'Inserção falhou'
    END as resultado;

-- 5. Testar atualização de status
UPDATE public.game_sessions 
SET status = 'paused', updated_at = NOW()
WHERE session_date = '2024-12-20'
  AND start_time = '19:00:00';

-- 6. Verificar se a atualização funcionou
SELECT 
    '✅ Teste de atualização' as teste,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.game_sessions 
            WHERE session_date = '2024-12-20'
              AND start_time = '19:00:00'
              AND status = 'paused'
        ) THEN 'Atualização funcionou'
        ELSE 'Atualização falhou'
    END as resultado;

-- 7. Limpar dados de teste
DELETE FROM public.game_sessions 
WHERE session_date = '2024-12-20'
  AND start_time = '19:00:00';

-- 8. Verificar se a limpeza funcionou
SELECT 
    '✅ Teste de limpeza' as teste,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM public.game_sessions 
            WHERE session_date = '2024-12-20'
              AND start_time = '19:00:00'
        ) THEN 'Limpeza funcionou'
        ELSE 'Limpeza falhou'
    END as resultado;

-- 9. Verificar sessões existentes com status
SELECT 
    '📊 Sessões existentes com status' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN status = 'active' THEN 1 END) as sessoes_ativas,
    COUNT(CASE WHEN status = 'paused' THEN 1 END) as sessoes_pausadas,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as sessoes_canceladas,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as sessoes_concluidas,
    COUNT(CASE WHEN status IS NULL THEN 1 END) as sessoes_sem_status
FROM public.game_sessions;

-- 10. Verificar jogos pausados e suas sessões
SELECT 
    '🎮 Jogos pausados e suas sessões' as info,
    g.id as game_id,
    g.name as game_name,
    g.status as game_status,
    COUNT(gs.id) as total_sessoes,
    COUNT(CASE WHEN gs.status = 'active' THEN 1 END) as sessoes_ativas,
    COUNT(CASE WHEN gs.status = 'paused' THEN 1 END) as sessoes_pausadas
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'paused'
GROUP BY g.id, g.name, g.status
ORDER BY g.name;

-- =====================================================
-- 🎯 RESULTADOS ESPERADOS
-- =====================================================

-- Se tudo estiver funcionando:
-- 1. ✅ Coluna status existe
-- 2. ✅ Constraint existe
-- 3. ✅ Inserção funcionou
-- 4. ✅ Inserção funcionou
-- 5. ✅ Atualização funcionou
-- 6. ✅ Atualização funcionou
-- 7. ✅ Limpeza funcionou
-- 8. ✅ Limpeza funcionou
-- 9. 📊 Mostra estatísticas das sessões
-- 10. 🎮 Mostra jogos pausados e suas sessões

-- =====================================================
