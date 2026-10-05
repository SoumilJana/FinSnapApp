import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

pattern = r"try \{\s*final results = await FlutterOnnxOcr.recognizeFromFile\(imagePath\);\s*text = results.map\(\(e\) => e\.text\)\.join\('\\n'\);\s*\} catch \(e\) \{"
replace_with = """try {
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

text = re.sub(pattern, replace_with, text)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
