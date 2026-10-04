import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  // We need to update the prompt in parseTransaction
  final oldPrompt = '''
  - "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military 
time, no am/pm, no commas, just the exact format). If no date is found, use the current date or null.
''';
  final oldPrompt2 = '- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military \ntime, no am/pm, no commas, just the exact format). If no date is found, use the current date or null.';

  final newPrompt = '''
  - "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas, just the exact format). Search carefully for ANY date in the OCR text (e.g., "14 Oct 2026", "14/10", "4 Oct", "8:30 PM"). If the year is missing, assume the current year. If the time is missing, assume 12:00. DO NOT fallback to the current date unless absolutely no date string is found.
''';

  content = content.replaceAll(oldPrompt, newPrompt);
  content = content.replaceAll(oldPrompt2, newPrompt);
  
  // Also we need to make sure the amount fix (strip 7) is in parseTransaction!
  // I only added it to parseTransactionFromImage before!
  final oldAmount = '- "amount": (double) The numerical amount paid. (e.g. 150.0)';
  final newAmount = '''
  - "amount": (double) The numerical amount paid. (e.g. 150.0). CRITICAL: The OCR often misreads the Indian Rupee symbol (₹) as the number 7. If you see a leading 7 that acts as a currency symbol (e.g., 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0!
''';
  content = content.replaceAll(oldAmount, newAmount);
  
  file.writeAsStringSync(content);
  print('Updated prompt!');
}
