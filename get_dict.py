import urllib.request

url = "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/release/2.6/ppocr/utils/ppocr_keys_v1.txt"
urllib.request.urlretrieve(url, "assets/models/ppocr_keys_v1.txt")
