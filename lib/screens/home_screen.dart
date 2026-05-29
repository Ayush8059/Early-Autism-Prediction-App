import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/assessment_service.dart';
import '../core/dashboard_service.dart';
import '../core/language_service.dart';
import '../core/profile_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final Future<ParentProfile> _profileFuture;
  late final Future<int> _dailyStreakFuture;
  late final Future<bool> _activityCompletedTodayFuture;
  late final Future<List<AssessmentSummary>> _recentAssessmentsFuture;
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
    _profileFuture = SupabaseConfig.isConfigured
        ? ProfileService(
            Supabase.instance.client,
          ).getCurrentParentProfile().then((profile) {
            LanguageService.setLanguage(profile.language);
            return profile;
          })
        : Future.value(
            const ParentProfile(
              fullName: 'Parent Profile',
              email: 'Supabase not connected',
              phoneNumber: '',
              feedback: '',
              avatarPath: '',
              avatarUrl: '',
              language: 'English',
              notificationEnabled: false,
              reminderHour: 9,
              reminderMinute: 0,
              reminderDays: [1, 2, 3, 4, 5, 6, 7],
            ),
          );
    _dailyStreakFuture = SupabaseConfig.isConfigured
        ? DashboardService(Supabase.instance.client).getDailyStreak()
        : Future.value(0);
    _activityCompletedTodayFuture = SupabaseConfig.isConfigured
        ? DashboardService(Supabase.instance.client).hasCompletedActivityToday()
        : Future.value(false);
    _recentAssessmentsFuture = SupabaseConfig.isConfigured
        ? AssessmentService(
            Supabase.instance.client,
          ).fetchRecentAssessments(limit: 1)
        : Future.value([]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, _, __) {
        return Scaffold(
          body: Stack(
            children: [
              // Subtle background depth
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark 
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              
              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      title: Text(
                        'AutiSense',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppTheme.primary,
                        ),
                      ),
                      centerTitle: false,
                      automaticallyImplyLeading: false,
                      actions: [
                        IconButton(
                          icon: const Icon(LucideIcons.bell),
                          onPressed: () {},
                          color: isDark ? Colors.white70 : AppTheme.textPrimaryLight,
                        ),
                      ],
                    ),
                    
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          FutureBuilder<ParentProfile>(
                            future: _profileFuture,
                            builder: (context, snapshot) {
                              final name = snapshot.data?.fullName ?? 'Parent Profile';
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    LanguageService.t('welcomeBack'),
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ).animate().fade().slideX(begin: -0.1),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$name!',
                                    style: Theme.of(context).textTheme.displayMedium,
                                  ).animate().fade(delay: 100.ms).slideX(begin: -0.1),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 22),
                          _buildHeroCard(context)
                              .animate()
                              .fade(delay: 200.ms)
                              .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
                          const SizedBox(height: 20),
                          
                          // Educational Section - autism is not a disease
                          _buildEducationalBlock(context),
                          
                          const SizedBox(height: 20),
                          _buildParentAiCard(context)
                              .animate()
                              .fade(delay: 300.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(child: _buildStreakMetricCard(context)),
                              const SizedBox(width: 14),
                              Expanded(child: _buildTodayGoalCard(context)),
                            ],
                          ).animate().fade(delay: 400.ms).slideY(begin: 0.1),
                          const SizedBox(height: 26),
                          Text(
                            'Support Guide',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          _buildSupportGuide(context)
                              .animate()
                              .fade(delay: 500.ms),
                          const SizedBox(height: 26),
                          _buildAssessmentPulse(context)
                              .animate()
                              .fade(delay: 600.ms)
                              .slideY(begin: 0.1),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEducationalBlock(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lightbulb, color: Colors.green, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Did you know?',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Autism is NOT a disease.',
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'It is a unique neurobiological condition. With early support, therapeutic activities, and environmental adjustments, every child can thrive and build amazing skills.',
            style: Theme.of(context).textTheme.bodyLarge!.copyWith(
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoPill('Neurodiversity', LucideIcons.brainCircuit),
        ],
      ),
    ).animate().custom(
      duration: 1500.ms,
      builder: (context, value, child) {
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(math.sin(value * math.pi * 2) * 0.02)
            ..rotateY(math.cos(value * math.pi * 2) * 0.02),
          alignment: Alignment.center,
          child: child,
        );
      }
    );
  }

  Widget _buildInfoPill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentAiCard(BuildContext context) {
    return GlassCard(
      height: 132,
      padding: const EdgeInsets.all(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatbotScreen()),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            top: -22,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: math.sin(_controller.value * math.pi * 2) * 0.14,
                  child: child,
                );
              },
              child: Icon(
                LucideIcons.botMessageSquare,
                size: 110,
                color: AppTheme.primary.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.botMessageSquare,
                  color: Colors.white,
                  size: 29,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'AI Parent Guide',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Ask about activities, reminders, routines, and saved screening results.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(height: 1.2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return GlassCard(
      height: 230,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _HeroMotionField(controller: _controller)),
            Positioned(
              left: 24,
              top: 54,
              child: Opacity(
                opacity: 0.34,
                child: _Animated3DOrb(controller: _controller, size: 44),
              ),
            ),
            Positioned(
              right: 70,
              top: 24,
              child: _Floating3DToken(
                controller: _controller,
                icon: LucideIcons.activity,
                color: Colors.white,
                phase: 0.22,
              ),
            ),
            Positioned(
              right: 18,
              top: 66,
              child: _Floating3DToken(
                controller: _controller,
                icon: LucideIcons.sparkles,
                color: const Color(0xFFFFD166),
                phase: 0.68,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    LanguageService.t('todayFocus'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Today is for one small win.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete one guided activity to keep the streak alive. Assessments stay in history for check-ins.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.86),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakMetricCard(BuildContext context) {
    return GlassCard(
      onTap: () async {
        final streak = await _dailyStreakFuture;
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StreakLadderScreen(streak: streak)),
        );
      },
      height: 118,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -10,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: math.sin(_controller.value * math.pi * 2) * 0.16,
                  child: child,
                );
              },
              child: Icon(
                LucideIcons.flame,
                color: Colors.orangeAccent.withOpacity(0.15),
                size: 72,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.flame,
                color: Colors.orangeAccent,
                size: 26,
              ),
              const Spacer(),
              FutureBuilder<int>(
                future: _dailyStreakFuture,
                builder: (context, snapshot) {
                  final streak = snapshot.data ?? 0;
                  return Text(
                    '$streak',
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      color: Colors.orangeAccent,
                    ),
                  );
                },
              ),
              Text(
                LanguageService.t('dailyStreak'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayGoalCard(BuildContext context) {
    return GlassCard(
      height: 118,
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<bool>(
        future: _activityCompletedTodayFuture,
        builder: (context, snapshot) {
          final hasProgressToday = snapshot.data ?? false;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasProgressToday ? LucideIcons.badgeCheck : LucideIcons.target,
                color: AppTheme.accent,
                size: 26,
              ),
              const Spacer(),
              Text(
                hasProgressToday ? 'Done' : '1',
                style: Theme.of(
                  context,
                ).textTheme.displayMedium!.copyWith(color: AppTheme.accent),
              ),
              Text(
                hasProgressToday ? 'Today logged' : 'Today goal',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStreakExplainer(BuildContext context) {
    return GlassCard(
      height: 132,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(math.sin(_controller.value * math.pi * 2) * 0.32),
                child: child,
              );
            },
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB703), Color(0xFFFB7185)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.24),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.zap, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'How streak updates',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Finish one guided activity per day. Photo checks and questionnaires stay in history, but they do not build streaks.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildMiniRule('Activity'),
                    const SizedBox(width: 8),
                    _buildMiniRule('Practice'),
                    const SizedBox(width: 8),
                    _buildMiniRule('Daily'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniRule(String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.primary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildSupportGuide(BuildContext context) {
    final items = [
      _SupportGuideItem(
        title: 'Social communication',
        body:
            'Speech, play, turn-taking, and joint-attention practice can help daily interaction.',
        icon: LucideIcons.messagesSquare,
        color: AppTheme.primary,
      ),
      _SupportGuideItem(
        title: 'Sensory comfort',
        body:
            'Gentle routines, texture choices, and calm spaces can reduce overload.',
        icon: LucideIcons.hand,
        color: Colors.orangeAccent,
      ),
      _SupportGuideItem(
        title: 'Routine flexibility',
        body: 'Visual schedules and small transitions can make changes easier.',
        icon: LucideIcons.calendarClock,
        color: AppTheme.accent,
      ),
      _SupportGuideItem(
        title: 'Regulation skills',
        body:
            'Movement breaks, breathing, and deep-pressure activities support calm focus.',
        icon: LucideIcons.heartPulse,
        color: AppTheme.secondary,
      ),
      _SupportGuideItem(
        title: 'Parent Well-being',
        body:
            'A calm parent supports a calm child. Practice self-care and connect with caregiver support groups.',
        icon: LucideIcons.smile,
        color: Colors.teal,
      ),
      _SupportGuideItem(
        title: 'Professional Care',
        body:
            'Share documented patterns and observations with a pediatrician or psychologist for intervention.',
        icon: LucideIcons.stethoscope,
        color: Colors.indigo,
      ),
    ];

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _SupportGuideCard(
            item: items[index],
            controller: _controller,
            phase: index * 0.19,
          );
        },
      ),
    );
  }

  Widget _buildAssessmentPulse(BuildContext context) {
    return FutureBuilder<List<AssessmentSummary>>(
      future: _recentAssessmentsFuture,
      builder: (context, snapshot) {
        final item = (snapshot.data ?? []).isNotEmpty
            ? snapshot.data!.first
            : null;
        return GlassCard(
          height: 112,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1 + math.sin(_controller.value * math.pi * 2) * 0.05,
                    child: child,
                  );
                },
                child: const Icon(
                  LucideIcons.checkCircle2,
                  color: Colors.green,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item?.title ?? 'No saved results',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item == null
                          ? 'Complete an assessment to see progress.'
                          : '${item.riskLevel} risk • ${item.scoreText}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(height: 1.18),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item == null ? '-' : _shortDate(item.createdAt),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        );
      },
    );
  }

  String _shortDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day)
      return LanguageService.t('today');
    return '${date.day}/${date.month}';
  }
}

class _Animated3DOrb extends StatelessWidget {
  final AnimationController controller;
  final double size;

  const _Animated3DOrb({required this.controller, this.size = 138});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final angle = controller.value * math.pi * 2;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(angle * 0.55)
            ..rotateX(math.sin(angle) * 0.18),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.82),
                  Colors.white.withOpacity(0.18),
                  Colors.white.withOpacity(0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.brainCircuit,
              color: Colors.white,
              size: 54,
            ),
          ),
        );
      },
    );
  }
}

class _SupportGuideItem {
  const _SupportGuideItem({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String title;
  final String body;
  final IconData icon;
  final Color color;
}

class _SupportGuideCard extends StatelessWidget {
  const _SupportGuideCard({
    required this.item,
    required this.controller,
    required this.phase,
  });

  final _SupportGuideItem item;
  final AnimationController controller;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Stack(
          children: [
            Positioned(
              right: -18,
              bottom: -18,
              child: AnimatedBuilder(
                animation: controller,
                builder: (context, child) {
                  final angle = (controller.value + phase) * math.pi * 2;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(math.cos(angle) * 0.34)
                      ..rotateX(math.sin(angle) * 0.20),
                    child: child,
                  );
                },
                child: Icon(
                  item.icon,
                  size: 92,
                  color: item.color.withOpacity(0.08),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(item.icon, color: item.color, size: 28),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(height: 1.2),
                ),
                const SizedBox(height: 12),
                Text(
                  'Not a disease',
                  style: TextStyle(
                    color: item.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Floating3DToken extends StatelessWidget {
  const _Floating3DToken({
    required this.controller,
    required this.icon,
    required this.color,
    required this.phase,
  });

  final AnimationController controller;
  final IconData icon;
  final Color color;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final angle = (controller.value + phase) * math.pi * 2;
        return Transform.translate(
          offset: Offset(math.cos(angle) * 8, math.sin(angle) * 10),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateX(math.sin(angle) * 0.22)
              ..rotateY(math.cos(angle) * 0.28),
            child: child,
          ),
        );
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}

class _HeroMotionField extends StatelessWidget {
  const _HeroMotionField({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _HeroMotionPainter(controller.value),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}

class _HeroMotionPainter extends CustomPainter {
  _HeroMotionPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.24);

    for (var i = 0; i < 6; i++) {
      final t = (value + i * 0.16) % 1;
      final x = size.width * (0.16 + i * 0.15);
      final y = size.height * (0.18 + math.sin((t + i) * math.pi * 2) * 0.12);
      canvas.drawCircle(Offset(x, y), 3 + (i % 2), dotPaint);
      canvas.drawLine(
        Offset(x, y + 16),
        Offset(size.width * 0.82, size.height * (0.70 - i * 0.05)),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HeroMotionPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class StreakLadderScreen extends StatelessWidget {
  const StreakLadderScreen({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final steps = streak < 7 ? 7 : streak;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Streak Ladder'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            children: [
              Text(
                '$streak day streak',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete one guided activity each day to climb higher.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: CustomPaint(
                    painter: _StreakLadderPainter(streak: streak, steps: steps),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StreakLadderPainter extends CustomPainter {
  _StreakLadderPainter({required this.streak, required this.steps});

  final int streak;
  final int steps;

  @override
  void paint(Canvas canvas, Size size) {
    final railPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.20)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final rungPaint = Paint()
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.92),
      Offset(size.width * 0.68, size.height * 0.08),
      railPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.42, size.height * 0.96),
      Offset(size.width * 0.90, size.height * 0.12),
      railPaint,
    );

    for (var i = 0; i < steps; i++) {
      final t = steps == 1 ? 0.0 : i / (steps - 1);
      final y = size.height * (0.88 - t * 0.74);
      final x = size.width * (0.26 + t * 0.48);
      final active = i < streak;
      rungPaint.color = active
          ? AppTheme.accent
          : AppTheme.textSecondary.withOpacity(0.18);
      canvas.drawLine(
        Offset(x, y),
        Offset(x + size.width * 0.20, y - size.height * 0.04),
        rungPaint,
      );

      final glowPaint = Paint()
        ..color = (active ? AppTheme.primary : Colors.white).withOpacity(
          active ? 0.28 : 0.8,
        );
      canvas.drawCircle(
        Offset(x + size.width * 0.10, y - size.height * 0.02),
        active ? 24 : 17,
        glowPaint,
      );
      final dotPaint = Paint()
        ..color = active ? AppTheme.primary : Colors.white;
      canvas.drawCircle(
        Offset(x + size.width * 0.10, y - size.height * 0.02),
        active ? 16 : 12,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StreakLadderPainter oldDelegate) {
    return oldDelegate.streak != streak || oldDelegate.steps != steps;
  }
}
