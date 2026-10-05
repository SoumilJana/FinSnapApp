import urllib.request
import json
import base64

def fetch_github(api_url):
    req = urllib.request.Request(api_url, headers={'User-Agent': 'Mozilla/5.0'})
    try:
        with urllib.request.urlopen(req) as response:
            return json.loads(response.read().decode())
    except Exception as e:
        print(f"Error fetching {api_url}: {e}")
        return None

# Let's search github for ch_PP-OCRv5_det_mobile.onnx
url = "https://api.github.com/search/code?q=ch_PP-OCRv5_det_mobile.onnx"
res = fetch_github(url)
if res:
    for item in res.get('items', [])[:5]:
        print(item['repository']['full_name'], item['path'])
