import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdater {
  static const String _pubspecUrl = 'https://raw.githubusercontent.com/SoumilJana/FinSnapApp/main/pubspec.yaml';
  
  static Future<void> checkForUpdates(BuildContext context) async {
    try {
      // 1. Get current local version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 2. Fetch remote pubspec.yaml
      final response = await http.get(Uri.parse(_pubspecUrl));
      if (response.statusCode == 200) {
        final content = response.body;
        
        // 3. Extract version using regex
        final match = RegExp(r'^version:\s*([0-9]+\.[0-9]+\.[0-9]+).*$', multiLine: true).firstMatch(content);
        if (match != null) {
          final remoteVersion = match.group(1)!;

          // 4. Compare versions
          if (_isUpdateAvailable(currentVersion, remoteVersion)) {
            _showUpdateDialog(context, remoteVersion);
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
    }
  }

  static bool _isUpdateAvailable(String current, String remote) {
    // Simple semver comparison (e.g. 1.0.3 vs 1.0.4)
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> remoteParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = currentParts.length > i ? currentParts[i] : 0;
      int r = remoteParts.length > i ? remoteParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  static void _showUpdateDialog(BuildContext context, String remoteVersion) {
    // Check if widget is still mounted using BuildContext extension if available, or just assume it is for this quick check.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Update Available! 🎉'),
          content: Text(
              'A new version ($remoteVersion) of FinSnap is available. Would you like to update now to get the latest features and fixes?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: const Text('Later', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                final apkUrl = 'https://raw.githubusercontent.com/SoumilJana/FinSnapApp/main/releases/FinSnapApp-v$remoteVersion.apk';
                _launchURL(apkUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1E2C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }
}
