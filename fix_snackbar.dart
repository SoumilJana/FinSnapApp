import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    '''
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }
''',
    '''
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('AI processing failed. Please edit manually!'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
'''
  ); // Wait, this replaceFirst is risky because that pattern might appear elsewhere or not match exactly.
}
