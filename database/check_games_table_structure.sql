-- =====================================================
-- VERIFICAÇÃO DA ESTRUTURA DA TABELA GAMES
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- Este script verifica a estrutura da tabela games e
-- identifica problemas com a associação de administradores
-- =====================================================

-- 1. Verificar se a tabela games existe
SELECT 
    'VERIFICAÇÃO DE EXISTÊNCIA' as categoria,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name = 'games'
        ) THEN 'TABELA GAMES EXISTE'
        ELSE 'ERRO: TABELA GAMES NÃO EXISTE'
    END as status;

-- 2. Verificar estrutura da tabela games
SELECT 
    'ESTRUTURA DA TABELA GAMES' as categoria,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'games' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Verificar se existe coluna user_id
SELECT 
    'VERIFICAÇÃO COLUNA USER_ID' as categoria,
    CASE 
        WHEN EXISTS (
            SELECT FROM information_schema.columns 
            WHERE table_name = 'games' 
            AND column_name = 'user_id'
            AND table_schema = 'public'
        ) THEN 'COLUNA USER_ID EXISTE'
        ELSE 'ERRO: COLUNA USER_ID NÃO EXISTE'
    END as status;

-- 4. Verificar dados na tabela games
SELECT 
    'DADOS NA TABELA GAMES' as categoria,
    COUNT(*) as total_jogos,
    COUNT(DISTINCT user_id) as administradores_unicos,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as jogos_com_administrador,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as jogos_sem_administrador
FROM games;

-- 5. Listar jogos e seus administradores
SELECT 
    'JOGOS E ADMINISTRADORES' as categoria,
    g.id as game_id,
    g.organization_name,
    g.user_id as admin_user_id,
    u.email as admin_email,
    g.created_at
FROM games g
LEFT JOIN users u ON g.user_id = u.id
ORDER BY g.created_at DESC
LIMIT 10;

-- 6. Verificar se há jogos sem administrador
SELECT 
    'JOGOS SEM ADMINISTRADOR' as categoria,
    COUNT(*) as quantidade
FROM games 
WHERE user_id IS NULL;

-- 7. Verificar relacionamentos com users
SELECT 
    'RELACIONAMENTOS COM USERS' as categoria,
    COUNT(*) as total_relacionamentos
FROM games g
INNER JOIN users u ON g.user_id = u.id;

-- 8. Verificar se há problemas de integridade
SELECT 
    'VERIFICAÇÃO DE INTEGRIDADE' as categoria,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM games g
            LEFT JOIN users u ON g.user_id = u.id
            WHERE g.user_id IS NOT NULL AND u.id IS NULL
        ) THEN 'ERRO: Há jogos com user_id inválido'
        ELSE 'OK: Todos os user_id são válidos'
    END as status;
