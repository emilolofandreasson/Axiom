abstract final class Env {
  static const eventHubEndpoint = String.fromEnvironment(
    'EVENT_HUB_ENDPOINT',
    defaultValue: '',
  );
  static const eventHubSasToken = String.fromEnvironment(
    'EVENT_HUB_SAS_TOKEN',
    defaultValue: '',
  );
  static const hmacSalt = String.fromEnvironment(
    'HMAC_SALT',
    defaultValue: 'dev-salt-change-in-prod',
  );
}
