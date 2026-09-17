// Deletes the calling user's account entirely: their uploaded Storage files,
// then the auth.users row itself (which cascades to their `triggers` and
// `reports` rows — both already declared `on delete cascade` back to
// auth.users in the schema migration).
//
// The service role key never leaves this function; the client only ever
// calls this endpoint with its own session token.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const BUCKETS = ["trigger-targets", "trigger-content"];

Deno.serve(async (req) => {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Missing Authorization header" }), { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Verify the caller is who they claim to be, using their own token.
  const callerClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return new Response(JSON.stringify({ error: "Invalid session" }), { status: 401 });
  }
  const userId = userData.user.id;

  // Admin client — service role, never exposed to the app.
  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  for (const bucket of BUCKETS) {
    const { data: files } = await adminClient.storage.from(bucket).list(userId);
    if (files && files.length > 0) {
      const paths = files.map((f) => `${userId}/${f.name}`);
      await adminClient.storage.from(bucket).remove(paths);
    }
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(userId);
  if (deleteError) {
    return new Response(JSON.stringify({ error: deleteError.message }), { status: 500 });
  }

  return new Response(JSON.stringify({ success: true }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
