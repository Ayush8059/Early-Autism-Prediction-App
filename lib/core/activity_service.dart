import 'package:supabase_flutter/supabase_flutter.dart';
import 'child_service.dart';

class ActivityRecord {
  const ActivityRecord({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.recommendedRiskLevel,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String? recommendedRiskLevel;
}

class ActivityService {
  ActivityService(this._client);

  final SupabaseClient _client;

  static const List<ActivityRecord> defaultActivities = [
    ActivityRecord(
      id: '',
      title: 'Color Sorting',
      description: 'Sort blocks by color and shape to build focus.',
      category: 'Focus',
      recommendedRiskLevel: 'Low',
    ),
    ActivityRecord(
      id: '',
      title: 'Follow the Sound',
      description: 'Listen, locate, and point toward sounds.',
      category: 'Attention',
      recommendedRiskLevel: 'Medium',
    ),
    ActivityRecord(
      id: '',
      title: 'Emotion Cards',
      description: 'Match faces with happy, sad, calm, or angry.',
      category: 'Social',
      recommendedRiskLevel: 'Medium',
    ),
    ActivityRecord(
      id: '',
      title: 'Texture Touch',
      description: 'Explore soft, rough, smooth, and fuzzy textures.',
      category: 'Sensory',
      recommendedRiskLevel: 'High',
    ),
  ];

  Future<List<ActivityRecord>> fetchActivities() async {
    final rows = await _client
        .from('activities')
        .select('id, title, description, category, recommended_risk_level')
        .order('title');
    return [
      for (final row in rows)
        ActivityRecord(
          id: row['id'] as String,
          title: row['title'] as String,
          description: row['description'] as String,
          category: row['category'] as String,
          recommendedRiskLevel: row['recommended_risk_level'] as String?,
        ),
    ];
  }

  Future<ActivityRecord?> fetchRecommendedActivity() async {
    final activities = await fetchActivities();
    final merged = _withDefaultActivities(activities);
    if (merged.isEmpty) return null;

    final riskLevel = await _latestRiskLevel();
    final matching = riskLevel == null
        ? merged
        : merged
              .where((item) => item.recommendedRiskLevel == riskLevel)
              .toList();
    final pool = matching.isEmpty ? merged : matching;
    final rotation = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return pool[rotation % pool.length];
  }

  Future<void> completeActivity(String activityId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final childId = await ChildService(_client).getOrCreateDefaultChildId();
    await _client.from('activity_completions').insert({
      'parent_id': user.id,
      'child_id': childId,
      'activity_id': activityId,
    });
  }

  Future<void> completeActivityByTitle({
    required String title,
    required String description,
    required String category,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final existing = await _client
        .from('activities')
        .select('id')
        .eq('title', title)
        .maybeSingle();

    final activityId =
        existing?['id'] as String? ??
        (await _client
                .from('activities')
                .insert({
                  'title': title,
                  'description': description,
                  'category': category,
                  'recommended_risk_level': 'Low',
                })
                .select('id')
                .single())['id']
            as String;

    await completeActivity(activityId);
  }

  List<ActivityRecord> _withDefaultActivities(List<ActivityRecord> records) {
    final byTitle = {for (final record in records) record.title: record};
    for (final fallback in defaultActivities) {
      byTitle.putIfAbsent(fallback.title, () => fallback);
    }
    return byTitle.values.toList();
  }

  Future<String?> _latestRiskLevel() async {
    try {
      final questionnaireRows = await _client
          .from('questionnaire_assessments')
          .select('risk_level, created_at')
          .order('created_at', ascending: false)
          .limit(1);
      final photoRows = await _client
          .from('photo_assessments')
          .select('risk_level, created_at')
          .order('created_at', ascending: false)
          .limit(1);

      final rows =
          [
            ...questionnaireRows,
            ...photoRows,
          ].where((row) => row['risk_level'] != null).toList()..sort(
            (a, b) => DateTime.parse(
              b['created_at'] as String,
            ).compareTo(DateTime.parse(a['created_at'] as String)),
          );

      return rows.isEmpty ? null : rows.first['risk_level'] as String?;
    } catch (_) {
      return null;
    }
  }
}
