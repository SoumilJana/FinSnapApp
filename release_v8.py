import os
import shutil

source_apk = r"build\app\outputs\flutter-apk\app-release.apk"
dest_apk = r"releases\FinSnapApp-v1.0.8.apk"
desktop_apk = r"C:\Users\skull\OneDrive\Desktop\FinSnapApp-v1.0.8.apk"

shutil.copy2(source_apk, dest_apk)
shutil.copy2(source_apk, desktop_apk)

os.system('git add releases/FinSnapApp-v1.0.8.apk pubspec.yaml lib/transaction_parser.dart')
os.system('git commit -m "fix: revert Requesty model to gemma-4-31b-it"')
os.system('git push origin main')
