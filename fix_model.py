import re

with open("lib/transaction_parser.dart", "r", encoding="utf-8") as f:
    text = f.read()

# Change model to a well known free model on Requesty/OpenRouter
text = text.replace('"model": "gemma-4-31b-it"', '"model": "google/gemma-2-27b-it"')

with open("lib/transaction_parser.dart", "w", encoding="utf-8") as f:
    f.write(text)
