import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_model.dart';
import '../repositories/transaction_repository.dart';

class AiChatService {
  // Requesty configuration (Currently Active)
  final String requestyApiKey = '<REQUESTY_API_KEY_REMOVED>';
  final String requestyApiUrl = 'https://router.requesty.ai/v1/chat/completions';
  final String requestyModelName = 'google/gemma-4-31b-it';

  // OpenRouter configuration (Kept as fallback just in case)
  final String openRouterApiKey = '<OPENROUTER_API_KEY_REMOVED>';
  final String openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  final String openRouterModelName = 'google/gemini-pro-1.5';

  // Active configuration
  late String apiKey;
  late String apiUrl;
  late String modelName;

  final TransactionRepository _repository = TransactionRepository();
  
  final List<Map<String, String>> _messages = [];

  AiChatService() {
    // Connect to Requesty for now
    apiKey = requestyApiKey;
    apiUrl = requestyApiUrl;
    modelName = requestyModelName;
  }

  String _convertToCsv(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return "No transactions found.";
    
    final buffer = StringBuffer();
    buffer.writeln("Date,Merchant,Amount,Category,Type,Note");
    
    for (final t in transactions) {
      // Basic escaping for CSV
      final merchant = t.merchant.replaceAll(',', '');
      final category = t.category.replaceAll(',', '');
      final type = t.isIncome ? "Income" : "Expense";
      final note = (t.note ?? '').replaceAll(',', ' ');
      
      buffer.writeln("${t.date},$merchant,${t.amount},$category,$type,$note");
    }
    
    return buffer.toString();
  }

  Future<String> sendMessage(String message) async {
    final transactions = _repository.transactionsNotifier.value;
    final String csvData = _convertToCsv(transactions);

    final systemInstruction = '''
You are an expert AI CA (Chartered Accountant) built directly into the user's budget app. You HAVE full access to their transactions.

I am providing you with the user's real transaction data right now in CSV format below. 
You MUST use this data to answer their questions. Do NOT say you don't have access to their bank accounts, because the data is provided to you right here:

--- START TRANSACTION DATA ---
$csvData
--- END TRANSACTION DATA ---

Rules for your responses:
1. ALWAYS format statistical breakdowns, monthly reviews, and lists using Markdown tables.
2. Be proactive about suggesting areas where the user can cut costs or save money.
3. Be concise but highly analytical. Point out unnecessary "Impulse/Useless" expenses, biggest expenses, or worrying trends based ON THE DATA provided above.
4. If the user asks about something not in the data, tell them it isn't in the provided dataset.
5. When providing monetary values, prefix them with the currency symbol (e.g. ₹ or \$, based on what's visible in the data, assume ₹ for India if unsure).
''';

    // Make sure the first message is always the most up-to-date system instruction
    if (_messages.isEmpty) {
      _messages.add({"role": "system", "content": systemInstruction});
    } else if (_messages.first["role"] == "system") {
      _messages.first["content"] = systemInstruction;
    } else {
      _messages.insert(0, {"role": "system", "content": systemInstruction});
    }

    _messages.add({"role": "user", "content": message});

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode({
          "model": modelName,
          "messages": _messages,
        })
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String replyText = jsonResponse['choices'][0]['message']['content'];
        _messages.add({"role": "assistant", "content": replyText});
        return replyText;
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return "An error occurred with the AI service (Status ${response.statusCode}). Please try again later.";
      }
    } catch (e) {
      print("Unknown Error: $e");
      return "An unexpected error occurred. Please check your connection and try again.";
    }
  }

  Future<String> generateSmartSummary(List<TransactionModel> transactions) async {
    final String csvData = _convertToCsv(transactions);
    final prompt = '''
Analyze the following recent transactions and provide a short, single-paragraph financial summary (2-3 sentences max). 
Highlight the biggest spending category or any worrying trends, and give one brief, actionable piece of advice.
Pay special attention to the 'Note' column in the data, as it contains the user's specific context, specific items bought, or feelings about the purchase. Use these notes to make your summary highly personalized and specific.
Keep it encouraging but realistic. DO NOT use markdown headers or lists. Just plain text.


--- TRANSACTIONS ---
$csvData
--- END TRANSACTIONS ---
''';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey'
        },
        body: jsonEncode({
          "model": modelName,
          "messages": [
            {"role": "user", "content": prompt}
          ],
        })
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['choices'][0]['message']['content'].trim();
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        return "Unable to generate insights at this time.";
      }
    } catch (e) {
      print("Unknown Error: $e");
      return "Unable to generate insights due to a network error.";
    }
  }
}
