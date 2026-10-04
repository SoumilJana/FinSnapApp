import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '''
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
''',
    '''
        body: jsonEncode({
          "model": "gemma-4-31b-it",
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ]
        }),
      ).timeout(const Duration(seconds: 25));
'''
  );
  
  file.writeAsStringSync(content);
  print('Added timeout to Requesty HTTP POST!');
}
