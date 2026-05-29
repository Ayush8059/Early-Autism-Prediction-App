import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../screens/captcha_screen.dart';
import 'supabase_config.dart';

class CaptchaService {
  CaptchaService._();

  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static Future<String?> verify(BuildContext context) async {
    if (!SupabaseConfig.isCaptchaEnabled) return null;
    if (!isSupportedPlatform) return null;
    if (!context.mounted) return null;

    return Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const CaptchaScreen()),
    );
  }
}
