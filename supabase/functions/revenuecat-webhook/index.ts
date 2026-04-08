// Supabase Edge Function: revenuecat-webhook
// Empfängt RevenueCat Webhook-Events und aktualisiert die Supabase subscriptions-Tabelle
//
// Die subscriptions-Tabelle hat folgende Spalten (aus supabase_setup.sql):
//   user_id, plan, valid_until, source, revenuecat_product_id,
//   revenuecat_store, environment, cancelled_at, cancel_reason, started_at
//
// Konfiguration in RevenueCat Dashboard:
//   Webhooks → Neue URL: https://<project-ref>.supabase.co/functions/v1/revenuecat-webhook
//   Authorization: Bearer <REVENUECAT_WEBHOOK_SECRET>
//
// Supabase Secrets setzen (einmalig via CLI):
//   supabase secrets set REVENUECAT_WEBHOOK_SECRET=<dein-secret>
//   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<service-role-key>

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const REVENUECAT_WEBHOOK_SECRET = Deno.env.get('REVENUECAT_WEBHOOK_SECRET');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

type RevenueCatEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'CANCELLATION'
  | 'UNCANCELLATION'
  | 'BILLING_ISSUE'
  | 'EXPIRATION'
  | 'PRODUCT_CHANGE'
  | 'TRANSFER';

interface RevenueCatEvent {
  type: RevenueCatEventType;
  app_user_id: string;        // = Supabase User-ID (via Purchases.logIn(userId))
  product_id?: string;        // z.B. 'foody_pro_monthly' oder 'foody_pro_yearly'
  entitlement_ids?: string[]; // z.B. ['pro']
  expiration_at_ms?: number;  // Unix ms → wird zu valid_until
  purchased_at_ms?: number;
  cancel_reason?: string;
  environment?: 'SANDBOX' | 'PRODUCTION';
  store?: 'APP_STORE' | 'PLAY_STORE';
}

interface RevenueCatWebhookBody {
  api_version: string;
  event: RevenueCatEvent;
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Webhook-Secret prüfen
  if (REVENUECAT_WEBHOOK_SECRET) {
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== `Bearer ${REVENUECAT_WEBHOOK_SECRET}`) {
      console.error('Unauthorized webhook attempt');
      return new Response('Unauthorized', { status: 401 });
    }
  }

  let body: RevenueCatWebhookBody;
  try {
    body = await req.json();
  } catch {
    return new Response('Invalid JSON body', { status: 400 });
  }

  const { event } = body;
  console.log(`RevenueCat Event: ${event.type} for user ${event.app_user_id}`);

  // Service-Role-Client (umgeht RLS)
  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  const userId = event.app_user_id;

  // valid_until aus expiration_at_ms (milliseconds → ISO string)
  const validUntil = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null;

  const startedAt = event.purchased_at_ms
    ? new Date(event.purchased_at_ms).toISOString()
    : null;

  // Plan bestimmen
  const isPro = event.entitlement_ids?.includes('pro') ?? false;
  let plan: 'free' | 'pro' | 'pro_yearly' = 'free';
  if (isPro && event.product_id?.includes('yearly')) {
    plan = 'pro_yearly';
  } else if (isPro) {
    plan = 'pro';
  }

  try {
    switch (event.type) {

      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'UNCANCELLATION':
        // Pro-Abo aktivieren / verlängern
        await supabase.from('subscriptions').upsert({
          user_id: userId,
          plan,
          valid_until: validUntil,
          started_at: startedAt,
          source: 'revenuecat',
          revenuecat_product_id: event.product_id ?? null,
          revenuecat_store: event.store ?? null,
          environment: event.environment ?? null,
          cancelled_at: null,       // Kündigung aufheben
          cancel_reason: null,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });

        console.log(`✅ Pro aktiviert für ${userId} – gültig bis ${validUntil}`);
        break;

      case 'CANCELLATION':
        // Abo gekündigt – bleibt aktiv bis valid_until, dann automatisch abgelaufen
        await supabase.from('subscriptions')
          .update({
            cancelled_at: new Date().toISOString(),
            cancel_reason: event.cancel_reason ?? null,
            updated_at: new Date().toISOString(),
          })
          .eq('user_id', userId);

        console.log(`⚠️ Abo gekündigt für ${userId}, aktiv bis ${validUntil}`);
        break;

      case 'EXPIRATION':
      case 'BILLING_ISSUE':
        // Abgelaufen → auf Free zurücksetzen
        await supabase.from('subscriptions').upsert({
          user_id: userId,
          plan: 'free',
          valid_until: null,
          source: 'revenuecat',
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });

        console.log(`❌ Abo abgelaufen für ${userId}`);
        break;

      case 'PRODUCT_CHANGE':
        // Planwechsel (z.B. monatlich → jährlich)
        await supabase.from('subscriptions').upsert({
          user_id: userId,
          plan,
          valid_until: validUntil,
          revenuecat_product_id: event.product_id ?? null,
          updated_at: new Date().toISOString(),
        }, { onConflict: 'user_id' });

        console.log(`🔄 Plan gewechselt für ${userId} → ${plan}`);
        break;

      case 'TRANSFER':
        console.log(`ℹ️ Transfer Event für ${userId} – keine Aktion`);
        break;

      default:
        console.log(`ℹ️ Unbekannter Event-Typ: ${event.type}`);
    }

    return new Response(JSON.stringify({ success: true, event: event.type }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' },
    });

  } catch (error) {
    console.error('Fehler beim Verarbeiten des RevenueCat Webhooks:', error);
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
