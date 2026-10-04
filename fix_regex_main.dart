import 'dart:io';

void main() {
  final file = File('lib/main.dart');
  String content = file.readAsStringSync();
  
  // Replace the regex
  content = content.replaceAll(
    r"r'(?:(?:^|\s)(?:rs\.?|inr|f|r)|₹|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)'",
    r"r'(?:(?:^|\s)(?:rs\.?|inr|f|r|7)|₹|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)'"
  );
  
  // Also just in case the fallback captures a leading 7 on a huge amount, let's leave the fallback alone for now, because the first regex will catch it!

  file.writeAsStringSync(content);
  print('Fixed regex in main.dart!');
}
