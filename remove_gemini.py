import re

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = re.sub(r"  // Replace this with your Gemini API Key.*?\n  static const String _geminiApiKey = [^\n]+;\n?", "", text)
text = re.sub(r"    if \(_geminiApiKey == [^\}]+?\}\n?", "", text)

pattern = r"    final modelsToTry = \[.*?throw Exception\(\"All Gemini models failed\. Last error: \$lastError\"\);\s*\}"

replacement = """    final url = Uri.parse('https://router.requesty.ai/v1/chat/completions');
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
        String text = jsonResponse['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(text);
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

text = re.sub(pattern, replacement, text, flags=re.DOTALL)

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(text)
