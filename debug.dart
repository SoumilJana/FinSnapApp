import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  var content = file.readAsStringSync();
  
  content = content.replaceAll(
    'final result = await _generateJsonWithRequesty(prompt);',
    '''print("Calling Requesty...");
        final result = await _generateJsonWithRequesty(prompt);
        print("Requesty returned: \$result");'''
  );
  
  file.writeAsStringSync(content);
  print('Added debug statements!');
}
