class SupabaseConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const hcaptchaSiteKey = String.fromEnvironment('HCAPTCHA_SITE_KEY');

  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
  static bool get isCaptchaEnabled => hcaptchaSiteKey.isNotEmpty;
}
