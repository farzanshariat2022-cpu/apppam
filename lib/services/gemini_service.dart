import 'dart:convert';
import 'package:http/http.dart' as http;

/// سرویس اتصال مستقیم اپلیکیشن به Gemini API.
///
/// این نسخه برای معماری فعلی پروژه «معمار» طراحی شده:
/// Flutter → Gemini API
///
/// API Key از تنظیمات کاربر دریافت می‌شود و در URL قرار نمی‌گیرد.
/// احراز هویت با هدر x-goog-api-key انجام می‌شود.
class GeminiService {
  static const String _model = 'gemini-3.6-flash';

  Future<String?> generateText({
    required String apiKey,
    required String prompt,
  }) async {
    final cleanApiKey = apiKey.trim();

    // ─────────────────────────────────────────────
    // 1. بررسی API Key
    // ─────────────────────────────────────────────

    if (cleanApiKey.isEmpty) {
      print('');
      print('━━━━━━━━ GEMINI DEBUG ━━━━━━━━');
      print('❌ ERROR: Gemini API Key is empty.');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return null;
    }

    // ─────────────────────────────────────────────
    // 2. ساخت URL
    // ─────────────────────────────────────────────

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/'
      '$_model:generateContent',
    );

    print('');
    print('━━━━━━━━ GEMINI REQUEST ━━━━━━━');
    print('Model: $_model');
    print('URL: $uri');
    print(
      'API Key: '
      '${cleanApiKey.substring(0, cleanApiKey.length > 6 ? 6 : cleanApiKey.length)}******',
    );
    print('Prompt length: ${prompt.length}');
    print('Sending request...');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // ───────────────────────────────────────────
      // 3. ارسال درخواست
      // ───────────────────────────────────────────

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'x-goog-api-key': cleanApiKey,
            },
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {
                      'text': prompt,
                    }
                  ]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 500,
              },
            }),
          )
          .timeout(
            const Duration(seconds: 30),
          );

      // ───────────────────────────────────────────
      // 4. لاگ پاسخ Gemini
      // ───────────────────────────────────────────

      final responseBody = utf8.decode(
        response.bodyBytes,
        allowMalformed: true,
      );

      print('');
      print('━━━━━━━━ GEMINI RESPONSE ━━━━━━━');
      print('HTTP Status: ${response.statusCode}');
      print('Response length: ${responseBody.length}');
      print('Response body: $responseBody');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // ───────────────────────────────────────────
      // 5. بررسی HTTP Status
      // ───────────────────────────────────────────

      if (response.statusCode != 200) {
        print('');
        print('❌ GEMINI REQUEST FAILED');
        print('HTTP Status: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return null;
      }

      // ───────────────────────────────────────────
      // 6. Parse کردن JSON
      // ───────────────────────────────────────────

      final dynamic decoded = jsonDecode(responseBody);

      if (decoded is! Map<String, dynamic>) {
        print('❌ Gemini response is not a JSON object.');
        return null;
      }

      final candidates = decoded['candidates'];

      if (candidates is! List || candidates.isEmpty) {
        print('❌ Gemini returned no candidates.');
        return null;
      }

      final firstCandidate = candidates.first;

      if (firstCandidate is! Map<String, dynamic>) {
        print('❌ Invalid Gemini candidate.');
        return null;
      }

      final content = firstCandidate['content'];

      if (content is! Map<String, dynamic>) {
        print('❌ Gemini response has no content.');
        return null;
      }

      final parts = content['parts'];

      if (parts is! List || parts.isEmpty) {
        print('❌ Gemini response has no parts.');
        return null;
      }

      // ───────────────────────────────────────────
      // 7. استخراج متن
      // ───────────────────────────────────────────

      final textParts = <String>[];

      for (final part in parts) {
        if (part is Map<String, dynamic>) {
          final text = part['text'];

          if (text is String && text.trim().isNotEmpty) {
            textParts.add(text);
          }
        }
      }

      final result = textParts.join().trim();

      if (result.isEmpty) {
        print('❌ Gemini returned empty text.');
        return null;
      }

      // ───────────────────────────────────────────
      // 8. موفقیت
      // ───────────────────────────────────────────

      print('');
      print('━━━━━━━━ GEMINI SUCCESS ━━━━━━━');
      print('✅ Gemini request succeeded.');
      print('Model: $_model');
      print('Generated text length: ${result.length}');
      print('Generated text: $result');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return result;
    } catch (e, stackTrace) {
      // ───────────────────────────────────────────
      // 9. خطای غیرمنتظره
      // ───────────────────────────────────────────

      print('');
      print('━━━━━━━━ GEMINI EXCEPTION ━━━━━');
      print('❌ Exception: $e');
      print('');
      print('Stack trace:');
      print(stackTrace);
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return null;
    }
  }
}
