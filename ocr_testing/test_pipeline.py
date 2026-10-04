import os
import sys
import json
import requests
import easyocr
from rapidocr_onnxruntime import RapidOCR

if sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

REQUESTY_API_KEY = "YOUR_REQUESTY_API_KEY"

PROMPT_TEMPLATE = """
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The other party in the transaction. If expense, who was paid (e.g. "AJOY GOSWAMI"). If income, who sent the money (e.g. "ASMIT GHOSH" or "Sukumar Jana"). CRITICAL: "Soumil Jana" is the app owner. Do NOT set merchant to Soumil Jana.
- "amount": (double) The numerical amount. The OCR may format it like 'R1,000', '￥215', '¥ 215', '215', or just '240'/'150'. Strip out ALL letters, commas, and currency symbols (R, ￥, ¥, ). For example, 'R4,000' -> 4000.0, '215' -> 215.0, '9.5' -> 9.5.
- "date": (string) The date and time strictly in YYYY-MM-DD HH:mm format (24-hour time). Examples in OCR: "0ctober 1 at 2:32 PM", "4 Oct 2026, 6:34am", "September 14 at 10:27 AM". (Note: OCR sometimes reads 'O' as '0' like '0ctober'). If the year is missing, assume the current year.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) CRITICAL RULE: Set to true if this is money received (credit). Set to false if money spent (debit). 
  * If the OCR contains "Payment Received", it is Income (true).
  * If the OCR contains "Payment Successful" and "From: Soumil Jana", it is an Expense (false).
  * If the OCR says "From [Someone]" and "To: Soumil Jana", it is Income (true).

Here is the raw OCR text of the payment screenshot:
---
{ocr_text}
---
"""

def extract_text_easyocr(image_path):
    try:
        reader = easyocr.Reader(['en'])
        result = reader.readtext(image_path, detail=0)
        return "\n".join(result)
    except Exception as e:
        return f"[!] EasyOCR Failed: {e}"

def extract_text_rapidocr(image_path):
    try:
        engine = RapidOCR()
        result, _ = engine(image_path)
        if result:
            return "\n".join([res[1] for res in result])
        return ""
    except Exception as e:
        return f"[!] RapidOCR Failed: {e}"

def parse_with_ai(ocr_text, model_name="gemma-4-31b-it"):
    print(f"\n[*] Sending to AI ({model_name}) for parsing...")
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
        print("[*] AI Parsing Complete. Output:")
        print("-" * 40)
        print(raw_output)
        print("-" * 40)
    else:
        print(f"[!] API Request Failed: {response.text}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python test_pipeline.py <path_to_image>")
        sys.exit(1)
        
    image_path = sys.argv[1]
    print(f"[*] Analyzing: {image_path}\n")
    
    # Keeping EasyOCR in the background, hidden from output
    # easy_text = extract_text_easyocr(image_path)
    
    print("=" * 50)
    print("RAPIDOCR OUTPUT")
    print("=" * 50)
    rapid_text = extract_text_rapidocr(image_path)
    print(rapid_text.encode("utf-8", errors="replace").decode("utf-8", errors="replace"))

    print("\n" + "=" * 50)
    print("We will now send the RapidOCR result to the AI.")
    print("=" * 50)
    
    if rapid_text and not rapid_text.startswith("[!]"):
        parse_with_ai(rapid_text)
