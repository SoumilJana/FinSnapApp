import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Remove the pop from _processSharedImage
  final oldPop = '''
      // Automatically go back to the previous app after a short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        SystemNavigator.pop();
      });
''';
  if (content.contains(oldPop)) {
    content = content.replaceFirst(oldPop, '');
  }

  // Add the pop to the end of _processImageInBackground
  final oldEnd = '''
        print("Failed to reset pending state: \$e");
      }
    }
  }

  void _showError(String message) {
''';
  final newEnd = '''
        print("Failed to reset pending state: \$e");
      }
    }
    
    // Automatically go back to the previous app after the transaction is fully saved
    Future.delayed(const Duration(milliseconds: 1500), () {
      SystemNavigator.pop();
    });
  }

  void _showError(String message) {
''';

  if (content.contains(oldEnd)) {
    content = content.replaceFirst(oldEnd, newEnd);
    file.writeAsStringSync(content);
    print('Successfully moved SystemNavigator.pop!');
  } else {
    print('Could not find the end of _processImageInBackground!');
  }
}
