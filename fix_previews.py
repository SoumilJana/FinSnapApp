with open('android/app/src/main/res/xml/widget_info.xml', 'r', encoding='utf-8') as f:
    text = f.read()
if 'previewLayout' not in text:
    text = text.replace('android:initialLayout', 'android:previewLayout="@layout/widget_layout"\n    android:initialLayout')
    with open('android/app/src/main/res/xml/widget_info.xml', 'w', encoding='utf-8') as f:
        f.write(text)

with open('android/app/src/main/res/xml/widget_info_monthly.xml', 'r', encoding='utf-8') as f:
    text = f.read()
if 'previewLayout' not in text:
    text = text.replace('android:initialLayout', 'android:previewLayout="@layout/widget_layout_monthly"\n    android:initialLayout')
    with open('android/app/src/main/res/xml/widget_info_monthly.xml', 'w', encoding='utf-8') as f:
        f.write(text)
