import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ParentProfile {
  const ParentProfile({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.feedback,
    required this.avatarPath,
    required this.avatarUrl,
    required this.language,
    required this.notificationEnabled,
    required this.reminderHour,
    required this.reminderMinute,
    required this.reminderDays,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String feedback;
  final String avatarPath;
  final String avatarUrl;
  final String language;
  final bool notificationEnabled;
  final int reminderHour;
  final int reminderMinute;
  final List<int> reminderDays;
}

class ProfileService {
  ProfileService(this._client);

  final SupabaseClient _client;

  Future<ParentProfile> getCurrentParentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const ParentProfile(
        fullName: 'Parent Profile',
        email: 'Not signed in',
        phoneNumber: '',
        feedback: '',
        avatarPath: '',
        avatarUrl: '',
        language: 'English',
        notificationEnabled: false,
        reminderHour: 9,
        reminderMinute: 0,
        reminderDays: [1, 2, 3, 4, 5, 6, 7],
      );
    }

    final profile = await _client
        .from('profiles')
        .select('full_name, email, phone_number, feedback, avatar_url, language, notification_enabled, reminder_hour, reminder_minute, reminder_days')
        .eq('id', user.id)
        .maybeSingle();

    final profileName = profile?['full_name'] as String?;
    final metadataName = user.userMetadata?['full_name'] as String?;

    final avatarPath = (profile?['avatar_url'] as String?) ?? '';
    final avatarSignedUrl = avatarPath.isEmpty
        ? ''
        : await _client.storage.from('parent-avatars').createSignedUrl(avatarPath, 3600);
    final rawLanguage = (profile?['language'] as String?) ?? 'English';

    return ParentProfile(
      fullName: profileName?.trim().isNotEmpty == true
          ? profileName!
          : (metadataName?.trim().isNotEmpty == true ? metadataName! : 'Parent Profile'),
      email: (profile?['email'] as String?) ?? user.email ?? 'No email',
      phoneNumber: (profile?['phone_number'] as String?) ?? '',
      feedback: (profile?['feedback'] as String?) ?? '',
      avatarPath: avatarPath,
      avatarUrl: avatarSignedUrl,
      language: rawLanguage == 'en' ? 'English' : rawLanguage,
      notificationEnabled: (profile?['notification_enabled'] as bool?) ?? false,
      reminderHour: (profile?['reminder_hour'] as int?) ?? 9,
      reminderMinute: (profile?['reminder_minute'] as int?) ?? 0,
      reminderDays: ((profile?['reminder_days'] as List<dynamic>?) ?? [1, 2, 3, 4, 5, 6, 7]).cast<int>(),
    );
  }

  Future<void> updateReminderSettings({
    required bool enabled,
    required int hour,
    required int minute,
    required List<int> days,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'notification_enabled': enabled,
      'reminder_hour': hour,
      'reminder_minute': minute,
      'reminder_days': days,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<void> updateParentDetails({
    required String phoneNumber,
    required String feedback,
    required String avatarUrl,
    required String language,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      'phone_number': phoneNumber.trim(),
      'feedback': feedback.trim(),
      'avatar_url': avatarUrl.trim(),
      'language': language.trim(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<String> uploadAvatar(File image) async {
    final user = _client.auth.currentUser;
    if (user == null) return '';

    final path = '${user.id}/parent-avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('parent-avatars').upload(
          path,
          image,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );
    return path;
  }

  Future<String> uploadAvatarBytes(Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) return '';

    final path = '${user.id}/parent-avatar-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage.from('parent-avatars').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true, contentType: 'image/jpeg'),
        );
    return path;
  }
}
