import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(RegExp(r"static const String _openRouterApiKey =[^;]+;"), "static const String _openRouterApiKey = 'REPLACE_WITH_YOUR_OPENROUTER_API_KEY';");
  content = content.replaceAll(RegExp(r"static const String _geminiApiKey =[^;]+;"), "static const String _geminiApiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';");
  content = content.replaceAll(RegExp(r"static const String _requestyApiKey =[^;]+;"), "static const String _requestyApiKey = 'REPLACE_WITH_YOUR_REQUESTY_API_KEY';");
  
  file.writeAsStringSync(content);
  print('Done cleaning!');
}
