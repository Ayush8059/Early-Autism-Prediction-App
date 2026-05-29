import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const maxImageBytes = 5 * 1024 * 1024;

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const anonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? '';
    const mlBackendUrl = Deno.env.get('ML_BACKEND_URL') ?? '';
    const mlApiKey = Deno.env.get('ML_API_KEY') ?? Deno.env.get('MLAPIKEY') ?? '';

    if (!mlBackendUrl || !mlApiKey) {
      return json({ error: 'ML backend is not configured.' }, 503);
    }

    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const { imageBase64 } = await req.json();
    if (typeof imageBase64 !== 'string' || imageBase64.length === 0) {
      return json({ error: 'imageBase64 is required.' }, 400);
    }

    const imageBytes = decodeBase64Image(imageBase64);
    if (imageBytes.byteLength === 0) {
      return json({ error: 'Image is empty.' }, 400);
    }
    if (imageBytes.byteLength > maxImageBytes) {
      return json({ error: 'Image is too large. Maximum allowed size is 5 MB.' }, 413);
    }

    const formData = new FormData();
    formData.append(
      'file',
      new Blob([imageBytes], { type: 'image/jpeg' }),
      `user-${userData.user.id}.jpg`,
    );

    const endpoint = `${mlBackendUrl.replace(/\/$/, '')}/predict`;
    const mlResponse = await fetch(endpoint, {
      method: 'POST',
      headers: { 'x-ml-api-key': mlApiKey },
      body: formData,
    });

    const responseText = await mlResponse.text();
    let responseBody: unknown;
    try {
      responseBody = JSON.parse(responseText);
    } catch {
      responseBody = { error: responseText };
    }

    if (!mlResponse.ok) {
      return json({ error: 'ML backend failed.', detail: responseBody }, mlResponse.status);
    }

    return json(responseBody);
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

function decodeBase64Image(value: string) {
  const clean = value.includes(',') ? value.split(',').pop() ?? '' : value;
  const binary = atob(clean);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }
  return bytes;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
