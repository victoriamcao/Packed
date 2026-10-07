// generate-packing-list
//
// Lets logged-in users get AI packing lists without bringing their own
// Anthropic API key. The key lives here as a secret (never in the app),
// the prompt is built server-side (so the endpoint can't be used as a
// general-purpose free Claude proxy), and each user gets a monthly cap.
//
// Setup:
//   supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   (optional) supabase secrets set ANTHROPIC_MODEL=claude-haiku-4-5-20251001
//   (optional) supabase secrets set MONTHLY_LIST_LIMIT=20
//   supabase functions deploy generate-packing-list
//
// Needs the ai_generations table from supabase/migrations.

import { createClient } from "jsr:@supabase/supabase-js@2";

const MODEL = Deno.env.get("ANTHROPIC_MODEL") ?? "claude-haiku-4-5-20251001";
const MONTHLY_LIMIT = Number(Deno.env.get("MONTHLY_LIST_LIMIT") ?? "20");
const TOOL_NAME = "record_packing_list";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

type Weather = {
  highF: number;
  lowF: number;
  precipitationMM: number;
  snowfallCM: number;
  windKMH: number;
  isForecast: boolean;
  condition: string;
};

type TripRequest = {
  destination?: string;
  tripType?: string;
  gender?: string;
  travelDate?: string;
  lengthDays?: number;
  weather?: Weather;
};

// Keep user-supplied text short and single-line before it goes in the prompt.
const clean = (value: unknown, max = 80) =>
  typeof value === "string" ? value.replace(/\s+/g, " ").trim().slice(0, max) : "";

function buildPrompt(trip: TripRequest): string {
  const days = Math.min(Math.max(Math.round(Number(trip.lengthDays) || 1), 1), 60);
  let weatherLine = "Weather: unknown - use seasonally reasonable assumptions for the destination and date.";
  const w = trip.weather;
  if (w && typeof w.highF === "number") {
    const source = w.isForecast ? "forecast" : "historical average";
    weatherLine =
      `Weather (${source}): high ${Math.round(w.highF)}°F, low ${Math.round(w.lowF)}°F, ` +
      `precipitation ${Number(w.precipitationMM).toFixed(1)}mm, snowfall ${Number(w.snowfallCM).toFixed(1)}cm, ` +
      `wind ${Math.round(w.windKMH)}km/h. Overall conditions: ${clean(w.condition, 20)}.`;
  }

  return `Generate a complete, practical packing list for the trip described below.

Destination: ${clean(trip.destination) || "Not specified"}
Trip type: ${clean(trip.tripType, 40)}
Traveler: ${clean(trip.gender, 30)}
Trip length: ${days} day(s)
Travel date: ${clean(trip.travelDate, 10)}
${weatherLine}

Guidelines:
- Scale clothing quantities sensibly to the trip length (include the quantity in the item name when more than one is needed).
- Group items into clear categories such as Essentials, Clothing, Toiletries & Personal Items, and any trip-specific gear category appropriate to the trip type and weather.
- Include practical essentials (documents, chargers, toiletries) as well as weather- and activity-appropriate items.
- Do not include duplicate items.

Call the ${TOOL_NAME} tool with the full list.`;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) {
    return json({ error: "AI lists aren't set up on the server yet." }, 503);
  }

  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  const { data: userData, error: userError } = await admin.auth.getUser(jwt);
  const user = userData?.user;
  if (userError || !user) {
    return json({ error: "Log in to get AI packing lists." }, 401);
  }

  // Monthly cap per user.
  const since = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
  const { count, error: countError } = await admin
    .from("ai_generations")
    .select("*", { count: "exact", head: true })
    .eq("user_id", user.id)
    .gte("created_at", since);
  if (countError) {
    console.error("ai_generations count failed", countError);
    return json({ error: "AI lists are unavailable right now." }, 503);
  }
  if ((count ?? 0) >= MONTHLY_LIMIT) {
    return json({ error: `You've used all ${MONTHLY_LIMIT} AI lists for this month.` }, 429);
  }

  let trip: TripRequest;
  try {
    trip = await req.json();
  } catch {
    return json({ error: "Bad request" }, 400);
  }

  const anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": apiKey,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 4096,
      tools: [
        {
          name: TOOL_NAME,
          description: "Records the generated packing list.",
          input_schema: {
            type: "object",
            properties: {
              items: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    name: { type: "string", description: "The item, with a quantity in the name if more than one (e.g. \"3 T-shirts\")." },
                    category: { type: "string", description: "A short category label (e.g. Essentials, Clothing, Hiking Gear)." },
                  },
                  required: ["name", "category"],
                },
              },
            },
            required: ["items"],
          },
        },
      ],
      tool_choice: { type: "tool", name: TOOL_NAME },
      messages: [{ role: "user", content: buildPrompt(trip) }],
    }),
  });

  if (!anthropicResponse.ok) {
    console.error("Anthropic API error", anthropicResponse.status, await anthropicResponse.text());
    return json({ error: "AI lists are unavailable right now." }, 502);
  }

  const result = await anthropicResponse.json();
  const toolUse = (result.content ?? []).find(
    (block: { type: string; name?: string }) => block.type === "tool_use" && block.name === TOOL_NAME,
  );
  const rawItems: unknown[] = Array.isArray(toolUse?.input?.items) ? toolUse.input.items : [];
  const items = rawItems
    .filter((i): i is { name: string; category: string } =>
      typeof (i as { name?: unknown })?.name === "string" && typeof (i as { category?: unknown })?.category === "string")
    .slice(0, 200)
    .map((i) => ({ name: i.name.slice(0, 100), category: i.category.slice(0, 50) }));

  if (items.length === 0) {
    return json({ error: "The AI didn't return a list. Try again." }, 502);
  }

  // Only successful generations count toward the monthly cap.
  await admin.from("ai_generations").insert({ user_id: user.id });

  return json({ items });
});
