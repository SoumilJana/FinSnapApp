with open("lib/app_updater.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace(
    "'https://raw.githubusercontent.com/SoumilJana/FinSnapApp/main/releases/FinSnapApp-v$remoteVersion.apk'",
    "'https://github.com/SoumilJana/FinSnapApp/releases/download/v$remoteVersion/FinSnapApp-v$remoteVersion.apk'"
)

with open("lib/app_updater.dart", "w", encoding="utf-8") as f:
    f.write(text)
