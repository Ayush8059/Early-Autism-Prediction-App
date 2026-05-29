import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/assessment_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';

class AssessmentResultsScreen extends StatefulWidget {
  const AssessmentResultsScreen({super.key});

  @override
  State<AssessmentResultsScreen> createState() =>
      _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  late Future<List<AssessmentSummary>> _assessmentsFuture;

  AssessmentService? get _service {
    if (!SupabaseConfig.isConfigured) return null;
    return AssessmentService(Supabase.instance.client);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _assessmentsFuture =
        _service?.fetchRecentAssessments(limit: 50) ?? Future.value([]);
  }

  Future<void> _delete(AssessmentSummary assessment) async {
    await _service?.deleteAssessment(assessment);
    if (!mounted) return;
    setState(_load);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Assessment deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Assessment Results'),
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
        child: FutureBuilder<List<AssessmentSummary>>(
          future: _assessmentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.circleAlert,
                        color: Colors.redAccent,
                        size: 42,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load saved results.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }

            final assessments = snapshot.data ?? [];
            if (assessments.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'No saved assessment results yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: assessments.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = assessments[index];
                final color = item.riskLevel == 'High'
                    ? Colors.redAccent
                    : item.riskLevel == 'Medium'
                    ? Colors.orangeAccent
                    : AppTheme.accent;

                return GlassCard(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AssessmentDetailScreen(assessment: item),
                    ),
                  ),
                  height: 170,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.type == 'photo'
                              ? LucideIcons.scanFace
                              : LucideIcons.clipboardList,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${item.riskLevel} • ${item.scoreText}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              _formatDate(item.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          LucideIcons.trash2,
                          color: Colors.redAccent,
                        ),
                        onPressed: () => _delete(item),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class AssessmentDetailScreen extends StatelessWidget {
  const AssessmentDetailScreen({super.key, required this.assessment});

  final AssessmentSummary assessment;

  @override
  Widget build(BuildContext context) {
    final service = AssessmentService(Supabase.instance.client);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(assessment.title),
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
        child: FutureBuilder<AssessmentDetail>(
          future: service.fetchAssessmentDetail(assessment),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const Center(child: Text('Result not found.'));
            }

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assessment.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _summaryLine(assessment),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 18),
                      if (detail.autisticPercent != null &&
                          detail.nonAutisticPercent != null) ...[
                        _buildPercentBar(
                          context,
                          'Autistic pattern',
                          detail.autisticPercent!,
                          Colors.orangeAccent,
                        ),
                        const SizedBox(height: 12),
                        _buildPercentBar(
                          context,
                          'Non-autistic pattern',
                          detail.nonAutisticPercent!,
                          AppTheme.accent,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        detail.message,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium!.copyWith(height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (detail.answers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Answers',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (final answer in detail.answers)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassCard(
                        height: 92,
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(
                              (answer['answer'] as bool? ?? false)
                                  ? LucideIcons.check
                                  : LucideIcons.x,
                              color: AppTheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                answer['question'] as String? ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPercentBar(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    final normalized = (value / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text(
              '${value.toStringAsFixed(1)}%',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: normalized,
            minHeight: 9,
            color: color,
            backgroundColor: color.withOpacity(0.14),
          ),
        ),
      ],
    );
  }

  String _summaryLine(AssessmentSummary assessment) {
    if (assessment.type == 'photo') {
      return '${assessment.scoreText} - ${assessment.riskLevel} risk';
    }
    return '${assessment.riskLevel} risk - ${assessment.scoreText}';
  }
}
