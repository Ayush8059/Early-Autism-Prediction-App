import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/assessment_service.dart';
import '../core/ml_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';

class PhotoAnalysisScreen extends StatefulWidget {
  const PhotoAnalysisScreen({super.key});

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  String _imagePath = '';
  bool _isAnalyzing = false;
  bool _isSaving = false;
  AnalysisResult? _result;

  late final AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _imagePath = '';
        _result = null;
      });
    }
  }

  Future<void> _analyzePhoto() async {
    final imageBytes = _imageBytes;
    if (imageBytes == null) return;

    setState(() => _isAnalyzing = true);
    _scanController.repeat(reverse: true);

    final result = await MLService.analyzeImageBytes(imageBytes);

    if (mounted) {
      _scanController.stop();
      setState(() {
        _isAnalyzing = false;
        _result = result;
      });
      if (_isSuccessfulResult(result)) {
        await _savePhotoResult(result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Analysis failed. Result not saved.')),
        );
      }
    }
  }

  Future<void> _savePhotoResult(AnalysisResult result) async {
    if (!SupabaseConfig.isConfigured || !_isSuccessfulResult(result)) return;
    setState(() => _isSaving = true);
    try {
      final service = AssessmentService(Supabase.instance.client);
      var imagePath = _imagePath;
      final imageBytes = _imageBytes;
      if (imagePath.isEmpty && imageBytes != null) {
        imagePath = await service.uploadChildPhotoBytes(imageBytes);
        _imagePath = imagePath;
      }
      await service.savePhotoAssessment(result: result, imagePath: imagePath);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Photo result saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save photo result.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetPhoto() {
    setState(() {
      _imageBytes = null;
      _imagePath = '';
      _result = null;
      _isAnalyzing = false;
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Photo Analysis'),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final previewHeight = (constraints.maxHeight * 0.54).clamp(
              300.0,
              460.0,
            );

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Capture or upload a clear front-facing photo for visual cue screening.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate().fade().slideY(begin: -0.1),
                  const SizedBox(height: 14),
                  _buildCaptureGuide(),
                  const SizedBox(height: 18),
                  SizedBox(height: previewHeight, child: _buildPreview())
                      .animate()
                      .fade(delay: 150.ms)
                      .scale(begin: const Offset(0.98, 0.98)),
                  const SizedBox(height: 18),
                  _buildActions(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCaptureGuide() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (LucideIcons.sunMedium, 'Good light'),
      (LucideIcons.scanFace, 'Front face'),
      (LucideIcons.images, 'Camera or gallery'),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(isDark ? 0.04 : 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.$1, color: AppTheme.primary, size: 16),
                const SizedBox(width: 7),
                Text(
                  item.$2,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fade(delay: 80.ms).slideX(begin: -0.05);
  }

  Widget _buildPreview() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _imageBytes == null ? _buildEmptyState() : _buildImageState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0.12),
            AppTheme.accent.withOpacity(0.10),
            isDark ? AppTheme.backgroundDark.withOpacity(0.9) : Colors.white.withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -18,
            child: Icon(
              LucideIcons.sparkles,
              size: 128,
              color: AppTheme.accent.withOpacity(0.12),
            ),
          ),
          Positioned(
            left: -18,
            bottom: -18,
            child: Icon(
              LucideIcons.scanFace,
              size: 132,
              color: AppTheme.primary.withOpacity(0.10),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.cardDark : Colors.white.withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.10) : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      LucideIcons.scanFace,
                      color: AppTheme.primary,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Choose photo source',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Take a fresh picture or upload an existing clear photo.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildMiniSourceChip(
                        LucideIcons.camera,
                        'Take photo',
                        () => _pickPhoto(ImageSource.camera),
                      ),
                      _buildMiniSourceChip(
                        LucideIcons.images,
                        'Upload',
                        () => _pickPhoto(ImageSource.gallery),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(_imageBytes!, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.18),
                Colors.transparent,
                Colors.black.withOpacity(0.35),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        if (_isAnalyzing) _buildScanOverlay(),
        if (_result != null) _buildResultOverlay(),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Row(
            children: [
              _buildPhotoBadge(LucideIcons.shieldCheck, 'Private on device', isDark),
              const Spacer(),
              _buildPhotoBadge(
                LucideIcons.sparkles,
                _result == null ? 'Ready' : 'Complete',
                isDark,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _scanController,
          builder: (context, child) {
            return Stack(
              children: [
                Container(color: AppTheme.primary.withOpacity(0.20)),
                Positioned(
                  top: _scanController.value * constraints.maxHeight,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accent.withOpacity(0.85),
                          blurRadius: 14,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.62),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Analyzing photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResultOverlay() {
    final isSuccess = _isSuccessfulResult(_result!);
    return Container(
      color: Colors.black.withOpacity(0.78),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 74),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSuccess ? LucideIcons.checkCircle : LucideIcons.circleAlert,
            color: isSuccess ? AppTheme.accent : Colors.orangeAccent,
            size: 54,
          ).animate().scale(curve: Curves.elasticOut),
          const SizedBox(height: 12),
          Text(
            '${_displayLabel(_result!.label)} pattern',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ).animate().fade(delay: 300.ms),
          const SizedBox(height: 10),
          _buildPercentBar(
            label: 'Autistic pattern',
            value: _result!.autisticPercent,
            color: Colors.orangeAccent,
          ),
          const SizedBox(height: 8),
          _buildPercentBar(
            label: 'Non-autistic pattern',
            value: _result!.nonAutisticPercent,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 10),
          Text(
            '${_result!.confidenceScore.toStringAsFixed(1)}% confidence. ${_result!.message}',
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 10),
            const Text(
              'Saving result...',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_imageBytes == null) {
      return Row(
        children: [
          Expanded(
            child: _buildSourceButton(
              icon: LucideIcons.camera,
              label: 'Take Photo',
              color: AppTheme.primary,
              onTap: () => _pickPhoto(ImageSource.camera),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSourceButton(
              icon: LucideIcons.images,
              label: 'Upload Photo',
              color: AppTheme.secondary,
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
          ),
        ],
      ).animate().slideY(begin: 0.2, curve: Curves.easeOutBack).fade();
    }

    if (!_isAnalyzing && _result == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomButton(
            text: 'Run Analysis',
            icon: LucideIcons.cpu,
            onPressed: _analyzePhoto,
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryAction(
                  icon: LucideIcons.camera,
                  label: 'Retake',
                  onTap: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSecondaryAction(
                  icon: LucideIcons.images,
                  label: 'Gallery',
                  onTap: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ).animate().fade();
    }

    if (_result != null) {
      return Row(
        children: [
          Expanded(
            child: _buildSourceButton(
              icon: LucideIcons.refreshCcw,
              label: 'New Photo',
              color: AppTheme.primary,
              onTap: _resetPhoto,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSecondaryAction(
              icon: LucideIcons.images,
              label: 'Gallery',
              onTap: () => _pickPhoto(ImageSource.gallery),
            ),
          ),
        ],
      );
    }

    return const SizedBox(height: 56);
  }

  Widget _buildMiniSourceChip(IconData icon, String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.12) : AppTheme.primary.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.primary, size: 17),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentBar({
    required String label,
    required double value,
    required Color color,
  }) {
    final normalized = (value / 100).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: normalized,
              backgroundColor: Colors.white.withOpacity(0.16),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.28),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textPrimary,
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: AppTheme.primary.withOpacity(0.28)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildPhotoBadge(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardDark.withOpacity(0.9) : Colors.white.withOpacity(0.86),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white : AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _displayLabel(String label) {
    if (label == 'Non_Autistic') return 'Non-autistic';
    if (label == 'Autistic') return 'Autistic';
    return label;
  }

  bool _isSuccessfulResult(AnalysisResult result) {
    return result.label != 'Unknown' && result.confidenceScore > 0;
  }
}
