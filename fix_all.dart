import 'dart:io';

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>();
  for (var file in files) {
    if (file.path.endsWith('.dart')) {
      String content = file.readAsStringSync();
      if (content.contains('â‚¹')) {
        content = content.replaceAll('â‚¹', '₹');
        file.writeAsStringSync(content);
        print('Fixed ${file.path}');
      }
    }
  }
}
