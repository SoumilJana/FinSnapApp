import re

with open("android/app/src/main/AndroidManifest.xml", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace('<application', '<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>\n    <application')

with open("android/app/src/main/AndroidManifest.xml", "w", encoding="utf-8") as f:
    f.write(text)
