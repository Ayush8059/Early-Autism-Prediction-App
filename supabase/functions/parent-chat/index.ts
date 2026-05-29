import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

type ChatMessage = {
  role: 'user' | 'assistant';
  message: string;
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization') ?? '';
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const groqApiKey = Deno.env.get('GROQ_API_KEY') ?? '';
    const openAiApiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
    const aiApiKey = Deno.env.get('AI_API_KEY') ?? (groqApiKey || openAiApiKey);
    const aiProvider = Deno.env.get('AI_PROVIDER') ?? (groqApiKey ? 'groq' : 'openai');
    const aiApiUrl = Deno.env.get('AI_API_URL') ??
      (aiProvider === 'groq'
        ? 'https://api.groq.com/openai/v1/chat/completions'
        : 'https://api.openai.com/v1/chat/completions');
    const aiModel = Deno.env.get('AI_MODEL') ??
      (aiProvider === 'groq' ? 'llama-3.1-8b-instant' : 'gpt-4o-mini');

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      global: { headers: { Authorization: authHeader } },
    });

    const { data: userData, error: userError } = await supabase.auth.getUser();
    if (userError || !userData.user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const { message, language } = await req.json();
    if (typeof message !== 'string' || message.trim().length === 0) {
      return json({ error: 'Message is required' }, 400);
    }

    const cleanMessage = message.trim().slice(0, 1200);
    const selectedLanguage = typeof language === 'string' && language.trim().length > 0
      ? language.trim()
      : 'English';

    const context = await loadParentContext(supabase, userData.user.id);
    const recentMessages = await loadRecentMessages(supabase, userData.user.id);

    const reply = isHighRiskMessage(cleanMessage)
      ? crisisReply(selectedLanguage)
      : aiApiKey
        ? await callAiProvider({
          url: aiApiUrl,
          key: aiApiKey,
          model: aiModel,
          message: cleanMessage,
          language: selectedLanguage,
          context,
          recentMessages,
        })
        : fallbackReply(cleanMessage, selectedLanguage, context);

    await supabase.from('chat_messages').insert({
      parent_id: userData.user.id,
      role: 'user',
      message: cleanMessage,
    });

    await supabase.from('chat_messages').insert({
      parent_id: userData.user.id,
      role: 'assistant',
      message: reply,
    });

    return json({ reply });
  } catch (error) {
    return json({ error: String(error) }, 500);
  }
});

async function loadParentContext(supabase: ReturnType<typeof createClient>, parentId: string) {
  const [{ data: profile }, { data: child }, { data: questionnaire }, { data: photo }] = await Promise.all([
    supabase
      .from('profiles')
      .select('full_name, language, phone_number, feedback')
      .eq('id', parentId)
      .maybeSingle(),
    supabase
      .from('children')
      .select('name, date_of_birth, gender')
      .eq('parent_id', parentId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase
      .from('questionnaire_assessments')
      .select('score, risk_level, created_at')
      .eq('parent_id', parentId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle(),
    supabase
      .from('photo_assessments')
      .select('confidence_score, risk_level, message, created_at')
      .eq('parent_id', parentId)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle(),
  ]);

  return {
    parentName: profile?.full_name ?? 'Parent',
    preferredLanguage: profile?.language ?? 'English',
    parentFeedback: profile?.feedback ?? '',
    childName: child?.name ?? '',
    childAge: child?.date_of_birth ? ageFromDate(child.date_of_birth) : '',
    childGender: child?.gender ?? '',
    latestQuestionnaire: questionnaire
      ? `Score ${questionnaire.score}, risk ${questionnaire.risk_level}, date ${questionnaire.created_at}`
      : 'No questionnaire result yet',
    latestPhoto: photo
      ? `Risk ${photo.risk_level ?? 'unknown'}, confidence ${photo.confidence_score ?? 'unknown'}, note ${photo.message ?? ''}`
      : 'No photo assessment yet',
  };
}

async function loadRecentMessages(supabase: ReturnType<typeof createClient>, parentId: string): Promise<ChatMessage[]> {
  const { data } = await supabase
    .from('chat_messages')
    .select('role, message')
    .eq('parent_id', parentId)
    .order('created_at', { ascending: false })
    .limit(8);

  return ((data ?? []) as ChatMessage[]).reverse();
}

async function callAiProvider(args: {
  url: string;
  key: string;
  model: string;
  message: string;
  language: string;
  context: Record<string, unknown>;
  recentMessages: ChatMessage[];
}) {
  const systemPrompt = buildSystemPrompt(args.language, args.context);
  const messages = [
    { role: 'system', content: systemPrompt },
    ...args.recentMessages.map((item) => ({
      role: item.role,
      content: item.message,
    })),
    { role: 'user', content: args.message },
  ];

  const response = await fetch(args.url, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${args.key}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: args.model,
      messages,
      temperature: 0.55,
      max_tokens: 420,
    }),
  });

  if (!response.ok) {
    return fallbackReply(args.message, args.language, args.context);
  }

  const data = await response.json();
  const reply = data?.choices?.[0]?.message?.content;
  return typeof reply === 'string' && reply.trim().length > 0
    ? reply.trim()
    : fallbackReply(args.message, args.language, args.context);
}

function buildSystemPrompt(language: string, context: Record<string, unknown>) {
  return `
You are AutiSense Parent Assistant.
Reply in ${language}. If the parent writes in another language, still follow the selected language unless they explicitly ask otherwise.

Context:
- Parent name: ${context.parentName}
- Parent feedback/concern: ${context.parentFeedback}
- Child name: ${context.childName || 'not provided'}
- Child age: ${context.childAge || 'not provided'}
- Child gender: ${context.childGender || 'not provided'}
- Latest questionnaire: ${context.latestQuestionnaire}
- Latest photo assessment: ${context.latestPhoto}

Rules:
1. Never diagnose autism or any medical condition.
2. Explain screening results as patterns/indicators only.
3. Recommend a qualified doctor, pediatrician, therapist, or emergency care when appropriate.
4. Give short, practical activities parents can do safely at home.
5. Personalize recommendations using child age, recent results, parent concerns, and selected language.
6. If asked for more activities, give new suggestions rather than repeating the same one.
7. Keep answers concise: 3-6 short bullets or a short paragraph.
8. For crisis words like seizure, self-harm, danger, breathing, unconscious, severe injury, tell the parent to seek urgent medical help immediately.
`.trim();
}

function fallbackReply(message: string, language = 'English', context: Record<string, unknown> = {}) {
  const lower = message.toLowerCase();
  const asksActivity = lower.includes('activity') ||
    lower.includes('activities') ||
    lower.includes('recommend') ||
    lower.includes('more') ||
    lower.includes('suggest') ||
    lower.includes('game');

  if (language === 'Hindi') {
    if (asksActivity) {
      return 'Aaj ke liye naya activity idea: Joint Attention Play. Ek toy ki taraf point karke “dekho” bolen, 3 seconds wait karein, aur child response kare toh praise karein. Sirf 5-6 repeats karein. Yeh practice hai, diagnosis/treatment nahi.';
    }
    return 'Main screening result aur activities samjha sakta hoon, lekin diagnosis nahi kar sakta. Agar concern repeat ho raha hai toh pediatrician ya therapist se consult karein.';
  }

  if (asksActivity) {
    return 'Try a new activity: Joint Attention Play. Point to a toy, say “look,” wait 3 seconds, and praise any look/reach/response. Repeat 5-6 times only. This is practice guidance, not diagnosis or treatment.';
  }

  if (lower.includes('photo') || lower.includes('assessment') || lower.includes('score')) {
    return `Use results to track patterns over time. Latest context: ${context.latestQuestionnaire ?? 'no questionnaire yet'}; ${context.latestPhoto ?? 'no photo result yet'}. For accurate advice, consult a qualified doctor.`;
  }

  return 'I can help explain activities, reminders, and screening results. I cannot diagnose; for accurate medical advice, please visit a qualified doctor.';
}

function isHighRiskMessage(message: string) {
  const lower = message.toLowerCase();
  return [
    'seizure',
    'not breathing',
    'unconscious',
    'self harm',
    'suicide',
    'danger',
    'emergency',
    'severe injury',
    'choking',
  ].some((term) => lower.includes(term));
}

function crisisReply(language: string) {
  if (language === 'Hindi') {
    return 'Yeh urgent medical concern lag sakta hai. Kripya turant local emergency number, nearest hospital, ya qualified doctor se contact karein. App emergency care ka replacement nahi hai.';
  }
  return 'This may be an urgent medical concern. Please contact local emergency services, the nearest hospital, or a qualified doctor immediately. This app is not a replacement for emergency care.';
}

function ageFromDate(date: string) {
  const birthDate = new Date(date);
  if (Number.isNaN(birthDate.getTime())) return '';
  const now = new Date();
  const months = (now.getFullYear() - birthDate.getFullYear()) * 12 + now.getMonth() - birthDate.getMonth();
  if (months < 24) return `${Math.max(months, 0)} months`;
  return `${Math.floor(months / 12)} years ${months % 12} months`;
}

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
