import urllib.request
import json

url = "https://pub.dev/api/packages/flutter_onnx_ocr"
req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
try:
    with urllib.request.urlopen(req) as response:
        data = json.loads(response.read().decode())
        version = data['latest']['version']
        
        url_readme = f"https://pub.dev/api/packages/flutter_onnx_ocr/versions/{version}"
        # actually pub.dev API doesn't expose readme easily unless we download the archive.
        # Let's clone the repo instead since we know it's https://github.com/Axpeykie/full-ocr.git
except Exception as e:
    pass
