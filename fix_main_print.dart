import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains('print("OCR TEXT: "')) {
    content = content.replaceFirst(
      'String text = recognizedText.text;',
      'String text = recognizedText.text;\n      print("OCR TEXT: \\n" + text + "\\n===END OCR===");'
    );
    file.writeAsStringSync(content);
    print('Added print statement to main.dart!');
  }
}
