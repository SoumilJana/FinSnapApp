import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  
  final fallbackCode = '''
  static Map<String, dynamic>? _extractLocallyFromOcr(String text) {
    try {
      double amount = 0.0;
      String merchant = "Unknown";
      String date = DateTime.now().toString().substring(0, 16).replaceAll(' ', 'T');
      bool isIncome = false;
      
      final lines = text.split('\\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      // Basic amount extraction
      final amountRegex = RegExp(r'(?:Rs\\.?|INR|₹)?\\s*(\\d+(?:\\.\\d{1,2})?)', caseSensitive: false);
      for (final line in lines) {
        if (line.contains('₹') || line.toLowerCase().contains('rs')) {
          final match = amountRegex.firstMatch(line);
          if (match != null) {
            amount = double.tryParse(match.group(1) ?? '0') ?? 0.0;
            break;
          }
        }
      }
      
      // If amount is still 0, just look for any standalone number that looks like an amount
      if (amount == 0.0) {
        for (final line in lines) {
           if (double.tryParse(line) != null) {
             amount = double.parse(line);
             break;
           }
        }
      }

      // Check if income
      final lowerText = text.toLowerCase();
      if (lowerText.contains('payment received') || lowerText.contains('received') || lowerText.contains('credited') || lowerText.contains('from:')) {
        isIncome = true;
      }

      // Merchant extraction
      for (int i = 0; i < lines.length; i++) {
        final lowerLine = lines[i].toLowerCase();
        if (lowerLine.startsWith('paid to') && i + 1 < lines.length) {
          merchant = lines[i + 1];
          break;
        } else if (lowerLine.startsWith('to:') && i + 1 < lines.length) {
          merchant = lines[i + 1];
          break;
        } else if (lowerLine.startsWith('from:') && i + 1 < lines.length) {
          merchant = lines[i].substring(5).trim();
          if (merchant.isEmpty) merchant = lines[i+1];
          break;
        }
      }
      
      if (merchant == "Unknown" && lines.isNotEmpty) {
        merchant = lines.firstWhere((l) => l.length > 2 && l.length < 20, orElse: () => 'Unknown');
      }

      return {
        "merchant": merchant,
        "amount": amount,
        "date": date,
        "category": "Other",
        "isImpulse": false,
        "isIncome": isIncome,
      };
    } catch (e) {
      return null;
    }
  }
''';

  final replaceTarget = 'static Future<Map<String, dynamic>?> _generateJsonWithRequesty(String prompt) async {';
  
  if (content.contains(replaceTarget) && !content.contains('_extractLocallyFromOcr')) {
    content = content.replaceFirst(replaceTarget, fallbackCode + '\n  ' + replaceTarget);
  }
  
  // Now modify parseTransaction to catch Requesty errors and fallback!
  final parseTargetOld = '''
  static Future<Map<String, dynamic>?> parseTransaction(String ocrText) async {
    if (_openRouterApiKey == 'REPLACE_WITH_YOUR_OPENROUTER_API_KEY') {
      throw Exception("OpenRouter API key is not configured.");
    }
    return _generateJsonWithRequesty(prompt);
  }
''';

  // I need to use regex to replace it because `prompt` variable is generated inside it
  final regexParse = RegExp(r'static Future<Map<String, dynamic>\?> parseTransaction\(String ocrText\) async \{[\s\S]*?return _generateJsonWithRequesty\(prompt\);\s*\}');
  
  if (regexParse.hasMatch(content)) {
    content = content.replaceFirst(regexParse, '''
  static Future<Map<String, dynamic>?> parseTransaction(String ocrText) async {
    final prompt = \\'\\'\\'
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The name of the other party in the transaction. If money was spent, this is the recipient. If money was received (income), this is the SENDER. CRITICAL: "Soumil Jana" is the app owner. If the money is sent TO Soumil Jana, it is an INCOME transaction. Do not set the merchant to Soumil Jana.
- "amount": (double) The numerical amount paid. (e.g. 150.0). CRITICAL: The OCR often misreads the Indian Rupee symbol (₹) as the number 7. If you see a leading 7 that acts as a currency symbol (e.g., 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0!
- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas, just the exact format). Search carefully for ANY date in the OCR text (e.g., "14 Oct 2026", "14/10", "4 Oct", "8:30 PM"). If the year is missing, assume the current year. If the time is missing, assume 12:00. DO NOT fallback to the current date unless absolutely no date string is found.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) Set to true if this is money received (credit). Set to false if it is money spent (debit) or paid. CRITICAL: If the money was sent TO "Soumil Jana", this MUST be true!

Note: The current date and time is \${DateTime.now().toString()}. If the screenshot specifies a date without a year (e.g. "16 Sep" or "Yesterday"), assume the current year. If no date is found, use the current date and time.

Here is the raw OCR text of the payment screenshot:
---
\$ocrText
---
\\'\\'\\';

    try {
      final result = await _generateJsonWithRequesty(prompt);
      if (result != null) return result;
    } catch (e) {
      print("Requesty failed, falling back to local: \$e");
    }
    
    return _extractLocallyFromOcr(ocrText);
  }
''');
  }

  file.writeAsStringSync(content);
  print('Added local fallback logic and wired it up!');
}
