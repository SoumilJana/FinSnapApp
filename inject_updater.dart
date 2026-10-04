import 'dart:io';

void main() {
  final file = File('lib/screens/home_screen.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains('import \\'../services/update_service.dart\\';')) {
    content = content.replaceFirst(
      'import \\'dart:io\\';', 
      'import \\'dart:io\\';\nimport \\'../services/update_service.dart\\';'
    );
  }
  
  content = content.replaceFirst(
    '  void initState() {\n    super.initState();\n    _repository.loadTransactions();\n  }',
    '  void initState() {\n    super.initState();\n    _repository.loadTransactions();\n    WidgetsBinding.instance.addPostFrameCallback((_) {\n      UpdateService.checkForUpdates(context);\n    });\n  }'
  );
  
  file.writeAsStringSync(content);
  print('Injected UpdateService!');
}
