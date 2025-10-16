-- =====================================================
-- TABELAS DO SISTEMA DE NOTIFICAÇÕES
-- =====================================================

-- Tabela: notifications
CREATE TABLE public.notifications (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    player_id uuid NOT NULL,
    game_id uuid NOT NULL,
    type text NOT NULL, -- 'game_reminder', 'game_confirmation', 'game_cancelled', 'game_updated'
    title text NOT NULL,
    message text NOT NULL,
    status text DEFAULT 'pending' NOT NULL, -- 'pending', 'sending', 'sent', 'delivered', 'failed', 'cancelled', 'read'
    channels text[] NOT NULL, -- ['whatsapp', 'email', 'push']
    metadata jsonb DEFAULT '{}' NOT NULL, -- Dados específicos do canal
    scheduled_for timestamp with time zone NOT NULL,
    sent_at timestamp with time zone NULL,
    delivered_at timestamp with time zone NULL,
    read_at timestamp with time zone NULL,
    error_message text NULL,
    retry_count integer DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notifications_pkey PRIMARY KEY (id),
    CONSTRAINT notifications_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE,
    CONSTRAINT notifications_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id) ON DELETE CASCADE,
    CONSTRAINT notifications_type_check CHECK (type IN ('game_reminder', 'game_confirmation', 'game_cancelled', 'game_updated')),
    CONSTRAINT notifications_status_check CHECK (status IN ('pending', 'sending', 'sent', 'delivered', 'failed', 'cancelled', 'read')),
    CONSTRAINT notifications_channels_check CHECK (array_length(channels, 1) > 0)
);

-- Tabela: notification_configs (já existe, mas vamos garantir que está correta)
CREATE TABLE IF NOT EXISTS public.notification_configs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    player_id uuid NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    advance_hours integer DEFAULT 24 NOT NULL,
    whatsapp_enabled boolean DEFAULT true NOT NULL,
    whatsapp_number text NULL,
    email_enabled boolean DEFAULT false NOT NULL,
    email text NULL,
    push_enabled boolean DEFAULT true NOT NULL,
    game_types text[] DEFAULT '{"all"}'::text[] NOT NULL,
    days_of_week text[] DEFAULT '{"0","1","2","3","4","5","6"}'::text[] NOT NULL,
    time_slots integer[] DEFAULT '{18,19,20,21}'::integer[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notification_configs_pkey PRIMARY KEY (id),
    CONSTRAINT notification_configs_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE,
    CONSTRAINT notification_configs_player_id_unique UNIQUE (player_id)
);

-- Tabela: notification_templates
CREATE TABLE public.notification_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    type text NOT NULL,
    title text NOT NULL,
    message text NOT NULL,
    variables jsonb DEFAULT '{}' NOT NULL, -- Variáveis que podem ser substituídas
    required_channels text[] NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notification_templates_pkey PRIMARY KEY (id),
    CONSTRAINT notification_templates_type_check CHECK (type IN ('game_reminder', 'game_confirmation', 'game_cancelled', 'game_updated')),
    CONSTRAINT notification_templates_type_unique UNIQUE (type)
);

-- Tabela: notification_logs
CREATE TABLE public.notification_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    notification_id uuid NOT NULL,
    channel text NOT NULL,
    status text NOT NULL, -- 'sent', 'delivered', 'failed', 'read'
    error_message text NULL,
    response jsonb NULL,
    timestamp timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT notification_logs_pkey PRIMARY KEY (id),
    CONSTRAINT notification_logs_notification_id_fkey FOREIGN KEY (notification_id) REFERENCES public.notifications(id) ON DELETE CASCADE,
    CONSTRAINT notification_logs_channel_check CHECK (channel IN ('whatsapp', 'email', 'push')),
    CONSTRAINT notification_logs_status_check CHECK (status IN ('sent', 'delivered', 'failed', 'read'))
);

-- Tabela: player_fcm_tokens
CREATE TABLE public.player_fcm_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    player_id uuid NOT NULL,
    fcm_token text NOT NULL,
    device_type text DEFAULT 'mobile' NOT NULL, -- 'mobile', 'web', 'desktop'
    is_active boolean DEFAULT true NOT NULL,
    last_used_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT player_fcm_tokens_pkey PRIMARY KEY (id),
    CONSTRAINT player_fcm_tokens_player_id_fkey FOREIGN KEY (player_id) REFERENCES public.players(id) ON DELETE CASCADE,
    CONSTRAINT player_fcm_tokens_fcm_token_unique UNIQUE (fcm_token),
    CONSTRAINT player_fcm_tokens_device_type_check CHECK (device_type IN ('mobile', 'web', 'desktop'))
);

-- =====================================================
-- ÍNDICES
-- =====================================================

-- Índices para notifications
CREATE INDEX notifications_player_id_idx ON public.notifications USING btree (player_id);
CREATE INDEX notifications_game_id_idx ON public.notifications USING btree (game_id);
CREATE INDEX notifications_status_idx ON public.notifications USING btree (status);
CREATE INDEX notifications_scheduled_for_idx ON public.notifications USING btree (scheduled_for);
CREATE INDEX notifications_type_idx ON public.notifications USING btree (type);
CREATE INDEX notifications_created_at_idx ON public.notifications USING btree (created_at);

-- Índices para notification_configs
CREATE INDEX notification_configs_player_id_idx ON public.notification_configs USING btree (player_id);
CREATE INDEX notification_configs_enabled_idx ON public.notification_configs USING btree (enabled);

-- Índices para notification_templates
CREATE INDEX notification_templates_type_idx ON public.notification_templates USING btree (type);
CREATE INDEX notification_templates_is_active_idx ON public.notification_templates USING btree (is_active);

-- Índices para notification_logs
CREATE INDEX notification_logs_notification_id_idx ON public.notification_logs USING btree (notification_id);
CREATE INDEX notification_logs_channel_idx ON public.notification_logs USING btree (channel);
CREATE INDEX notification_logs_status_idx ON public.notification_logs USING btree (status);
CREATE INDEX notification_logs_timestamp_idx ON public.notification_logs USING btree (timestamp);

-- Índices para player_fcm_tokens
CREATE INDEX player_fcm_tokens_player_id_idx ON public.player_fcm_tokens USING btree (player_id);
CREATE INDEX player_fcm_tokens_is_active_idx ON public.player_fcm_tokens USING btree (is_active);
CREATE INDEX player_fcm_tokens_last_used_at_idx ON public.player_fcm_tokens USING btree (last_used_at);

-- =====================================================
-- RLS (ROW LEVEL SECURITY)
-- =====================================================

-- Habilitar RLS em todas as tabelas
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.player_fcm_tokens ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- POLÍTICAS RLS PARA NOTIFICATIONS
-- =====================================================

-- Policy para SELECT: Jogador pode ver suas próprias notificações
CREATE POLICY "Players can view their own notifications." ON public.notifications
FOR SELECT USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notifications.player_id AND players.user_id = auth.uid())))
);

-- Policy para INSERT: Sistema pode criar notificações para jogadores
CREATE POLICY "System can create notifications for players." ON public.notifications
FOR INSERT WITH CHECK (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notifications.player_id AND players.user_id = auth.uid())))
);

-- Policy para UPDATE: Sistema pode atualizar notificações
CREATE POLICY "System can update notifications." ON public.notifications
FOR UPDATE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notifications.player_id AND players.user_id = auth.uid())))
);

-- Policy para DELETE: Sistema pode deletar notificações antigas
CREATE POLICY "System can delete old notifications." ON public.notifications
FOR DELETE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notifications.player_id AND players.user_id = auth.uid())))
);

-- =====================================================
-- POLÍTICAS RLS PARA NOTIFICATION_CONFIGS
-- =====================================================

-- Policy para SELECT: Jogador pode ver suas próprias configurações
CREATE POLICY "Players can view their own notification configs." ON public.notification_configs
FOR SELECT USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notification_configs.player_id AND players.user_id = auth.uid())))
);

-- Policy para INSERT: Jogador pode criar suas próprias configurações
CREATE POLICY "Players can create their own notification configs." ON public.notification_configs
FOR INSERT WITH CHECK (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notification_configs.player_id AND players.user_id = auth.uid())))
);

-- Policy para UPDATE: Jogador pode atualizar suas próprias configurações
CREATE POLICY "Players can update their own notification configs." ON public.notification_configs
FOR UPDATE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notification_configs.player_id AND players.user_id = auth.uid())))
);

-- Policy para DELETE: Jogador pode deletar suas próprias configurações
CREATE POLICY "Players can delete their own notification configs." ON public.notification_configs
FOR DELETE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notification_configs.player_id AND players.user_id = auth.uid())))
);

-- =====================================================
-- POLÍTICAS RLS PARA NOTIFICATION_TEMPLATES
-- =====================================================

-- Policy para SELECT: Todos podem ver templates ativos
CREATE POLICY "Everyone can view active notification templates." ON public.notification_templates
FOR SELECT USING (is_active = true);

-- Policy para INSERT/UPDATE/DELETE: Apenas administradores (por enquanto, permitir para todos)
CREATE POLICY "Admins can manage notification templates." ON public.notification_templates
FOR ALL USING (true);

-- =====================================================
-- POLÍTICAS RLS PARA NOTIFICATION_LOGS
-- =====================================================

-- Policy para SELECT: Jogador pode ver logs de suas notificações
CREATE POLICY "Players can view logs of their notifications." ON public.notification_logs
FOR SELECT USING (
    (EXISTS ( SELECT 1 FROM public.notifications WHERE (notifications.id = notification_logs.notification_id AND EXISTS ( SELECT 1 FROM public.players WHERE (players.id = notifications.player_id AND players.user_id = auth.uid())))))
);

-- Policy para INSERT: Sistema pode criar logs
CREATE POLICY "System can create notification logs." ON public.notification_logs
FOR INSERT WITH CHECK (true);

-- =====================================================
-- POLÍTICAS RLS PARA PLAYER_FCM_TOKENS
-- =====================================================

-- Policy para SELECT: Jogador pode ver seus próprios tokens
CREATE POLICY "Players can view their own FCM tokens." ON public.player_fcm_tokens
FOR SELECT USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = player_fcm_tokens.player_id AND players.user_id = auth.uid())))
);

-- Policy para INSERT: Jogador pode criar seus próprios tokens
CREATE POLICY "Players can create their own FCM tokens." ON public.player_fcm_tokens
FOR INSERT WITH CHECK (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = player_fcm_tokens.player_id AND players.user_id = auth.uid())))
);

-- Policy para UPDATE: Jogador pode atualizar seus próprios tokens
CREATE POLICY "Players can update their own FCM tokens." ON public.player_fcm_tokens
FOR UPDATE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = player_fcm_tokens.player_id AND players.user_id = auth.uid())))
);

-- Policy para DELETE: Jogador pode deletar seus próprios tokens
CREATE POLICY "Players can delete their own FCM tokens." ON public.player_fcm_tokens
FOR DELETE USING (
    (EXISTS ( SELECT 1 FROM public.players WHERE (players.id = player_fcm_tokens.player_id AND players.user_id = auth.uid())))
);

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger para atualizar 'updated_at' em notifications
CREATE OR REPLACE FUNCTION public.update_notifications_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notifications_updated_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW EXECUTE FUNCTION public.update_notifications_updated_at();

-- Trigger para atualizar 'updated_at' em notification_configs
CREATE OR REPLACE FUNCTION public.update_notification_configs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notification_configs_updated_at
BEFORE UPDATE ON public.notification_configs
FOR EACH ROW EXECUTE FUNCTION public.update_notification_configs_updated_at();

-- Trigger para atualizar 'updated_at' em notification_templates
CREATE OR REPLACE FUNCTION public.update_notification_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notification_templates_updated_at
BEFORE UPDATE ON public.notification_templates
FOR EACH ROW EXECUTE FUNCTION public.update_notification_templates_updated_at();

-- Trigger para atualizar 'updated_at' em player_fcm_tokens
CREATE OR REPLACE FUNCTION public.update_player_fcm_tokens_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_player_fcm_tokens_updated_at
BEFORE UPDATE ON public.player_fcm_tokens
FOR EACH ROW EXECUTE FUNCTION public.update_player_fcm_tokens_updated_at();

-- =====================================================
-- DADOS INICIAIS
-- =====================================================

-- Inserir templates padrão
INSERT INTO public.notification_templates (type, title, message, required_channels, variables) VALUES
('game_confirmation', 'Confirmação de Jogo - {{game_name}}', 'Olá {{player_name}}! Você foi convidado para o jogo {{game_name}} em {{game_date}} às {{game_time}} no local {{game_location}}. Para confirmar sua presença, acesse: {{confirmation_link}}', ARRAY['whatsapp', 'email', 'push'], '{"game_name": "Nome do jogo", "player_name": "Nome do jogador", "game_date": "Data do jogo", "game_time": "Horário do jogo", "game_location": "Local do jogo", "confirmation_link": "Link de confirmação"}'),
('game_reminder', 'Lembrete de Jogo - {{game_name}}', 'Olá {{player_name}}! Lembrete: Você tem um jogo em {{hours_until}} horas! {{game_name}} em {{game_date}} às {{game_time}} no local {{game_location}}. Não esqueça de levar roupas adequadas e água!', ARRAY['whatsapp', 'email', 'push'], '{"game_name": "Nome do jogo", "player_name": "Nome do jogador", "game_date": "Data do jogo", "game_time": "Horário do jogo", "game_location": "Local do jogo", "hours_until": "Horas até o jogo"}'),
('game_cancellation', 'Jogo Cancelado - {{game_name}}', 'Olá {{player_name}}! Infelizmente o jogo {{game_name}} em {{game_date}} às {{game_time}} foi cancelado. Motivo: {{reason}}. Desculpe pelo inconveniente.', ARRAY['whatsapp', 'email', 'push'], '{"game_name": "Nome do jogo", "player_name": "Nome do jogador", "game_date": "Data do jogo", "game_time": "Horário do jogo", "reason": "Motivo do cancelamento"}'),
('game_update', 'Jogo Atualizado - {{game_name}}', 'Olá {{player_name}}! O jogo {{game_name}} foi atualizado. Nova data: {{game_date}} às {{game_time}} no local {{game_location}}. Alterações: {{changes}}', ARRAY['whatsapp', 'email', 'push'], '{"game_name": "Nome do jogo", "player_name": "Nome do jogador", "game_date": "Data do jogo", "game_time": "Horário do jogo", "game_location": "Local do jogo", "changes": "Descrição das alterações"}')
ON CONFLICT (type) DO NOTHING;

-- =====================================================
-- FUNÇÕES ÚTEIS
-- =====================================================

-- Função para limpar notificações antigas (mais de 30 dias)
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notifications 
    WHERE created_at < (now() - interval '30 days')
    AND status IN ('sent', 'delivered', 'failed', 'cancelled');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Função para limpar logs antigos (mais de 90 dias)
CREATE OR REPLACE FUNCTION public.cleanup_old_notification_logs()
RETURNS INTEGER AS $$
DECLARE
    deleted_count INTEGER;
BEGIN
    DELETE FROM public.notification_logs 
    WHERE timestamp < (now() - interval '90 days');
    
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$ LANGUAGE plpgsql;

-- Função para obter estatísticas de notificações
CREATE OR REPLACE FUNCTION public.get_notification_stats(player_id_param UUID)
RETURNS TABLE (
    total_notifications BIGINT,
    sent_notifications BIGINT,
    failed_notifications BIGINT,
    pending_notifications BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_notifications,
        COUNT(*) FILTER (WHERE status = 'sent') as sent_notifications,
        COUNT(*) FILTER (WHERE status = 'failed') as failed_notifications,
        COUNT(*) FILTER (WHERE status = 'pending') as pending_notifications
    FROM public.notifications 
    WHERE notifications.player_id = player_id_param;
END;
$$ LANGUAGE plpgsql;
