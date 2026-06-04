import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class AnalysisResult {
  final String label; // Autistic or Non_Autistic
  final double confidenceScore; // 0.0 to 100.0
  final double autisticPercent;
  final double nonAutisticPercent;
  final String riskLevel; // Low, Medium, High
  final String message;

  AnalysisResult({
    required this.label,
    required this.confidenceScore,
    required this.autisticPercent,
    required this.nonAutisticPercent,
    required this.riskLevel,
    required this.message,
  });
}

class MLService {
  static const String _apiUrl = String.fromEnvironment('ML_API_URL');

  /// TODO: Integrate your actual ML model here.
  /// If using an API: Make an http.post request with the image file.
  /// If using TensorFlow Lite: Run the interpreter on the image bytes.
  static Future<AnalysisResult> analyzeImage(File image) async {
    return analyzeImageBytes(await image.readAsBytes());
  }

  static Future<AnalysisResult> analyzeImageBytes(Uint8List imageBytes) async {
    if (SupabaseConfig.isConfigured &&
        Supabase.instance.client.auth.currentUser != null) {
      try {
        return await _analyzeWithSupabaseFunction(imageBytes);
      } catch (error) {
        return AnalysisResult(
          label: 'Unknown',
          confidenceScore: 0,
          autisticPercent: 0,
          nonAutisticPercent: 0,
          riskLevel: 'Medium',
          message: _friendlyApiError(error),
        );
      }
    }

    if (_apiUrl.trim().isNotEmpty) {
      try {
        return await _analyzeWithApi(imageBytes);
      } catch (error) {
        return AnalysisResult(
          label: 'Unknown',
          confidenceScore: 0,
          autisticPercent: 0,
          nonAutisticPercent: 0,
          riskLevel: 'Medium',
          message: _friendlyApiError(error),
        );
      }
    }

    // Simulate processing time
    await Future.delayed(const Duration(seconds: 4));

    // MOCK RESULT: Replace this with actual model inference logic
    return AnalysisResult(
      label: 'Non_Autistic',
      confidenceScore: 82.5,
      autisticPercent: 17.5,
      nonAutisticPercent: 82.5,
      riskLevel: 'Low',
      message:
          'Visual cue screening shows stronger non-autistic pattern confidence. Continue monitoring with the questionnaire.',
    );
  }

  static Future<AnalysisResult> _analyzeWithSupabaseFunction(
    Uint8List imageBytes,
  ) async {
    final response = await Supabase.instance.client.functions.invoke(
      'photo-analysis',
      body: {'imageBase64': base64Encode(imageBytes)},
    );

    final data = _responseMap(response.data);
    if (data['error'] != null) {
      throw StateError(data['error'].toString());
    }

    return _analysisResultFromMap(data);
  }

  static Future<AnalysisResult> _analyzeWithApi(Uint8List imageBytes) async {
    final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'photo.jpg',
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 60),
    );
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(_errorMessageFromResponse(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _analysisResultFromMap(data);
  }

  static Map<String, dynamic> _responseMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    if (value is String) {
      return jsonDecode(value) as Map<String, dynamic>;
    }
    throw StateError('Invalid ML response.');
  }

  static AnalysisResult _analysisResultFromMap(Map<String, dynamic> data) {
    return AnalysisResult(
      label: data['label'] as String? ?? 'Unknown',
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble() ?? 0,
      autisticPercent: (data['autisticPercent'] as num?)?.toDouble() ?? 0,
      nonAutisticPercent: (data['nonAutisticPercent'] as num?)?.toDouble() ?? 0,
      riskLevel: data['riskLevel'] as String? ?? 'Medium',
      message:
          data['message'] as String? ??
          'Screening complete. Please consult a qualified doctor for medical guidance.',
    );
  }

  static String _errorMessageFromResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return 'ML backend error (${response.statusCode}): $detail';
      }
    } catch (_) {
      // Fall through to generic message below.
    }
    return 'ML backend error (${response.statusCode}). Please check the backend terminal.';
  }

  static String _friendlyApiError(Object error) {
    final text = error.toString();
    if (text.contains('Invalid ML API key') || text.contains('401')) {
      return 'The secure ML server rejected the request. Please check the Supabase ML_API_KEY secret.';
    }
    if (text.contains('Upload a JPG or PNG') || text.contains('400')) {
      return 'The backend rejected the uploaded photo. Please choose a JPG or PNG image and try again.';
    }
    if (text.contains('Model file not found')) {
      return 'The model file was not found. Put best_efficientnetb0.h5 inside the ml_backend folder.';
    }
    if (text.contains('Prediction failed') || text.contains('500')) {
      return text.replaceFirst('Bad state: ', '');
    }
    return 'The secure ML backend could not be reached. Please check the Supabase photo-analysis function and Hugging Face Space.';
  }

  /// Calculates risk based on Q1-Q12 assessment score.
  /// 0-3 = Low Risk, 4-7 = Medium Risk, 8-12 = High Risk
  static String getQuestionnaireRiskMessage(int score) {
    if (score <= 3) {
      return 'Low Risk ($score/12).\nYour child is hitting typical behavioral milestones. Keep engaging with them!';
    } else if (score <= 7) {
      return 'Medium Risk ($score/12).\nWe detected some behavioral flags. Consider discussing these results with a pediatrician.';
    } else {
      return 'High Risk ($score/12).\nWe recommend consulting a healthcare professional for a formal developmental evaluation.';
    }
  }
}
