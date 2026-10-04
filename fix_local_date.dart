import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  // Undo the bad replacement
  content = content.replaceFirst(
'''      String date = DateTime.now().toString().substring(0, 16).replaceAll(' ', 'T');
      
      // Better Date Extraction
      final dateRegex = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\\s+(\\d{1,2})[^\\d]*(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm)?)', caseSensitive: false);
      for (final line in lines) {
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          final monthStr = match.group(1)!;
          final dayStr = match.group(2)!;
          final timeStr = match.group(3)!;
          
          final months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
          int monthIdx = months.indexWhere((m) => monthStr.toLowerCase().startsWith(m)) + 1;
          
          if (monthIdx > 0) {
             final year = DateTime.now().year;
             
             int hours = 12;
             int minutes = 0;
             final timeMatch = RegExp(r'(\\d{1,2}):(\\d{2})\\s*(AM|PM|am|pm)?', caseSensitive: false).firstMatch(timeStr);
             if (timeMatch != null) {
               hours = int.parse(timeMatch.group(1)!);
               minutes = int.parse(timeMatch.group(2)!);
               final ampm = (timeMatch.group(3) ?? '').toUpperCase();
               if (ampm == 'PM' && hours < 12) hours += 12;
               if (ampm == 'AM' && hours == 12) hours = 0;
             }
             
             final dt = DateTime(year, monthIdx, int.parse(dayStr), hours, minutes);
             date = dt.toString().substring(0, 16).replaceAll(' ', 'T');
             break;
          }
        }
      }''', 
      "String date = DateTime.now().toString().substring(0, 16).replaceAll(' ', 'T');"
  );
  
  // Now place it AFTER lines is declared
  final replaceLines = "final lines = text.split('\\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();";
  final newLines = '''
      final lines = text.split('\\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      // Better Date Extraction
      final dateRegex = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\\s+(\\d{1,2})[^\\d]*(\\d{1,2}:\\d{2}\\s*(?:AM|PM|am|pm)?)', caseSensitive: false);
      for (final line in lines) {
        final match = dateRegex.firstMatch(line);
        if (match != null) {
          final monthStr = match.group(1)!;
          final dayStr = match.group(2)!;
          final timeStr = match.group(3)!;
          
          final months = ['jan','feb','mar','apr','may','jun','jul','aug','sep','oct','nov','dec'];
          int monthIdx = months.indexWhere((m) => monthStr.toLowerCase().startsWith(m)) + 1;
          
          if (monthIdx > 0) {
             final year = DateTime.now().year;
             
             int hours = 12;
             int minutes = 0;
             final timeMatch = RegExp(r'(\\d{1,2}):(\\d{2})\\s*(AM|PM|am|pm)?', caseSensitive: false).firstMatch(timeStr);
             if (timeMatch != null) {
               hours = int.parse(timeMatch.group(1)!);
               minutes = int.parse(timeMatch.group(2)!);
               final ampm = (timeMatch.group(3) ?? '').toUpperCase();
               if (ampm == 'PM' && hours < 12) hours += 12;
               if (ampm == 'AM' && hours == 12) hours = 0;
             }
             
             final dt = DateTime(year, monthIdx, int.parse(dayStr), hours, minutes);
             date = dt.toString().substring(0, 16).replaceAll(' ', 'T');
             break;
          }
        }
      }
''';

  content = content.replaceFirst(replaceLines, newLines);

  file.writeAsStringSync(content);
  print('Fixed variable ordering!');
}
