-- =====================================================
-- 🔍 VERIFICAÇÃO: Data da Próxima Sessão no Widget
-- =====================================================
-- Script para verificar se as sessões estão sendo 
-- criadas e exibidas corretamente no widget "Meus Jogos"
-- =====================================================

-- 1. Verificar estrutura da tabela game_sessions
SELECT 
    '📋 Estrutura da tabela game_sessions' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'game_sessions'
ORDER BY ordinal_position;

-- 2. Verificar se existem jogos cadastrados
SELECT 
    '🎮 Jogos cadastrados' as info,
    COUNT(*) as total_jogos,
    COUNT(CASE WHEN frequency = 'weekly' THEN 1 END) as jogos_semanais,
    COUNT(CASE WHEN frequency = 'biweekly' THEN 1 END) as jogos_quinzenais,
    COUNT(CASE WHEN frequency = 'monthly' THEN 1 END) as jogos_mensais,
    COUNT(CASE WHEN frequency = 'one_time' THEN 1 END) as jogos_avulsos
FROM public.games 
WHERE status = 'active';

-- 3. Verificar se existem sessões criadas
SELECT 
    '📅 Sessões criadas' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN session_date >= CURRENT_DATE THEN 1 END) as sessoes_futuras,
    COUNT(CASE WHEN session_date < CURRENT_DATE THEN 1 END) as sessoes_passadas
FROM public.game_sessions;

-- 4. Verificar sessões por jogo (próximas sessões)
SELECT 
    '🔍 Próximas sessões por jogo' as info,
    g.organization_name as nome_jogo,
    g.frequency as frequencia,
    COUNT(gs.id) as total_sessoes,
    MIN(gs.session_date) as primeira_sessao,
    MAX(gs.session_date) as ultima_sessao,
    COUNT(CASE WHEN gs.session_date >= CURRENT_DATE THEN 1 END) as sessoes_futuras
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
GROUP BY g.id, g.organization_name, g.frequency
ORDER BY g.organization_name;

-- 5. Verificar próxima sessão específica para cada jogo
SELECT 
    '⏭️ Próxima sessão de cada jogo' as info,
    g.organization_name as nome_jogo,
    gs.session_date as proxima_data,
    gs.start_time as hora_inicio,
    gs.end_time as hora_fim,
    gs.status as status_sessao
FROM public.games g
LEFT JOIN LATERAL (
    SELECT session_date, start_time, end_time, status
    FROM public.game_sessions gs2
    WHERE gs2.game_id = g.id 
      AND gs2.session_date >= CURRENT_DATE
    ORDER BY gs2.session_date ASC
    LIMIT 1
) gs ON true
WHERE g.status = 'active'
ORDER BY g.organization_name;

-- 6. Verificar jogos sem sessões futuras
SELECT 
    '⚠️ Jogos sem sessões futuras' as info,
    g.organization_name as nome_jogo,
    g.frequency as frequencia,
    g.created_at as data_criacao,
    COUNT(gs.id) as total_sessoes_criadas
FROM public.games g
LEFT JOIN public.game_sessions gs ON g.id = gs.game_id
WHERE g.status = 'active'
GROUP BY g.id, g.organization_name, g.frequency, g.created_at
HAVING COUNT(CASE WHEN gs.session_date >= CURRENT_DATE THEN 1 END) = 0
ORDER BY g.organization_name;

-- 7. Verificar jogos com sessões futuras
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

-- 8. Verificar dados que seriam retornados pela consulta do Flutter
SELECT 
    '📱 Dados para o widget Flutter' as info,
    g.id as game_id,
    g.organization_name as nome_jogo,
    gs.session_date as proxima_sessao_data,
    gs.start_time as proxima_sessao_inicio,
    gs.end_time as proxima_sessao_fim,
    CASE 
        WHEN gs.session_date IS NULL THEN 'Próxima sessão não agendada'
        ELSE 'Próxima sessão: ' || gs.session_date
    END as texto_exibicao
FROM public.games g
LEFT JOIN LATERAL (
    SELECT session_date, start_time, end_time
    FROM public.game_sessions gs2
    WHERE gs2.game_id = g.id 
      AND gs2.session_date >= CURRENT_DATE
    ORDER BY gs2.session_date ASC
    LIMIT 1
) gs ON true
WHERE g.status = 'active'
ORDER BY g.organization_name;

-- 9. Verificar se há problemas com datas
SELECT 
    '🗓️ Verificação de datas' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN session_date IS NULL THEN 1 END) as datas_nulas,
    COUNT(CASE WHEN session_date < '2020-01-01' THEN 1 END) as datas_muito_antigas,
    COUNT(CASE WHEN session_date > '2030-12-31' THEN 1 END) as datas_muito_futuras,
    MIN(session_date) as data_mais_antiga,
    MAX(session_date) as data_mais_recente
FROM public.game_sessions;

-- 10. Verificar horários das sessões
SELECT 
    '⏰ Verificação de horários' as info,
    COUNT(*) as total_sessoes,
    COUNT(CASE WHEN start_time IS NULL THEN 1 END) as inicio_nulo,
    COUNT(CASE WHEN end_time IS NULL THEN 1 END) as fim_nulo,
    COUNT(CASE WHEN start_time IS NOT NULL AND end_time IS NOT NULL THEN 1 END) as horarios_completos
FROM public.game_sessions;

-- =====================================================
-- 📊 RESUMO DA VERIFICAÇÃO
-- =====================================================

-- Verificar se a implementação está funcionando corretamente:
-- 1. ✅ Jogos devem ter sessões criadas (exceto jogos avulsos)
-- 2. ✅ Sessões futuras devem existir para jogos recorrentes
-- 3. ✅ Próxima sessão deve ser a mais próxima da data atual
-- 4. ✅ Horários devem estar preenchidos
-- 5. ✅ Widget deve exibir "Próxima sessão não agendada" para jogos sem sessões futuras

-- =====================================================
-- 🚨 POSSÍVEIS PROBLEMAS E SOLUÇÕES
-- =====================================================

-- PROBLEMA 1: Jogos sem sessões futuras
-- SOLUÇÃO: Verificar se a geração de sessões está funcionando
--          ou se o jogo é do tipo "one_time" (avulso)

-- PROBLEMA 2: Datas nulas ou inválidas
-- SOLUÇÃO: Verificar a lógica de criação de sessões

-- PROBLEMA 3: Horários nulos
-- SOLUÇÃO: Verificar se start_time e end_time estão sendo definidos

-- PROBLEMA 4: Widget não atualiza
-- SOLUÇÃO: Verificar se a consulta está sendo executada corretamente
--          e se os dados estão sendo passados para o widget

-- =====================================================




