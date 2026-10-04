import 'dart:io';

void main() {
  final file = File('lib/screens/home_screen.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains("import 'border_progress_painter.dart';")) {
    content = content.replaceFirst(
      "import '../repositories/transaction_repository.dart';", 
      "import '../repositories/transaction_repository.dart';\nimport 'border_progress_painter.dart';"
    );
    file.writeAsStringSync(content);
    print('Fixed imports!');
  }
}
