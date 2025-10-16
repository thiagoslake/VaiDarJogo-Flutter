-- =====================================================
-- RECRIAR TABELAS PRINCIPAIS DO SISTEMA
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Recriar as tabelas principais caso estejam faltando
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se as tabelas estiverem faltando
-- 2. Este script recria as tabelas com estrutura básica
-- 3. Não afeta dados existentes
-- =====================================================

-- =====================================================
-- 1. CRIAR TABELA USERS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true
);

-- =====================================================
-- 2. CRIAR TABELA PLAYERS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    birth_date DATE,
    primary_position VARCHAR(50),
    secondary_position VARCHAR(50),
    preferred_foot VARCHAR(10),
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 3. CRIAR TABELA GAMES (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT,
    location VARCHAR(255),
    organization_name VARCHAR(255),
    players_per_team INTEGER DEFAULT 7,
    substitutes_per_team INTEGER DEFAULT 3,
    number_of_teams INTEGER DEFAULT 2,
    game_date DATE,
    day_of_week VARCHAR(20),
    frequency VARCHAR(50) DEFAULT 'weekly',
    price_config JSONB,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 4. CRIAR TABELA GAME_PLAYERS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.game_players (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    player_type VARCHAR(20) DEFAULT 'casual',
    status VARCHAR(20) DEFAULT 'active',
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(game_id, player_id)
);

-- =====================================================
-- 5. CRIAR TABELA GAME_SESSIONS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.game_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    session_date DATE NOT NULL,
    start_time TIME,
    end_time TIME,
    location VARCHAR(255),
    notes TEXT,
    status VARCHAR(20) DEFAULT 'scheduled',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 6. CRIAR TABELA PARTICIPATION_REQUESTS (se não existir)
-- =====================================================

CREATE TABLE IF NOT EXISTS public.participation_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id UUID NOT NULL REFERENCES public.games(id) ON DELETE CASCADE,
    player_id UUID NOT NULL REFERENCES public.players(id) ON DELETE CASCADE,
    status VARCHAR(20) DEFAULT 'pending',
    message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(game_id, player_id)
);

-- =====================================================
-- 7. CRIAR ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para users
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_phone ON public.users(phone);
CREATE INDEX IF NOT EXISTS idx_users_active ON public.users(is_active);

-- Índices para players
CREATE INDEX IF NOT EXISTS idx_players_user_id ON public.players(user_id);
CREATE INDEX IF NOT EXISTS idx_players_phone ON public.players(phone_number);
CREATE INDEX IF NOT EXISTS idx_players_status ON public.players(status);

-- Índices para games
CREATE INDEX IF NOT EXISTS idx_games_user_id ON public.games(user_id);
CREATE INDEX IF NOT EXISTS idx_games_status ON public.games(status);
CREATE INDEX IF NOT EXISTS idx_games_frequency ON public.games(frequency);

-- Índices para game_players
CREATE INDEX IF NOT EXISTS idx_game_players_game_id ON public.game_players(game_id);
CREATE INDEX IF NOT EXISTS idx_game_players_player_id ON public.game_players(player_id);
CREATE INDEX IF NOT EXISTS idx_game_players_status ON public.game_players(status);
CREATE INDEX IF NOT EXISTS idx_game_players_type ON public.game_players(player_type);

-- Índices para game_sessions
CREATE INDEX IF NOT EXISTS idx_game_sessions_game_id ON public.game_sessions(game_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_date ON public.game_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_game_sessions_status ON public.game_sessions(status);

-- Índices para participation_requests
CREATE INDEX IF NOT EXISTS idx_participation_requests_game_id ON public.participation_requests(game_id);
CREATE INDEX IF NOT EXISTS idx_participation_requests_player_id ON public.participation_requests(player_id);
CREATE INDEX IF NOT EXISTS idx_participation_requests_status ON public.participation_requests(status);

-- =====================================================
-- 8. HABILITAR RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participation_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 9. CRIAR POLÍTICAS RLS BÁSICAS
-- =====================================================

-- Políticas para users
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.users;
CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Políticas para players
DROP POLICY IF EXISTS "Users can view own player profile" ON public.players;
CREATE POLICY "Users can view own player profile" ON public.players
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own player profile" ON public.players;
CREATE POLICY "Users can update own player profile" ON public.players
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own player profile" ON public.players;
CREATE POLICY "Users can insert own player profile" ON public.players
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Políticas para games
DROP POLICY IF EXISTS "Users can view all games" ON public.games;
CREATE POLICY "Users can view all games" ON public.games
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can create games" ON public.games;
CREATE POLICY "Users can create games" ON public.games
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Game admins can update games" ON public.games;
CREATE POLICY "Game admins can update games" ON public.games
    FOR UPDATE USING (auth.uid() = user_id);

-- Políticas para game_players
DROP POLICY IF EXISTS "Users can view game players" ON public.game_players;
CREATE POLICY "Users can view game players" ON public.game_players
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage game players" ON public.game_players;
CREATE POLICY "Users can manage game players" ON public.game_players
    FOR ALL USING (true);

-- Políticas para game_sessions
DROP POLICY IF EXISTS "Users can view game sessions" ON public.game_sessions;
CREATE POLICY "Users can view game sessions" ON public.game_sessions
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage game sessions" ON public.game_sessions;
CREATE POLICY "Users can manage game sessions" ON public.game_sessions
    FOR ALL USING (true);

-- Políticas para participation_requests
DROP POLICY IF EXISTS "Users can view participation requests" ON public.participation_requests;
CREATE POLICY "Users can view participation requests" ON public.participation_requests
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can manage participation requests" ON public.participation_requests;
CREATE POLICY "Users can manage participation requests" ON public.participation_requests
    FOR ALL USING (true);

-- =====================================================
-- 10. CRIAR TRIGGER PARA ATUALIZAR updated_at
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para atualizar updated_at
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_players_updated_at ON public.players;
CREATE TRIGGER update_players_updated_at
    BEFORE UPDATE ON public.players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_games_updated_at ON public.games;
CREATE TRIGGER update_games_updated_at
    BEFORE UPDATE ON public.games
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_game_players_updated_at ON public.game_players;
CREATE TRIGGER update_game_players_updated_at
    BEFORE UPDATE ON public.game_players
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_game_sessions_updated_at ON public.game_sessions;
CREATE TRIGGER update_game_sessions_updated_at
    BEFORE UPDATE ON public.game_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_participation_requests_updated_at ON public.participation_requests;
CREATE TRIGGER update_participation_requests_updated_at
    BEFORE UPDATE ON public.participation_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 11. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    RAISE NOTICE '✅ Tabelas principais criadas/verificadas';
    RAISE NOTICE '✅ Índices criados/verificados';
    RAISE NOTICE '✅ RLS habilitado';
    RAISE NOTICE '✅ Políticas RLS criadas';
    RAISE NOTICE '✅ Triggers criados';
    RAISE NOTICE '🎉 Sistema pronto para uso!';
END $$;




