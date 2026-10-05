import os
import sys
import json
import requests
import easyocr
import re
from datetime import datetime
from rapidocr_onnxruntime import RapidOCR

if sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

REQUESTY_API_KEY = "<REQUESTY_API_KEY_REMOVED>"

PROMPT_TEMPLATE = """You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The other party in the transaction. If expense, who was paid (e.g. "AJOY GOSWAMI"). If the OCR shows "To: [Name]" and "UPI ID: [ID]", prefer the [Name] as the merchant. If income, who sent the money. CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.
- "amount": (double) The numerical amount. The OCR may format it like 'R1,000', 'Y215', '215', or just '240'/'150'. Strip out ALL letters, commas, and currency symbols. 
- "date": (string) The date and time strictly in YYYY-MM-DD HH:mm format (24-hour time). Examples in OCR: "0ctober 1 at 2:32 PM", "4 Oct 2026, 6:34am", "September 14 at 10:27 AM". (Note: OCR sometimes reads 'O' as '0' like '0ctober'). If the year is missing, assume the current year (which is 2026).
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) CRITICAL RULE: Set to true if this is money received (credit). Set to false if money spent (debit). 
  * If the OCR contains "Payment Received" or "Money Received", it is Income (true).
  * If the OCR contains "Payment Successful", "Paid to", "Sent to", or "Paying", it is an Expense (false).
  * If the OCR says "From [Someone]" and "To: Soumil Jana", it is Income (true).
  * If unsure, default to Expense (false).

Examples to help you understand different screenshots:

EXAMPLE 1 (Spent Money on UPI / Food):
If screenshot says "Paid to Swiggy", "350", "15 Sept 2026, 8:00 pm".
You output: {"merchant": "Swiggy", "amount": 350.0, "date": "2026-09-15 20:00", "category": "Food/Dining", "isImpulse": false, "isIncome": false}

EXAMPLE 2 (Received Money / Income):
If screenshot says "From Sukumar Jana", "To: Soumil Jana", "1,000", "1 Sept 2026, 9:20 am". (Notice money is FROM Sukumar)
You output: {"merchant": "Sukumar Jana", "amount": 1000.0, "date": "2026-09-01 09:20", "category": "Income", "isImpulse": false, "isIncome": true}

EXAMPLE 3 (Expense with UPI ID):
If OCR has "Payment Successful", "₹400", "October 2 at 9:37 AM", "To: VAIBHAV PANSARI", "vaibhavcool4805@okicici".
You output: {"merchant": "Vaibhav Pansari", "amount": 400.0, "date": "2026-10-02 09:37", "category": "Other", "isImpulse": false, "isIncome": false}

EXAMPLE 4 (Income with UPI ID):
If OCR has "Payment Received", "₹240", "October 2 at 9:36 AM", "To: xxxxxx8110@superyes", "From: SAPTARSHI BAGCHI", "roni.bagchi-2@okaxis".
You output: {"merchant": "Saptarshi Bagchi", "amount": 240.0, "date": "2026-10-02 09:36", "category": "Income", "isImpulse": false, "isIncome": true}

Here is the raw OCR text of the payment screenshot:
---
{ocr_text}
---"""

def extract_text_rapidocr(image_path):
    try:
        engine = RapidOCR()
        result, _ = engine(image_path)
        if result:
            return "\\n".join([res[1] for res in result])
        return ""
    except Exception as e:
        return f"[!] RapidOCR Failed: {e}"

def get_ordinal(n):
    if 11 <= (n % 100) <= 13:
        return str(n) + 'th'
    return str(n) + {1: 'st', 2: 'nd', 3: 'rd'}.get(n % 10, 'th')

def parse_with_ai(ocr_text, model_name="google/gemma-4-31b-it"):
    prompt = PROMPT_TEMPLATE.replace("{ocr_text}", ocr_text)
    
    headers = {
        "Authorization": f"Bearer {REQUESTY_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": prompt}
        ]
    }
    
    response = requests.post("https://router.requesty.ai/v1/chat/completions", headers=headers, json=data)
    if response.status_code == 200:
        result = response.json()
        raw_output = result['choices'][0]['message']['content']
        
        # Clean JSON from markdown if exists
        json_str = raw_output
        match = re.search(r'\\{.*?\\}', raw_output, re.DOTALL)
        if match:
            json_str = match.group(0)
            
        try:
            data = json.loads(json_str)
            merchant = data.get("merchant", "Unknown")
            amt = data.get("amount", 0)
            amt_str = str(int(amt)) if amt == int(amt) else str(amt)
            
            date_val = data.get("date", "")
            if date_val:
                date_obj = datetime.strptime(date_val, "%Y-%m-%d %H:%M")
                day = get_ordinal(date_obj.day)
                date_formatted = f"{day} {date_obj.strftime('%B %Y')}"
                time_formatted = date_obj.strftime("%I %M %p").lower().lstrip("0")
            else:
                date_formatted = "Unknown"
                time_formatted = "Unknown"
            
            is_inc = data.get("isIncome", False)
            payment_type = "Income" if is_inc else "Expense"
            
            print("--- AI Outcome ---")
            print(f"Merchant/Source - {merchant}")
            print(f"Amount - {amt_str}")
            print(f"Date - {date_formatted}")
            print(f"Time - {time_formatted}")
            print(f"Payment Type - {payment_type}")
            
        except Exception as e:
            print(f"[!] Failed to parse AI output: {e}\\nRaw: {raw_output}")
    else:
        print(f"[!] API Request Failed: {response.text}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_pipeline.py <path_to_image>")
        sys.exit(1)
        
    image_path = sys.argv[1]
    
    rapid_text = extract_text_rapidocr(image_path)
    
    print("--- OCR Extracted Text ---")
    try:
        print(rapid_text)
    except UnicodeEncodeError:
        print(rapid_text.encode('utf-8', errors='replace').decode('utf-8', errors='replace'))
    print("")
    
    if rapid_text and not rapid_text.startswith("[!]"):
        parse_with_ai(rapid_text)
