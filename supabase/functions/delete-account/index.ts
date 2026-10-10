// delete-account
//
// Permanently deletes the calling user's account and all of their data:
// map photos in Storage, map pins, packing lists, list shares, profile,
// and finally the auth user itself. Required by App Store Guideline
// 5.1.1(v) for any app that lets people create an account.
//
// Uses the service-role key, which Supabase injects into Edge Functions
// automatically. It must never be put in the app.
//
// Deploy: supabase functions deploy delete-account

import { createClient } from "jsr:@supabase/supabase-js@2";

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const jwt = (req.headers.get("Authorization") ?? "").replace(/^Bearer\s+/i, "");
  if (!jwt) {
    return json({ error: "Not logged in" }, 401);
  }

  const admin = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // Who is asking? Verified from their own access token.
  const { data: userData, error: userError } = await admin.auth.getUser(jwt);
  const user = userData?.user;
  if (userError || !user) {
    return json({ error: "Not logged in" }, 401);
  }
  const userId = user.id;

  try {
    // 1. Photos in Storage live under "<userId>/...".
    const bucket = admin.storage.from("map-photos");
    while (true) {
      const { data: files, error } = await bucket.list(userId, { limit: 100 });
      if (error) throw error;
      if (!files || files.length === 0) break;
      const { error: removeError } = await bucket.remove(files.map((f) => `${userId}/${f.name}`));
      if (removeError) throw removeError;
      if (files.length < 100) break;
    }

    // 2. Rows. list_shares may not exist if sharing was never set up.
    const steps: Array<[string, string]> = [
      ["list_shares", "user_id"],
      ["map_pins", "user_id"],
      ["packing_lists", "user_id"],
      ["ai_generations", "user_id"],
      ["profiles", "id"],
    ];
    for (const [table, column] of steps) {
      const { error } = await admin.from(table).delete().eq(column, userId);
      // 42P01 = table doesn't exist; fine to skip.
      if (error && error.code !== "42P01" && !/does not exist|schema cache/i.test(error.message)) {
        throw error;
      }
    }

    // 3. The auth user itself.
    const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
    if (deleteError) throw deleteError;

    return json({ deleted: true });
  } catch (e) {
    console.error("delete-account failed", userId, e);
    return json({ error: "Couldn't delete your account. Please try again." }, 500);
  }
});
