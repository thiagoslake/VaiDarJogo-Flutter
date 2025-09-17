-- =====================================================
-- MIGRAÇÃO PASSO A PASSO - SISTEMA DE AUTENTICAÇÃO
-- =====================================================
-- Execute cada seção separadamente no Supabase SQL Editor

-- =====================================================
-- PASSO 1: Criar tabela de usuários
-- =====================================================
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

-- =====================================================
-- PASSO 2: Adicionar user_id na tabela games (se existir)
-- =====================================================
-- Execute apenas se a tabela 'games' existir
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        -- Adicionar coluna user_id se não existir
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'games' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE games ADD COLUMN user_id UUID;
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela games';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela games';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela games não encontrada';
    END IF;
END $$;

-- =====================================================
-- PASSO 3: Adicionar user_id na tabela players (se existir)
-- =====================================================
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'players' AND column_name = 'user_id'
        ) THEN
            ALTER TABLE players ADD COLUMN user_id UUID;
            RAISE NOTICE '✅ Coluna user_id adicionada à tabela players';
        ELSE
            RAISE NOTICE 'ℹ️ Coluna user_id já existe na tabela players';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Tabela players não encontrada';
    END IF;
END $$;

-- =====================================================
-- PASSO 4: Adicionar foreign keys (se as colunas existirem)
-- =====================================================
-- Para tabela games
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'games' AND column_name = 'user_id'
    ) THEN
        -- Remover constraint se existir
        ALTER TABLE games DROP CONSTRAINT IF EXISTS fk_games_user_id;
        -- Adicionar nova constraint
        ALTER TABLE games 
        ADD CONSTRAINT fk_games_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Foreign key adicionada à tabela games';
    END IF;
END $$;

-- Para tabela players
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE players DROP CONSTRAINT IF EXISTS fk_players_user_id;
        ALTER TABLE players 
        ADD CONSTRAINT fk_players_user_id 
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Foreign key adicionada à tabela players';
    END IF;
END $$;

-- =====================================================
-- PASSO 5: Criar índices para performance
-- =====================================================
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_is_active ON users(is_active);

-- Para tabela games
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'games' AND column_name = 'user_id'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_games_user_id ON games(user_id);
        RAISE NOTICE '✅ Índice criado para games.user_id';
    END IF;
END $$;

-- Para tabela players
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' AND column_name = 'user_id'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_players_user_id ON players(user_id);
        RAISE NOTICE '✅ Índice criado para players.user_id';
    END IF;
END $$;

-- =====================================================
-- PASSO 6: Habilitar Row Level Security (RLS)
-- =====================================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'games') THEN
        ALTER TABLE games ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela games';
    END IF;
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'players') THEN
        ALTER TABLE players ENABLE ROW LEVEL SECURITY;
        RAISE NOTICE '✅ RLS habilitado na tabela players';
    END IF;
END $$;

-- =====================================================
-- PASSO 7: Criar políticas RLS
-- =====================================================
-- Políticas para tabela users
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON users;
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

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

-- =====================================================
-- PASSO 8: Criar funções e triggers para Supabase Auth
-- =====================================================
-- Função para criar usuário automaticamente após registro no Supabase Auth
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

-- Trigger para criar usuário automaticamente
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Função para atualizar last_login_at
CREATE OR REPLACE FUNCTION public.update_last_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW()
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger para atualizar last_login_at
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
    AFTER UPDATE OF last_sign_in_at ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.update_last_login();

-- =====================================================
-- PASSO 9: Verificar se tudo foi aplicado corretamente
-- =====================================================
DO $$
DECLARE
    user_table_exists BOOLEAN;
    games_has_user_id BOOLEAN;
    players_has_user_id BOOLEAN;
BEGIN
    -- Verificar se a tabela users foi criada
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'users'
    ) INTO user_table_exists;
    
    -- Verificar se games tem user_id
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'games' AND column_name = 'user_id'
    ) INTO games_has_user_id;
    
    -- Verificar se players tem user_id
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'players' AND column_name = 'user_id'
    ) INTO players_has_user_id;
    
    RAISE NOTICE '🎉 VERIFICAÇÃO FINAL:';
    RAISE NOTICE '📊 Tabela users criada: %', user_table_exists;
    RAISE NOTICE '📊 Tabela games tem user_id: %', games_has_user_id;
    RAISE NOTICE '📊 Tabela players tem user_id: %', players_has_user_id;
    
    IF user_table_exists THEN
        RAISE NOTICE '✅ Sistema de autenticação configurado com sucesso!';
    ELSE
        RAISE NOTICE '❌ Erro: Tabela users não foi criada';
    END IF;
END $$;
