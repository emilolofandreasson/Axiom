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
}
