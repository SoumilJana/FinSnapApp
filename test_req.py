import urllib.request
import json

url = "https://router.requesty.ai/v1/chat/completions"
req = urllib.request.Request(url, method="POST")
req.add_header("Content-Type", "application/json")
req.add_header("Authorization", "Bearer <REQUESTY_API_KEY_REMOVED>")

data = {
    "model": "google/gemma-2-27b-it",
    "messages": [
        {"role": "user", "content": "Return JSON: {\"test\": 1}"}
    ]
}

try:
    with urllib.request.urlopen(req, data=json.dumps(data).encode("utf-8")) as response:
        print(response.read().decode("utf-8"))
except Exception as e:
    print("Error:", e)
