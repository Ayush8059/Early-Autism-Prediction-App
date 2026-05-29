import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/activity_service.dart';
import '../core/language_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../core/theme_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';

class ActivitiesScreen extends StatelessWidget {
  const ActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fallbackActivities = [
      _ActivityItem(
        title: 'Color Sorting',
        desc: 'Sort blocks by color and shape to build focus.',
        demoText: 'Drag matching blocks into the same color group.',
        goal: 'Focus',
        time: '8 min',
        icon: LucideIcons.box,
        color: AppTheme.primary,
      ),
      _ActivityItem(
        title: 'Follow the Sound',
        desc: 'Listen, locate, and point toward sounds.',
        demoText: 'Play a sound from one side and ask the child to point.',
        goal: 'Attention',
        time: '6 min',
        icon: LucideIcons.music,
        color: AppTheme.secondary,
      ),
      _ActivityItem(
        title: 'Emotion Cards',
        desc: 'Match faces with happy, sad, calm, or angry.',
        demoText: 'Show one face card and name the emotion together.',
        goal: 'Social',
        time: '10 min',
        icon: LucideIcons.smile,
        color: AppTheme.accent,
      ),
      _ActivityItem(
        title: 'Texture Touch',
        desc: 'Explore soft, rough, smooth, and fuzzy textures.',
        demoText: 'Offer one texture at a time and watch comfort cues.',
        goal: 'Sensory',
        time: '7 min',
        icon: LucideIcons.hand,
        color: Colors.orangeAccent,
      ),
      _ActivityItem(
        title: 'Mirror Mimic',
        desc: 'Imitate simple facial expressions and gestures.',
        demoText: 'Sit in front of a mirror and ask the child to copy your smile or wave.',
        goal: 'Communication',
        time: '5 min',
        icon: LucideIcons.users,
        color: Colors.teal,
      ),
      _ActivityItem(
        title: 'Story Sequencing',
        desc: 'Arrange 3 pictures to tell a simple story.',
        demoText: 'Place three cards (Wake up, Eat, Play) and ask for the order.',
        goal: 'Cognitive',
        time: '12 min',
        icon: LucideIcons.bookOpen,
        color: Colors.indigo,
      ),
      _ActivityItem(
        title: 'Deep Pressure Hugs',
        desc: 'Use gentle firm pressure to help calm the system.',
        demoText: 'Wrap in a soft blanket or give a firm, slow hug.',
        goal: 'Regulation',
        time: '5 min',
        icon: LucideIcons.heart,
        color: Colors.redAccent,
      ),
      _ActivityItem(
        title: 'Bubble Pop',
        desc: 'Trace and pop bubbles to build hand-eye coordination.',
        demoText: 'Blow bubbles and encourage the child to pop them with one finger.',
        goal: 'Motor',
        time: '6 min',
        icon: LucideIcons.sparkles,
        color: Colors.lightBlue,
      ),
      _ActivityItem(
        title: 'Wait & Go',
        desc: 'Practice stop-and-start activities.',
        demoText: 'Say "Go" to walk and "Stop" to freeze. Switch roles.',
        goal: 'Inhibition',
        time: '8 min',
        icon: LucideIcons.playCircle,
        color: Colors.amber,
      ),
      _ActivityItem(
        title: 'Visual Schedule Fun',
        desc: 'Match daily tasks with visual icons.',
        demoText: 'Show a picture of a toothbrush and ask what comes next.',
        goal: 'Routine',
        time: '10 min',
        icon: LucideIcons.calendar,
        color: Colors.deepPurple,
      ),
      _ActivityItem(
        title: 'Animal Crawl',
        desc: 'Move like different animals (bear, crab, frog).',
        demoText: 'Gallop like a horse or crawl low like a lizard.',
        goal: 'Physical',
        time: '15 min',
        icon: LucideIcons.dog,
        color: Colors.brown,
      ),
      _ActivityItem(
        title: 'Joint Attention Point',
        desc: 'Look where you point and share interest.',
        demoText: 'Point at a bird or toy and say "Look at that!" Wait for eye contact.',
        goal: 'Social',
        time: '4 min',
        icon: LucideIcons.navigation,
        color: Colors.cyan,
      ),
    ];

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final background = isDark
            ? AppTheme.backgroundDark
            : AppTheme.backgroundLight;
        return ValueListenableBuilder<String>(
          valueListenable: LanguageService.currentLanguage,
          builder: (context, _, __) => Scaffold(
            backgroundColor: background,
            appBar: AppBar(
              backgroundColor: background,
              title: Text(LanguageService.t('activities')),
              leading: IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SafeArea(
              child: FutureBuilder<List<_ActivityItem>>(
                future: _loadActivities(fallbackActivities),
                builder: (context, snapshot) {
                  final activities = snapshot.data ?? fallbackActivities;
                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 110),
                    children: [
                      Text(
                        LanguageService.t('activitiesIntro'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fade().slideY(begin: -0.2),
                      const SizedBox(height: 22),
                      _buildFeaturedCard(
                        context,
                        activities.first,
                      ).animate().fade(delay: 120.ms).slideY(begin: 0.08),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text(
                            LanguageService.t('recommended'),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.sparkles,
                                  size: 15,
                                  color: AppTheme.accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${activities.length} ${LanguageService.t('tasks')}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.62,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemCount: activities.length,
                        itemBuilder: (context, index) {
                          return _buildActivityCard(context, activities[index])
                              .animate()
                              .fade(delay: (180 + 90 * index).ms)
                              .scale(
                                begin: const Offset(0.96, 0.96),
                                curve: Curves.easeOutBack,
                              );
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<List<_ActivityItem>> _loadActivities(
    List<_ActivityItem> fallback,
  ) async {
    if (!SupabaseConfig.isConfigured) return fallback;
    final records = await ActivityService(
      Supabase.instance.client,
    ).fetchActivities();
    if (records.isEmpty) return fallback;
    final loaded = [
      for (final record in records)
        _ActivityItem(
          id: record.id,
          title: record.title,
          desc: record.description,
          demoText: record.description,
          goal: record.category,
          time: '8 min',
          icon: _iconForCategory(record.category),
          color: _colorForCategory(record.category),
        ),
    ];
    final byTitle = {for (final item in loaded) item.title: item};
    for (final item in fallback) {
      byTitle.putIfAbsent(item.title, () => item);
    }
    return byTitle.values.toList();
  }

  IconData _iconForCategory(String category) {
    if (category.toLowerCase().contains('sensory')) return LucideIcons.hand;
    if (category.toLowerCase().contains('communication'))
      return LucideIcons.smile;
    if (category.toLowerCase().contains('attention')) return LucideIcons.music;
    return LucideIcons.box;
  }

  Color _colorForCategory(String category) {
    if (category.toLowerCase().contains('sensory')) return Colors.orangeAccent;
    if (category.toLowerCase().contains('communication'))
      return AppTheme.accent;
    if (category.toLowerCase().contains('attention')) return AppTheme.secondary;
    return AppTheme.primary;
  }

  Widget _buildFeaturedCard(BuildContext context, _ActivityItem item) {
    return GlassCard(
      height: 168,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [
              item.color.withOpacity(0.90),
              AppTheme.primary.withOpacity(0.86),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -14,
              bottom: -22,
              child: Icon(
                item.icon,
                size: 128,
                color: Colors.white.withOpacity(0.13),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    LanguageService.t('startToday'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Colors.white,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Colors.white.withOpacity(0.88),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, _ActivityItem item) {
    return GlassCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ActivityDemoScreen(activity: item),
          ),
        );
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, size: 27, color: item.color),
              ),
              const Spacer(),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppTheme.textSecondary.withOpacity(0.65),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontSize: 18, height: 1.08),
          ),
          const SizedBox(height: 8),
          Text(
            item.desc,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontSize: 12.5, height: 1.25),
          ),
          const Spacer(),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildChip(context, LucideIcons.clock, item.time),
              _buildChip(context, LucideIcons.checkCircle2, item.goal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.textSecondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String? id;
  final String title;
  final String desc;
  final String demoText;
  final String goal;
  final String time;
  final IconData icon;
  final Color color;

  const _ActivityItem({
    this.id,
    required this.title,
    required this.desc,
    required this.demoText,
    required this.goal,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class _ActivityDemoScreen extends StatefulWidget {
  final _ActivityItem activity;

  const _ActivityDemoScreen({required this.activity});

  @override
  State<_ActivityDemoScreen> createState() => _ActivityDemoScreenState();
}

class _ActivityDemoScreenState extends State<_ActivityDemoScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.activity;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(item.title),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          ThemeToggleButton(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          children: [
            GlassCard(
              height: 330,
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            item.color.withOpacity(0.16),
                            AppTheme.accent.withOpacity(0.10),
                            isDark ? AppTheme.backgroundDark.withOpacity(0.9) : Colors.white.withOpacity(0.9),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: _buildLiveDemo(item, _controller.value),
                      ),
                    );
                  },
                ),
              ),
            ).animate().fade().scale(begin: const Offset(0.98, 0.98)),
            const SizedBox(height: 22),
            Text(item.title, style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(item.demoText, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    context,
                    LucideIcons.clock,
                    item.time,
                    'Duration',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoTile(
                    context,
                    LucideIcons.checkCircle2,
                    item.goal,
                    'Skill',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text('How to guide', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildStep(context, '1', 'Set up the activity in a quiet space.'),
            _buildStep(context, '2', item.demoText),
            _buildStep(
              context,
              '3',
              'Give praise, keep it short, and stop if the child feels tired.',
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _completeActivity,
              icon: const Icon(LucideIcons.check),
              label: const Text('Mark Complete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeActivity() async {
    if (!SupabaseConfig.isConfigured) return;
    final service = ActivityService(Supabase.instance.client);
    if (widget.activity.id != null) {
      await service.completeActivity(widget.activity.id!);
    } else {
      await service.completeActivityByTitle(
        title: widget.activity.title,
        description: widget.activity.desc,
        category: widget.activity.goal,
      );
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity completed. Streak updated.')),
    );
  }

  Widget _buildLiveDemo(_ActivityItem item, double value) {
    final title = item.title.toLowerCase();
    final goal = item.goal.toLowerCase();
    if (title.contains('sound') || goal.contains('attention')) {
      return _SoundDemo(color: item.color, value: value);
    }
    if (title.contains('emotion') || goal.contains('social')) {
      return _EmotionDemo(color: item.color, value: value);
    }
    if (title.contains('texture') || goal.contains('sensory')) {
      return _TextureDemo(color: item.color, value: value);
    }
    if (title.contains('mirror') || goal.contains('communication')) {
      return _MirrorDemo(color: item.color, value: value);
    }
    if (title.contains('story') || goal.contains('cognitive')) {
      return _StorySequenceDemo(color: item.color, value: value);
    }
    if (title.contains('pressure') || goal.contains('regulation')) {
      return _PressureDemo(color: item.color, value: value);
    }
    if (title.contains('bubble') || goal.contains('motor')) {
      return _BubbleDemo(color: item.color, value: value);
    }
    if (title.contains('wait') || goal.contains('inhibition')) {
      return _WaitGoDemo(color: item.color, value: value);
    }
    if (title.contains('schedule') || goal.contains('routine')) {
      return _ScheduleDemo(color: item.color, value: value);
    }
    if (title.contains('crawl') || goal.contains('physical')) {
      return _MovementDemo(color: item.color, value: value);
    }
    if (title.contains('joint') || title.contains('point')) {
      return _JointAttentionDemo(color: item.color, value: value);
    }
    return _ColorSortingDemo(color: item.color, value: value);
  }

  Widget _buildInfoTile(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return GlassCard(
      height: 92,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 21, color: AppTheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(fontSize: 18),
                ),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium!.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ColorSortingDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _ColorSortingDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(bottom: 20, child: _Tray(color: color)),
          Positioned(
            left: 28 + value * 42,
            top: 54 + value * 72,
            child: _Cube(color: AppTheme.primary, value: value),
          ),
          Positioned(
            right: 32 + value * 26,
            top: 42 + value * 78,
            child: _Cube(color: AppTheme.secondary, value: 1 - value),
          ),
          Positioned(
            left: 100,
            top: 20 + value * 70,
            child: _Cube(color: AppTheme.accent, value: value),
          ),
        ],
      ),
    );
  }
}

class _SoundDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _SoundDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final speakerX = -70 + value * 140;
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (int i = 0; i < 3; i++)
            Transform.scale(
              scale: 0.7 + value + i * 0.28,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.25 - i * 0.05),
                    width: 4,
                  ),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(speakerX, 0),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY((value - 0.5) * 0.7),
              child: Icon(LucideIcons.volume2, size: 86, color: color),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Icon(
              LucideIcons.hand,
              size: 54,
              color: AppTheme.textPrimary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _EmotionDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _FaceCard(
            icon: LucideIcons.smile,
            color: AppTheme.accent,
            offset: Offset(-76 + value * 22, 18),
            value: value,
          ),
          _FaceCard(
            icon: LucideIcons.frown,
            color: AppTheme.secondary,
            offset: Offset(76 - value * 22, 18),
            value: 1 - value,
          ),
          _FaceCard(
            icon: LucideIcons.laugh,
            color: color,
            offset: Offset(0, -34 - value * 10),
            value: value,
          ),
        ],
      ),
    );
  }
}

class _TextureDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _TextureDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: Offset(0, value * 18),
            child: Icon(LucideIcons.hand, size: 78, color: color),
          ),
          Positioned(
            bottom: 34,
            left: 24,
            child: _TextureTile(color: AppTheme.primary, label: 'Soft'),
          ),
          Positioned(
            bottom: 34,
            left: 98,
            child: _TextureTile(color: AppTheme.secondary, label: 'Rough'),
          ),
          Positioned(
            bottom: 34,
            right: 24,
            child: _TextureTile(color: AppTheme.accent, label: 'Smooth'),
          ),
        ],
      ),
    );
  }
}

class _MirrorDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _MirrorDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 190,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: color.withOpacity(0.28), width: 4),
            ),
          ),
          Transform.translate(
            offset: Offset(-34 + value * 18, -4),
            child: _PersonIcon(color: color, icon: LucideIcons.smile),
          ),
          Transform.translate(
            offset: Offset(44 - value * 18, -4),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0),
              child: _PersonIcon(color: AppTheme.accent, icon: LucideIcons.smile),
            ),
          ),
          Positioned(
            bottom: 12,
            child: _DemoLabel('Copy the face'),
          ),
        ],
      ),
    );
  }
}

class _StorySequenceDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _StorySequenceDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final icons = [LucideIcons.sunrise, LucideIcons.utensils, LucideIcons.gamepad2];
    final labels = ['Wake', 'Eat', 'Play'];
    return SizedBox(
      width: 280,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 52,
            left: 18,
            right: 18,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          for (var i = 0; i < 3; i++)
            Positioned(
              left: 28 + i * 82.0,
              top: 22 + (i == 1 ? value * 16 : (1 - value) * 10),
              child: _SequenceCard(
                icon: icons[i],
                label: labels[i],
                color: i == 1 ? color : AppTheme.primary,
              ),
            ),
          Positioned(bottom: 18, child: _DemoLabel('Put cards in order')),
        ],
      ),
    );
  }
}

class _PressureDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _PressureDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.scale(
            scale: 1.0 - value * 0.05,
            child: Container(
              width: 170,
              height: 126,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.34), AppTheme.primary.withOpacity(0.22)],
                ),
                borderRadius: BorderRadius.circular(36),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.20),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.heart, color: Colors.white, size: 50),
            ),
          ),
          Positioned(
            left: 38 + value * 14,
            child: Icon(LucideIcons.hand, size: 56, color: color),
          ),
          Positioned(
            right: 38 + value * 14,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..scale(-1.0, 1.0),
              child: Icon(LucideIcons.hand, size: 56, color: color),
            ),
          ),
          Positioned(bottom: 18, child: _DemoLabel('Gentle firm pressure')),
        ],
      ),
    );
  }
}

class _BubbleDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _BubbleDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        children: [
          for (var i = 0; i < 7; i++)
            Positioned(
              left: 34.0 + (i % 3) * 74 + value * (i.isEven ? 14 : -10),
              top: 30.0 + i * 18 - value * 26,
              child: _Bubble(
                size: 30.0 + (i % 3) * 10,
                color: i.isEven ? color : AppTheme.accent,
              ),
            ),
          Positioned(
            bottom: 30,
            right: 54 + value * 30,
            child: Icon(LucideIcons.hand, size: 64, color: AppTheme.textPrimary.withOpacity(0.72)),
          ),
          Positioned(bottom: 12, left: 74, child: _DemoLabel('Pop one bubble')),
        ],
      ),
    );
  }
}

class _WaitGoDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _WaitGoDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final go = value > 0.48;
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 52,
            left: 28,
            right: 28,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color.withOpacity(0.16),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 450),
            left: go ? 176 : 56,
            bottom: 70,
            child: _PersonIcon(color: go ? AppTheme.accent : Colors.redAccent, icon: go ? LucideIcons.play : LucideIcons.pause),
          ),
          Positioned(
            top: 30,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (go ? AppTheme.accent : Colors.redAccent).withOpacity(0.16),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Text(
                go ? 'GO' : 'WAIT',
                style: TextStyle(
                  color: go ? AppTheme.accent : Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _ScheduleDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    final icons = [LucideIcons.brush, LucideIcons.bookOpen, LucideIcons.moon];
    final labels = ['Brush', 'Read', 'Sleep'];
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 214,
            height: 158,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: color.withOpacity(0.20), width: 2),
            ),
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(icons[i], color: i == 1 ? color : AppTheme.textSecondary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w800))),
                        Icon(i < value * 4 ? LucideIcons.checkCircle2 : LucideIcons.circle, color: i < value * 4 ? AppTheme.accent : AppTheme.textSecondary, size: 18),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Positioned(bottom: 16, child: _DemoLabel('Follow next step')),
        ],
      ),
    );
  }
}

class _MovementDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _MovementDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 48,
            left: 34,
            right: 34,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(-72 + value * 144, -4 + (value - 0.5).abs() * 18),
            child: Transform.rotate(
              angle: (value - 0.5) * 0.5,
              child: _PersonIcon(color: color, icon: LucideIcons.accessibility),
            ),
          ),
          Positioned(bottom: 14, child: _DemoLabel('Move slowly together')),
        ],
      ),
    );
  }
}

class _JointAttentionDemo extends StatelessWidget {
  final Color color;
  final double value;

  const _JointAttentionDemo({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 270,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 38,
            top: 34,
            child: Transform.scale(
              scale: 1 + value * 0.12,
              child: Icon(LucideIcons.star, color: color, size: 48),
            ),
          ),
          Positioned(
            left: 40,
            bottom: 58,
            child: _PersonIcon(color: AppTheme.primary, icon: LucideIcons.user),
          ),
          Positioned(
            left: 116,
            bottom: 90,
            child: Transform.rotate(
              angle: -0.65 + value * 0.12,
              child: Icon(LucideIcons.mousePointer2, color: color, size: 62),
            ),
          ),
          Positioned(
            left: 134,
            top: 68,
            child: Container(
              width: 76,
              height: 3,
              color: color.withOpacity(0.35),
            ),
          ),
          Positioned(bottom: 16, child: _DemoLabel('Point and share look')),
        ],
      ),
    );
  }
}

class _Cube extends StatelessWidget {
  final Color color;
  final double value;

  const _Cube({required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(-0.45)
        ..rotateY((value - 0.5) * 0.8),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonIcon extends StatelessWidget {
  final Color color;
  final IconData icon;

  const _PersonIcon({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 40),
    );
  }
}

class _DemoLabel extends StatelessWidget {
  final String text;

  const _DemoLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SequenceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SequenceCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final Color color;

  const _Bubble({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.34), width: 2),
      ),
    );
  }
}

class _Tray extends StatelessWidget {
  final Color color;

  const _Tray({required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.85),
      child: Container(
        width: 190,
        height: 92,
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(0.35), width: 3),
        ),
      ),
    );
  }
}

class _FaceCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Offset offset;
  final double value;

  const _FaceCard({
    required this.icon,
    required this.color,
    required this.offset,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY((value - 0.5) * 0.8),
        child: Container(
          width: 86,
          height: 116,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.25), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 46),
        ),
      ),
    );
  }
}

class _TextureTile extends StatelessWidget {
  final Color color;
  final String label;

  const _TextureTile({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.22), width: 2),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
