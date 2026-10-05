import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Add import
if "import 'package:image/image.dart' as img;" not in text:
    text = text.replace("import 'dart:io';", "import 'dart:io';\nimport 'package:image/image.dart' as img;")

# Add resize logic
replace_this = """      String text = '';
      try {
        final results = await FlutterOnnxOcr.recognizeFromFile(imagePath);
        text = results.map((e) => e.text).join('\\n');
      } catch (e) {"""

with_this = """      String text = '';
      try {
        final bytes = await File(imagePath).readAsBytes();
        final image = img.decodeImage(bytes);
        if (image != null) {
          final resized = img.copyResize(image, width: 720); // Resize width to 720 to dramatically speed up OCR
          final resizedBytes = img.encodeJpg(resized);
          final results = await FlutterOnnxOcr.recognizeFromBytes(resizedBytes);
          text = results.map((e) => e.text).join('\\n');
        } else {
          throw Exception("Could not decode image");
        }
      } catch (e) {"""

text = text.replace(replace_this, with_this)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
