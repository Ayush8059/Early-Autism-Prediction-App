import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'child_service.dart';
import 'ml_service.dart';

class AssessmentSummary {
  const AssessmentSummary({
    required this.id,
    required this.type,
    required this.title,
    required this.riskLevel,
    required this.scoreText,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String riskLevel;
  final String scoreText;
  final DateTime createdAt;
}

class AssessmentDetail {
  const AssessmentDetail({
    required this.summary,
    required this.message,
    required this.autisticPercent,
    required this.nonAutisticPercent,
    required this.answers,
  });

  final AssessmentSummary summary;
  final String message;
  final double? autisticPercent;
  final double? nonAutisticPercent;
  final List<dynamic> answers;
}

class AssessmentService {
  AssessmentService(this._client);

  final SupabaseClient _client;

  Future<void> saveQuestionnaireAssessment({
    required int score,
    required String riskLevel,
    required List<Map<String, dynamic>> answers,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final childId = await ChildService(_client).getOrCreateDefaultChildId();

    await _client.from('questionnaire_assessments').insert({
      'parent_id': user.id,
      'child_id': childId,
      'score': score,
      'risk_level': riskLevel,
      'answers': answers,
    });
  }

  Future<void> savePhotoAssessment({
    required AnalysisResult result,
    String imagePath = '',
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final childId = await ChildService(_client).getOrCreateDefaultChildId();

    await _client.from('photo_assessments').insert({
      'parent_id': user.id,
      'child_id': childId,
      'image_path': imagePath.isEmpty
          ? '${user.id}/local-${DateTime.now().millisecondsSinceEpoch}.jpg'
          : imagePath,
      'status': 'completed',
      'confidence_score': result.confidenceScore,
      'autistic_percent': result.autisticPercent,
      'non_autistic_percent': result.nonAutisticPercent,
      'risk_level': result.riskLevel,
      'message': result.message,
      'completed_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<String> uploadChildPhotoBytes(Uint8List bytes) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please sign in first.');
    }

    final path =
        '${user.id}/photo-${DateTime.now().millisecondsSinceEpoch}.jpg';
    await _client.storage
        .from('child-photos')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );
    return path;
  }

  Future<List<AssessmentSummary>> fetchRecentAssessments({
    int limit = 20,
  }) async {
    final questionnaireRows = await _client
        .from('questionnaire_assessments')
        .select('id, score, risk_level, created_at')
        .order('created_at', ascending: false)
        .limit(limit);

    final photoRows = await _client
        .from('photo_assessments')
        .select(
          'id, confidence_score, autistic_percent, non_autistic_percent, risk_level, created_at',
        )
        .order('created_at', ascending: false)
        .limit(limit);

    final summaries = <AssessmentSummary>[
      for (final row in questionnaireRows)
        AssessmentSummary(
          id: row['id'] as String,
          type: 'questionnaire',
          title: 'Questionnaire',
          riskLevel: row['risk_level'] as String,
          scoreText: '${row['score']}/12',
          createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
        ),
      for (final row in photoRows) _photoSummary(row),
    ];

    summaries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return summaries.take(limit).toList();
  }

  AssessmentSummary _photoSummary(Map<String, dynamic> row) {
    final autistic = (row['autistic_percent'] as num?)?.toDouble();
    final nonAutistic = (row['non_autistic_percent'] as num?)?.toDouble();
    final label = autistic != null && nonAutistic != null
        ? (autistic >= nonAutistic ? 'Autistic' : 'Non-autistic')
        : 'Photo';
    final confidence = autistic != null && nonAutistic != null
        ? (autistic >= nonAutistic ? autistic : nonAutistic)
        : (row['confidence_score'] as num?)?.toDouble();

    return AssessmentSummary(
      id: row['id'] as String,
      type: 'photo',
      title: 'Photo Analysis - $label',
      riskLevel: (row['risk_level'] as String?) ?? 'Pending',
      scoreText: confidence == null
          ? 'Processing'
          : 'Confidence ${confidence.toStringAsFixed(1)}%',
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  Future<void> deleteAssessment(AssessmentSummary assessment) async {
    final table = assessment.type == 'photo'
        ? 'photo_assessments'
        : 'questionnaire_assessments';
    if (assessment.type == 'photo') {
      final row = await _client
          .from('photo_assessments')
          .select('image_path')
          .eq('id', assessment.id)
          .maybeSingle();
      final imagePath = row?['image_path'] as String?;
      if (imagePath != null && !imagePath.contains('/local-')) {
        await _client.storage.from('child-photos').remove([imagePath]);
      }
    }
    await _client.from(table).delete().eq('id', assessment.id);
  }

  Future<AssessmentDetail> fetchAssessmentDetail(
    AssessmentSummary summary,
  ) async {
    if (summary.type == 'photo') {
      final row = await _client
          .from('photo_assessments')
          .select('message, autistic_percent, non_autistic_percent')
          .eq('id', summary.id)
          .single();

      return AssessmentDetail(
        summary: summary,
        message: (row['message'] as String?) ?? '',
        autisticPercent: (row['autistic_percent'] as num?)?.toDouble(),
        nonAutisticPercent: (row['non_autistic_percent'] as num?)?.toDouble(),
        answers: const [],
      );
    }

    final row = await _client
        .from('questionnaire_assessments')
        .select('answers')
        .eq('id', summary.id)
        .single();

    return AssessmentDetail(
      summary: summary,
      message: 'Questionnaire score ${summary.scoreText}.',
      autisticPercent: null,
      nonAutisticPercent: null,
      answers: (row['answers'] as List<dynamic>?) ?? const [],
    );
  }

  String riskLevelForScore(int score) {
    if (score >= 8) return 'High';
    if (score >= 4) return 'Medium';
    return 'Low';
  }
}
