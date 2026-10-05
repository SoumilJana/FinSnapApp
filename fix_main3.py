import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

pattern = r"final inputImage = InputImage\.fromFilePath\(imagePath\);\s*final textRecognizer = TextRecognizer\(\s*script: TextRecognitionScript\.latin,\s*\);\s*final recognizedText = await textRecognizer\.processImage\(inputImage\);\s*textRecognizer\.close\(\);\s*String quickMerchant = 'Processing\.\.\.';\s*double quickAmount = 0\.0;\s*String text = recognizedText\.text;"

new_code = """String text = '';
        try {
          final results = await FlutterOnnxOcr.recognizeFromFile(imagePath);
          text = results.map((e) => e.text).join('\\n');
        } catch (e) {
          print("OCR Error: $e");
        }
        
        String quickMerchant = 'Processing...';
        double quickAmount = 0.0;"""

text = re.sub(pattern, new_code, text)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
