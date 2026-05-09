abstract final class Env {
  static const hmacSalt = String.fromEnvironment(
    'HMAC_SALT',
    defaultValue: 'dev-salt-change-in-prod',
  );
}
