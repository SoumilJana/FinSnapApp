import sys

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

start_str = "    final modelsToTry = [\n      'gemini-3.1-flash-lite',"
end_str = "throw Exception(\"All Gemini models failed. Last error: $lastError\");\n  }"

start_idx = text.find(start_str)
end_idx = text.find(end_str)

if start_idx == -1 or end_idx == -1:
    print("Could not find block")
    sys.exit(1)
    
end_idx += len(end_str)

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

new_text = text[:start_idx] + replacement + text[end_idx:]

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(new_text)
print("Replaced")
