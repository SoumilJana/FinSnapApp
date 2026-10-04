import 'dart:io';

void main() {
  final file = File('android/app/build.gradle.kts');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.getByName("debug")\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")'
  );
  
  file.writeAsStringSync(content);
  print('Added proguard rules config!');
}
