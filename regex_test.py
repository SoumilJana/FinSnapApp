import re

text = "adriksona123@okhdfcbank\n7150.0\n1 Oct - 2:32 PM"

amountMatch = re.search(r'(?:(?:^|\s)(?:rs\.?|inr|f|r|7)|,1|\?)\s?(\d+(?:,\d+)*(?:\.\d{1,2})?)', text, re.IGNORECASE)
if amountMatch:
    print("MATCH 1:", amountMatch.group(1))

amountMatch2 = re.search(r'^[^\d]*(\d+(?:,\d+)*(?:\.\d{1,2})?)\s*$', text.split('\n')[1])
if amountMatch2:
    print("MATCH 2:", amountMatch2.group(1))
