import re

with open("README.md", "r", encoding="utf-8") as f:
    text = f.read()

text = re.sub(r"FinSnapApp-v1\.0\.6\.apk", "FinSnapApp-v1.0.8.apk", text)

with open("README.md", "w", encoding="utf-8") as f:
    f.write(text)
