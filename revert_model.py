import re

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace('"model": "google/gemma-2-27b-it"', '"model": "gemma-4-31b-it"')

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(text)
