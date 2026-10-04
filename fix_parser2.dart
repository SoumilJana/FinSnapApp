import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains('Future<Map<String, dynamic>?> _generateJsonWithRequesty')) {
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
    
    // Find the last closing brace
    int lastBraceIndex = content.lastIndexOf('}');
    content = content.substring(0, lastBraceIndex) + RequestyFunc + '\n}\n';
    file.writeAsStringSync(content);
    print('Added _generateJsonWithRequesty!');
  } else {
    print('Already contains it?');
  }
}
