import re

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("CRITICAL: The OCR often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7150.0 instead of 150.0), STRIP THE LEADING 7. Output 150.0 instead of 7150.0.", "")
text = text.replace("CRITICAL: The AI often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7150.0 instead of 150.0), STRIP THE LEADING 7. Output 150.0 instead of 7150.0.", "")
# Also let's emphasize merchant logic!
text = text.replace('If expense, who was paid (e.g. "AJOY GOSWAMI"). If income, who sent the money (e.g. "ASMIT GHOSH" or "Sukumar Jana"). CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.', 'If expense, who was paid (e.g. "AJOY GOSWAMI"). If the OCR shows "To: [Name]" and "UPI ID: [ID]", prefer the [Name] as the merchant. If income, who sent the money. CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.')

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(text)
