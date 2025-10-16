-- =====================================================
-- VERIFICAÇÃO BÁSICA - APENAS SE AS TABELAS EXISTEM
-- Sistema: VaiDarJogo Flutter
-- =====================================================

-- =====================================================
-- VERIFICAR EXISTÊNCIA DAS TABELAS PRINCIPAIS
-- =====================================================

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests') 
        THEN '✅ OBRIGATÓRIA'
        ELSE 'ℹ️ OPCIONAL'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'users', 'players', 'games', 'game_players', 'game_sessions', 
    'participation_requests', 'notifications', 'notification_configs', 
    'notification_templates', 'notification_logs', 'player_fcm_tokens'
)
ORDER BY 
    CASE 
        WHEN table_name IN ('users', 'players', 'games', 'game_players', 'game_sessions', 'participation_requests') 
        THEN 1 
        ELSE 2 
    END,
    table_name;




