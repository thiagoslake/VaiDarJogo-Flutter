-- =====================================================
-- DEBUG: ASSOCIAÇÃO DE ADMINISTRADORES A JOGOS
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- Este script ajuda a debugar problemas com a associação
-- de administradores a jogos
-- =====================================================

-- 1. Verificar estrutura da tabela games
SELECT 
    'ESTRUTURA DA TABELA GAMES' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'games' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Verificar se há jogos na tabela
SELECT 
    'TOTAL DE JOGOS' as info,
    COUNT(*) as quantidade
FROM games;

-- 3. Verificar jogos com e sem administrador
SELECT 
    'JOGOS COM/SEM ADMINISTRADOR' as info,
    CASE 
        WHEN user_id IS NOT NULL THEN 'COM ADMINISTRADOR'
        ELSE 'SEM ADMINISTRADOR'
    END as status,
    COUNT(*) as quantidade
FROM games
GROUP BY (user_id IS NOT NULL);

-- 4. Listar todos os jogos e seus administradores
SELECT 
    'JOGOS E ADMINISTRADORES' as info,
    g.id as game_id,
    g.organization_name,
    g.user_id as admin_user_id,
    u.email as admin_email,
    u.name as admin_name,
    g.created_at
FROM games g
LEFT JOIN users u ON g.user_id = u.id
ORDER BY g.created_at DESC;

-- 5. Verificar se há usuários na tabela users
SELECT 
    'TOTAL DE USUÁRIOS' as info,
    COUNT(*) as quantidade
FROM users;

-- 6. Listar usuários
SELECT 
    'USUÁRIOS CADASTRADOS' as info,
    id,
    email,
    name,
    created_at
FROM users
ORDER BY created_at DESC;

-- 7. Verificar relacionamentos entre games e users
SELECT 
    'RELACIONAMENTOS GAMES-USERS' as info,
    COUNT(*) as total_relacionamentos
FROM games g
INNER JOIN users u ON g.user_id = u.id;

-- 8. Verificar jogos órfãos (sem usuário válido)
SELECT 
    'JOGOS ÓRFÃOS' as info,
    COUNT(*) as quantidade
FROM games g
LEFT JOIN users u ON g.user_id = u.id
WHERE g.user_id IS NOT NULL AND u.id IS NULL;

-- 9. Verificar se há problemas de integridade
SELECT 
    'VERIFICAÇÃO DE INTEGRIDADE' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM games g
            LEFT JOIN users u ON g.user_id = u.id
            WHERE g.user_id IS NOT NULL AND u.id IS NULL
        ) THEN 'ERRO: Há jogos com user_id inválido'
        ELSE 'OK: Todos os user_id são válidos'
    END as status;

-- 10. Verificar jogos criados recentemente
SELECT 
    'JOGOS RECENTES' as info,
    g.id,
    g.organization_name,
    g.user_id,
    u.email as admin_email,
    g.created_at
FROM games g
LEFT JOIN users u ON g.user_id = u.id
WHERE g.created_at >= NOW() - INTERVAL '7 days'
ORDER BY g.created_at DESC;
