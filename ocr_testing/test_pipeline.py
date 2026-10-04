import os
import sys
import json
import requests
import easyocr

if sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

REQUESTY_API_KEY = "YOUR_REQUESTY_API_KEY"

PROMPT_TEMPLATE = """
You are a transaction parser. Extract the transaction details directly from this payment screenshot.
Return ONLY a raw JSON object with the following keys, with NO markdown formatting, NO backticks, and NO other text:
- "merchant": (string) The name of the other party in the transaction. If money was spent, this is the recipient. If money was received (income), this is the SENDER. CRITICAL: "Soumil Jana" is the app owner. If the money is sent TO Soumil Jana, it is an INCOME transaction. Do not set the merchant to Soumil Jana.
- "amount": (double) The numerical amount paid. (e.g. 150.0). CRITICAL: Extract the EXACT numerical amount you see. Do NOT guess or strip digits unless there is a clear space (e.g., '2 215' might be 215). If the OCR says 2215, output 2215.0. If it says 'r215', output 215.0.
- "date": (string) The date and time of the transaction strictly in YYYY-MM-DD HH:mm format (use 24-hour military time, no am/pm, no commas, just the exact format). Search carefully for ANY date in the OCR text (e.g., "14 Oct 2026", "14/10", "4 Oct", "8:30 PM"). If the year is missing, assume the current year. If the time is missing, assume 12:00. DO NOT fallback to the current date unless absolutely no date string is found.
- "category": (string) Categorize into: Groceries, Food/Dining, Transport, Utilities, Entertainment, Impulse/Useless, Transfer, Income, Other.
- "isImpulse": (boolean) Set to true if it looks like an unnecessary impulse buy.
- "isIncome": (boolean) Set to true ONLY if this is money received (credit). Set to false if it is money spent (debit) or paid. CRITICAL: If the money was sent TO "Soumil Jana" or says "Received from", this MUST be true! If it says "Paid to", "Sent to", or is a merchant payment, it MUST be false! If it is unclear, DEFAULT to false (expense).

Here is the raw OCR text of the payment screenshot:
---
{ocr_text}
---
"""

def extract_text_from_image(image_path):
    print(f"[*] Running EasyOCR on {image_path}...")
    try:
        reader = easyocr.Reader(['en'])
        result = reader.readtext(image_path, detail=0)
        text = "\n".join(result)
        
        print("[*] OCR Extraction Complete. Raw Text:")
        print("-" * 40)
        print(text.encode("utf-8", errors="replace").decode("utf-8", errors="replace"))
        print("-" * 40)
        return text
    except Exception as e:
        print(f"[!] OCR Failed: {e}")
        return None

def parse_with_ai(ocr_text):
    print("[*] Sending to AI for parsing...")
    prompt = PROMPT_TEMPLATE.replace("{ocr_text}", ocr_text)
    
    headers = {
        "Authorization": f"Bearer {REQUESTY_API_KEY}",
        "Content-Type": "application/json"
    }
    
    data = {
        "model": "gemma-4-31b-it",
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
    ocr_text = extract_text_from_image(image_path)
    if ocr_text:
        parse_with_ai(ocr_text)
