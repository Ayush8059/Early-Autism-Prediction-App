import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/auth_service.dart';
import '../core/language_service.dart';
import '../core/profile_service.dart';
import '../core/reminder_service.dart';
import '../core/supabase_config.dart';
import '../core/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'auth_screen.dart';
import 'chatbot_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notificationsEnabled = false;
  int _reminderHour = 9;
  int _reminderMinute = 0;
  List<int> _reminderDays = [1, 2, 3, 4, 5, 6, 7];
  String _selectedLanguage = 'English';
  String _avatarPath = '';
  String _avatarUrl = '';
  File? _profileImage;
  Uint8List? _profileImageBytes;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  late final Future<ParentProfile> _profileFuture;

  static const List<String> _languages = [
    'English',
    'Hindi',
    'Bengali',
    'Tamil',
    'Telugu',
    'Marathi',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
    'Urdu',
    'Odia',
    'Assamese',
    'Spanish',
    'French',
    'Arabic',
  ];

  ProfileService? get _profileService {
    if (!SupabaseConfig.isConfigured) return null;
    return ProfileService(Supabase.instance.client);
  }

  @override
  void initState() {
    super.initState();
    _profileFuture =
        _profileService?.getCurrentParentProfile().then((profile) {
          _notificationsEnabled = profile.notificationEnabled;
          _reminderHour = profile.reminderHour;
          _reminderMinute = profile.reminderMinute;
          _reminderDays = profile.reminderDays;
          _selectedLanguage = profile.language;
          LanguageService.setLanguage(profile.language);
          _avatarPath = profile.avatarPath;
          _avatarUrl = profile.avatarUrl;
          _phoneController.text = profile.phoneNumber;
          _feedbackController.text = profile.feedback;
          return profile;
        }) ??
        Future.value(
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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    if (SupabaseConfig.isConfigured) {
      await AuthService(Supabase.instance.client).signOut();
    }

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently deletes your profile, saved assessments, activity history, chat history, and private uploads. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!SupabaseConfig.isConfigured) {
      _showMessage('Supabase is not configured.');
      return;
    }

    try {
      await AuthService(Supabase.instance.client).deleteAccount();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (_) => false,
      );
    } catch (error) {
      _showMessage(
        'Could not delete account: ${error.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(_t('profileTitle')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickProfilePhoto,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.primary,
                          backgroundImage: _profileAvatarImage(),
                          child:
                              _profileImageBytes == null &&
                                  _profileImage == null &&
                                  _avatarUrl.isEmpty
                              ? const Icon(
                                  LucideIcons.user,
                                  size: 50,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            size: 17,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ).animate().scale(
                    curve: Curves.easeOutBack,
                    duration: 600.ms,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<ParentProfile>(
                    future: _profileFuture,
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      return Column(
                        children: [
                          Text(
                            profile?.fullName ?? 'Parent Profile',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Text(
                            profile?.email ?? 'Loading profile...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              _t('settings'),
              style: Theme.of(context).textTheme.titleMedium,
            ).animate().fade(delay: 200.ms),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(18),
              child: _buildParentDetailsPanel(),
            ).animate().fade(delay: 250.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: _buildReminderPanel(),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    onTap: _pickLanguage,
                    leading: const Icon(
                      LucideIcons.languages,
                      color: AppTheme.secondary,
                    ),
                    title: Text(_t('language')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedLanguage),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: _toggleThemeMode,
                    leading: Icon(
                      themeService.themeMode == ThemeMode.dark
                          ? LucideIcons.moon
                          : (themeService.themeMode == ThemeMode.light
                                ? LucideIcons.sun
                                : LucideIcons.laptop),
                      color: AppTheme.primary,
                    ),
                    title: const Text('Theme Mode'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeService.themeMode == ThemeMode.dark
                              ? 'Dark'
                              : (themeService.themeMode == ThemeMode.light
                                    ? 'Light'
                                    : 'System'),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 16,
                          color: AppTheme.textSecondary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                    ),
                    leading: const Icon(
                      LucideIcons.botMessageSquare,
                      color: AppTheme.primary,
                    ),
                    title: const Text('AI Parent Chat'),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      LucideIcons.shieldCheck,
                      color: AppTheme.accent,
                    ),
                    title: Text(_t('privacy')),
                    trailing: Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: AppTheme.textSecondary.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 450.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.info,
                      color: Colors.orangeAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Note: This app uses online screening and activity data for guidance only. For accurate diagnosis, treatment, or medical advice, please visit a qualified doctor.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium!.copyWith(height: 1.35),
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 520.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
            GlassCard(
              height: 80,
              onTap: _signOut,
              child: const Row(
                children: [
                  Icon(LucideIcons.logOut, color: Colors.redAccent),
                  SizedBox(width: 16),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ).animate().fade(delay: 600.ms).slideY(begin: 0.1),
            const SizedBox(height: 14),
            GlassCard(
              height: 88,
              onTap: _deleteAccount,
              padding: const EdgeInsets.all(18),
              child: const Row(
                children: [
                  Icon(LucideIcons.userX, color: Colors.redAccent),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, color: Colors.redAccent),
                ],
              ),
            ).animate().fade(delay: 650.ms).slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleThemeMode() async {
    final modes = ThemeMode.values;
    final currentIndex = themeService.themeMode.index;
    final nextIndex = (currentIndex + 1) % modes.length;
    await themeService.setThemeMode(modes[nextIndex]);
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildReminderPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bellRing, color: AppTheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Reminders',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _notificationsEnabled
                        ? '${_formattedReminderTime()} - ${_formattedReminderDays()}'
                        : 'Paused',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Switch(
              value: _notificationsEnabled,
              activeColor: AppTheme.primary,
              onChanged: _toggleReminder,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickReminderTime,
                icon: const Icon(LucideIcons.clock, size: 18),
                label: Text(
                  _formattedReminderTime(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickReminderDays,
                icon: const Icon(LucideIcons.calendarDays, size: 18),
                label: Text(
                  _reminderDays.length == 7
                      ? 'Every day'
                      : '${_reminderDays.length} days',
                  overflow: TextOverflow.ellipsis,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            final day = index + 1;
            final selected = _reminderDays.contains(day);
            return FilterChip(
              label: Text(_weekdayShortLabel(day)),
              selected: selected,
              onSelected: (checked) => _toggleReminderDay(day, checked),
              selectedColor: AppTheme.primary.withOpacity(0.18),
              checkmarkColor: AppTheme.primary,
              labelStyle: TextStyle(
                color: selected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildParentDetailsPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.contact, color: AppTheme.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _t('parentDetails'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.phone),
            labelText: _t('contactNo'),
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.75),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: isDark
                  ? BorderSide(color: Colors.white.withOpacity(0.12))
                  : BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _feedbackController,
          minLines: 2,
          maxLines: 4,
          style: TextStyle(
            color: isDark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: const Icon(LucideIcons.messageSquareText),
            labelText: _t('feedback'),
            labelStyle: TextStyle(
              color: isDark ? Colors.white70 : AppTheme.textSecondary,
            ),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.75),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: isDark
                  ? BorderSide(color: Colors.white.withOpacity(0.12))
                  : BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Saved details are shown here and stored securely in your Supabase profile.',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _saveParentDetails,
            icon: const Icon(LucideIcons.save, size: 18),
            label: Text(_t('saveDetails')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  ImageProvider? _profileAvatarImage() {
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);
    if (_profileImage != null) return FileImage(_profileImage!);
    if (_avatarUrl.isNotEmpty) return NetworkImage(_avatarUrl);
    return null;
  }

  Future<void> _pickProfilePhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 900,
    );
    if (photo == null) return;

    final bytes = await photo.readAsBytes();
    final image = File(photo.path);
    setState(() {
      _profileImage = image;
      _profileImageBytes = bytes;
    });

    if (_profileService != null) {
      final avatarPath = await _profileService!.uploadAvatarBytes(bytes);
      if (avatarPath.isNotEmpty) {
        setState(() => _avatarPath = avatarPath);
        await _saveParentDetails(showSuccess: false);
      }
    }
  }

  Future<void> _saveParentDetails({bool showSuccess = true}) async {
    final phone = _phoneController.text.trim();
    final feedback = _feedbackController.text.trim();
    final hasDetails =
        phone.isNotEmpty || feedback.isNotEmpty || _avatarPath.isNotEmpty;

    if (showSuccess && !hasDetails) {
      _showMessage(
        'Add contact number, feedback, or profile photo before saving.',
      );
      return;
    }

    await _profileService?.updateParentDetails(
      phoneNumber: phone,
      feedback: feedback,
      avatarUrl: _avatarPath,
      language: _selectedLanguage,
    );

    if (showSuccess) {
      _showMessage(_t('profileSaved'));
    }
  }

  Future<void> _toggleReminder(bool enabled) async {
    setState(() => _notificationsEnabled = enabled);

    if (enabled) {
      final scheduled = await ReminderService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        days: _reminderDays,
      );
      if (!scheduled) {
        setState(() => _notificationsEnabled = false);
        _showMessage('Notification permission was not granted.');
        return;
      }
    } else {
      await ReminderService.cancelDailyReminder();
    }

    await _saveReminderSettings();
    _showMessage(enabled ? 'Reminder enabled.' : 'Reminder disabled.');
  }

  Future<void> _toggleReminderDay(int day, bool checked) async {
    final nextDays = [..._reminderDays];
    if (checked) {
      nextDays.add(day);
    } else if (nextDays.length > 1) {
      nextDays.remove(day);
    } else {
      _showMessage('Select at least one reminder day.');
      return;
    }
    nextDays.sort();

    setState(() => _reminderDays = nextDays);

    if (_notificationsEnabled) {
      await ReminderService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        days: _reminderDays,
      );
    }

    await _saveReminderSettings();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );

    if (picked == null) return;

    setState(() {
      _reminderHour = picked.hour;
      _reminderMinute = picked.minute;
    });

    if (_notificationsEnabled) {
      await ReminderService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        days: _reminderDays,
      );
    }

    await _saveReminderSettings();
    _showMessage('Reminder time updated.');
  }

  Future<void> _pickReminderDays() async {
    final selected = [..._reminderDays];

    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reminder Days'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(7, (index) {
                  final day = index + 1;
                  return CheckboxListTile(
                    value: selected.contains(day),
                    title: Text(_weekdayLabel(day)),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true) {
                          selected.add(day);
                        } else {
                          selected.remove(day);
                        }
                        selected.sort();
                      });
                    },
                  );
                }),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() => _reminderDays = result);

    if (_notificationsEnabled) {
      await ReminderService.scheduleDailyReminder(
        hour: _reminderHour,
        minute: _reminderMinute,
        days: _reminderDays,
      );
    }

    await _saveReminderSettings();
    _showMessage('Reminder days updated.');
  }

  Future<void> _pickLanguage() async {
    final language = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 520),
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                  child: Row(
                    children: [
                      Text(
                        'Choose Language',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(LucideIcons.x),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: _languages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final item = _languages[index];
                      final selected = item == _selectedLanguage;
                      return ListTile(
                        onTap: () => Navigator.pop(context, item),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        tileColor: selected
                            ? AppTheme.primary.withOpacity(0.12)
                            : Colors.white.withOpacity(0.72),
                        leading: Icon(
                          selected
                              ? LucideIcons.circleCheck
                              : LucideIcons.languages,
                          color: selected
                              ? AppTheme.primary
                              : AppTheme.textSecondary,
                        ),
                        title: Text(
                          item,
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (language == null) return;
    setState(() => _selectedLanguage = language);
    LanguageService.setLanguage(language);
    await _saveParentDetails(showSuccess: false);
    _showMessage('${_t('languageChanged')} $language.');
  }

  Future<void> _saveReminderSettings() {
    return _profileService?.updateReminderSettings(
          enabled: _notificationsEnabled,
          hour: _reminderHour,
          minute: _reminderMinute,
          days: _reminderDays,
        ) ??
        Future.value();
  }

  String _formattedReminderTime() {
    final time = TimeOfDay(hour: _reminderHour, minute: _reminderMinute);
    return time.format(context);
  }

  String _formattedReminderDays() {
    if (_reminderDays.length == 7) return 'Every day';
    return _reminderDays.map(_weekdayShortLabel).join(', ');
  }

  String _weekdayLabel(int day) {
    const labels = {
      1: 'Monday',
      2: 'Tuesday',
      3: 'Wednesday',
      4: 'Thursday',
      5: 'Friday',
      6: 'Saturday',
      7: 'Sunday',
    };
    return labels[day]!;
  }

  String _weekdayShortLabel(int day) {
    const labels = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
    };
    return labels[day]!;
  }

  String _t(String key) {
    final values =
        _localizedText[_selectedLanguage] ?? _localizedText['English']!;
    return values[key] ?? _localizedText['English']![key] ?? key;
  }

  static const Map<String, Map<String, String>> _localizedText = {
    'English': {
      'profileTitle': 'Parent Profile',
      'settings': 'Settings',
      'parentDetails': 'Parent Details',
      'contactNo': 'Contact number',
      'feedback': 'Feedback',
      'saveDetails': 'Save details',
      'profileSaved': 'Profile details saved.',
      'language': 'Language',
      'privacy': 'Privacy & Data',
      'languageChanged': 'Language changed to',
    },
    'Hindi': {
      'profileTitle': 'अभिभावक प्रोफाइल',
      'settings': 'सेटिंग्स',
      'parentDetails': 'अभिभावक विवरण',
      'contactNo': 'संपर्क नंबर',
      'feedback': 'प्रतिक्रिया',
      'saveDetails': 'विवरण सेव करें',
      'profileSaved': 'प्रोफाइल विवरण सेव हो गया.',
      'language': 'भाषा',
      'privacy': 'गोपनीयता और डेटा',
      'languageChanged': 'भाषा बदलकर',
    },
    'Bengali': {
      'profileTitle': 'অভিভাবক প্রোফাইল',
      'settings': 'সেটিংস',
      'parentDetails': 'অভিভাবকের বিবরণ',
      'contactNo': 'যোগাযোগ নম্বর',
      'feedback': 'প্রতিক্রিয়া',
      'saveDetails': 'বিবরণ সংরক্ষণ করুন',
      'profileSaved': 'প্রোফাইল সংরক্ষণ হয়েছে.',
      'language': 'ভাষা',
      'privacy': 'গোপনীয়তা ও ডেটা',
      'languageChanged': 'ভাষা পরিবর্তন হয়েছে',
    },
    'Tamil': {
      'profileTitle': 'பெற்றோர் சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'parentDetails': 'பெற்றோர் விவரங்கள்',
      'contactNo': 'தொடர்பு எண்',
      'feedback': 'கருத்து',
      'saveDetails': 'விவரங்களை சேமி',
      'profileSaved': 'சுயவிவரம் சேமிக்கப்பட்டது.',
      'language': 'மொழி',
      'privacy': 'தனியுரிமை மற்றும் தரவு',
      'languageChanged': 'மொழி மாற்றப்பட்டது',
    },
    'Telugu': {
      'profileTitle': 'తల్లిదండ్రుల ప్రొఫైల్',
      'settings': 'సెట్టింగ్స్',
      'parentDetails': 'తల్లిదండ్రుల వివరాలు',
      'contactNo': 'సంప్రదింపు నంబర్',
      'feedback': 'అభిప్రాయం',
      'saveDetails': 'వివరాలు సేవ్ చేయండి',
      'profileSaved': 'ప్రొఫైల్ సేవ్ అయ్యింది.',
      'language': 'భాష',
      'privacy': 'గోప్యత & డేటా',
      'languageChanged': 'భాష మార్చబడింది',
    },
    'Marathi': {
      'profileTitle': 'पालक प्रोफाइल',
      'settings': 'सेटिंग्ज',
      'parentDetails': 'पालक तपशील',
      'contactNo': 'संपर्क क्रमांक',
      'feedback': 'अभिप्राय',
      'saveDetails': 'तपशील जतन करा',
      'profileSaved': 'प्रोफाइल जतन झाले.',
      'language': 'भाषा',
      'privacy': 'गोपनीयता आणि डेटा',
      'languageChanged': 'भाषा बदलली',
    },
    'Gujarati': {
      'profileTitle': 'વાલી પ્રોફાઇલ',
      'settings': 'સેટિંગ્સ',
      'parentDetails': 'વાલીની વિગતો',
      'contactNo': 'સંપર્ક નંબર',
      'feedback': 'પ્રતિસાદ',
      'saveDetails': 'વિગતો સાચવો',
      'profileSaved': 'પ્રોફાઇલ સાચવાઈ.',
      'language': 'ભાષા',
      'privacy': 'ગોપનીયતા અને ડેટા',
      'languageChanged': 'ભાષા બદલાઈ',
    },
    'Kannada': {
      'profileTitle': 'ಪೋಷಕರ ಪ್ರೊಫೈಲ್',
      'settings': 'ಸೆಟ್ಟಿಂಗ್ಸ್',
      'parentDetails': 'ಪೋಷಕರ ವಿವರಗಳು',
      'contactNo': 'ಸಂಪರ್ಕ ಸಂಖ್ಯೆ',
      'feedback': 'ಪ್ರತಿಕ್ರಿಯೆ',
      'saveDetails': 'ವಿವರಗಳನ್ನು ಉಳಿಸಿ',
      'profileSaved': 'ಪ್ರೊಫೈಲ್ ಉಳಿಸಲಾಗಿದೆ.',
      'language': 'ಭಾಷೆ',
      'privacy': 'ಗೌಪ್ಯತೆ ಮತ್ತು ಡೇಟಾ',
      'languageChanged': 'ಭಾಷೆ ಬದಲಿಸಲಾಗಿದೆ',
    },
    'Malayalam': {
      'profileTitle': 'രക്ഷിതൃ പ്രൊഫൈൽ',
      'settings': 'ക്രമീകരണങ്ങൾ',
      'parentDetails': 'രക്ഷിതൃ വിവരങ്ങൾ',
      'contactNo': 'ബന്ധപ്പെടാനുള്ള നമ്പർ',
      'feedback': 'അഭിപ്രായം',
      'saveDetails': 'വിവരങ്ങൾ സംരക്ഷിക്കുക',
      'profileSaved': 'പ്രൊഫൈൽ സംരക്ഷിച്ചു.',
      'language': 'ഭാഷ',
      'privacy': 'സ്വകാര്യതയും ഡാറ്റയും',
      'languageChanged': 'ഭാഷ മാറ്റി',
    },
    'Punjabi': {
      'profileTitle': 'ਮਾਤਾ-ਪਿਤਾ ਪ੍ਰੋਫਾਈਲ',
      'settings': 'ਸੈਟਿੰਗਾਂ',
      'parentDetails': 'ਮਾਤਾ-ਪਿਤਾ ਵੇਰਵੇ',
      'contactNo': 'ਸੰਪਰਕ ਨੰਬਰ',
      'feedback': 'ਫੀਡਬੈਕ',
      'saveDetails': 'ਵੇਰਵੇ ਸੰਭਾਲੋ',
      'profileSaved': 'ਪ੍ਰੋਫਾਈਲ ਸੰਭਾਲੀ ਗਈ.',
      'language': 'ਭਾਸ਼ਾ',
      'privacy': 'ਪਰਦੇਦਾਰੀ ਅਤੇ ਡਾਟਾ',
      'languageChanged': 'ਭਾਸ਼ਾ ਬਦਲੀ ਗਈ',
    },
    'Urdu': {
      'profileTitle': 'والدین پروفائل',
      'settings': 'ترتیبات',
      'parentDetails': 'والدین کی تفصیلات',
      'contactNo': 'رابطہ نمبر',
      'feedback': 'رائے',
      'saveDetails': 'تفصیلات محفوظ کریں',
      'profileSaved': 'پروفائل محفوظ ہو گیا.',
      'language': 'زبان',
      'privacy': 'رازداری اور ڈیٹا',
      'languageChanged': 'زبان تبدیل ہو گئی',
    },
    'Odia': {
      'profileTitle': 'ଅଭିଭାବକ ପ୍ରୋଫାଇଲ୍',
      'settings': 'ସେଟିଂସ୍',
      'parentDetails': 'ଅଭିଭାବକ ବିବରଣୀ',
      'contactNo': 'ଯୋଗାଯୋଗ ନମ୍ବର',
      'feedback': 'ମତାମତ',
      'saveDetails': 'ବିବରଣୀ ସେଭ୍ କରନ୍ତୁ',
      'profileSaved': 'ପ୍ରୋଫାଇଲ୍ ସେଭ୍ ହେଲା.',
      'language': 'ଭାଷା',
      'privacy': 'ଗୋପନୀୟତା ଓ ଡାଟା',
      'languageChanged': 'ଭାଷା ପରିବର୍ତ୍ତନ ହେଲା',
    },
    'Assamese': {
      'profileTitle': 'অভিভাৱক প্ৰফাইল',
      'settings': 'ছেটিংছ',
      'parentDetails': 'অভিভাৱকৰ বিৱৰণ',
      'contactNo': 'যোগাযোগ নম্বৰ',
      'feedback': 'মতামত',
      'saveDetails': 'বিৱৰণ সংৰক্ষণ কৰক',
      'profileSaved': 'প্ৰফাইল সংৰক্ষণ হল.',
      'language': 'ভাষা',
      'privacy': 'গোপনীয়তা আৰু ডাটা',
      'languageChanged': 'ভাষা সলনি হল',
    },
    'Spanish': {
      'profileTitle': 'Perfil del padre',
      'settings': 'Ajustes',
      'parentDetails': 'Datos del padre',
      'contactNo': 'Numero de contacto',
      'feedback': 'Comentarios',
      'saveDetails': 'Guardar datos',
      'profileSaved': 'Perfil guardado.',
      'language': 'Idioma',
      'privacy': 'Privacidad y datos',
      'languageChanged': 'Idioma cambiado a',
    },
    'French': {
      'profileTitle': 'Profil parent',
      'settings': 'Parametres',
      'parentDetails': 'Details du parent',
      'contactNo': 'Numero de contact',
      'feedback': 'Retour',
      'saveDetails': 'Enregistrer',
      'profileSaved': 'Profil enregistre.',
      'language': 'Langue',
      'privacy': 'Confidentialite et donnees',
      'languageChanged': 'Langue changee en',
    },
    'Arabic': {
      'profileTitle': 'ملف ولي الأمر',
      'settings': 'الإعدادات',
      'parentDetails': 'تفاصيل ولي الأمر',
      'contactNo': 'رقم التواصل',
      'feedback': 'الملاحظات',
      'saveDetails': 'حفظ التفاصيل',
      'profileSaved': 'تم حفظ الملف.',
      'language': 'اللغة',
      'privacy': 'الخصوصية والبيانات',
      'languageChanged': 'تم تغيير اللغة إلى',
    },
  };
}
