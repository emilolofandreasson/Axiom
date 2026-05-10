abstract final class Env {
  static const hmacSalt = String.fromEnvironment(
    'HMAC_SALT',
    defaultValue: 'dev-salt-change-in-prod',
  );
  static const geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
  static const proxyUrl = String.fromEnvironment(
    'PROXY_URL',
    defaultValue: 'https://proxy-taupe-eight-41.vercel.app',
  );

  // Supabase — project oymlddjcusiyaxtfcvad
  // Paste the anon/public key from Supabase → Settings → API.
  static const supabaseUrl     = 'https://oymlddjcusiyaxtfcvad.supabase.co';
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Kq3F2WpG4joClDvAtlYuFA_fYuWUbTj',
  );
}
