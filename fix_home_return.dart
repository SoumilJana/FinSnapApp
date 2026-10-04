import 'dart:io';

void main() {
  final file = File('lib/screens/home_screen.dart');
  String content = file.readAsStringSync();
  
  // Find the exact place to replace
  int indexOfBuildTransactionTile = content.indexOf('Widget _buildTransactionTile(');
  int lastClosingBrace = content.lastIndexOf('}', content.length - 1);
  int secondLastClosingBrace = content.lastIndexOf('}', lastClosingBrace - 1);
  
  final newEndCode = '''
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
  }
''';

  content = content.substring(0, secondLastClosingBrace) + newEndCode;
  file.writeAsStringSync(content);
  print('Fixed the return statement via substring!');
}
