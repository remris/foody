// Supabase Edge Function: groq-proxy
// Leitet KI-Anfragen sicher an Groq weiter.
// Der API-Key liegt nur in Supabase Secrets – nie im App-Bundle.
//
// Deployment:
//   supabase functions deploy groq-proxy
//   supabase secrets set GROQ_API_KEY=gsk_...
//
// Rate-Limits (serverseitig erzwungen):
//   Free:  5 Anfragen / Woche
//   Pro:   unlimitiert

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions";
const FREE_WEEKLY_LIMIT = 5;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req: Request) => {
  // CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // ── 1. Auth prüfen ──────────────────────────────────────────────────
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return json({ error: "Nicht authentifiziert" }, 401);
    }

    const token = authHeader.startsWith("Bearer ")
      ? authHeader.slice(7).trim()
      : authHeader.trim();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: `Bearer ${token}` } } }
    );

    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) {
      console.error("Auth Fehler:", authError?.message, "Token prefix:", token.substring(0, 20));
      return json({ error: `Auth Fehler: ${authError?.message ?? "Ungültiger Token"}` }, 401);
    }

    // ── 2. Abo-Status prüfen ────────────────────────────────────────────
    const { data: sub } = await supabase
      .from("subscriptions")
      .select("plan, valid_until")
      .eq("user_id", user.id)
      .maybeSingle();

    const isPro =
      sub?.plan === "pro" &&
      (!sub.valid_until || new Date(sub.valid_until) > new Date());

    // ── 3. Rate-Limit für Free-User ─────────────────────────────────────
    if (!isPro) {
      const weekStart = getWeekStart();
      const { data: usage } = await supabase
        .from("ai_usage")
        .select("used_this_week, week_start")
        .eq("user_id", user.id)
        .maybeSingle();

      const currentWeekUsage =
        usage?.week_start === weekStart ? (usage?.used_this_week ?? 0) : 0;

      if (currentWeekUsage >= FREE_WEEKLY_LIMIT) {
        return json(
          {
            error: "WEEKLY_LIMIT_REACHED",
            used: currentWeekUsage,
            limit: FREE_WEEKLY_LIMIT,
          },
          429
        );
      }

      // Usage hochzählen
      await supabase.from("ai_usage").upsert(
        {
          user_id: user.id,
          week_start: weekStart,
          used_this_week: currentWeekUsage + 1,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "user_id" }
      );
    }

    // ── 4. Request-Body parsen ──────────────────────────────────────────
    const { prompt, model } = await req.json();
    if (!prompt) {
      return json({ error: "prompt fehlt" }, 400);
    }

    const groqModel = model ?? "llama-3.3-70b-versatile";

    // ── 5. Groq API aufrufen ────────────────────────────────────────────
    const groqKey = Deno.env.get("GROQ_API_KEY");
    if (!groqKey) {
      return json({ error: "GROQ_API_KEY nicht konfiguriert" }, 500);
    }

    const groqResponse = await fetch(GROQ_API_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${groqKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: groqModel,
        messages: [{ role: "user", content: prompt }],
        temperature: 1.2,
        max_tokens: 4096,
        top_p: 0.9,
      }),
    });

    if (!groqResponse.ok) {
      const errorText = await groqResponse.text();
      console.error("Groq Fehler:", groqResponse.status, errorText);
      return json(
        { error: `Groq API Fehler: ${groqResponse.status}` },
        groqResponse.status
      );
    }

    const groqData = await groqResponse.json();
    const content = groqData?.choices?.[0]?.message?.content ?? "";

    return json({ content }, 200);
  } catch (err) {
    console.error("Proxy Fehler:", err);
    return json({ error: String(err) }, 500);
  }
});

// ── Hilfsfunktionen ────────────────────────────────────────────────────────

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** ISO-Wochenstart (Montag) im Format YYYY-MM-DD */
function getWeekStart(): string {
  const now = new Date();
  const day = now.getDay(); // 0=So, 1=Mo, ...
  const diff = day === 0 ? -6 : 1 - day; // Montag als Wochenstart
  const monday = new Date(now);
  monday.setDate(now.getDate() + diff);
  return monday.toISOString().split("T")[0];
}
