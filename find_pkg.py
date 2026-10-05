import os
for root, dirs, files in os.walk(r"C:\Users\skull\AppData\Local\Pub\Cache\hosted\pub.dev"):
    for dir in dirs:
        if "flutter_onnx_ocr" in dir:
            print(os.path.join(root, dir))
