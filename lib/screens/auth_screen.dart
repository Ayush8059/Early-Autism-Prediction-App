import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/auth_service.dart';
import '../core/captcha_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/custom_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'main_layout.dart';
import 'tutorial_screen.dart';
import 'update_password_screen.dart';
import 'dart:math' as math;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _bgController;
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberEmail = true;
  bool _showPasswordRules = false;
  late final Stream<AuthState>? _authStateChanges;

  static const _rememberEmailKey = 'remember_login_email';
  static const _savedEmailKey = 'saved_login_email';
  static const deletedEmailsKey = 'deleted_account_emails';

  AuthService? get _authService {
    if (!SupabaseConfig.isConfigured) return null;
    return AuthService(Supabase.instance.client);
  }

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _authStateChanges = _authService?.authStateChanges;
    _authStateChanges?.listen((state) {
      if (!mounted || state.event != AuthChangeEvent.passwordRecovery) return;

      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()));
    });

    _loadSavedLogin();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formIsValid = _formKey.currentState!.validate();
    final shouldShowRules = _isSignUp && _passwordNeedsStrongRules();
    if (_showPasswordRules != shouldShowRules) {
      setState(() => _showPasswordRules = shouldShowRules);
    }
    if (!formIsValid) return;

    final authService = _authService;
    if (authService == null) {
      _showMessage(
        'Add your Supabase URL and anon key before using authentication.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        await _forgetDeletedEmailForSignup();
        final captchaToken = await _captchaTokenOrAbort();
        if (SupabaseConfig.isCaptchaEnabled && captchaToken == null) return;

        await authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text,
          captchaToken: captchaToken,
        );
        await _forgetDeletedEmailForSignup();
        _showMessage(
          'Account created. You can log in now.',
        );
      } else {
        await _signInWithCaptchaOnlyWhenNeeded(authService);
      }

      await _saveLoginPreference();

      if (mounted && Supabase.instance.client.auth.currentUser != null) {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final shouldShowTutorial = await TutorialScreen.shouldShow(
          userId: userId,
        );
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => shouldShowTutorial
                ? TutorialScreen(userId: userId)
                : const MainLayout(),
          ),
          (_) => false,
        );
      }
    } on AuthException catch (error) {
      _showMessage(_friendlyAuthMessage(error));
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithCaptchaOnlyWhenNeeded(AuthService authService) async {
    try {
      await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
    } on AuthException catch (error) {
      if (!_isCaptchaRequired(error)) {
        rethrow;
      }

      final captchaToken = await _captchaTokenOrAbort();
      if (SupabaseConfig.isCaptchaEnabled && captchaToken == null) return;

      await authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        captchaToken: captchaToken,
      );
    }
  }

  bool _isCaptchaRequired(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('captcha') ||
        message.contains('verification') ||
        message.contains('challenge');
  }

  bool _isInvalidCredentialError(AuthException error) {
    final message = error.message.toLowerCase();
    return message.contains('invalid login credentials') ||
        message.contains('invalid credentials') ||
        message.contains('email not confirmed') ||
        message.contains('invalid email or password');
  }

  String _friendlyAuthMessage(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('password should contain') ||
        message.contains('password') && message.contains('character of each')) {
      return 'Password must include uppercase, lowercase, number, and symbol.';
    }
    if (_isInvalidCredentialError(error)) {
      return 'Invalid login credentials.';
    }
    if (_isCaptchaRequired(error)) {
      return 'Please complete security verification and try again.';
    }
    return error.message;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.length < 8) {
      return 'Use at least 8 characters.';
    }
    if (_isSignUp) {
      final hasLower = RegExp(r'[a-z]').hasMatch(password);
      final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
      final hasNumber = RegExp(r'[0-9]').hasMatch(password);
      final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
      if (!hasLower || !hasUpper || !hasNumber || !hasSymbol) {
        return '';
      }
    }
    return null;
  }

  bool _passwordNeedsStrongRules() {
    final password = _passwordController.text;
    if (password.length < 8) return false;
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
    return !hasLower || !hasUpper || !hasNumber || !hasSymbol;
  }

  Future<void> _loadSavedLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final remember = prefs.getBool(_rememberEmailKey) ?? true;
    final savedEmail = prefs.getString(_savedEmailKey) ?? '';
    setState(() {
      _rememberEmail = remember;
      if (remember && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
      }
    });
  }

  Future<void> _saveLoginPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberEmailKey, _rememberEmail);
    if (_rememberEmail) {
      await prefs.setString(_savedEmailKey, _emailController.text.trim());
    } else {
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<void> _forgetDeletedEmailForSignup() async {
    final email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final deletedEmails = prefs.getStringList(deletedEmailsKey) ?? [];
    if (deletedEmails.remove(email)) {
      await prefs.setStringList(deletedEmailsKey, deletedEmails);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showMessage('Enter your email first.');
      return;
    }

    final authService = _authService;
    if (authService == null) {
      _showMessage('Supabase is not configured yet.');
      return;
    }

    try {
      final captchaToken = await _captchaTokenOrAbort();
      if (SupabaseConfig.isCaptchaEnabled && captchaToken == null) return;

      await authService.resetPassword(email, captchaToken: captchaToken);
      _showMessage('Password reset email sent.');
    } on AuthException catch (error) {
      _showMessage(error.message);
    }
  }

  Future<String?> _captchaTokenOrAbort() async {
    if (!SupabaseConfig.isCaptchaEnabled) return null;

    _showMessage('Complete CAPTCHA verification to continue.');
    if (!CaptchaService.isSupportedPlatform) {
      _showMessage('CAPTCHA is available on Android device builds only.');
      return null;
    }

    final token = await CaptchaService.verify(context);
    if (token == null || token.isEmpty) {
      _showMessage('CAPTCHA verification was not completed.');
      return null;
    }
    return token;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width > 760;

    return Scaffold(
      body: Stack(
        children: [
          // Animated 3D background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _AuthBackgroundPainter(
                    animationValue: _bgController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                const Positioned(
                  top: 10,
                  right: 16,
                  child: ThemeToggleButton(),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWide ? 48 : 22,
                      vertical: 24,
                    ),
                    child: AutofillGroup(
                      child: Form(
                        key: _formKey,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLogoSection(context),
                              const SizedBox(height: 26),
                              _buildAuthCard(context)
                                  .animate()
                                  .fade(duration: 600.ms)
                                  .slideY(
                                    begin: 0.1,
                                    curve: Curves.easeOutBack,
                                  ),
                              const SizedBox(height: 18),
                              _buildSwitchModeButton(
                                isDark,
                              ).animate().fade(delay: 200.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark
        ? const Color(0xFF111827).withOpacity(0.94)
        : Colors.white.withOpacity(0.96);
    final borderColor = isDark
        ? Colors.white.withOpacity(0.12)
        : AppTheme.primary.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.32 : 0.12),
            blurRadius: 34,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isSignUp ? LucideIcons.userPlus : LucideIcons.shieldCheck,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _isSignUp ? 'Create Account' : 'Welcome Back',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
              color: isDark ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isSignUp
                ? 'Create a secure parent profile to save progress.'
                : 'Sign in to continue tracking activities and results.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          if (_isSignUp) ...[
            _buildTextField(
              context: context,
              controller: _nameController,
              label: 'Full name',
              icon: LucideIcons.user,
              validator: (value) => value == null || value.trim().length < 2
                  ? 'Enter your name'
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            context: context,
            controller: _emailController,
            label: 'Email',
            icon: LucideIcons.mail,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            validator: (value) {
              final email = value?.trim() ?? '';
              return email.contains('@') && email.contains('.')
                  ? null
                  : 'Enter a valid email';
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            context: context,
            controller: _passwordController,
            label: 'Password',
            icon: LucideIcons.lock,
            obscureText: _obscurePassword,
            autofillHints: [
              _isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            suffixIcon: IconButton(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
              icon: Icon(
                _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: _validatePassword,
          ),
          if (_isSignUp && _showPasswordRules) ...[
            const SizedBox(height: 8),
            _buildPasswordRuleMessage(context),
          ],
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _rememberEmail,
              onChanged: (value) =>
                  setState(() => _rememberEmail = value ?? true),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppTheme.primary,
              title: Text(
                'Remember email on this device',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: isDark ? Colors.white70 : AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Password can be saved securely by Android Password Manager.',
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: isDark ? Colors.white54 : AppTheme.textSecondary,
                  height: 1.2,
                ),
              ),
            ),
          ],
          if (!_isSignUp)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _resetPassword,
                child: const Text('Forgot password?'),
              ),
            )
          else
            const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: CustomButton(
              text: _isLoading
                  ? 'Please wait'
                  : (_isSignUp ? 'Sign Up' : 'Log In'),
              icon: _isSignUp ? LucideIcons.userPlus : LucideIcons.logIn,
              onPressed: _isLoading ? () {} : _submit,
            ),
          ).animate().shimmer(delay: 400.ms, duration: 1800.ms),
          if (!SupabaseConfig.isConfigured) ...[
            const SizedBox(height: 14),
            Text(
              'Supabase is not configured. Run with --dart-define values.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall!.copyWith(color: Colors.redAccent),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchModeButton(bool isDark) {
    return TextButton(
      onPressed: _isLoading
          ? null
          : () => setState(() {
              _isSignUp = !_isSignUp;
              _showPasswordRules = false;
              _formKey.currentState?.reset();
              _nameController.clear();
              _emailController.clear();
              _passwordController.clear();
            }),
      child: Text(
        _isSignUp
            ? 'Already have an account? Log in'
            : 'New here? Create an account',
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildPasswordRuleMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.circleAlert,
            size: 18,
            color: Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Password must include at least 8 characters, one uppercase letter, one lowercase letter, one number, and one symbol.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.redAccent,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.heartPulse,
                  size: 50,
                  color: AppTheme.primary,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.1, 1.1),
              duration: 2.seconds,
              curve: Curves.easeInOut,
            )
            .shimmer(delay: 1.seconds, duration: 2.seconds),
        const SizedBox(height: 16),
        Text(
          'AutiSense',
          style: Theme.of(context).textTheme.displayMedium!.copyWith(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ).animate().fade(delay: 100.ms).slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    Iterable<String>? autofillHints,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : AppTheme.textPrimary,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        labelStyle: TextStyle(
          color: isDark ? Colors.white70 : AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        prefixIcon: Icon(icon, color: AppTheme.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withOpacity(0.08)
            : const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.10)
                : const Color(0xFFE2E8F0),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: AppTheme.primary.withOpacity(0.75),
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _AuthBackgroundPainter extends CustomPainter {
  final double animationValue;
  final bool isDark;

  _AuthBackgroundPainter({required this.animationValue, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw background color
    paint.color = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, paint);

    // Draw animated blobs
    for (int i = 0; i < 3; i++) {
      final double phase = i * math.pi * 2 / 3;
      final double radius =
          size.width * 0.4 +
          math.sin(animationValue * math.pi * 2 + phase) * 50;
      final double x =
          size.width * 0.5 +
          math.cos(animationValue * math.pi * 2 + phase) * 100;
      final double y =
          size.height * 0.5 +
          math.sin(animationValue * math.pi * 2.5 + phase) * 150;

      final color = i == 0
          ? AppTheme.primary
          : (i == 1 ? AppTheme.secondary : AppTheme.accent);

      final gradient = RadialGradient(
        colors: [color.withOpacity(isDark ? 0.15 : 0.08), color.withOpacity(0)],
      );

      paint.shader = gradient.createShader(
        Rect.fromCircle(center: Offset(x, y), radius: radius),
      );
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AuthBackgroundPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isDark != isDark;
}
