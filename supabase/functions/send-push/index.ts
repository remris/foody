// Supabase Edge Function: send-push
// Versendet FCM Push-Notifications an einzelne User oder Topics
//
// Wird aufgerufen von:
//   - DB-Trigger bei neuen Haushalt-Chat-Nachrichten
//   - DB-Trigger bei neuen recipe_likes / recipe_comments
//   - Manuell via HTTP POST für MHD-Warnungen (täglich via Cron)
//
// Supabase Secrets setzen:
//   supabase secrets set FCM_SERVER_KEY=<firebase-server-key>
//   (oder besser: FCM_SERVICE_ACCOUNT_JSON=<service-account-json>)
//
// Aufruf-Format:
//   POST /functions/v1/send-push
//   Body: { "userId": "...", "title": "...", "body": "...", "data": {} }
//   ODER: { "topic": "household_xxx", "title": "...", "body": "..." }

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
// Firebase Server Key (aus Firebase Console → Projekteinstellungen → Cloud Messaging)
const FCM_SERVER_KEY = Deno.env.get('FCM_SERVER_KEY');

interface PushPayload {
  // Einzelner User (token-basiert)
  userId?: string;
  // Topic-Broadcast (z.B. 'household_<id>', 'global')
  topic?: string;
  title: string;
  body: string;
  data?: Record<string, string>;
  imageUrl?: string;
}

interface FcmMessage {
  to?: string;           // FCM Token oder /topics/<topic>
  registration_ids?: string[]; // Mehrere Tokens (max 500)
  notification: {
    title: string;
    body: string;
    image?: string;
  };
  data?: Record<string, string>;
  android?: {
    priority: 'high' | 'normal';
    notification?: {
      channel_id: string;
      click_action?: string;
    };
  };
  apns?: {
    payload: {
      aps: {
        sound: string;
        badge?: number;
      };
    };
  };
}

Deno.serve(async (req: Request) => {
  // CORS für lokale Tests
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // Authentifizierung: nur Service Role oder authentifizierte User
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response('Unauthorized', { status: 401 });
  }

  let payload: PushPayload;
  try {
    payload = await req.json();
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  if (!payload.title || !payload.body) {
    return new Response('title and body are required', { status: 400 });
  }

  const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

  let fcmTargets: string[] = [];
  let targetType: 'token' | 'topic' = 'token';

  if (payload.topic) {
    // Topic-Broadcast
    targetType = 'topic';
    fcmTargets = [`/topics/${payload.topic}`];
  } else if (payload.userId) {
    // Token-basiert: alle Tokens des Users holen
    const { data: tokens, error } = await supabase
      .from('push_tokens')
      .select('token')
      .eq('user_id', payload.userId);

    if (error || !tokens?.length) {
      return new Response(
        JSON.stringify({ success: false, reason: 'no_tokens_found' }),
        { status: 200, headers: { 'Content-Type': 'application/json' } }
      );
    }
    fcmTargets = tokens.map((t: { token: string }) => t.token);
  } else {
    return new Response('userId or topic required', { status: 400 });
  }

  if (!FCM_SERVER_KEY) {
    console.warn('FCM_SERVER_KEY nicht gesetzt – Simulation-Modus');
    console.log(`[SIMULATED] Sende Push an ${targetType}:`, fcmTargets, payload);
    return new Response(
      JSON.stringify({ success: true, simulated: true, targets: fcmTargets.length }),
      { headers: { 'Content-Type': 'application/json' } }
    );
  }

  // FCM Legacy API aufrufen (für Token-basierte Nachrichten)
  // Für Topic-basierte und neue Projekte: FCM v1 API verwenden
  const results = await Promise.allSettled(
    fcmTargets.map(async (target) => {
      const message: FcmMessage = {
        to: target,
        notification: {
          title: payload.title,
          body: payload.body,
          ...(payload.imageUrl ? { image: payload.imageUrl } : {}),
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            channel_id: 'fcm_high_importance',
          },
        },
        apns: {
          payload: {
            aps: { sound: 'default' },
          },
        },
      };

      const response = await fetch('https://fcm.googleapis.com/fcm/send', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `key=${FCM_SERVER_KEY}`,
        },
        body: JSON.stringify(message),
      });

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`FCM Error ${response.status}: ${errorText}`);
      }

      return response.json();
    })
  );

  const successful = results.filter(r => r.status === 'fulfilled').length;
  const failed = results.filter(r => r.status === 'rejected').length;

  // Notification in Log schreiben (optional)
  if (payload.userId) {
    await supabase.from('notification_log').insert({
      user_id: payload.userId,
      notification_type: payload.data?.type ?? 'general',
      title: payload.title,
      body: payload.body,
      data: payload.data,
    }).then(() => {}).catch(() => {}); // Fehler ignorieren wenn Tabelle nicht existiert
  }

  console.log(`✅ Push-Notifications: ${successful} erfolgreich, ${failed} fehlgeschlagen`);

  return new Response(
    JSON.stringify({ success: true, sent: successful, failed }),
    { headers: { 'Content-Type': 'application/json' } }
  );
});

