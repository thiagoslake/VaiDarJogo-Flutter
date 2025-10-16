-- =====================================================
-- 🔍 TESTE: Consulta da Próxima Sessão a partir de Hoje
-- =====================================================
-- Script para testar se a consulta está buscando corretamente
-- a próxima sessão a partir da data de hoje
-- =====================================================

-- 1. Verificar data atual do sistema
SELECT 
    '📅 Data atual do sistema' as info,
    CURRENT_DATE as data_atual,
    CURRENT_TIMESTAMP as timestamp_atual;

-- 2. Verificar todas as sessões existentes
SELECT 
    '📋 Todas as sessões existentes' as info,
    g.organization_name as nome_jogo,
    gs.session_date as data_sessao,
    gs.start_time as hora_inicio,
    gs.end_time as hora_fim,
    gs.status as status_sessao,
    CASE 
        WHEN gs.session_date < CURRENT_DATE THEN 'PASSADA'
        WHEN gs.session_date = CURRENT_DATE THEN 'HOJE'
        WHEN gs.session_date > CURRENT_DATE THEN 'FUTURA'
        ELSE 'INDEFINIDA'
    END as tipo_sessao
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
ORDER BY g.organization_name, gs.session_date;

-- 3. Testar a consulta exata que o Flutter está usando
SELECT 
    '🔍 Consulta Flutter - Próxima sessão por jogo' as info,
    g.organization_name as nome_jogo,
    gs.session_date as proxima_data,
    gs.start_time as proxima_hora_inicio,
    gs.end_time as proxima_hora_fim,
    gs.status as status_sessao
FROM public.games g
LEFT JOIN LATERAL (
    SELECT session_date, start_time, end_time, status
    FROM public.game_sessions gs2
    WHERE gs2.game_id = g.id 
      AND gs2.session_date >= CURRENT_DATE  -- ← Filtro a partir de hoje
    ORDER BY gs2.session_date ASC
    LIMIT 1
) gs ON true
WHERE g.status = 'active'
ORDER BY g.organization_name;

-- 4. Verificar sessões futuras por jogo (sem limite)
SELECT 
    '📅 Todas as sessões futuras por jogo' as info,
    g.organization_name as nome_jogo,
    COUNT(gs.id) as total_sessoes_futuras,
    MIN(gs.session_date) as primeira_sessao_futura,
    MAX(gs.session_date) as ultima_sessao_futura
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
  AND gs.session_date >= CURRENT_DATE
GROUP BY g.id, g.organization_name
ORDER BY g.organization_name;

-- 5. Verificar jogos sem sessões futuras
SELECT 
    '⚠️ Jogos sem sessões futuras' as info,
    g.organization_name as nome_jogo,
    g.frequency as frequencia,
    COUNT(gs.id) as total_sessoes_criadas,
    MAX(gs.session_date) as ultima_sessao_criada
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
GROUP BY g.id, g.organization_name, g.frequency
HAVING COUNT(CASE WHEN gs.session_date >= CURRENT_DATE THEN 1 END) = 0
ORDER BY g.organization_name;

-- 6. Verificar jogos com sessões futuras
SELECT 
    '✅ Jogos com sessões futuras' as info,
    g.organization_name as nome_jogo,
    g.frequency as frequencia,
    COUNT(CASE WHEN gs.session_date >= CURRENT_DATE THEN 1 END) as sessoes_futuras,
    MIN(CASE WHEN gs.session_date >= CURRENT_DATE THEN gs.session_date END) as proxima_sessao
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
GROUP BY g.id, g.organization_name, g.frequency
HAVING COUNT(CASE WHEN gs.session_date >= CURRENT_DATE THEN 1 END) > 0
ORDER BY proxima_sessao;

-- 7. Simular a consulta do Flutter com dados específicos
SELECT 
    '📱 Simulação da consulta Flutter' as info,
    g.id as game_id,
    g.organization_name as nome_jogo,
    gs.session_date as proxima_sessao_data,
    gs.start_time as proxima_sessao_inicio,
    gs.end_time as proxima_sessao_fim,
    CASE 
        WHEN gs.session_date IS NULL THEN 'Próxima sessão não agendada'
        ELSE 'Próxima sessão: ' || gs.session_date
    END as texto_exibicao_flutter
FROM public.games g
LEFT JOIN LATERAL (
    SELECT session_date, start_time, end_time
    FROM public.game_sessions gs2
    WHERE gs2.game_id = g.id 
      AND gs2.session_date >= CURRENT_DATE  -- ← Filtro a partir de hoje
    ORDER BY gs2.session_date ASC
    LIMIT 1
) gs ON true
WHERE g.status = 'active'
ORDER BY g.organization_name;

-- 8. Verificar se há sessões para hoje
SELECT 
    '🗓️ Sessões para hoje' as info,
    g.organization_name as nome_jogo,
    gs.session_date as data_sessao,
    gs.start_time as hora_inicio,
    gs.end_time as hora_fim,
    gs.status as status_sessao
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
  AND gs.session_date = CURRENT_DATE
ORDER BY g.organization_name, gs.start_time;

-- 9. Verificar sessões para amanhã
SELECT 
    '📅 Sessões para amanhã' as info,
    g.organization_name as nome_jogo,
    gs.session_date as data_sessao,
    gs.start_time as hora_inicio,
    gs.end_time as hora_fim,
    gs.status as status_sessao
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
  AND gs.session_date = CURRENT_DATE + INTERVAL '1 day'
ORDER BY g.organization_name, gs.start_time;

-- 10. Verificar se a consulta está funcionando corretamente
SELECT 
    '🔍 Verificação da consulta' as info,
    COUNT(*) as total_jogos,
    COUNT(CASE WHEN proxima_sessao IS NOT NULL THEN 1 END) as jogos_com_proxima_sessao,
    COUNT(CASE WHEN proxima_sessao IS NULL THEN 1 END) as jogos_sem_proxima_sessao
FROM (
    SELECT 
        g.id,
        g.organization_name,
        gs.session_date as proxima_sessao
    FROM public.games g
    LEFT JOIN LATERAL (
        SELECT session_date
        FROM public.game_sessions gs2
        WHERE gs2.game_id = g.id 
          AND gs2.session_date >= CURRENT_DATE
        ORDER BY gs2.session_date ASC
        LIMIT 1
    ) gs ON true
    WHERE g.status = 'active'
) subquery;

-- =====================================================
-- 📊 RESUMO DO TESTE
-- =====================================================

-- A consulta deve retornar:
-- 1. ✅ Sessões a partir de hoje (>= CURRENT_DATE)
-- 2. ✅ Apenas a próxima sessão (LIMIT 1)
-- 3. ✅ Ordenada por data (ORDER BY session_date ASC)
-- 4. ✅ Filtrada por jogo (WHERE game_id = ?)

-- =====================================================
-- 🚨 POSSÍVEIS PROBLEMAS E SOLUÇÕES
-- =====================================================

-- PROBLEMA 1: Não retorna sessões para hoje
-- SOLUÇÃO: Verificar se CURRENT_DATE está correto
--          Verificar se as sessões foram criadas corretamente

-- PROBLEMA 2: Retorna sessões passadas
-- SOLUÇÃO: Verificar se o filtro >= CURRENT_DATE está funcionando
--          Verificar se as datas estão no formato correto

-- PROBLEMA 3: Não retorna a próxima sessão
-- SOLUÇÃO: Verificar se ORDER BY session_date ASC está correto
--          Verificar se LIMIT 1 está funcionando

-- PROBLEMA 4: Retorna múltiplas sessões
-- SOLUÇÃO: Verificar se LIMIT 1 está sendo aplicado
--          Verificar se a consulta LATERAL está correta

-- =====================================================




