import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

class TransactionParser {
  // Replace this with your OpenRouter API Key
  static const String _openRouterApiKey = 'REPLACE_WITH_YOUR_OPENROUTER_API_KEY';

  // Replace this with your Gemini API Key (Required ONLY for PDF parsing)
  static const String _geminiApiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';
      
  static const String _requestyApiKey = 'REPLACE_WITH_YOUR_REQUESTY_API_KEY';

    static Future<Map<String, dynamic>?> parseTransaction(String ocrText) async {
    final prompt = '''
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The name of the other party in the transaction. If money was spent, this is the recipient. If money was received (income), this is the SENDER. CRITICAL: "Soumil Jana" is the app owner. If the money is sent TO Soumil Jana, it is an INCOME transaction. Do not set the merchant to Soumil Jana.
- "amount": (double) The numerical amount paid. (e.g. 150.0). CRITICAL: The OCR often misreads the Indian Rupee symbol (₹) as the number 7. If you see a leading 7 that acts as a currency symbol (e.g., 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0!
- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas, just the exact format). Search carefully for ANY date in the OCR text (e.g., "14 Oct 2026", "14/10", "4 Oct", "8:30 PM"). If the year is missing, assume the current year. If the time is missing, assume 12:00. DO NOT fallback to the current date unless absolutely no date string is found.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) Set to true if this is money received (credit). Set to false if it is money spent (debit) or paid. CRITICAL: If the money was sent TO "Soumil Jana", this MUST be true!

Note: The current date and time is ${DateTime.now().toString()}. If the screenshot specifies a date without a year (e.g. "16 Sep" or "Yesterday"), assume the current year. If no date is found, use the current date and time.

Here is the raw OCR text of the payment screenshot:
---
$ocrText
---
''';

    try {
      print("Calling Requesty...");
        final result = await _generateJsonWithRequesty(prompt);
        print("Requesty returned: $result");
      if (result != null) return result;
    } catch (e) {
      print("Requesty failed, falling back to local: $e");
    }
    
    return _extractLocallyFromOcr(ocrText);
  }


  static Future<Map<String, dynamic>?> parseTransactionFromImage(
    File imageFile,
  ) async {
    if (_geminiApiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      throw Exception("Gemini API key is not configured.");
    }

    final prompt =
        '''
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The name of the other party in the transaction. If money was spent, this is the recipient. If money was received (income), this is the SENDER. CRITICAL: "Soumil Jana" is the app owner. If the money is sent TO Soumil Jana, it is an INCOME transaction. Do not set the merchant to Soumil Jana.
- "amount": (double) The numerical amount. (e.g. 150.0). CRITICAL: The AI often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0.
- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas, just the exact format).
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) Set to true if this is money received (credit). Set to false if it is money spent (debit) or paid. CRITICAL: If the money was sent TO "Soumil Jana", this MUST be true!

Note: The current date and time is ${DateTime.now().toString()}. If the screenshot specifies a date without a year (e.g. "16 Sep" or "Yesterday"), assume the current year. If no date is found, use the current date and time.

Examples to help you understand different screenshots:

EXAMPLE 1 (Spent Money on UPI / Food):
If screenshot says "Paid to Swiggy", "₹350", "15 Sept 2026, 8:00 pm".
You output: {"merchant": "Swiggy", "amount": 350.0, "date": "2026-09-15 20:00", "category": "Food/Dining", "isImpulse": false, "isIncome": false}

EXAMPLE 2 (Received Money / Income):
If screenshot says "From Sukumar Jana", "To: Soumil Jana", "₹1,000", "1 Sept 2026, 9:20 am". (Notice money is FROM Sukumar)
You output: {"merchant": "Sukumar Jana", "amount": 1000.0, "date": "2026-09-01 09:20", "category": "Income", "isImpulse": false, "isIncome": true}

EXAMPLE 3 (Impulse Buy / Entertainment):
If screenshot says "Paid to Steam Games", "₹1200", "10 Aug 2026, 1:15 pm".
You output: {"merchant": "Steam Games", "amount": 1200.0, "date": "2026-08-10 13:15", "category": "Entertainment", "isImpulse": true, "isIncome": false}

CRITICAL: DO NOT output "User Safety: safe". DO NOT output any text other than the JSON object. You are a JSON API.
''';

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    String mimeType = "image/jpeg";
    if (imageFile.path.toLowerCase().endsWith(".png")) mimeType = "image/png";

    final url = Uri.parse('https://router.requesty.ai/v1/chat/completions');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_requestyApiKey'
        },
        body: jsonEncode({
          "model": "gemma-4-31b-it",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:$mimeType;base64,$base64Image"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = jsonResponse['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch == null) throw Exception('No JSON found in response');
        final Map<String, dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        return parsed;
      } else {
        print("Requesty Error HTTP ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Requesty Exception: $e");
    }

    return null;
  }

  static Future<Map<String, dynamic>?> _generateJsonWithOpenRouter(
    String prompt,
    String? base64Image,
    String? mimeType,
  ) async {
    List<Map<String, dynamic>> contentList = [];
    
    contentList.add({"type": "text", "text": prompt});

    if (base64Image != null && mimeType != null) {
      contentList.add({
        "type": "image_url",
        "image_url": {
          "url": "data:$mimeType;base64,$base64Image"
        }
      });
    }

    final modelsToTry = [
      'openrouter/free'
    ];

    for (String modelName in modelsToTry) {
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openRouterApiKey',
            'HTTP-Referer': 'http://localhost',
            'X-Title': 'FinSnap',
          },
          body: jsonEncode({
            "model": modelName,
            "messages": [
              {
                "role": "user",
                "content": contentList
              }
            ],
            "response_format": {"type": "json_object"}
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          String text = jsonResponse['choices'][0]['message']['content'];
          
          // Robustly extract JSON object in case the model prepends text like "User Safety: safe"
          final startIndex = text.indexOf('{');
          final endIndex = text.lastIndexOf('}');
          
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            text = text.substring(startIndex, endIndex + 1);
          }

          return jsonDecode(text) as Map<String, dynamic>;
        } else {
          print(
            "HTTP ${response.statusCode} from OpenRouter ($modelName): ${response.body}",
          );
        }
      } catch (e) {
        print("API Error on OpenRouter ($modelName): $e");
      }
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> parseBankStatement(
    File pdfFile,
  ) async {
    if (_geminiApiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY') {
      throw Exception("Gemini API key is not configured.");
    }

    final prompt =
        '''
You are a transaction parser. Extract all transactions (both DEBIT/spent and CREDIT/received) from this bank statement PDF.
Return ONLY a raw JSON array of objects, with NO markdown formatting.
Each object must have the following keys:
- "merchant": (string) The name of the other party in the transaction. If it's a debit (spent), this is who was paid. If it's a credit (income), this is who sent the money. Clean up the name to be readable.
- "amount": (double) The numerical amount. (e.g. 150.0). CRITICAL: The AI often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7400 instead of 400), STRIP THE LEADING 7. Output 400.0 instead of 7400.0.
- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas).
- "category": (string) Categorize the transaction into one of these: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if the category is 'Impulse/Useless' or if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) Set to true if this is money received (credit). Set to false if it is money spent (debit).

Note: The current date and time is ${DateTime.now().toString()}. If a date is missing the year, assume the current year.
''';

    final bytes = await pdfFile.readAsBytes();
    final base64Pdf = base64Encode(bytes);

    final modelsToTry = [
      'gemini-3.1-flash-lite',
      'gemini-3.0-flash',
      'gemini-3-flash',
      'gemma-3-27b-it',
      'gemini-1.5-flash',
      'gemini-1.5-pro',
    ];
    String lastError = "";

    for (String modelName in modelsToTry) {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=$_geminiApiKey',
      );

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [
              {
                "parts": [
                  {
                    "inlineData": {
                      "mimeType": "application/pdf",
                      "data": base64Pdf,
                    },
                  },
                  {"text": prompt},
                ],
              },
            ],
            "generationConfig": {"responseMimeType": "application/json"},
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          String text =
              jsonResponse['candidates'][0]['content']['parts'][0]['text'];
          final List<dynamic> parsed = jsonDecode(text);
          return parsed.cast<Map<String, dynamic>>();
        } else {
          lastError =
              "HTTP ${response.statusCode} for $modelName: ${response.body}";
          print(lastError);
          if (response.statusCode == 404 || response.statusCode == 503)
            continue;
          throw Exception(lastError);
        }
      } catch (e) {
        lastError = "API Error on $modelName: $e";
        print(lastError);
      }
    }

    throw Exception("All Gemini models failed. Last error: $lastError");
  }

  static Future<List<Map<String, dynamic>>> auditTransactions(
    List<Map<String, dynamic>> transactionsJson, {
    String feedbackContext = "",
  }) async {
    if (_openRouterApiKey == 'REPLACE_WITH_YOUR_OPENROUTER_API_KEY') {
      throw Exception("OpenRouter API key is not configured.");
    }

    final prompt = '''
You are an AI Auditor for a personal finance app. 
Review these transactions (specifically their notes or merchant names if note is missing) and identify cases where the current category is incorrect or could be more specific.
$feedbackContext

Input is a JSON array of transactions. 
Return ONLY a raw JSON array of suggestion objects, matching the exact order and length of the input.
Each returned object MUST have:
- "id": (string) The exact transaction ID.
- "shouldSuggestChange": (boolean) True if a change is highly recommended. False if the current category is correct or if there isn't enough confident information to change it.
- "suggestedCategory": (string or null) The corrected category. MUST be one of: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "suggestedSubcategory": (string or null) A more specific subcategory (e.g., "Football Turf", "Swiggy", "Fuel"). Keep it concise.
- "confidence": (number) Between 0.0 and 1.0 representing your confidence.
- "reason": (string or null) A very short, specific reason for the change, based ONLY on the note or merchant. (e.g. "Merchant name Swiggy clearly belongs to Food/Dining.")

CRITICAL RULES:
- Do NOT output any markdown formatting, backticks, or other text. Return ONLY the raw JSON array.
- DO NOT invent information.
- If the current category is already appropriate, return shouldSuggestChange: false.
- Be conservative. Only suggest a change if you are confident (\u003e0.8).
''';

    final modelsToTry = [
      'openrouter/free'
    ];
    String lastError = "";

    for (String modelName in modelsToTry) {
      final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');

      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_openRouterApiKey',
            'HTTP-Referer': 'http://localhost',
            'X-Title': 'FinSnap',
          },
          body: jsonEncode({
            "model": modelName,
            "messages": [
              {"role": "system", "content": prompt},
              {"role": "user", "content": jsonEncode(transactionsJson)},
            ],
            // Request JSON mode if supported
            "response_format": {"type": "json_object"}
          }),
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          String text = jsonResponse['choices'][0]['message']['content'];
          
          // Robustly extract JSON array in case the model prepends text like "User Safety: safe"
          int startIndex = text.indexOf('[');
          int endIndex = text.lastIndexOf(']');
          
          if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
            text = text.substring(startIndex, endIndex + 1);
          } else {
            // Try extracting an object if array brackets are missing
            startIndex = text.indexOf('{');
            endIndex = text.lastIndexOf('}');
            if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
              text = text.substring(startIndex, endIndex + 1);
            }
          }

          final decoded = jsonDecode(text);
          List<dynamic> parsed;
          if (decoded is List) {
            parsed = decoded;
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('suggestions')) {
            parsed = decoded['suggestions'] as List<dynamic>;
          } else if (decoded is Map) {
            parsed = [decoded];
          } else {
            parsed = [];
          }

          return parsed.cast<Map<String, dynamic>>();
        } else {
          lastError = "HTTP ${response.statusCode} for $modelName: ${response.body}";
          if (response.statusCode == 404 || response.statusCode == 429 || response.statusCode == 503)
            continue;
          throw Exception(lastError);
        }
      } catch (e) {
        lastError = "API Error on $modelName: $e";
      }
    }

    throw Exception("All OpenRouter free models failed. Last error: $lastError");
  }

    static Map<String, dynamic>? _extractLocallyFromOcr(String text) {
    try {
      double amount = 0.0;
      String merchant = "Unknown";
      String date = DateTime.now().toString().substring(0, 16).replaceAll(' ', 'T');

      bool isIncome = false;
      
            final lines = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      // Better Date Extraction
      final dateRegex = RegExp(r'(january|february|march|april|may|june|july|august|september|october|november|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{1,2})[^\d]*(\d{1,2}:\d{2}\s*(?:AM|PM|am|pm)?)', caseSensitive: false);
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
             final timeMatch = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM|am|pm)?', caseSensitive: false).firstMatch(timeStr);
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

      
      // Basic amount extraction
      final amountRegex = RegExp(r'(?:Rs\.?|INR|₹)?\s*(\d+(?:\.\d{1,2})?)', caseSensitive: false);
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

  static Future<Map<String, dynamic>?> _generateJsonWithRequesty(String prompt) async {
    final url = Uri.parse('https://router.requesty.ai/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_requestyApiKey'
        },
        body: jsonEncode({
          "model": "gemma-4-31b-it",
          "messages": [
            {
              "role": "user",
              "content": prompt
            }
          ]
        }),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String text = jsonResponse['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(text);
        if (jsonMatch == null) throw Exception('No JSON found in response');
        final Map<String, dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
        return parsed;
      } else {
        print("Requesty Error HTTP ${response.statusCode}: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Requesty Exception: $e");
    }
    return null;
  }

}
