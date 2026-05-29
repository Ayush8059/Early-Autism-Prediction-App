import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/reminder_service.dart';
import 'core/supabase_config.dart';
import 'core/theme.dart';
import 'core/theme_service.dart';
import 'screens/splash_screen.dart';

final themeService = ThemeService.instance;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  await ReminderService.initialize();

  runApp(const AutiSenseApp());
}

class AutiSenseApp extends StatelessWidget {
  const AutiSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeService,
      builder: (context, _) {
        AppTheme.setDarkMode(themeService.isDarkMode);
        return MaterialApp(
          title: 'AutiSense',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeService.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
