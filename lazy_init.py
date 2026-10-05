import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Remove initialization from main()
pattern_main = r"try \{\s*await FlutterOnnxOcr\.initialize\([\s\S]*?\);\s*\} catch \(e\) \{\s*print\(\"Failed to initialize OCR: \$e\"\);\s*\}"
text = re.sub(pattern_main, "", text)

# Add lazy init to IntentHandlerWrapperState
lazy_init = """  bool _isOcrInitialized = false;

  Future<void> _ensureOcrInitialized() async {
    if (_isOcrInitialized) return;
    try {
      await FlutterOnnxOcr.initialize(
        detectionModelPath: 'assets/models/ch_PP-OCRv3_det_infer.onnx',
        recognitionModelPath: 'assets/models/ch_PP-OCRv3_rec_infer.onnx',
        characterDictPath: 'assets/models/ch_ppocrv5_dict.txt',
      );
      _isOcrInitialized = true;
    } catch (e) {
      print("Failed to initialize OCR: $e");
    }
  }"""

text = text.replace("bool _isProcessing = false;", "bool _isProcessing = false;\n" + lazy_init)

# Call it in _handleSharedFile
call_init = """    try {
      await _ensureOcrInitialized();
      // 1. OCR Extract for quick offline details"""
text = text.replace("    try {\n      // 1. OCR Extract for quick offline details", call_init)

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
