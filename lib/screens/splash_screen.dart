import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import 'auth_screen.dart';
import 'main_layout.dart';
import 'onboarding_screen.dart';
import 'tutorial_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final nextScreen = await _getNextScreen();
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 600),
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    });
  }

  Future<Widget> _getNextScreen() async {
    if (!SupabaseConfig.isConfigured) {
      return const OnboardingScreen();
    }

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return const AuthScreen();
    final userId = session.user.id;
    return await TutorialScreen.shouldShow(userId: userId) ? TutorialScreen(userId: userId) : const MainLayout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 10)),
                ],
              ),
              child: const Icon(LucideIcons.heartPulse, size: 80, color: Colors.white),
            ).animate().scale(curve: Curves.elasticOut, duration: 1200.ms),
            const SizedBox(height: 32),
            Text(
              'AutiSense',
              style: Theme.of(context).textTheme.displayLarge!.copyWith(
                color: AppTheme.primary,
                fontSize: 48,
              ),
            ).animate().fade(delay: 500.ms).slideY(begin: 0.5),
            const SizedBox(height: 16),
            Text(
              'Empowering Early Detection',
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fade(delay: 800.ms),
          ],
        ),
      ),
    );
  }
}
