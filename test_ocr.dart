import 'package:flutter/material.dart';
import 'package:flutter_onnx_ocr/flutter_onnx_ocr.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print("Initializing OCR...");
  await FlutterOnnxOcr.initialize(
    detectionModelPath: 'assets/models/ch_PP-OCRv3_det_infer.onnx',
    recognitionModelPath: 'assets/models/ch_PP-OCRv3_rec_infer.onnx',
    characterDictPath: 'assets/models/ch_ppocrv5_dict.txt',
  );

  print("Initialized.");
  final dir = Directory('ocr_testing');
  final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jpg') || f.path.endsWith('.png')).toList();
  
  StringBuffer out = StringBuffer();

  for (var file in files) {
    print("Processing ${file.path}...");
    try {
      final results = await FlutterOnnxOcr.recognizeFromFile(file.path);
      String text = results.map((e) => e.text).join('\n');
      out.writeln("Results of ${file.uri.pathSegments.last}:");
      out.writeln(text);
      out.writeln("-------------------------");
    } catch (e) {
      out.writeln("Error on ${file.path}: $e");
    }
  }

  File('result.txt').writeAsStringSync(out.toString());
  print("Done. Saved to result.txt");
  exit(0);
}
