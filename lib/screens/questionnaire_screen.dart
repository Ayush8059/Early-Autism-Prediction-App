import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/assessment_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../core/ml_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';

class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  int _currentIndex = 0;
  int _riskScore = 0;
  bool _isFinished = false;
  bool _isSaving = false;
  bool _isSaved = false;
  final List<Map<String, dynamic>> _answers = [];

  // Q1-Q12 Standardized Assessment Mapping
  final List<String> _questions = [
    "Q1: Does your child enjoy playing peek-a-boo or hide-and-seek?",
    "Q2: Does your child point with one finger to ask for something or to get help?",
    "Q3: Does your child ever pretend, for example, to talk on the phone or take care of dolls?",
    "Q4: Does your child look you in the eye for more than a second or two when talking/playing?",
    "Q5: Does your child respond appropriately when you call their name?",
    "Q6: Does your child make unusual finger movements near their eyes?",
    "Q7: Does your child try to copy what you do (e.g., clapping, waving bye-bye)?",
    "Q8: Does your child smile back at you when you smile at them?",
    "Q9: Does your child stare at nothing or wander with no purpose?",
    "Q10: Does your child consistently cover their ears to block everyday noises?",
    "Q11: Does your child seem overly sensitive to certain textures of clothing?",
    "Q12: Does your child try to get your attention to show you something interesting?",
  ];

  // Some questions are reverse-scored based on typical behavioral milestones.
  // E.g., unusual finger movements (Q6), staring/wandering (Q9), covering ears (Q10), sensitive to textures (Q11).
  // If they answer "Yes" to these, risk increases. For others, "No" increases risk.
  final Set<int> _reverseCodedQuestionIndices = {5, 8, 9, 10}; 

  void _answer(bool isYes) {
    bool isReverseCoded = _reverseCodedQuestionIndices.contains(_currentIndex);
    final addsRisk = (isReverseCoded && isYes) || (!isReverseCoded && !isYes);

    _answers.add({
      'question_index': _currentIndex,
      'question': _questions[_currentIndex],
      'answer': isYes,
      'adds_risk': addsRisk,
    });
    
    // If reverse coded: Yes (+1 risk). If standard: No (+1 risk).
    if (addsRisk) {
      _riskScore++;
    }
    
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
    } else {
      setState(() => _isFinished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Q1-Q12 Screening'),
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isFinished ? _buildResults() : _buildQuestion(),
        ),
      ),
    );
  }

  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _questions.length,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
          borderRadius: BorderRadius.circular(8),
          minHeight: 10,
        ),
        const SizedBox(height: 32),
        Text(
          'Question ${_currentIndex + 1} of ${_questions.length}',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
        ).animate().fade(),
        const SizedBox(height: 24),
        Expanded(
          child: GlassCard(
            key: ValueKey(_currentIndex),
            child: Center(
              child: Text(
                _questions[_currentIndex],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge!.copyWith(fontSize: 26),
              ),
            ),
          ).animate().slideX(begin: 0.1, duration: 400.ms).fade(),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: CustomButton(
                text: 'No',
                icon: LucideIcons.x,
                onPressed: () => _answer(false),
                isPrimary: false,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomButton(
                text: 'Yes',
                icon: LucideIcons.check,
                onPressed: () => _answer(true),
                isPrimary: true,
              ),
            ),
          ],
        ).animate().slideY(begin: 0.5, curve: Curves.easeOutBack)
      ],
    );
  }

  Widget _buildResults() {
    // Determine color based on risk using the score
    Color riskColor = _riskScore >= 8 ? Colors.redAccent : (_riskScore >= 4 ? Colors.orangeAccent : AppTheme.accent);

    return Center(
      child: GlassCard(
        height: 380,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.clipboardCheck, size: 80, color: riskColor)
                .animate().scale(curve: Curves.elasticOut, duration: 800.ms),
            const SizedBox(height: 24),
            Text(
          'Assessment Complete',
              style: Theme.of(context).textTheme.titleLarge,
            ).animate().fade(delay: 300.ms),
            const SizedBox(height: 16),
            Text(
              MLService.getQuestionnaireRiskMessage(_riskScore),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ).animate().fade(delay: 500.ms),
            const SizedBox(height: 32),
            CustomButton(
              text: _isSaved ? 'Finish' : (_isSaving ? 'Saving' : 'Save Result'),
              icon: _isSaved ? LucideIcons.checkCheck : LucideIcons.save,
              onPressed: _isSaving
                  ? () {}
                  : () async {
                      if (!_isSaved) {
                        await _saveResult();
                      } else if (mounted) {
                        Navigator.pop(context);
                      }
                    },
            ).animate().scale(delay: 700.ms),
          ],
        ),
      ),
    );
  }

  Future<void> _saveResult() async {
    if (!SupabaseConfig.isConfigured) {
      _showMessage('Supabase is not configured.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = AssessmentService(Supabase.instance.client);
      await service.saveQuestionnaireAssessment(
        score: _riskScore,
        riskLevel: service.riskLevelForScore(_riskScore),
        answers: _answers,
      );
      if (!mounted) return;
      setState(() => _isSaved = true);
      _showMessage('Assessment saved.');
    } catch (_) {
      _showMessage('Could not save result. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
