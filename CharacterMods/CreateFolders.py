import os

def create_folders(base_path=""):
    character_names = [
        "Albedo", "Alhaitham", "Aloy", "Amber", "AratakiItto", "Arlecchino", "Baizhu", "Barbara", "Beidou", "Bennett", "Candace", "Charlotte", "Chasca", "Chevreuse", "Chiori", "Chongyun", "Citlali", "Clorinde", "Collei", "Cyno", "Dehya", "Diluc", "Diona", "Dori", "Emilie", "Eula", "Faruzan", "Fischl", "Freminet", "Furina", "GaMing", "Ganyu", "Gorou", "Heizou", "HuTao", "Jean", "JeanCN", "Kachina", "KaedeharaKazuha", "Kaeya", "KamisatoAyaka", "KamisatoAyato", "Kaveh", "Keqing", "Kirara", "Klee", "KujouSara", "KukiShinobu", "Layla", "Lisa", "Lynette", "Lyney", "Mavuika", "Mika", "Mizuki", "Mona", "Mualani", "Nahida", "Navia", "Neuvillette", "Nilou", "Ningguang", "Noelle", "RaidenShogun", "Razor", "Rosaria", "SangonomiyaKokomi", "Sayu", "Sethos", "Shenhe", "Sigewinne", "Sucrose", "Tartaglia", "Thoma", "Tighnari", "TravelerBoy", "TravelerGirl", "Venti", "Wanderer", "Wriothesley", "Xiangling", "Xianyun", "Xiao", "Xilonen", "Xingqiu", "XingqiuBamboo", "Xinyan", "YaeMiko", "Yanfei", "YaoYao", "Yelan", "Yoimiya", "YunJin", "Zhongli"
    ]
    
    for name in character_names:
        folder_path = os.path.join(base_path, name)
        os.makedirs(folder_path, exist_ok=True)
        print(f"Created: {folder_path}")

if __name__ == "__main__":
    create_folders()
