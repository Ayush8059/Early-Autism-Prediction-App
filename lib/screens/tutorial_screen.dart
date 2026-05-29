import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'main_layout.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.userId});

  final String? userId;

  static const seenKey = 'has_seen_autisense_tutorial';

  static String seenKeyForUser(String? userId) {
    if (userId == null || userId.isEmpty) return seenKey;
    return '${seenKey}_$userId';
  }

  static Future<bool> shouldShow({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(seenKeyForUser(userId)) ?? false);
  }

  static Future<void> markSeen({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(seenKeyForUser(userId), true);
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _TutorialPage(
      icon: LucideIcons.heartPulse,
      title: 'Welcome to AutiSense',
      body:
          'AutiSense helps parents organize early screening, child-friendly activities, progress streaks, and reminders in one secure place.',
    ),
    _TutorialPage(
      icon: LucideIcons.brainCircuit,
      title: 'AI-Assisted Screening',
      body:
          'Photo analysis and questionnaires are screening aids, not a medical diagnosis. Results are saved so you can track patterns over time.',
    ),
    _TutorialPage(
      icon: LucideIcons.gamepad2,
      title: 'Activities With 3D Tutorials',
      body:
          'Tap any activity to open a live 3D-style tutorial. It shows how the parent can guide the child step by step.',
    ),
    _TutorialPage(
      icon: LucideIcons.languages,
      title: 'Use Your Language',
      body:
          'Change the language from Parent Profile. Dashboard, Activities, Assessments, Profile, and AI chat can follow the selected language.',
    ),
    _TutorialPage(
      icon: LucideIcons.botMessageSquare,
      title: 'Ask AI Parent Chat',
      body:
          'Ask doubts about activities, reminders, and screening results. The AI replies in your selected language and always recommends a doctor for medical accuracy.',
    ),
    _TutorialPage(
      icon: LucideIcons.bellRing,
      title: 'Reminders And Streaks',
      body:
          'Choose the time and days that fit your routine. Daily streaks encourage consistent small steps without pressuring the child.',
    ),
    _TutorialPage(
      icon: LucideIcons.shieldCheck,
      title: 'Private By Design',
      body:
          'Your data is protected with Supabase Auth, private storage, and database policies so each parent can only access their own records.',
    ),
    _TutorialPage(
      icon: LucideIcons.stethoscope,
      title: 'Screening Is Not Diagnosis',
      body:
          'AutiSense provides online screening guidance only. For accurate diagnosis, treatment, or medical advice, please visit a qualified doctor.',
    ),
  ];

  Future<void> _finish() async {
    await TutorialScreen.markSeen(userId: widget.userId);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainLayout()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const ThemeToggleButton(),
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (index) => setState(() => _index = index),
                  itemBuilder: (context, index) {
                    final item = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.icon,
                            size: 58,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 34),
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item.body,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Row(
                    children: List.generate(
                      _pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 8),
                        width: i == _index ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? AppTheme.primary
                              : AppTheme.primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  CustomButton(
                    text: _index == _pages.length - 1 ? 'Start' : 'Next',
                    icon: _index == _pages.length - 1
                        ? LucideIcons.check
                        : LucideIcons.arrowRight,
                    onPressed: () {
                      if (_index == _pages.length - 1) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
