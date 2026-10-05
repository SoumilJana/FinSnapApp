import re

with open("lib/app_updater.dart", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("import 'package:url_launcher/url_launcher.dart';", "import 'package:ota_update/ota_update.dart';\nimport 'package:url_launcher/url_launcher.dart';")

text = text.replace("""              onPressed: () {
                Navigator.pop(context);
                final apkUrl = 'https://raw.githubusercontent.com/SoumilJana/FinSnapApp/main/releases/FinSnapApp-v$remoteVersion.apk';
                _launchURL(apkUrl);
              },""", """              onPressed: () {
                Navigator.pop(context);
                final apkUrl = 'https://raw.githubusercontent.com/SoumilJana/FinSnapApp/main/releases/FinSnapApp-v$remoteVersion.apk';
                _executeOtaUpdate(apkUrl);
              },""")

new_funcs = """  static void _executeOtaUpdate(String url) {
    try {
      OtaUpdate().execute(
        url,
        destinationFilename: 'FinSnapApp-update.apk',
      ).listen(
        (OtaEvent event) {
          debugPrint('OTA status: ${event.status}, value: ${event.value}');
        },
      );
    } catch (e) {
      debugPrint('Failed to make OTA update. Details: $e');
      _launchURL(url); // Fallback
    }
  }

  static Future<void> _launchURL(String url) async {"""

text = text.replace("  static Future<void> _launchURL(String url) async {", new_funcs)

with open("lib/app_updater.dart", "w", encoding="utf-8") as f:
    f.write(text)
