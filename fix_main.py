import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# 1. Remove google_mlkit_text_recognition import
text = text.replace("import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';", "import 'package:flutter_onnx_ocr/flutter_onnx_ocr.dart';")

# 2. Add initialization in main()
init_code = """
  try {
    await FlutterOnnxOcr.initialize(
      detectionModelPath: 'assets/models/ch_PP-OCRv3_det_infer.onnx',
      recognitionModelPath: 'assets/models/ch_PP-OCRv3_rec_infer.onnx',
      characterDictPath: 'assets/models/ch_ppocrv5_dict.txt',
    );
  } catch (e) {
    print("Failed to initialize OCR: $e");
  }
"""
text = text.replace("WidgetsFlutterBinding.ensureInitialized();", "WidgetsFlutterBinding.ensureInitialized();\n" + init_code)

# 3. Replace ML Kit processImage with FlutterOnnxOcr
mlkit_code_pattern = re.compile(r'final InputImage inputImage = InputImage\.fromFile\(File\(f\.path\)\);\s*final textRecognizer = TextRecognizer\(script: TextRecognitionScript\.latin\);\s*final RecognizedText recognizedText = await textRecognizer\.processImage\(inputImage\);\s*String text = recognizedText\.text;\s*textRecognizer\.close\(\);')

flutter_onnx_code = """
        String text = '';
        try {
          final results = await FlutterOnnxOcr.recognizeFromFile(f.path);
          text = results.map((e) => e.text).join('\\n');
        } catch (e) {
          print("OCR Error: $e");
        }
"""
text = mlkit_code_pattern.sub(flutter_onnx_code, text)

# 4. We also need to fix the quick amount matching since RapidOCR/PaddleOCR will correctly output '?' or similar, OR maybe it will output '250' directly.
# Wait, let's just make the quick parsing regex very robust.
regex_replace = r"""var amountMatch = RegExp(
        r'(?:(?:^|\s)(?:rs\.?|inr|f|r|7)|,1|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);"""
      
new_regex = r"""var amountMatch = RegExp(
        r'(?:(?:^|\s)(?:rs\.?|inr|f|r|7|?|?|Y)|,1|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)',
        caseSensitive: false,
      ).firstMatch(text);
      if (amountMatch == null) {
        // Fallback: just look for the largest number
        var matches = RegExp(r'\b(\d+(?:,\d+)*(?:\.\d{1,2})?)\b').allMatches(text);
        for (var m in matches) {
           var val = double.tryParse(m.group(1)!.replaceAll(',', ''));
           if (val != null && val < 1000000 && val > (quickAmount ?? 0)) {
               quickAmount = val;
           }
        }
      }"""
text = text.replace(regex_replace, new_regex)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
