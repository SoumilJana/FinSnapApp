with open("assets/models/ch_ppocrv5_dict.txt", "r", encoding="utf-8") as f:
    lines = f.readlines()
    print([c.strip() for c in lines if len(c.strip()) == 1 and ord(c.strip()) < 128][:20])
