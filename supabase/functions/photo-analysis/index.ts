import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

const maxImageBytes = 5 * 1024 * 1024;
const maxBase64Chars = Math.ceil(maxImageBytes * 1.37);

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
    if (!supabaseUrl || !anonKey) {
      return json({ error: 'Supabase auth is not configured.' }, 500);
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
    if (imageBase64.length > maxBase64Chars) {
      return json({ error: 'Image is too large. Maximum allowed size is 5 MB.' }, 413);
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

    const endpoint = predictionEndpoint(mlBackendUrl);
    const mlResponse = await fetch(endpoint, {
      method: 'POST',
      headers: { 'x-ml-api-key': mlApiKey },
      body: formData,
      signal: AbortSignal.timeout(65000),
    });

    const responseText = await mlResponse.text();
    let responseBody: unknown;
    try {
      responseBody = JSON.parse(responseText);
    } catch {
      responseBody = { error: responseText };
    }

    if (!mlResponse.ok) {
      return json({ error: 'ML backend failed.', detail: safeBackendDetail(responseBody) }, mlResponse.status);
    }

    return json(responseBody);
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

function predictionEndpoint(url: string) {
  const clean = url.trim().replace(/\/$/, '');
  return clean.endsWith('/predict') ? clean : `${clean}/predict`;
}

function safeBackendDetail(value: unknown) {
  if (value && typeof value === 'object' && 'detail' in value) {
    const detail = (value as { detail?: unknown }).detail;
    return typeof detail === 'string' ? detail.slice(0, 300) : 'Backend rejected the request.';
  }
  if (value && typeof value === 'object' && 'error' in value) {
    const error = (value as { error?: unknown }).error;
    return typeof error === 'string' ? error.slice(0, 300) : 'Backend rejected the request.';
  }
  if (typeof value === 'string') return value.slice(0, 300);
  return 'Backend rejected the request.';
}

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
