const MODEL = 'gemini-2.5-flash';
const BASE  = `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

async function callGemini(key, prompt, maxTokens, temperature) {
  const response = await fetch(`${BASE}?key=${key}`, {
    method:  'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature,
        maxOutputTokens: maxTokens,
        thinkingConfig: { thinkingBudget: 0 },
      },
    }),
  });
  const data = await response.json();
  return { status: response.status, data };
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin',  '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST')   return res.status(405).json({ error: 'Method not allowed' });

  const { prompt, apiKey, maxTokens = 1200, temperature = 0.4 } = req.body;
  const serverKey = process.env.GEMINI_API_KEY;
  const clientKey = apiKey && apiKey.length > 10 ? apiKey : null;

  if (!prompt) return res.status(400).json({ error: 'Missing prompt' });
  if (!clientKey && !serverKey) return res.status(400).json({ error: 'No API key configured' });

  try {
    // Try client key first (user's own key takes priority).
    if (clientKey) {
      const { status, data } = await callGemini(clientKey, prompt, maxTokens, temperature);
      if (status === 200) return res.status(200).json(data);
      // Client key failed — fall through to server key.
      console.log(`[proxy] client key failed (${status}), retrying with server key`);
    }

    // Fall back to server-side key.
    if (serverKey) {
      const { status, data } = await callGemini(serverKey, prompt, maxTokens, temperature);
      return res.status(status).json(data);
    }

    return res.status(500).json({ error: 'All keys exhausted' });
  } catch (err) {
    return res.status(500).json({ error: err.message });
  }
}
