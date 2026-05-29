import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/auth_service.dart';
import '../core/language_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/theme_toggle_button.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'activities_screen.dart';
import 'assessment_hub_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  static const Duration _inactivityTimeout = Duration(minutes: 5);

  int _currentIndex = 0;
  Timer? _inactivityTimer;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ActivitiesScreen(),
    const AssessmentHubScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _autoLogout);
  }

  Future<void> _autoLogout() async {
    if (!SupabaseConfig.isConfigured ||
        Supabase.instance.client.auth.currentUser == null) {
      return;
    }

    await AuthService(Supabase.instance.client).signOut();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, _, __) {
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _resetInactivityTimer(),
          onPointerMove: (_) => _resetInactivityTimer(),
          child: Scaffold(
            floatingActionButton: const ThemeToggleButton(),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            body: IndexedStack(index: _currentIndex, children: _screens),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (index) {
                    _resetInactivityTimer();
                    setState(() => _currentIndex = index);
                  },
                  backgroundColor: AppTheme.cardColor,
                  selectedItemColor: AppTheme.primary,
                  unselectedItemColor: AppTheme.textSecondary,
                  showUnselectedLabels: true,
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  items: [
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(LucideIcons.home),
                      ),
                      label: LanguageService.t('home'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(LucideIcons.gamepad2),
                      ),
                      label: LanguageService.t('activities'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(LucideIcons.stethoscope),
                      ),
                      label: LanguageService.t('assess'),
                    ),
                    BottomNavigationBarItem(
                      icon: const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Icon(LucideIcons.user),
                      ),
                      label: LanguageService.t('profile'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
