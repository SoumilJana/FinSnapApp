import re

with open("android/app/build.gradle.kts", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace(
    "compileOptions {\n        sourceCompatibility = JavaVersion.VERSION_17\n        targetCompatibility = JavaVersion.VERSION_17\n    }",
    "compileOptions {\n        isCoreLibraryDesugaringEnabled = true\n        sourceCompatibility = JavaVersion.VERSION_17\n        targetCompatibility = JavaVersion.VERSION_17\n    }"
)

if "dependencies {" not in text:
    text += "\n\ndependencies {\n    coreLibraryDesugaring(\"com.android.tools:desugar_jdk_libs:2.0.3\")\n}\n"

with open("android/app/build.gradle.kts", "w", encoding="utf-8") as f:
    f.write(text)
