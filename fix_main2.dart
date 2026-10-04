import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceAll(
    '_processImageInBackground(imagePath, newId);',
    '_processImageInBackground(newId, text);'
  );
  
  content = content.replaceAll(
    'Future<void> _processImageInBackground(String imagePath, String txId) async {',
    'Future<void> _processImageInBackground(String txId, String ocrText) async {'
  );
  
  content = content.replaceAll(
    '''      final parsedData = await TransactionParser.parseTransactionFromImage(
        File(imagePath),
      );''',
    '''      final parsedData = await TransactionParser.parseTransaction(ocrText);'''
  );
  
  file.writeAsStringSync(content);
  print('Updated main.dart to use fast text AI parsing!');
}
