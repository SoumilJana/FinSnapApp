import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(r"\'\'\'", "'''");
  
  file.writeAsStringSync(content);
  print('Fixed the syntax error with triple quotes!');
}
