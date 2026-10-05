import re
with open("pubspec.yaml", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace(
    "# assets:\n  #   - images/a_dot_burr.jpeg\n  #   - images/a_dot_ham.jpeg",
    "assets:\n    - assets/models/"
)
with open("pubspec.yaml", "w", encoding="utf-8") as f:
    f.write(text)
