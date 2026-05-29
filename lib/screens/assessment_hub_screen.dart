import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../core/language_service.dart';
import '../core/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'assessment_results_screen.dart';
import 'photo_analysis_screen.dart';
import 'questionnaire_screen.dart';

class AssessmentHubScreen extends StatelessWidget {
  const AssessmentHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.currentLanguage,
      builder: (context, _, __) => Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: Text(LanguageService.t('assessments')),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                LanguageService.t('assessIntro'),
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fade().slideY(begin: -0.2),
              const SizedBox(height: 32),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    _buildHubCard(
                      context,
                      title: LanguageService.t('photoAnalysis'),
                      subtitle: LanguageService.t('photoAnalysisDesc'),
                      icon: LucideIcons.scanFace,
                      color: AppTheme.primary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PhotoAnalysisScreen())),
                    ).animate().fade(delay: 200.ms).slideX(begin: 0.2),
                    const SizedBox(height: 20),
                    _buildHubCard(
                      context,
                      title: LanguageService.t('questionnaire'),
                      subtitle: LanguageService.t('questionnaireDesc'),
                      icon: LucideIcons.clipboardList,
                      color: AppTheme.secondary,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionnaireScreen())),
                    ).animate().fade(delay: 400.ms).slideX(begin: 0.2),
                    const SizedBox(height: 20),
                    _buildHubCard(
                      context,
                      title: 'Saved Results',
                      subtitle: 'Review previous assessment outcomes and remove old records.',
                      icon: LucideIcons.history,
                      color: AppTheme.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AssessmentResultsScreen())),
                    ).animate().fade(delay: 600.ms).slideX(begin: 0.2),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildHubCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GlassCard(
      onTap: onTap,
      height: 188,
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 120, color: color.withOpacity(0.05)),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            fontSize: 26,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary.withOpacity(0.5)),
            ],
          ),
        ],
      ),
    );
  }
}
