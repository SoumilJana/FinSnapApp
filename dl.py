import urllib.request
url = "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/release/2.7/ppocr/utils/ppocr_keys_v1.txt"
try:
    urllib.request.urlretrieve(url, "ppocr_keys_v1.txt")
    print("Downloaded dict")
except Exception as e:
    print(e)
