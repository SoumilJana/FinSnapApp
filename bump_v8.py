import re

with open("pubspec.yaml", "r", encoding="utf-8") as f:
    text = f.read()

text = re.sub(r"version: 1.0.7\+8", "version: 1.0.8+9", text)

with open("pubspec.yaml", "w", encoding="utf-8") as f:
    f.write(text)
