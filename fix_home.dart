import 'dart:io';

void main() {
  final file = File('lib/screens/home_screen.dart');
  String content = file.readAsStringSync();
  
  if (!content.contains("import 'border_progress_painter.dart';")) {
    content = content.replaceFirst(
      "import '../transaction_repository.dart';", 
      "import '../transaction_repository.dart';\nimport 'border_progress_painter.dart';"
    );
  }

  final oldTileCode = '''
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? Colors.blue.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Row(
''';

  final newTileCode = '''
    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPending
            ? null // handled by custom painter
            : Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 8,
                ),
              ]
            : [],
      ),
      child: Row(
''';

  content = content.replaceFirst(oldTileCode, newTileCode);
  
  final oldEndCode = '''
              ],
            ),
          ],
        ),
      );
    }
''';

  final newEndCode = '''
              ],
            ),
          ],
        ),
      );

      if (isPending) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 25), // Estimated processing time
            builder: (context, value, child) {
              return CustomPaint(
                painter: BorderProgressPainter(progress: value, color: Colors.blue, strokeWidth: 3.0),
                child: child,
              );
            },
            child: content,
          ),
        );
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: content,
      );
    }
''';

  content = content.replaceFirst(oldEndCode, newEndCode);
  
  file.writeAsStringSync(content);
  print('Updated home_screen.dart!');
}
