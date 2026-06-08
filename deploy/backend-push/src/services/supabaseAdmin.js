import { createClient } from '@supabase/supabase-js';

let client;

export function getSupabaseAdmin() {
  if (client) return client;
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  client = createClient(url, key, { auth: { persistSession: false } });
  return client;
}

export async function upsertDeviceToken({ token, platform, appVersion, marketingOptIn }) {
  const sb = getSupabaseAdmin();
  if (!sb) return { ok: false, error: 'Supabase not configured' };

  const { error } = await sb.from('device_tokens').upsert(
    {
      token,
      platform,
      app_version: appVersion ?? null,
      marketing_opt_in: marketingOptIn ?? true,
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'token' },
  );

  if (error) return { ok: false, error: error.message };
  return { ok: true };
}

export async function fetchMarketingTokens() {
  const sb = getSupabaseAdmin();
  if (!sb) return [];

  const { data, error } = await sb
    .from('device_tokens')
    .select('token')
    .eq('marketing_opt_in', true);

  if (error) {
    console.error('[Supabase] fetch tokens:', error.message);
    return [];
  }
  return (data ?? []).map((r) => r.token).filter(Boolean);
}

export async function logPush({ title, body, target, sent, failed }) {
  const sb = getSupabaseAdmin();
  if (!sb) return;
  await sb.from('push_logs').insert({
    title,
    body,
    target,
    sent_count: sent,
    failed_count: failed,
  });
}
