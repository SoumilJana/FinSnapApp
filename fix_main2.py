import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Replace ML Kit code manually
pattern = r"final InputImage inputImage.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?\n.*?String text = recognizedText.text;\n\s*textRecognizer.close\(\);"
# Actually, let's just find the exact block:
block = """      final InputImage inputImage = InputImage.fromFile(File(f.path));
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      String quickMerchant = 'Processing...';"""

new_block = """        String text = '';
        try {
          final results = await FlutterOnnxOcr.recognizeFromFile(f.path);
          text = results.map((e) => e.text).join('\\n');
        } catch (e) {
          print("OCR Error: $e");
        }

      String quickMerchant = 'Processing...';"""

text = text.replace(block, new_block)

# Remove the import just in case
text = text.replace("import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';", "")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
