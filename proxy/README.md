# Axiom Gemini Proxy

Solves CORS for Flutter web by proxying Gemini API calls server-side.

## Deploy to Vercel (free)

```bash
npm install -g vercel
cd proxy
vercel deploy --prod
```

Copy the deployed URL (e.g. `https://axiom-proxy.vercel.app`) and run the Flutter app with:

```bash
flutter run -d chrome --dart-define=PROXY_URL=https://axiom-proxy.vercel.app
```

## How it works

Flutter → `POST /api/gemini` (your proxy) → Gemini API → Flutter

The proxy adds CORS headers so the browser accepts the response.
The user's Gemini API key is sent in the request body (TLS encrypted).
