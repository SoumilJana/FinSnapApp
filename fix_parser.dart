import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  // Make parseTransaction use Requesty instead of OpenRouter!
  content = content.replaceAll(
    'return _generateJsonWithOpenRouter(prompt, null, null);',
    'return _generateJsonWithRequesty(prompt);'
  );
  
  // Add _generateJsonWithRequesty function
  if (!content.contains('_generateJsonWithRequesty')) {
    final RequestyFunc = '''
  static Future<Map<String, dynamic>?> _generateJsonWithRequesty(String prompt) async {
    final url = Uri.parse('https://router.requesty.ai/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer \$_requestyApiKey'
        },
        body: jsonEncode({
          "model": "gemma-4-31b-it",
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ]
        }),
      );
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = jsonResponse['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\\{[\\s\\S]*\\}').firstMatch(text);
        if (jsonMatch == null) throw Exception('No JSON found in response');
        final Map<String, dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        return parsed;
      } else {
        print("Requesty Error HTTP \${response.statusCode}: \${response.body}");
        return null;
      }
    } catch (e) {
      print("Requesty Exception: \$e");
    }
    return null;
  }
''';
    content = content.replaceFirst('static Future<Map<String, dynamic>?> _generateJsonWithOpenRouter', RequestyFunc + '\n  static Future<Map<String, dynamic>?> _generateJsonWithOpenRouter');
  }

  file.writeAsStringSync(content);
  print('Fixed transaction parser to use Requesty text!');
}
