# OCR & AI Parsing Testing Environment

This folder contains scripts to test OCR engines and the AI parsing logic locally on your laptop before pushing changes to the app.

## Setup

1. **Install Python**: You already have Python installed!
2. **Install Tesseract OCR**:
   - Download the installer from: [UB-Mannheim Tesseract Wiki](https://github.com/UB-Mannheim/tesseract/wiki)
   - Run the installer. Note the installation path (usually `C:\Program Files\Tesseract-OCR`).
   - If you install it somewhere else, update the `tesseract_cmd` path in `test_pipeline.py` (Line 9).
3. **Install Python Dependencies**:
   If they aren't installed already, open a terminal in this folder and run:
   ```bash
   pip install pytesseract pillow requests
   ```

## How to Test

Drop your payment screenshots into this folder, then run:

```bash
python test_pipeline.py screenshot1.png
```

The script will:
1. Run the image through the local Tesseract OCR engine and print the raw text it found.
2. Send that exact text to the Gemini AI using the prompt we are tuning.
3. Print the final JSON output that the app would normally save to the database.

## Tuning the AI Prompt

If you notice the AI is getting something wrong (like marking an expense as income, or extracting the wrong merchant name):
1. Open `test_pipeline.py`.
2. Look for the `PROMPT_TEMPLATE` string.
3. Add specific rules (e.g., "If you see 'adriksona123', it is an expense").
4. Run the script again until it gets it right 99% of the time!

Once we have a prompt that works flawlessly, we can move that prompt into the main Flutter app!
