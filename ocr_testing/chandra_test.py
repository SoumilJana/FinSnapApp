import sys
from chandra.model import InferenceManager
from chandra.input import load_file

def main():
    image_path = sys.argv[1]
    manager = InferenceManager(method="hf")
    images = load_file(image_path)
    results = manager.generate(images)
    for res in results:
        print(res.markdown)

if __name__ == "__main__":
    main()
