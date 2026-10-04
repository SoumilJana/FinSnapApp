import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  // Replace line 73
  final lines = content.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (lines[i].startsWith('- "amount": (double) The numerical amount.')) {
      lines[i] = '- "amount": (double) The numerical amount. (e.g. 150.0). CRITICAL: The AI often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0.';
    }
  }

  file.writeAsStringSync(lines.join('\n'));
  print('Fixed via lines replace!');
}
