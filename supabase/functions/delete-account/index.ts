import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function jwtRole(jwt: string) {
  try {
    const payload = jwt.split('.')[1];
    const normalized = payload.replace(/-/g, '+').replace(/_/g, '/');
    const decoded = JSON.parse(atob(normalized));
    return decoded.role as string | undefined;
  } catch (_) {
    return undefined;
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SERVICE_ROLE_KEY') ??
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Server is not configured.' }, 500);
    }

    if (jwtRole(serviceRoleKey) !== 'service_role') {
      return json(
        {
          error:
            'Delete account is not configured securely. Set SERVICE_ROLE_KEY to your Supabase service_role key.',
        },
        500,
      );
    }

    const authHeader = req.headers.get('Authorization') ?? '';
    const jwt = authHeader.replace('Bearer ', '').trim();
    if (!jwt) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    if (jwtRole(jwt) !== 'authenticated') {
      return json({ error: 'Unauthorized.' }, 401);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    const { data: userData, error: userError } = await admin.auth.getUser(jwt);
    const user = userData.user;
    if (userError || !user) {
      return json({ error: 'Unauthorized.' }, 401);
    }

    for (const bucket of ['child-photos', 'parent-avatars']) {
      const { data: files } = await admin.storage.from(bucket).list(user.id, { limit: 1000 });
      if (files && files.length > 0) {
        await admin.storage.from(bucket).remove(files.map((file) => `${user.id}/${file.name}`));
      }
    }

    const { error: deleteError } = await admin.auth.admin.deleteUser(user.id);
    if (deleteError) {
      return json({ error: deleteError.message }, 400);
    }

    return json({ ok: true });
  } catch (_) {
    return json({ error: 'Could not delete account.' }, 500);
  }
});
