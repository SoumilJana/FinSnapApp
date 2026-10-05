import re

with open("lib/main.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("text = results.map((e) => e.text).join('\n');", "text = results.map((e) => e.text).join('\\n');")

with open("lib/main.dart", "w", encoding="utf-8") as f:
    f.write(text)
