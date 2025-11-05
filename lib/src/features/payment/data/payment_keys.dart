/// Central place for Khalti (or other PSP) keys. Picks from --dart-define if provided.
class PaymentKeys {
  static const String khaltiPublicKey = String.fromEnvironment(
    'KHALTI_PUBLIC_KEY',
    defaultValue: 'test_public_key_dc74e0fd57cb46cd93832aee0a390234',
  );
  static const String khaltiSecretKey = String.fromEnvironment(
    'KHALTI_SECRET_KEY',
    defaultValue: 'test_secret_key_f59e8b7629b4431db8264e09fc830d76',
  );

  static bool get isConfigured =>
      !khaltiPublicKey.startsWith('test_') &&
      !khaltiSecretKey.startsWith('test_');

  static String get publicKey => khaltiPublicKey;
  static String get secretKey => khaltiSecretKey;
}
