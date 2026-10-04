import os
import glob
from rapidocr_onnxruntime import RapidOCR

def run_batch_ocr(directory, output_file):
    engine = RapidOCR()
    
    # Get all png files in the directory
    image_files = glob.glob(os.path.join(directory, "*.png"))
    image_files.sort()  # Sort alphabetically so expense1, expense2, income1 etc are grouped
    
    print(f"[*] Found {len(image_files)} images. Starting batch OCR...")
    
    with open(output_file, "w", encoding="utf-8") as f:
        for img_path in image_files:
            filename = os.path.basename(img_path)
            print(f"[*] Processing {filename}...")
            
            f.write("=" * 50 + "\n")
            f.write(f"Results of {filename}\n")
            f.write("=" * 50 + "\n")
            
            try:
                result, _ = engine(img_path)
                if result:
                    text = "\n".join([res[1] for res in result])
                    f.write(text + "\n\n")
                else:
                    f.write("[!] No text detected.\n\n")
            except Exception as e:
                f.write(f"[!] OCR Failed: {e}\n\n")
                
    print(f"[*] Batch complete. Results saved to {output_file}")

if __name__ == "__main__":
    ocr_dir = os.path.dirname(os.path.abspath(__file__))
    output_txt = os.path.join(ocr_dir, "ocr_results.txt")
    run_batch_ocr(ocr_dir, output_txt)
