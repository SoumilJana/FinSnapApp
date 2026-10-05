import re

with open('lib/transaction_parser.dart', 'r', encoding='utf-8') as f:
    content = f.read()

new_prompt_1 = """
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The other party in the transaction. If expense, who was paid (e.g. "AJOY GOSWAMI"). If income, who sent the money (e.g. "ASMIT GHOSH" or "Sukumar Jana"). CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.
- "amount": (double) The numerical amount. The OCR may format it like 'R1,000', 'Y215', '215', or just '240'/'150'. Strip out ALL letters, commas, and currency symbols. CRITICAL: The OCR often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7150.0 instead of 150.0), STRIP THE LEADING 7. Output 150.0 instead of 7150.0.
- "date": (string) The date and time strictly in YYYY-MM-DD HH:mm format (24-hour time). Examples in OCR: "0ctober 1 at 2:32 PM", "4 Oct 2026, 6:34am", "September 14 at 10:27 AM". (Note: OCR sometimes reads 'O' as '0' like '0ctober'). If the year is missing, assume the current year.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) CRITICAL RULE: Set to true if this is money received (credit). Set to false if money spent (debit). 
  * If the OCR contains "Payment Received" or "Money Received", it is Income (true).
  * If the OCR contains "Payment Successful", "Paid to", "Sent to", or "Paying", it is an Expense (false).
  * If the OCR says "From [Someone]" and "To: Soumil Jana", it is Income (true).
  * If unsure, default to Expense (false).

Note: The current date and time is ${DateTime.now().toString()}. If the screenshot specifies a date without a year (e.g. "16 Sep" or "Yesterday"), assume the current year. If no date is found, use the current date and time.

Here is the raw OCR text of the payment screenshot:
---
$ocrText
---
"""

new_prompt_2 = """
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The other party in the transaction. If expense, who was paid (e.g. "AJOY GOSWAMI"). If income, who sent the money (e.g. "ASMIT GHOSH" or "Sukumar Jana"). CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.
- "amount": (double) The numerical amount. The OCR may format it like 'R1,000', 'Y215', '215', or just '240'/'150'. Strip out ALL letters, commas, and currency symbols. CRITICAL: The AI often misreads the Rupee symbol as the number 7. If you see a leading 7 that looks like a currency symbol (e.g. 7150.0 instead of 150.0), STRIP THE LEADING 7. Output 150.0 instead of 7150.0.
- "date": (string) The date and time strictly in YYYY-MM-DD HH:mm format (24-hour time). Examples in OCR: "0ctober 1 at 2:32 PM", "4 Oct 2026, 6:34am", "September 14 at 10:27 AM". (Note: OCR sometimes reads 'O' as '0' like '0ctober'). If the year is missing, assume the current year.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) CRITICAL RULE: Set to true if this is money received (credit). Set to false if money spent (debit). 
  * If the OCR contains "Payment Received" or "Money Received", it is Income (true).
  * If the OCR contains "Payment Successful", "Paid to", "Sent to", or "Paying", it is an Expense (false).
  * If the OCR says "From [Someone]" and "To: Soumil Jana", it is Income (true).
  * If unsure, default to Expense (false).

Note: The current date and time is ${DateTime.now().toString()}. If the screenshot specifies a date without a year (e.g. "16 Sep" or "Yesterday"), assume the current year. If no date is found, use the current date and time.

Examples to help you understand different screenshots:

EXAMPLE 1 (Spent Money on UPI / Food):
If screenshot says "Paid to Swiggy", "350", "15 Sept 2026, 8:00 pm".
You output: {"merchant": "Swiggy", "amount": 350.0, "date": "2026-09-15 20:00", "category": "Food/Dining", "isImpulse": false, "isIncome": false}

EXAMPLE 2 (Received Money / Income):
If screenshot says "From Sukumar Jana", "To: Soumil Jana", "1,000", "1 Sept 2026, 9:20 am". (Notice money is FROM Sukumar)
You output: {"merchant": "Sukumar Jana", "amount": 1000.0, "date": "2026-09-01 09:20", "category": "Income", "isImpulse": false, "isIncome": true}

CRITICAL: DO NOT output "User Safety: safe". DO NOT output any text other than the JSON object. You are a JSON API.
"""

pattern1 = re.compile(r'(static Future<Map<String, dynamic>\?> parseTransaction\(String ocrText\) async \{\s*final prompt =\s*\'\'\').*?(\'\'\';)', re.DOTALL)
content = pattern1.sub(r'\1' + new_prompt_1 + r'\2', content)

pattern2 = re.compile(r'(static Future<Map<String, dynamic>\?> parseTransactionFromImage\([^)]*\)\s*async\s*\{\s*(?:if\s*\([^}]*\)\s*\{\s*[^}]*\s*\}\s*)?final prompt\s*=\s*\'\'\').*?(\'\'\';)', re.DOTALL)
content = pattern2.sub(r'\1' + new_prompt_2 + r'\2', content)

with open('lib/transaction_parser.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Done replacing.")
