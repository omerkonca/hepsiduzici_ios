-- FCM cihaz token kayıtları
CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  token text UNIQUE NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
  app_version text,
  marketing_opt_in boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_updated ON public.device_tokens(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_device_tokens_marketing ON public.device_tokens(marketing_opt_in) WHERE marketing_opt_in = true;

CREATE TABLE IF NOT EXISTS public.push_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  body text NOT NULL,
  target text NOT NULL DEFAULT 'all',
  sent_count int NOT NULL DEFAULT 0,
  failed_count int NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.push_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS device_tokens_insert_anon ON public.device_tokens;
CREATE POLICY device_tokens_insert_anon ON public.device_tokens
  FOR INSERT TO anon, authenticated WITH CHECK (true);

DROP POLICY IF EXISTS device_tokens_update_anon ON public.device_tokens;
CREATE POLICY device_tokens_update_anon ON public.device_tokens
  FOR UPDATE TO anon, authenticated USING (true) WITH CHECK (true);
