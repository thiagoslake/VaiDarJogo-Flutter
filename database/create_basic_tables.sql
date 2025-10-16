-- =====================================================
-- CRIAR TABELAS BÁSICAS DO SISTEMA
-- Sistema: VaiDarJogo Flutter
-- =====================================================
-- 
-- OBJETIVO: Criar apenas as tabelas principais básicas
-- 
-- ⚠️  IMPORTANTE: 
-- 1. Execute apenas se as tabelas estiverem faltando
-- 2. Este script cria apenas as tabelas básicas
-- 3. Sem índices complexos ou triggers
-- =====================================================

-- =====================================================
-- 1. CRIAR TABELA USERS
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
-- 2. CRIAR TABELA PLAYERS
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
-- 3. CRIAR TABELA GAMES
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
-- 4. CRIAR TABELA GAME_PLAYERS
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
-- 5. CRIAR TABELA GAME_SESSIONS
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
-- 6. CRIAR TABELA PARTICIPATION_REQUESTS
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
-- 7. HABILITAR RLS (ROW LEVEL SECURITY)
-- =====================================================

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.participation_requests ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- 8. CRIAR POLÍTICAS RLS BÁSICAS
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
-- 9. VERIFICAÇÃO FINAL
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '=== VERIFICAÇÃO FINAL ===';
    RAISE NOTICE '✅ Tabelas principais criadas';
    RAISE NOTICE '✅ RLS habilitado';
    RAISE NOTICE '✅ Políticas RLS criadas';
    RAISE NOTICE '🎉 Sistema básico pronto para uso!';
END $$;




