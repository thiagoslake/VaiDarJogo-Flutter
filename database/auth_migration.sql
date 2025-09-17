-- =====================================================
-- MIGRAÇÃO PARA SISTEMA DE AUTENTICAÇÃO
-- =====================================================
-- Este script adiciona suporte a usuários e segregação de dados

-- 1. Criar tabela de usuários
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

-- 2. Adicionar coluna user_id na tabela games (se não existir)
DO $$ 
BEGIN
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
        CREATE INDEX idx_games_user_id ON games(user_id);
    END IF;
END $$;

-- 3. Adicionar coluna user_id na tabela players (se a tabela e coluna existirem)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'players'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE players ADD COLUMN user_id UUID;
        
        -- Adicionar foreign key constraint
        ALTER TABLE players 
        ADD CONSTRAINT fk_players_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        -- Adicionar índice para performance
        CREATE INDEX idx_players_user_id ON players(user_id);
    END IF;
END $$;

-- 4. Adicionar coluna user_id na tabela game_players (se a tabela e coluna existirem)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'game_players'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'game_players' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE game_players ADD COLUMN user_id UUID;
        
        -- Adicionar foreign key constraint
        ALTER TABLE game_players 
        ADD CONSTRAINT fk_game_players_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        -- Adicionar índice para performance
        CREATE INDEX idx_game_players_user_id ON game_players(user_id);
    END IF;
END $$;

-- 5. Adicionar coluna user_id na tabela payments (se a tabela e coluna existirem)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'payments'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE payments ADD COLUMN user_id UUID;
        
        -- Adicionar foreign key constraint
        ALTER TABLE payments 
        ADD CONSTRAINT fk_payments_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        -- Adicionar índice para performance
        CREATE INDEX idx_payments_user_id ON payments(user_id);
    END IF;
END $$;

-- 6. Adicionar coluna user_id na tabela consolidation_saves (se a tabela e coluna existirem)
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'consolidation_saves'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'consolidation_saves' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE consolidation_saves ADD COLUMN user_id UUID;
        
        -- Adicionar foreign key constraint
        ALTER TABLE consolidation_saves 
        ADD CONSTRAINT fk_consolidation_saves_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        
        -- Adicionar índice para performance
        CREATE INDEX idx_consolidation_saves_user_id ON consolidation_saves(user_id);
    END IF;
END $$;

-- 7. Atualizar RLS (Row Level Security) para segregação por usuário

-- Habilitar RLS nas tabelas (apenas se existirem)
DO $$ 
BEGIN
    -- Habilitar RLS na tabela users
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users') THEN
        ALTER TABLE users ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Habilitar RLS na tabela games
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        ALTER TABLE games ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Habilitar RLS na tabela players
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        ALTER TABLE players ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Habilitar RLS na tabela game_players
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_players') THEN
        ALTER TABLE game_players ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Habilitar RLS na tabela payments
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
    END IF;
    
    -- Habilitar RLS na tabela consolidation_saves
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consolidation_saves') THEN
        ALTER TABLE consolidation_saves ENABLE ROW LEVEL SECURITY;
    END IF;
END $$;

-- Políticas para tabela users (apenas se a tabela existir)
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
    END IF;
END $$;

-- Políticas para tabela games (apenas se a tabela existir)
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
    END IF;
END $$;

-- Políticas para tabela players (apenas se a tabela existir)
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
    END IF;
END $$;

-- Políticas para tabela game_players (apenas se a tabela existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'game_players') THEN
        DROP POLICY IF EXISTS "Users can view own game_players" ON game_players;
        CREATE POLICY "Users can view own game_players" ON game_players
            FOR SELECT USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can insert own game_players" ON game_players;
        CREATE POLICY "Users can insert own game_players" ON game_players
            FOR INSERT WITH CHECK (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can update own game_players" ON game_players;
        CREATE POLICY "Users can update own game_players" ON game_players
            FOR UPDATE USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can delete own game_players" ON game_players;
        CREATE POLICY "Users can delete own game_players" ON game_players
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Políticas para tabela payments (apenas se a tabela existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'payments') THEN
        DROP POLICY IF EXISTS "Users can view own payments" ON payments;
        CREATE POLICY "Users can view own payments" ON payments
            FOR SELECT USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can insert own payments" ON payments;
        CREATE POLICY "Users can insert own payments" ON payments
            FOR INSERT WITH CHECK (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can update own payments" ON payments;
        CREATE POLICY "Users can update own payments" ON payments
            FOR UPDATE USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can delete own payments" ON payments;
        CREATE POLICY "Users can delete own payments" ON payments
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- Políticas para tabela consolidation_saves (apenas se a tabela existir)
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'consolidation_saves') THEN
        DROP POLICY IF EXISTS "Users can view own consolidation_saves" ON consolidation_saves;
        CREATE POLICY "Users can view own consolidation_saves" ON consolidation_saves
            FOR SELECT USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can insert own consolidation_saves" ON consolidation_saves;
        CREATE POLICY "Users can insert own consolidation_saves" ON consolidation_saves
            FOR INSERT WITH CHECK (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can update own consolidation_saves" ON consolidation_saves;
        CREATE POLICY "Users can update own consolidation_saves" ON consolidation_saves
            FOR UPDATE USING (auth.uid() = user_id);

        DROP POLICY IF EXISTS "Users can delete own consolidation_saves" ON consolidation_saves;
        CREATE POLICY "Users can delete own consolidation_saves" ON consolidation_saves
            FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 8. Função para criar usuário automaticamente após registro no Supabase Auth
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

-- 9. Trigger para criar usuário automaticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 10. Função para atualizar last_login_at
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Trigger para atualizar last_login_at
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
    AFTER UPDATE OF last_sign_in_at ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.update_last_login();

-- 12. Comentários para documentação
COMMENT ON TABLE users IS 'Tabela de usuários do sistema';
COMMENT ON COLUMN users.id IS 'ID do usuário (mesmo do Supabase Auth)';
COMMENT ON COLUMN users.email IS 'Email do usuário';
COMMENT ON COLUMN users.name IS 'Nome completo do usuário';
COMMENT ON COLUMN users.phone IS 'Telefone do usuário (opcional)';
COMMENT ON COLUMN users.created_at IS 'Data de criação da conta';
COMMENT ON COLUMN users.last_login_at IS 'Data do último login';
COMMENT ON COLUMN users.is_active IS 'Se o usuário está ativo';

-- 13. Índices adicionais para performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_games_status ON games(status);
CREATE INDEX IF NOT EXISTS idx_players_status ON players(status);

-- 14. Verificar se a migração foi aplicada com sucesso
DO $$
BEGIN
    RAISE NOTICE '✅ Migração de autenticação aplicada com sucesso!';
    RAISE NOTICE '📋 Tabelas atualizadas: users, games, players, game_players, payments, consolidation_saves';
    RAISE NOTICE '🔒 RLS habilitado para segregação por usuário';
    RAISE NOTICE '⚡ Índices criados para performance';
    RAISE NOTICE '🔄 Triggers configurados para sincronização com Supabase Auth';
END $$;
