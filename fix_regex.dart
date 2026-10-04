import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  // Extract JSON robustly
  content = content.replaceAll(
    "text = text.replaceAll('```json', '').replaceAll('```', '').trim();\n        final Map<String, dynamic> parsed = jsonDecode(text);",
    "final jsonMatch = RegExp(r'\\{[\\s\\S]*\\}').firstMatch(text);\n        if (jsonMatch == null) throw Exception('No JSON found in response');\n        final Map<String, dynamic> parsed = jsonDecode(jsonMatch.group(0)!);"
  );

  file.writeAsStringSync(content);
  print('Fixed via regex!');
}
