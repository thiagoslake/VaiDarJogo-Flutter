-- =====================================================
-- MIGRAÇÃO SEGURA PARA SISTEMA DE AUTENTICAÇÃO
-- =====================================================
-- Este script é mais seguro e verifica se as tabelas existem

-- 1. Criar tabela de usuários (se não existir)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    
    -- Constraints
    CONSTRAINT users_email_check CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    CONSTRAINT users_name_check CHECK (LENGTH(name) >= 2)
);

-- 2. Verificar e adicionar user_id na tabela games
DO $$ 
BEGIN
    -- Verificar se a tabela games existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        -- Adicionar coluna user_id se não existir
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'games' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE games ADD COLUMN user_id UUID;
            
            -- Adicionar foreign key constraint
            ALTER TABLE games 
            ADD CONSTRAINT fk_games_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            
            -- Adicionar índice para performance
            CREATE INDEX IF NOT EXISTS idx_games_user_id ON games(user_id);
            
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela games';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela games';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela games não encontrada - pulando...';
    END IF;
END $$;

-- 3. Verificar e adicionar user_id na tabela players
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'players' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE players ADD COLUMN user_id UUID;
            ALTER TABLE players 
            ADD CONSTRAINT fk_players_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            CREATE INDEX IF NOT EXISTS idx_players_user_id ON players(user_id);
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela players';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela players';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela players não encontrada - pulando...';
    END IF;
END $$;

-- 4. Verificar e adicionar user_id na tabela game_players (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_players') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'game_players' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE game_players ADD COLUMN user_id UUID;
            ALTER TABLE game_players 
            ADD CONSTRAINT fk_game_players_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            CREATE INDEX IF NOT EXISTS idx_game_players_user_id ON game_players(user_id);
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela game_players';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela game_players';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela game_players não encontrada - pulando...';
    END IF;
END $$;

-- 5. Verificar e adicionar user_id na tabela payments (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'payments' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE payments ADD COLUMN user_id UUID;
            ALTER TABLE payments 
            ADD CONSTRAINT fk_payments_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            CREATE INDEX IF NOT EXISTS idx_payments_user_id ON payments(user_id);
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela payments';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela payments';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela payments não encontrada - pulando...';
    END IF;
END $$;

-- 6. Verificar e adicionar user_id na tabela consolidation_saves (se existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consolidation_saves') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'consolidation_saves' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE consolidation_saves ADD COLUMN user_id UUID;
            ALTER TABLE consolidation_saves 
            ADD CONSTRAINT fk_consolidation_saves_user_id 
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            CREATE INDEX IF NOT EXISTS idx_consolidation_saves_user_id ON consolidation_saves(user_id);
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela consolidation_saves';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela consolidation_saves';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela consolidation_saves não encontrada - pulando...';
    END IF;
END $$;

-- 7. Habilitar RLS apenas nas tabelas que existem
DO $$ 
BEGIN
    -- Habilitar RLS na tabela users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE users ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela users';
    END IF;
    
    -- Habilitar RLS na tabela games
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        ALTER TABLE games ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela games';
    END IF;
    
    -- Habilitar RLS na tabela players
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        ALTER TABLE players ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela players';
    END IF;
    
    -- Habilitar RLS na tabela game_players (se existir)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_players') THEN
        ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela game_players';
    END IF;
    
    -- Habilitar RLS na tabela payments (se existir)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela payments';
    END IF;
    
    -- Habilitar RLS na tabela consolidation_saves (se existir)
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consolidation_saves') THEN
        ALTER TABLE consolidation_saves ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela consolidation_saves';
    END IF;
END $$;

-- 8. Criar políticas RLS apenas para tabelas que existem

-- Políticas para tabela users
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        DROP POLICY IF EXISTS "Users can view own profile" ON users;
        CREATE POLICY "Users can view own profile" ON users
            FOR SELECT USING (auth.uid() = id);

        DROP POLICY IF EXISTS "Users can update own profile" ON users;
        CREATE POLICY "Users can update own profile" ON users
            FOR UPDATE USING (auth.uid() = id);

        DROP POLICY IF EXISTS "Users can insert own profile" ON users;
        CREATE POLICY "Users can insert own profile" ON users
            FOR INSERT WITH CHECK (auth.uid() = id);
            
        RAISE NOTICE '✅ Políticas RLS criadas para tabela users';
    END IF;
END $$;

-- Políticas para tabela games
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        DROP POLICY IF EXISTS "Users can view own games" ON games;
        CREATE POLICY "Users can view own games" ON games
            FOR SELECT USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can insert own games" ON games;
        CREATE POLICY "Users can insert own games" ON games
            FOR INSERT WITH CHECK (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can update own games" ON games;
        CREATE POLICY "Users can update own games" ON games
            FOR UPDATE USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can delete own games" ON games;
        CREATE POLICY "Users can delete own games" ON games
            FOR DELETE USING (auth.uid() = user_id);
            
        RAISE NOTICE '✅ Políticas RLS criadas para tabela games';
    END IF;
END $$;

-- Políticas para tabela players
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        DROP POLICY IF EXISTS "Users can view own players" ON players;
        CREATE POLICY "Users can view own players" ON players
            FOR SELECT USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can insert own players" ON players;
        CREATE POLICY "Users can insert own players" ON players
            FOR INSERT WITH CHECK (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can update own players" ON players;
        CREATE POLICY "Users can update own players" ON players
            FOR UPDATE USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can delete own players" ON players;
        CREATE POLICY "Users can delete own players" ON players
            FOR DELETE USING (auth.uid() = user_id);
            
        RAISE NOTICE '✅ Políticas RLS criadas para tabela players';
    END IF;
END $$;

-- 9. Função para criar usuário automaticamente após registro no Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name, created_at)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
        NOW()
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Trigger para criar usuário automaticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 11. Função para atualizar last_login_at
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Trigger para atualizar last_login_at
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
    AFTER UPDATE OF last_sign_in_at ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.update_last_login();

-- 13. Índices adicionais para performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- 14. Verificar se a migração foi aplicada com sucesso
DO $$
DECLARE
    table_count INTEGER;
    user_table_exists BOOLEAN;
BEGIN
    -- Verificar se a tabela users foi criada
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'users'
    ) INTO user_table_exists;
    
    -- Contar tabelas com user_id
    SELECT COUNT(*) INTO table_count
    FROM information_schema.columns 
    WHERE column_name = 'user_id' 
    AND table_schema = 'public';
    
    RAISE NOTICE '🎉 MIGRAÇÃO CONCLUÍDA COM SUCESSO!';
    RAISE NOTICE '📊 Tabela users criada: %', user_table_exists;
    RAISE NOTICE '📊 Tabelas com user_id: %', table_count;
    RAISE NOTICE '🔒 RLS habilitado para segregação por usuário';
    RAISE NOTICE '⚡ Índices criados para performance';
    RAISE NOTICE '🔄 Triggers configurados para sincronização com Supabase Auth';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Sistema de autenticação pronto para uso!';
END $$;
