import asyncio
import os
import sys
from winrt.windows.media.ocr import OcrEngine
from winrt.windows.storage import StorageFile
from winrt.windows.graphics.imaging import BitmapDecoder

async def recognize_text(image_path):
    print(f"[*] Running Windows Native OCR on {image_path}...")
    try:
        file = await StorageFile.get_file_from_path_async(image_path)
        stream = await file.open_async(0) # 0 is FileAccessMode.Read
        decoder = await BitmapDecoder.create_async(stream)
        software_bitmap = await decoder.get_software_bitmap_async()
        
        # Initialize the OCR Engine for the current system language
        engine = OcrEngine.try_create_from_user_profile_languages()
        if not engine:
            print("[!] Could not create OCR Engine!")
            return None
            
        result = await engine.recognize_async(software_bitmap)
        print("[*] OCR Extraction Complete. Raw Text:")
        print("-" * 40)
        print(result.text.strip())
        print("-" * 40)
        return result.text
    except Exception as e:
        print(f"[!] OCR Failed: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python windows_ocr.py <image_path>")
        sys.exit(1)
        
    image_path = os.path.abspath(sys.argv[1])
    asyncio.run(recognize_text(image_path))
