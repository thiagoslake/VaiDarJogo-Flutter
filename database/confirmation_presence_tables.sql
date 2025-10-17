-- =====================================================
-- ESTRUTURA DE BANCO DE DADOS PARA CONFIRMAÇÃO DE PRESENÇA
-- VaiDarJogo Flutter App
-- =====================================================

-- 1. Tabela de Configurações de Confirmação por Jogo
CREATE TABLE IF NOT EXISTS game_confirmation_configs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(game_id)
);

-- 2. Tabela de Configurações de Envio por Tipo de Jogador
CREATE TABLE IF NOT EXISTS confirmation_send_configs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_confirmation_config_id uuid NOT NULL REFERENCES game_confirmation_configs(id) ON DELETE CASCADE,
    player_type text NOT NULL CHECK (player_type IN ('monthly', 'casual')),
    confirmation_order integer NOT NULL, -- 1, 2, 3... (ordem de envio)
    hours_before_game integer NOT NULL CHECK (hours_before_game > 0), -- 24, 12, 6...
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(game_confirmation_config_id, player_type, confirmation_order)
);

-- 3. Tabela de Confirmações Realizadas pelos Jogadores
CREATE TABLE IF NOT EXISTS player_confirmations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    confirmation_type text NOT NULL CHECK (confirmation_type IN ('confirmed', 'declined', 'pending')),
    confirmed_at timestamp with time zone,
    confirmation_method text CHECK (confirmation_method IN ('whatsapp', 'manual', 'app')),
    notes text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(game_id, player_id)
);

-- 4. Tabela de Logs de Envio de Confirmações
CREATE TABLE IF NOT EXISTS confirmation_send_logs (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    game_id uuid NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    player_id uuid NOT NULL REFERENCES players(id) ON DELETE CASCADE,
    send_config_id uuid REFERENCES confirmation_send_configs(id) ON DELETE CASCADE,
    scheduled_for timestamp with time zone NOT NULL,
    sent_at timestamp with time zone,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'cancelled')),
    error_message text,
    channel text CHECK (channel IN ('whatsapp', 'email', 'push')),
    message_content text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- ÍNDICES PARA PERFORMANCE
-- =====================================================

-- Índices para game_confirmation_configs
CREATE INDEX IF NOT EXISTS idx_game_confirmation_configs_game_id ON game_confirmation_configs(game_id);
CREATE INDEX IF NOT EXISTS idx_game_confirmation_configs_active ON game_confirmation_configs(is_active);

-- Índices para confirmation_send_configs
CREATE INDEX IF NOT EXISTS idx_confirmation_send_configs_config_id ON confirmation_send_configs(game_confirmation_config_id);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_configs_player_type ON confirmation_send_configs(player_type);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_configs_order ON confirmation_send_configs(confirmation_order);

-- Índices para player_confirmations
CREATE INDEX IF NOT EXISTS idx_player_confirmations_game_id ON player_confirmations(game_id);
CREATE INDEX IF NOT EXISTS idx_player_confirmations_player_id ON player_confirmations(player_id);
CREATE INDEX IF NOT EXISTS idx_player_confirmations_type ON player_confirmations(confirmation_type);
CREATE INDEX IF NOT EXISTS idx_player_confirmations_game_player ON player_confirmations(game_id, player_id);

-- Índices para confirmation_send_logs
CREATE INDEX IF NOT EXISTS idx_confirmation_send_logs_game_id ON confirmation_send_logs(game_id);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_logs_player_id ON confirmation_send_logs(player_id);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_logs_status ON confirmation_send_logs(status);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_logs_scheduled ON confirmation_send_logs(scheduled_for);
CREATE INDEX IF NOT EXISTS idx_confirmation_send_logs_send_config ON confirmation_send_logs(send_config_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Habilitar RLS nas tabelas
ALTER TABLE game_confirmation_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE confirmation_send_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE player_confirmations ENABLE ROW LEVEL SECURITY;
ALTER TABLE confirmation_send_logs ENABLE ROW LEVEL SECURITY;

-- Políticas para game_confirmation_configs
CREATE POLICY "Users can view game confirmation configs for their games" ON game_confirmation_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = game_confirmation_configs.game_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage game confirmation configs" ON game_confirmation_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = game_confirmation_configs.game_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );

-- Políticas para confirmation_send_configs
CREATE POLICY "Users can view send configs for their games" ON confirmation_send_configs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM game_confirmation_configs gcc
            JOIN games g ON gcc.game_id = g.id
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE gcc.id = confirmation_send_configs.game_confirmation_config_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage send configs" ON confirmation_send_configs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM game_confirmation_configs gcc
            JOIN games g ON gcc.game_id = g.id
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE gcc.id = confirmation_send_configs.game_confirmation_config_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );

-- Políticas para player_confirmations
CREATE POLICY "Users can view their own confirmations" ON player_confirmations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM players p 
            WHERE p.id = player_confirmations.player_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage their own confirmations" ON player_confirmations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM players p 
            WHERE p.id = player_confirmations.player_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all confirmations for their games" ON player_confirmations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = player_confirmations.game_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );

-- Políticas para confirmation_send_logs
CREATE POLICY "Users can view send logs for their games" ON confirmation_send_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = confirmation_send_logs.game_id 
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage send logs" ON confirmation_send_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM games g 
            JOIN game_players gp ON g.id = gp.game_id 
            JOIN players p ON gp.player_id = p.id 
            WHERE g.id = confirmation_send_logs.game_id 
            AND p.user_id = auth.uid()
            AND gp.is_admin = true
        )
    );

-- =====================================================
-- TRIGGERS PARA UPDATED_AT
-- =====================================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para updated_at
CREATE TRIGGER update_game_confirmation_configs_updated_at 
    BEFORE UPDATE ON game_confirmation_configs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_confirmation_send_configs_updated_at 
    BEFORE UPDATE ON confirmation_send_configs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_confirmations_updated_at 
    BEFORE UPDATE ON player_confirmations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_confirmation_send_logs_updated_at 
    BEFORE UPDATE ON confirmation_send_logs 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- VIEWS ÚTEIS PARA CONSULTAS
-- =====================================================

-- View para configurações completas de confirmação
CREATE OR REPLACE VIEW game_confirmation_configs_complete AS
SELECT 
    gcc.id as config_id,
    gcc.game_id,
    g.organization_name as game_name,
    gcc.is_active as config_active,
    csc.player_type,
    csc.confirmation_order,
    csc.hours_before_game,
    csc.is_active as send_config_active,
    gcc.created_at,
    gcc.updated_at
FROM game_confirmation_configs gcc
JOIN games g ON gcc.game_id = g.id
LEFT JOIN confirmation_send_configs csc ON gcc.id = csc.game_confirmation_config_id
ORDER BY gcc.game_id, csc.player_type, csc.confirmation_order;

-- View para status de confirmações dos jogadores
CREATE OR REPLACE VIEW player_confirmation_status AS
SELECT 
    pc.game_id,
    pc.player_id,
    p.name as player_name,
    gp.player_type,
    pc.confirmation_type,
    pc.confirmed_at,
    pc.confirmation_method,
    pc.notes,
    pc.created_at,
    pc.updated_at
FROM player_confirmations pc
JOIN players p ON pc.player_id = p.id
JOIN game_players gp ON pc.game_id = gp.game_id AND pc.player_id = gp.player_id
ORDER BY pc.game_id, gp.player_type, p.name;

-- =====================================================
-- FUNÇÕES ÚTEIS
-- =====================================================

-- Função para obter configurações de um jogo
CREATE OR REPLACE FUNCTION get_game_confirmation_configs(game_uuid uuid)
RETURNS TABLE (
    player_type text,
    confirmation_order integer,
    hours_before_game integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        csc.player_type,
        csc.confirmation_order,
        csc.hours_before_game
    FROM game_confirmation_configs gcc
    JOIN confirmation_send_configs csc ON gcc.id = csc.game_confirmation_config_id
    WHERE gcc.game_id = game_uuid 
    AND gcc.is_active = true 
    AND csc.is_active = true
    ORDER BY csc.player_type, csc.confirmation_order;
END;
$$ LANGUAGE plpgsql;

-- Função para obter jogadores de um jogo com status de confirmação
CREATE OR REPLACE FUNCTION get_game_players_with_confirmation_status(game_uuid uuid)
RETURNS TABLE (
    player_id uuid,
    player_name text,
    player_type text,
    confirmation_type text,
    confirmed_at timestamp with time zone,
    confirmation_method text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        gp.player_id,
        p.name,
        gp.player_type,
        COALESCE(pc.confirmation_type, 'pending') as confirmation_type,
        pc.confirmed_at,
        pc.confirmation_method
    FROM game_players gp
    JOIN players p ON gp.player_id = p.id
    LEFT JOIN player_confirmations pc ON gp.game_id = pc.game_id AND gp.player_id = pc.player_id
    WHERE gp.game_id = game_uuid 
    AND gp.status = 'active'
    ORDER BY gp.player_type, p.name;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- DADOS DE EXEMPLO (OPCIONAL - PARA TESTES)
-- =====================================================

-- Inserir configuração de exemplo para um jogo (descomente se necessário)
/*
INSERT INTO game_confirmation_configs (game_id, is_active) 
VALUES ('your-game-uuid-here', true);

-- Configurações para mensalistas
INSERT INTO confirmation_send_configs (game_confirmation_config_id, player_type, confirmation_order, hours_before_game)
SELECT 
    gcc.id,
    'monthly',
    1,
    48
FROM game_confirmation_configs gcc 
WHERE gcc.game_id = 'your-game-uuid-here';

INSERT INTO confirmation_send_configs (game_confirmation_config_id, player_type, confirmation_order, hours_before_game)
SELECT 
    gcc.id,
    'monthly',
    2,
    24
FROM game_confirmation_configs gcc 
WHERE gcc.game_id = 'your-game-uuid-here';

-- Configurações para avulsos
INSERT INTO confirmation_send_configs (game_confirmation_config_id, player_type, confirmation_order, hours_before_game)
SELECT 
    gcc.id,
    'casual',
    1,
    24
FROM game_confirmation_configs gcc 
WHERE gcc.game_id = 'your-game-uuid-here';

INSERT INTO confirmation_send_configs (game_confirmation_config_id, player_type, confirmation_order, hours_before_game)
SELECT 
    gcc.id,
    'casual',
    2,
    12
FROM game_confirmation_configs gcc 
WHERE gcc.game_id = 'your-game-uuid-here';
*/

-- =====================================================
-- COMENTÁRIOS FINAIS
-- =====================================================

-- Esta estrutura permite:
-- 1. Configurar múltiplas confirmações por tipo de jogador
-- 2. Controlar a ordem e timing das confirmações
-- 3. Rastrear todas as confirmações realizadas
-- 4. Logar todos os envios para debugging
-- 5. Manter segurança com RLS
-- 6. Performance otimizada com índices
-- 7. Integridade referencial com foreign keys
