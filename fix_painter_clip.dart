import 'dart:io';

void main() {
  final file = File('lib/screens/border_progress_painter.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    'final rect = Rect.fromLTWH(0, 0, size.width, size.height);',
    'final rect = Rect.fromLTWH(strokeWidth/2, strokeWidth/2, size.width - strokeWidth, size.height - strokeWidth);'
  );
  
  file.writeAsStringSync(content);
  print('Fixed border progress painter rect clipping!');
}
