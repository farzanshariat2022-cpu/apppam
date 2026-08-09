import 'dart:convert';
import 'package:http/http.dart' as http;

/// فراخوانی مستقیم Gemini 2.5 Flash از کلاینت.
/// بدون Cloud Functions — مناسب معماری فعلی پروژه.
class GeminiService {
  static const _model = 'gemini-2.5-flash';

  Future<String?> generateText({
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.trim().isEmpty) return null;

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent?key=$apiKey',
    );

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.8,
            'maxOutputTokens': 500,
          },
        }),
      );

      if (response.statusCode != 200) {
        print(
          'Gemini API Error ${response.statusCode}: '
          '${response.body}',
        );
        return null;
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      final candidates = data['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        print('Gemini API: No candidates returned.');
        return null;
      }

      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        print('Gemini API: No text parts returned.');
        return null;
      }

      return (parts[0]['text'] as String?)?.trim();
    } catch (e) {
      print('Gemini API Exception: $e');
      return null;
    }
  }
}
