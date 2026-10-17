import 'dart:convert';
import 'package:http/http.dart' as http;

/// Gemini API. Key ko `--dart-define=GEMINI_API_KEY=xxxx` se dein.
class AiService {
  static const _key = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-flash-latest'; // error aaye to model name yahan change karein

  static Future<String> _ask(String prompt, {bool asJson = false}) async {
    if (_key.isEmpty) {
      throw Exception(
          'GEMINI_API_KEY set nahi hai. App ko --dart-define=GEMINI_API_KEY=your_key ke saath run karein.');
    }
    final res = await http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent'),
      headers: {'Content-Type': 'application/json', 'x-goog-api-key': _key},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        if (asJson) 'generationConfig': {'responseMimeType': 'application/json'},
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('AI error (${res.statusCode}). API key ya model name check karein.');
    }
    final data = jsonDecode(res.body);
    return (data['candidates'][0]['content']['parts'][0]['text'] as String).trim();
  }

  /// WhatsApp message (ready / reminder / update)
  static Future<String> message({
    required String name,
    required String item,
    required double balance,
    required String purpose,
    required String language,
    required String tone,
  }) =>
      _ask('You write short WhatsApp messages for a tailor shop in Pakistan. '
          'Language: $language. Tone: $tone. Customer: $name. Item: $item. Purpose: $purpose. '
          'Pending balance: Rs ${balance.toStringAsFixed(0)} (mention only if above 0). '
          'Max 3 lines, at most one emoji, end with a thanks. Return only the message text.');

  /// Design ideas
  static Future<String> designIdeas({required String item, required String note}) =>
      _ask('You are a fashion advisor for Pakistani tailoring (shalwar kameez, kurta, waistcoat, '
          'sherwani, bridal, abaya etc). Item: $item. Customer notes: $note. '
          'Give 4 short, trendy design ideas (collar, sleeves, embroidery, trims, fabric pairing) '
          'as a numbered list in simple Roman Urdu mixed with English terms. Max 90 words total.');

  /// "Ahmed ka 2 suit Friday tak, total 8000 advance 3000" -> structured order
  static Future<Map<String, dynamic>> parseOrder(String text) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final out = await _ask(
        'Extract a tailor order from this text (Urdu / Roman Urdu / English). Today is $today. '
        'Return JSON with keys: customerName (string), item (string), note (string), '
        'total (number, 0 if unknown), advance (number, 0 if unknown), '
        'deliveryInDays (integer days from today, 7 if unknown). Text: """$text"""',
        asJson: true);
    return Map<String, dynamic>.from(jsonDecode(out));
  }

  /// "chest 40 waist 34 length 42" -> measurement fields
  static Future<Map<String, String>> parseMeasurements(String text, List<String> fields) async {
    final out = await _ask(
        'Extract tailor measurements (in inches) from this text (Urdu / Roman Urdu / English). '
        'Return JSON with exactly these keys: ${fields.join(', ')}. Use a string value, '
        'or an empty string if not mentioned. Text: """$text"""',
        asJson: true);
    final m = Map<String, dynamic>.from(jsonDecode(out));
    return {for (final f in fields) f: '${m[f] ?? ''}'};
  }

  /// Dashboard business insights
  static Future<String> insights(Map<String, dynamic> stats) =>
      _ask('You are a smart business advisor for a small tailor shop in Pakistan. '
          'Shop stats (JSON): ${jsonEncode(stats)}. Give exactly 3 short, practical, actionable tips '
          '(about deliveries, udhaar recovery, workload) in simple Roman Urdu. Max 70 words total.');
}
