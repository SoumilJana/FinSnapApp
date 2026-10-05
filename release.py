import os
import shutil

source_apk = r"build\app\outputs\flutter-apk\app-release.apk"
dest_apk = r"releases\FinSnapApp-v1.0.7.apk"
desktop_apk = r"C:\Users\skull\OneDrive\Desktop\FinSnapApp-v1.0.7.apk"

shutil.copy2(source_apk, dest_apk)
shutil.copy2(source_apk, desktop_apk)

os.system('git add releases/FinSnapApp-v1.0.7.apk pubspec.yaml lib/main.dart lib/transaction_parser.dart')
os.system('git commit -m "fix: resize OCR image, fix model name, lazy init OCR to fix white screen"')
os.system('git push origin main')
