import re

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Replace API Key
text = text.replace("rqsty-YOUR_REQUESTY_API_KEY", "rqsty-sk-BPBMK")

# 2. Replace fake model
text = text.replace('"gemma-4-31b-it"', '"google/gemma-2-27b-it"')

# 3. Remove Gemini Key declaration
text = re.sub(r'  // Replace this with your Gemini API Key[^\n]*\n  static const String _geminiApiKey = [^\n]+;\n?', '', text)

# 4. Remove Gemini check in parseTransactionFromImage
text = re.sub(r'    if \(_geminiApiKey == [^\}]+?\}\n?', '', text)

# 5. Remove Gemini check in parseBankStatement
# Already removed by above regex because it matches any _geminiApiKey check.

# 6. Rewrite parseBankStatement's modelsToTry block
pattern = r"    final modelsToTry = \[\s*'gemini-3\.1-flash-lite',[\s\S]*?throw Exception\(\"All Gemini models failed\. Last error: \$lastError\"\);\s*\}"

replacement = r"""    final url = Uri.parse('https://router.requesty.ai/v1/chat/completions');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_requestyApiKey'
        },
        body: jsonEncode({
          "model": "google/gemma-2-27b-it",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": prompt},
                {
                  "type": "image_url",
                  "image_url": {
                    "url": "data:application/pdf;base64,$base64Pdf"
                  }
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        String responseText = jsonResponse['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(responseText);
        if (jsonMatch != null) {
          final List<dynamic> parsed = jsonDecode(jsonMatch.group(0)!);
          return parsed.cast<Map<String, dynamic>>();
        }
      }
    } catch (e) {
      print("Requesty PDF Error: $e");
    }
    throw Exception("Requesty failed to parse PDF");
  }"""

text = re.sub(pattern, replacement.replace('\\', '\\\\'), text, flags=re.DOTALL)

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(text)
print("Done")
