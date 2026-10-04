import 'dart:io';

void main() {
  final file = File('lib/transaction_parser.dart');
  String content = file.readAsStringSync();
  content = content.replaceAll('â‚¹', 'Rs. ');
  // Enhance the OCR 7 instruction further
  content = content.replaceAll(
    'is a Rs.  symbol. VERY IMPORTANT: The OCR OFTEN reads the "Rs. " symbol as the number "7". If the amount is e.g. 7150 but the item is cheap, or if the 7 is slightly separated like "7 150", it means "Rs. 150". Strip the leading 7 if it represents the Rupee symbol.',
    'is a Rs. symbol. CRITICAL: OCR OFTEN reads the Rupee symbol (₹) as the number "7". If the amount starts with 7 (e.g. 750, 71200) check if it makes sense. If it is a small purchase (e.g. food for 750), it is highly likely it was actually Rs. 50. ALWAYS strip the leading 7 if it represents the currency symbol.'
  );
  file.writeAsStringSync(content);
  print('Fixed encoding issues!');
}
