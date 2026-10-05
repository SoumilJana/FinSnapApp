with open("android/app/build.gradle.kts", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("desugar_jdk_libs:2.0.3", "desugar_jdk_libs:2.1.4")

with open("android/app/build.gradle.kts", "w", encoding="utf-8") as f:
    f.write(text)
