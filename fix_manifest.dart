import 'dart:io';

void main() {
  final file = File('android/app/src/main/AndroidManifest.xml');
  String content = file.readAsStringSync();
  
  if (!content.contains('<data android:scheme="https" />')) {
    content = content.replaceFirst(
      '</queries>',
      '    <intent>\n            <action android:name="android.intent.action.VIEW" />\n            <data android:scheme="https" />\n        </intent>\n    </queries>'
    );
    file.writeAsStringSync(content);
    print('Injected https query!');
  } else {
    print('Already injected.');
  }
}
