import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('â‚¹', '₹');
  file.writeAsStringSync(content);
  print('Fixed encoding in main.dart!');
}
