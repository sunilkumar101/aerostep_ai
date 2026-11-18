import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Stride AI powered by the Gemini API (Google AI Studio).
///
/// The key is injected at build time and never committed:
///   flutter build appbundle --dart-define-from-file=secrets.json
/// with secrets.json = {"GEMINI_API_KEY": "...", "GEMINI_MODEL": "gemini-3.5-flash-lite"}.
///
/// On Android the request carries `X-Android-Package` / `X-Android-Cert`, so the
/// key can be restricted in Google Cloud to this package + signing certificate.
/// Without a key (or on any error) callers fall back to the offline coach.
class GeminiCoach {
  GeminiCoach._();
  static final instance = GeminiCoach._();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-3.5-flash-lite');
  static const _channel = MethodChannel('aerostep/app');

  bool get enabled => _apiKey.isNotEmpty;

  String? _certSha1;
  bool _certLoaded = false;

  static const _systemPrompt = '''
You are Stride AI, the friendly walking and weight-loss coach inside the AeroStep pedometer app.
Rules:
- Reply in the same language and script the user writes in (e.g. English, Urdu, Roman Urdu, Hindi).
- Keep answers short: at most 4 sentences or 4 bullet points, practical and encouraging.
- Use the user's live stats below when relevant; never invent numbers that are not given.
  For walking time, use the "Brisk walking time needed" figure (people walk about 100-120 steps per minute).
- AeroStep counts steps with the phone's step sensor even when the app is closed; never tell users to keep the app open.
- Topics: walking, steps, cadence, pace, hydration, calories, sleep/recovery, healthy habits and general nutrition.
- You are not a doctor. For pain, injury, pregnancy, chronic illness, eating disorders or medication questions,
  give general safety advice and recommend seeing a qualified professional.
- If asked about something unrelated to health and fitness, answer briefly and steer back to walking.
''';

  /// Returns Gemini's reply, or throws on network / API errors.
  ///
  /// [history] is the conversation so far as (text, fromUser) pairs, oldest
  /// first, ending with the new user question. [stats] is a short plain-text
  /// summary of today's activity used as grounding.
  Future<String> reply(List<(String, bool)> history, String stats) async {
    if (!enabled) throw StateError('No GEMINI_API_KEY configured');
    try {
      return await _generate(_model, history, stats);
    } on HttpException catch (e) {
      // A retired (404) or overloaded (503) model: retry once on the
      // auto-updating lite alias so the coach keeps working without an update.
      if (_model == _fallbackModel || !(e.message.contains('404') || e.message.contains('503'))) rethrow;
      return _generate(_fallbackModel, history, stats);
    }
  }

  static const _fallbackModel = 'gemini-flash-lite-latest';

  Future<String> _generate(String model, List<(String, bool)> history, String stats) async {
    final recent = history.length > 12 ? history.sublist(history.length - 12) : history;
    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': '$_systemPrompt\nUser stats right now:\n$stats'},
        ],
      },
      'contents': [
        for (final (text, fromUser) in recent)
          {
            'role': fromUser ? 'user' : 'model',
            'parts': [
              {'text': text},
            ],
          },
      ],
      'generationConfig': {'temperature': 0.6, 'maxOutputTokens': 512},
    });

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.https('generativelanguage.googleapis.com', '/v1beta/models/$model:generateContent');
      final req = await client.postUrl(uri);
      req.headers
        ..contentType = ContentType.json
        ..set('x-goog-api-key', _apiKey);
      if (Platform.isAndroid) {
        final cert = await _signingSha1();
        req.headers.set('X-Android-Package', 'com.sunilkhatri.aerostep');
        if (cert != null) req.headers.set('X-Android-Cert', cert);
      } else if (Platform.isIOS) {
        req.headers.set('X-Ios-Bundle-Identifier', 'com.sunilkhatri.aerostep');
      }
      req.add(utf8.encode(body));
      final res = await req.close().timeout(const Duration(seconds: 30));
      final text = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        debugPrint('Gemini HTTP ${res.statusCode}: $text');
        throw HttpException('Gemini HTTP ${res.statusCode}');
      }
      final json = jsonDecode(text) as Map<String, dynamic>;
      final candidates = json['candidates'] as List<dynamic>? ?? const [];
      if (candidates.isEmpty) throw const FormatException('Gemini returned no candidates');
      final parts = ((candidates.first as Map)['content'] as Map?)?['parts'] as List<dynamic>? ?? const [];
      final answer = parts.map((p) => (p as Map)['text'] ?? '').join().trim();
      if (answer.isEmpty) throw const FormatException('Gemini returned an empty answer');
      return answer;
    } finally {
      client.close(force: true);
    }
  }

  /// SHA-1 of the APK signing certificate, uppercase hex without colons.
  Future<String?> _signingSha1() async {
    if (_certLoaded) return _certSha1;
    _certLoaded = true;
    try {
      _certSha1 = await _channel.invokeMethod<String>('signingCertSha1');
    } catch (e) {
      debugPrint('signingCertSha1 unavailable: $e');
    }
    return _certSha1;
  }
}
