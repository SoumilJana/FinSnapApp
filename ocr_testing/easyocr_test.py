import os
import sys
import easyocr

if sys.stdout.encoding.lower() != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')

def extract_text_from_image(image_path):
    print(f"[*] Running EasyOCR on {image_path}...")
    try:
        # reader = easyocr.Reader(['en', 'hi']) # 'hi' for Hindi if needed for Rs symbol, but 'en' works well enough usually
        reader = easyocr.Reader(['en'])
        
        # detail=0 returns a list of strings instead of bounding boxes
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

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python easyocr_test.py <image_path>")
        sys.exit(1)
        
    image_path = os.path.abspath(sys.argv[1])
    extract_text_from_image(image_path)
