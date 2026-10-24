# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import os
import re
import json

#Characters = {'df65bb00': 'Albedo', '3ef08385': 'Alhaitham', '46de82f3': 'Aloy', 'a2ea4b2d': 'Amber', '557b2eff': 'AmberCN', '0107925f': 'Ayaka', 'b473c856': 'Ayato',
#              '17baa562': 'Baizhu', '85282151': 'Barbara', '8b9e7c22': 'BarbaraSummertime', '51197c51': 'Beidou', '6cff51b4': 'Bennett', '9cee8711': 'Candace',
#              'c5a6d98e': 'Charlotte', '4d8d965a': 'Chevreuse', '186eac84': 'Childe', 'c8e25747': 'Chiori', '489e3621': 'Chongyun', '07f8ad68': 'Clorinde',
#              '348e58c4': 'Collei', '226f076e': 'Cyno', '9aeecbcb': 'Dehya', '71625c4d': 'Diluc', 'a2d909c8': 'DilucFlamme', 'e8083f19': 'Diona', '2a2a63ab': 'Dori',
#              '107ba6e7': 'Eula', '6162188c': 'Faruzan', 'bf6aef4d': 'Fischl', '8f473224': 'FischlHighness', 'd2bfc751': 'Freminet', '8294fe98': 'Furina',
#              'b94ef036': 'GaMing', 'a5169f1d': 'Ganyu', '9b3f356e': 'GanyuTwilight', '3ce94cac': 'Gorou', '51a75ba6': 'Heizou', 'dd16576c': 'HuTao', '3e61a41f': 'Itto',
#              '191af650': 'Jean', '93bb2522': 'JeanCN', '16fef1eb': 'JeanSea', '8a081f34': 'Kaeya', 'b9b77eff': 'KaeyaSailwind', 'b56fd424': 'Kaveh', '7c0c47b3': 'Kazuha',
#              '3aaf3e94': 'Keqing', '0d7e3cc5': 'KeqingOpulent', 'b57d7fe2': 'Kirara', 'dcd74904': 'Klee', '0f5fedb4': 'KleeBlossomingStarlight', 'dde4750a': 'Kokomi',
#              'b82eaa26': 'KujouSara', '2656ccca': 'Layla', '2a557add': 'Lisa', '37c70461': 'LisaStudent', '98eb2db4': 'Lynette', '6f7b7740': 'Lyney', '1876e82e': 'Mika',
#              '7a1dc890': 'Mona', '515f3ce6': 'MonaCN', '7106f05d': 'Nahida', 'f4e09bd7': 'Navia', 'cad3a022': 'Neuvillette', 'b2acc1df': 'Nilou', 'f9e1b52b': 'Ningguang',
#              'db37b198': 'NingguangOrchid', 'd1384d15': 'Noelle', 'cad5bebb': 'Qiqi', 'e48c61f3': 'RaidenShogun', '4662c505': 'Razor', '748f40a5': 'Rosaria',
#              '59a1f8b1': 'RosariaCN', 'c70b7fce': 'Sayu', 'e44b58b5': 'Shenhe', 'ee0980eb': 'ShenheFrostFlower', '7cfb62ea': 'Shinobu', 'b655c335': 'Sucrose',
#              '24ecd71a': 'Thoma', 'ed2e7d59': 'Tighnari', 'c77e380b': 'TravelerBoy', '8239be13': 'TravelerGirl', '09a91a5c': 'Venti', '0110e1c7': 'Wanderer',
#              'aa6f1268': 'Wriothesley', '9427917d': 'Xiangling', '39838e8f': 'Xianyun', '9464bf2d': 'Xiao', '25aed172': 'Xingqiu', 'cc158a1e': 'XingqiuBamboo',
#              '76ed85f0': 'Xinyan', '3a7f71f5': 'Yae', 'eb8b62d3': 'Yanfei', '293449d6': 'YaoYao', 'c58c76f9': 'Yelan', '65618289': 'Yoimiya', '221f052e': 'YunJin',
#              'a75ba32e': 'Zhongli', '6895f405': 'Arlecchino'}

Characters = {
              'Albedo': ['1', 'df65bb00', '0d7dc936', '3b4159ca', '9f6d193b'], 'Alhaitham': ['2', '3ef08385', '639d1fb8', '1d1783dd', 'be0197c5'], 'Aloy': ['3', '46de82f3', '5d1da717', '2b5e2530', 'f8d61c99'],
              'Amber': ['4', 'a2ea4b2d', 'b03c7e30', '36d20a67', '81b777ca'], 'AmberCN': ['5', '557b2eff', 'b41d4d94', 'f35340d5', 'dbc594b6'], 'Arlecchino': ['6', '6895f405', 'e811d2a1', 'e211de60', '8b17a419'],
              'Ayaka': ['7', '0107925f', '0cafd227', '3d534190', '0c7e5f66'], 'Ayato': ['8', 'b473c856', 'e59b09d6', '19b13b6e', '2482a5ee'], 'Baizhu': ['9', '17baa562', 'be0be707', '42f0e587', '105da9c1'],
              'Barbara': ['10', '85282151', '1bc3490d', '22a31278', '0f18519e'], 'BarbaraSummertime': ['11', '8b9e7c22', '9cc5a563', '639d62b6', '27057f58'], 'Beidou': ['12', '51197c51', 'fed42bef', 'b8634f05', 'bd166d95'],
              'Bennett': ['13', '6cff51b4', 'cdc66323', 'd4acf3f7', 'acde80a4'], 'Candace': ['14', '9cee8711', 'a84cc930', 'e5fd4e8a', '729f8219'], 'Charlotte': ['15', 'c5a6d98e', 'ff554aca', 'c195ab20', '54841c9b'],
              'Chevreuse': ['16', '4d8d965a', '77208d51', '8e8fe0e3', '350c5b58'], 'Childe': ['17', '186eac84', '531d9358', 'fff25ec8', '7e7aeada'], 'Chiori': ['18', 'c8e25747', '65d5b68c', 'c4ed0dcd', 'af52cb39'],
              'Chongyun': ['19', '489e3621', '0c6dd2d6', '2f997aab', '93136ff7'], 'Clorinde': ['20', '07f8ad68', 'd6371da1', 'f672845e', 'f0b6d3f1'], 'Collei': ['21', '348e58c4', '3da6f8c7', 'e5fe748c', '1b2f9d1b'],
              'Cyno': ['22', '226f076e', 'af184471', '6867e0b8', '9ea96ce5'], 'Dehya': ['23', '9aeecbcb', '63e3e58e', '31ea99dd', '3feafd9a'], 'Diluc': ['24', '71625c4d', 'e16fa548', 'afb527f6', '6d0e22f0'],
              'DilucFlamme': ['25', 'a2d909c8', 'a5323853', '105887c0', '16350d1b'], 'Diona': ['26', 'e8083f19', '740a72e3', '558b43fe', '9fb434ae'], 'Dori': ['27', '2a2a63ab', '04929496', 'b0c49997', '1339b941'],
              'Eula': ['28', '107ba6e7', '660399d1', '9ab68521', 'f8e35031'], 'Faruzan': ['29', '6162188c', 'faad3720', '1ed4dc04', '3ceab969'], 'Fischl': ['30', 'bf6aef4d', '6428104d', '0d1c1932', 'd451d8d8'],
              'FischlHighness': ['31', '8f473224', 'ad6be7a1', 'dbd6a5c3', 'a800a294'], 'Freminet': ['32', 'd2bfc751', '6d40de64', '4443153c', '333aa56c'], 'Furina': ['33', '8294fe98', '045e580b', 'd8c43862', 'a327ea5e'],
              'GaMing': ['34', 'b94ef036', 'b5eb19b6', 'cd9b5130', '968dba13'], 'Ganyu': ['35', 'a5169f1d', '1575ec63', '6f47a39d', 'cf27251f'], 'GanyuTwilight': ['36', '9b3f356e', 'cb283c86', '9a5c01d2', '5ff2f1d1'],
              'Gorou': ['37', '3ce94cac', 'b2e57c84', 'f4db799d', 'a144269e'], 'Heizou': ['38', '51a75ba6', 'd4c9bab4', 'c121cffe', '889d1e64'], 'HuTao': ['39', 'dd16576c', '3de1efe2', '153dba3f', '51afdfcf'],
              'Itto': ['40', '3e61a41f', 'be597118', 'f186e87b', '5bcab405'], 'Jean': ['41', '191af650', '115737ff', '3cb8153c', '1722136c'], 'JeanCN': ['42', '93bb2522', 'aad861e0', 'd159bf31', '0ffefb98'],
              'JeanSea': ['43', '16fef1eb', '69c0c24e', 'ac801371', '3ffb0363'], 'Kaeya': ['44', '8a081f34', '2b3f575a', '763b60b9', 'fb2eff2a'], 'KaeyaSailwind': ['45', 'b9b77eff', '59f2a0f2', 'e026c9ae', '74dce34a'],
              'Kaveh': ['46', 'b56fd424', '5966a63f', 'db2490d6', 'd09a3948'], 'Kazuha': ['47', '7c0c47b3', '356cdbde', '28a1fab0', '5f7534b6'], 'Keqing': ['48', '3aaf3e94', 'cbf1894b', '0bf8e621', '723848fe'],
              'KeqingOpulent': ['49', '0d7e3cc5', '7c6fc8c3', '6f010b58', '52f78cb7'], 'Kirara': ['50', 'b57d7fe2', 'f6e9af7d', '01d54938', '33b3d6e5'], 'Klee': ['51', 'dcd74904', '073c71f5', 'aec1d55e', 'c3448489'],
              'KleeBlossomingStarlight': ['52', '0f5fedb4', '4cf8240a', '652497c2', '4d6c496b'], 'Kokomi': ['53', 'dde4750a', '74900c81', '7b61fb15', '4ed0c9f8'], 'KujouSara': ['54', 'b82eaa26', '109b3f6c', '1c97dd7c', 'af472687'],
              'Layla': ['55', '2656ccca', '8ec3c0d8', '72f035f8', 'fa03c149'], 'Lisa': ['56', '2a557add', '518a6840', '8bfa989d', '92b87c71'], 'LisaStudent': ['57', '37c70461', 'f30eece6', '5db2f8f4', 'd77ffc4f'],
              'Lynette': ['58', '98eb2db4', '39d89255', '42addacd', 'f828b5be'], 'Lyney': ['59', '6f7b7740', '09bcb0fd', 'd62090f5', '0df88f2e'], 'Mika': ['60', '1876e82e', '41760901', 'b8a027a1', '285f6696'],
              'Mona': ['61', '7a1dc890', 'd75308d8', 'b043715a', 'a8191396'], 'MonaCN': ['62', '515f3ce6', 'd5ad8084', 'bad2731b', 'e543af5d'], 'Nahida': ['63', '7106f05d', '9b13c166', 'de60b92f', '902b57ef'],
              'Navia': ['64', 'f4e09bd7', '7321d0b1', 'bc0e2536', '8a666020'], 'Neuvillette': ['65', 'cad3a022', 'f055eadd', 'f060f732', 'ea5c17ee'], 'Nilou': ['66', 'b2acc1df', '1e8a5e3c', 'fda8e783', '583fba29'],
              'Ningguang': ['67', 'f9e1b52b', 'ad75352c', '735eaea4', '1f0ab400'], 'NingguangOrchid': ['68', 'db37b198', 'c904f198', 'a8246d4a', '396aa3ec'], 'Noelle': ['69', 'd1384d15', '9cf0789e', '1517291d', '8f1eff2c'],
              'Qiqi': ['70', 'cad5bebb', '56057a2c', 'cf928b89', '85c5b5ed'], 'RaidenShogun': ['71', 'e48c61f3', '7a583c12', '1a495487', '0c37fc86'], 'Razor': ['72', '4662c505', '1b36c8c9', 'd34d79bc', '93e1752e'],
              'Rosaria': ['73', '748f40a5', '65ccd309', '4de959bd', '06b8fbf5'], 'RosariaCN': ['74', '59a1f8b1', 'bdca273e', 'a7bee046', '86e0d16b'], 'Sayu': ['75', 'c70b7fce', 'd26fddb8', '52457202', '9f8a009c'],
              'Sethos': ['76', '60d33d25', '2faea4e4', '495a9ec3', '71b6a523'], 'Shenhe': ['77', 'e44b58b5', '33a92492', '541cf273', '86c4f5ec'], 'ShenheFrostFlower': ['78', 'ee0980eb', '83a9116d', '263019b8', 'd36f368d'],
              'Shinobu': ['79', '7cfb62ea', 'ff16c309', '93ed7092', '7073386b'], 'Sucrose': ['80', 'b655c335', '06e86a68', '52230792', 'c43b5b80'], 'Thoma': ['81', '24ecd71a', 'b2155854', '1fb4b2dd', '1b428e0a'],
              'Tighnari': ['82', 'ed2e7d59', '69a807fc', 'c8b9f094', '4831b8f1'], 'TravelerBoy': ['83', 'c77e380b', '8ed7c5f0', '4dfdf2be', '517e5e7e'], 'TravelerGirl': ['84', '8239be13', 'e7612ed8', '8772fa81', '8d2c7c7c'],
              'Venti': ['85', '09a91a5c', '1afcf31d', 'a6823bb3', '6568ac68'], 'Wanderer': ['86', '0110e1c7', '6bba515c', 'a716d4f2', '798f0feb'], 'Wriothesley': ['87', 'aa6f1268', '9e62b4e7', '9f5dc53b', 'f7242288'],
              'Xiangling': ['88', '9427917d', '6bb79582', '2b663556', '29744879'], 'Xianyun': ['89', '39838e8f', '7f79ea6e', 'd853ccb4', '3e5e310f'], 'Xiao': ['90', '9464bf2d', 'ced409c1', '258ab074', '8ddd3ae9'],
              'Xingqiu': ['91', '25aed172', '82c97b1c', '8f0e9948', '4c25bd5f'], 'XingqiuBamboo': ['92', 'cc158a1e', '76df4025', '07c7c5b6', '41426386'], 'Xinyan': ['93', '76ed85f0', '97f78c9b', 'f4b3fc47', 'c07f3de3'],
              'Yae': ['94', '3a7f71f5', '5d09aa00', 'd9ee433a', '4aebeee0'], 'Yanfei': ['95', 'eb8b62d3', '776c5330', '3a67db3a', '145f48e9'], 'YaoYao': ['96', '293449d6', '6c14db37', '139a19fb', 'bea7a2f7'],
              'Yelan': ['97', 'c58c76f9', '82e14ea2', 'f6e01e3c', '428b836c'], 'Yoimiya': ['98', '65618289', '85777bb6', '40299082', 'c67e30fd'], 'YunJin': ['99', '221f052e', 'c632b8df', '65220c80', '1207d3e9'],
              'Zhongli': ['100', 'a75ba32e', '4c8480f5', 'f0a40042', 'eb3aaca2'], 'Emilie': ['101', '62679081', 'ad5364a7', '6325e18b', '6325e18b'], 'Sigewinne': ['102', 'c883a144', '072fe941', '1855ae41', 'defddf41']}


Mod_IDs = {
    'Albedo': 1,
    'Alhaitham': 1,
    'Aloy': 1,
    'Amber': 1,
    'AmberCN': 1,
    'Arlecchino': 1,
    'Ayaka': 1,
    'Ayato': 1,
    'Baizhu': 1,
    'Barbara': 1,
    'BarbaraSummertime': 1,
    'Beidou': 1,
    'Bennett': 1,
    'Candace': 1,
    'Charlotte': 1,
    'Chevreuse': 1,
    'Childe': 1,
    'Chiori': 1,
    'Chongyun': 1,
    'Clorinde': 1,
    'Collei': 1,
    'Cyno': 1,
    'Dehya': 1,
    'Diluc': 1,
    'DilucFlamme': 1,
    'Diona': 1,
    'Dori': 1,
    'Eula': 1,
    'Emilie': 1,
    'Faruzan': 1,
    'Fischl': 1,
    'FischlHighness': 1,
    'Freminet': 1,
    'Furina': 1,
    'GaMing': 1,
    'Ganyu': 1,
    'GanyuTwilight': 1,
    'Gorou': 1,
    'Heizou': 1,
    'HuTao': 1,
    'Itto': 1,
    'Jean': 1,
    'JeanCN': 1,
    'JeanSea': 1,
    'Kaeya': 1,
    'KaeyaSailwind': 1,
    'Kaveh': 1,
    'Kazuha': 1,
    'Keqing': 1,
    'KeqingOpulent': 1,
    'Kirara': 1,
    'Klee': 1,
    'KleeBlossomingStarlight': 1,
    'Kokomi': 1,
    'KujouSara': 1,
    'Layla': 1,
    'Lisa': 1,
    'LisaStudent': 1,
    'Lynette': 1,
    'Lyney': 1,
    'Mika': 1,
    'Mona': 1,
    'MonaCN': 1,
    'Nahida': 1,
    'Navia': 1,
    'Neuvillette': 1,
    'Nilou': 1,
    'Ningguang': 1,
    'NingguangOrchid': 1,
    'Noelle': 1,
    'Qiqi': 1,
    'RaidenShogun': 1,
    'Razor': 1,
    'Rosaria': 1,
    'RosariaCN': 1,
    'Sayu': 1,
    'Sethos': 1,
    'Shenhe': 1,
    'ShenheFrostFlower': 1,
    'Shinobu': 1,
    'Sigewinne': 1,
    'Sucrose': 1,
    'Thoma': 1,
    'Tighnari': 1,
    'TravelerBoy': 1,
    'TravelerGirl': 1,
    'Venti': 1,
    'Wanderer': 1,
    'Wriothesley': 1,
    'Xiangling': 1,
    'Xianyun': 1,
    'Xiao': 1,
    'Xingqiu': 1,
    'XingqiuBamboo': 1,
    'Xinyan': 1,
    'Yae': 1,
    'Yanfei': 1,
    'YaoYao': 1,
    'Yelan': 1,
    'Yoimiya': 1,
    'YunJin': 1,
    'Zhongli': 1
}


Variables = """; Mod Manager
global $Mod_Enabled = 0
global $ModID = {Mod_ID}
global $CharacterID = {Character_ID}

global $IncludedInMaxCount = 0
global $First_Run = 1

global $Resources_Set = 0

"""

Present_Section = """; Mod Manager
if $\\NuraThings\\ModManager\\CharacterModData\\Active_{Character_Name} == 1
    if $First_Run == 1
        pre $\\NuraThings\\ModManager\\first_run = 1
        $First_Run = 0
    endif

    if $\\NuraThings\\ModManager\\config_mode == 1
        if $\\NuraThings\\ModManager\\charSwap == 1
            $IncludedInMaxCount = 0
        endif

        if $IncludedInMaxCount == 0
            if $\\NuraThings\\ModManager\\currentCharMaxID < $ModID
                $\\NuraThings\\ModManager\\currentCharMaxID = $ModID
            endif
            $IncludedInMaxCount = 1
        endif
    endif

else if $IncludedInMaxCount == 1
    $IncludedInMaxCount = 0
    post $Resources_Set = 0
endif

if $\\NuraThings\\ModManager\\CharacterModData\\{Character_Name} == $ModID
    post $Mod_Enabled = 1
    
    if $Resources_Set == 0
        post run = CommandListSetResources
    endif

else
    post $Mod_Enabled = 0
    post $Resources_Set = 0
endif


"""



Character_Name = ''
Character_ID = 0

preserve_data = False

rabbit_path = ''
rabbit_namespace = ''

use_mod_name = True

reset_next = False

target_strings = ['match_priority', 'allow_duplicate_hash', 'match_first_index', 'match_index_count']


def get_sections(data):
    return re.findall(r'(\[.*\][^\[]*?\n\s*hash\s*=\s*[a-f0-9]{8}[\s\S]*?)(?=\s*(?:\s*;.*\n)*\s*\[)\s*', data+'[', re.IGNORECASE)


def parse_key_section(match):
    section_name, section_text = match  # Unpack the tuple

    # Extract conditions, key, type, and variables
    conditions = re.search(r'conditions? = ([^\n]+)', section_text, re.IGNORECASE)
    keys = re.findall(r'key\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    backs = re.findall(r'back\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    type_ = re.search(r'type = ([^\n]+)', section_text, re.IGNORECASE)
    variable_match = re.search(r'\$(\w+) = ([^\n]+)', section_text, re.IGNORECASE)

    conditions = conditions.group(1).strip() if conditions else None
    keys = " or ".join([key.strip() for key in keys])
    backs = " or ".join([back.strip() for back in backs])
    type_ = type_.group(1).strip() if type_ else None

    variable_name = variable_match.group(1).strip() if variable_match else None
    variable_value = variable_match.group(2).strip() if variable_match else None
    number_count = len(re.findall(r'\d+', variable_value)) if variable_value else 0

    return [section_name, keys, type_, variable_name, variable_value, number_count, conditions, backs]


def get_toggles(data):
    #return re.findall(r'\[(\w+)\]\s+condition\s*=\s*.*\s+key\s*=\s*(\d+)\s+type\s*=\s*(cycle|toggle)\s*\$(\w+)\s*=\s*((?:\d+,?)+)', data, re.IGNORECASE)
    pattern = pattern = r"""
\[(Key[^\]]*)\]              # Match and capture section header (e.g., [Key*])
(                            # Start of group to capture the section's content
(?:\n(?!\[)[^\n]*)*?         # Match lines within the section, excluding lines starting with [
)                            # End of group
(?=\n\[\w|\Z)              # Stop when a new section starts (next [) or at the end of the string
"""

    # Compile the regex pattern with VERBOSE flag (without DOTALL)
    compiled_pattern = re.compile(pattern, flags=re.VERBOSE | re.IGNORECASE)

    # Find all matches
    matches = compiled_pattern.findall(data+'[')
   # print(matches)
    results = [parse_key_section(match) for match in matches]

    return results


def collect_ini(folder_path):

    global Character_Name
    global Character_ID

    global preserve_data
    global reset_next

    global rabbit_path
    global rabbit_namespace

    global use_mod_name

    ini_files = []
    ini_paths = []

    if 'OutfitTracker.ini' in os.listdir(folder_path):
        rabbit_path = folder_path
        with open(os.path.join(folder_path, 'OutfitTracker.ini'), "r", encoding="utf-8") as f:
            lines = f.readlines()
            for line in lines:
                if 'namespace' in line:
                    rabbit_namespace = line.replace('namespace = ', '').replace('\n', '')
                    break
            f.close()


    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)

        if 'BufferValues' in file_path:
            continue

        if 'disabled' not in file_path.lower() and os.path.isdir(file_path):
            collect_ini(file_path)

        elif (os.path.splitext(filename)[1] == ".ini" and "desktop" not in filename.lower() and "ntuser" not in filename.lower()
              and 'disabled' not in filename.lower() and "backup" not in filename.lower()):
            ini_files.append(filename)
            ini_paths.append(file_path)


    for ini_file, ini_path in zip(ini_files, ini_paths):

        Sections = []
        Key_Conditions = []

        toggles = []

        if reset_next:
            RabbitThing = False
            rabbit_path = ''
            preserve_data = False
            rabbit_namespace = ''

        if not preserve_data:
            Character_Name = ''
            Character_ID = 0

        head, tail = os.path.split(folder_path)
        mod_name = tail
        if rabbit_path != '':
            head, tail = os.path.split(rabbit_path)
            mod_name = tail

        use_mod_name = True

        if rabbit_path != '' and rabbit_path in ini_path and 'OutfitTracker' not in ini_file:
            out_lines = []
            with open(os.path.join(folder_path, ini_file), "r+", encoding="utf-8") as f:
                data = f.read()
                for Chara in Characters:
                    if Characters[Chara][1] in data and Characters[Chara][2] in data and Characters[Chara][3] in data and Characters[Chara][4] in data:
                        Character_Name = Chara
                        Character_ID = Characters[Chara][0]
                        if mod_name is Chara+'Mod':
                            use_mod_name = False
                        preserve_data = True

                if 'Mod_Enabled' not in data and rabbit_namespace != '':
                    if not os.path.exists(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)):
                        with open(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file), "w",
                                  encoding="utf-8") as f2:
                            f2.write(data)
                            f2.close()
                            print(
                                f'''Created Backup - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
                    ''')
                    else:
                        print(
                            f'''Backup already Exists - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
                    ''')

                    f.seek(0)
                    lines = f.readlines()
                    for line in lines:
                        if 'condition = $active == 1 && $outfit == $outfitTag' in line:
                            line = line.replace('\n', '').replace('$active', '$\\'+rabbit_namespace+'\\active')
                            out_lines.append(f'''{line} && $\\{rabbit_namespace}\\Mod_Enabled == 1
''')

                        elif 'condition = $active == 1' in line:
                            line = line.replace('\n', '').replace('$active', '$\\'+rabbit_namespace+'\\active')
                            out_lines.append(f'''{line} && $\\{rabbit_namespace}\\Mod_Enabled == 1
''')

                        else:
                            out_lines.append(line)
                    f.truncate(0)
                    print(f'''Affected File - {ini_path}
''')
                    with open(os.path.join(folder_path, ini_file), "w", encoding="utf-8") as f:
                        f.writelines(out_lines)
                        f.close()
                else:
                    print(f'''Analyzed File - {ini_path}
                    ''')

                f.close()
                continue

        try:
            out_lines = []
            data = ''
            with open(os.path.join(folder_path, ini_file), "r+", encoding="utf-8") as f:
                data = f.read()

                toggles = get_toggles(data)

                if len(toggles) > 0:
                    print(toggles)
                    toggles_info = 'Toggle (Amount): Key(s) and Back(s)\n'
                    add_other_controls = False
                    for toggle in toggles:

                        if toggle[0] and toggle[1] and toggle[2] and toggle[4]:
                            if toggle[2] == 'hold':
                                add_other_controls = True

                            elif toggle[2] == 'toggle' or toggle[2] == 'cycle':
                                amount_of_toggles = 0
                                if toggle[2] == 'toggle':
                                    amount_of_toggles = 2
                                else:
                                    amount_of_toggles = toggle[5]
                                if toggle[0].replace('Key', '').capitalize() != toggle[3].capitalize():
                                    toggles_info += f'''\n{toggle[0].replace('Key', '').capitalize()}/{toggle[3].capitalize()} ({amount_of_toggles}): {toggle[1]}{" and "+toggle[7] if toggle[7] else ""}'''
                                else:
                                    toggles_info += f'''\n{toggle[3].capitalize()} ({amount_of_toggles}): {toggle[1]}{" and "+toggle[7] if toggle[7] else ""}'''

                    if add_other_controls:
                        toggles_info += '\n\n\nHold: Key(s)\n'
                        for toggle in toggles:
                            if (toggle[0] and toggle[1] and toggle[2] and toggle[4]) and (toggle[2] == 'hold'):
                                if toggle[0].replace('Key', '').capitalize() != toggle[3].capitalize():
                                    toggles_info += f'''\n{toggle[0].replace('Key', '').capitalize()}/{toggle[3].capitalize()}: {toggle[1]}'''
                                else:
                                    toggles_info += f'''\n{toggle[3].capitalize()}: {toggle[1]}'''

                    if toggles_info != 'Toggle (Amount) - Key\n':
                        with open(os.path.join(folder_path, 'Toggles.txt'), "w", encoding="utf-8") as ft:
                            ft.write(toggles_info)
                            ft.close()
                            print('Generated Toggles.txt inside - '+folder_path+'\n')

                og_data = data
                data_lines = data.splitlines()
                credits_string = ''
                if match := re.search(r'\[ResourceCreditInfo.*\][\s\S]*?data\s*=\s*\"(.*)\"', data, re.IGNORECASE):
                    credits_string = match.group(1)

                for condition_line in data_lines:
                    if 'condition = ' in condition_line and '$Mod_Enabled' not in condition_line:
                        if condition_line not in Key_Conditions:
                            Key_Conditions.append(condition_line)

                Sections = get_sections(data)

                RabbitThing = 'OutfitTracker' in ini_file

                if not RabbitThing:
                    for Chara in Characters:
                        if Characters[Chara][1] in data and Characters[Chara][2] in data and Characters[Chara][3] in data and Characters[Chara][4] in data:
                            Character_Name = Chara
                            Character_ID = Characters[Chara][0]
                            if mod_name is Chara + 'Mod':
                                use_mod_name = False
                else:
                    reset_next = True

                if 'global $ModID =' not in data and (RabbitThing or (Character_Name != '' and ('TextureOverride' in data or 'ShaderOverride' in data) and 'namespace = NuraThings' not in data and '$\\NuraThings\\SkillCounter' not in data)):

                    if len(Key_Conditions) > 0:
                        for condition in Key_Conditions:
                            if '$active' in condition or '$object_detected' in condition:
                                data = data.replace(condition, condition + ' && $Mod_Enabled', 1)
                            elif '$active' in data:
                                data = data.replace(condition, condition + ' && $active && $Mod_Enabled', 1)
                            else:
                                data = data.replace(condition, condition + ' && $Mod_Enabled', 1)

                    for Section in Sections:
                        OldSection = Section
                        PartsOfSection = Section.splitlines()
                        has_match_priority = False

                        max_index = -1

                        if 'match_priority' in Section or 'allow_duplicate_hash' in Section or 'match_first_index' in Section or 'match_index_count' in Section:
                            has_match_priority = True

                            for i, elem in enumerate(Section):
                                if any(target_string in str(elem) for target_string in target_strings):
                                    max_index = max(max_index, i)

                        HashID = [index for (index, item) in enumerate(PartsOfSection) if
                                  'hash' in item and ';' not in item and 'allow_duplicate_hash' not in item]

                        HashID = HashID[0]
                        Hash = PartsOfSection[HashID]

                        if not has_match_priority:
                            if '[TextureOverride' in Section:
                                Section = Section.replace(Hash, Hash + '\nmatch_priority = 0', 1)
                            elif '[ShaderOverride' in Section:
                                Section = Section.replace(Hash, Hash + '\nallow_duplicate_hash = True', 1)
                            PartsOfSection = Section.splitlines()

                        if 'if $Mod_Enabled' not in Section:
                            priority_index = max_index if max_index > -1 else HashID + 1

                            Section = Section.replace(PartsOfSection[priority_index],
                                                      PartsOfSection[priority_index] + '\nif $Mod_Enabled', 1)

                            # print(PartsOfSection, HashID)

                            depth = 0
                            indent = ' ' * 4
                            indented_section_lines = []

                            for line in Section.splitlines():

                                conditional = 0
                                first_word = line.strip().split(' ')[0].lower()

                                if first_word == 'if':
                                    depth += 1
                                    conditional = 1

                                elif first_word in ['else', 'elif']:
                                    conditional = 1

                                elif first_word == 'endif':
                                    depth -= 1

                                indented_section_lines.append(indent * (depth - conditional) + line.strip())


                            Section = Section.replace(Section, '\n'.join(indented_section_lines), 1)

                            #print('1', Section)
                            if RabbitThing and '$currentOutfit = $nextOutfit' in Section:
                                Section += '\nelse\n\t$currentOutfit = -1\nendif'
                            else:
                                Section += '\nendif'

                            if 'if $Mod_Enabled\nendif' in Section:
                                Section = Section.replace('if $Mod_Enabled\nendif', '')


                        data = data.replace(OldSection, Section, 1)

                    data += '\n[Constants]\n' + Variables.format(Character_ID=Character_ID, Mod_ID=Mod_IDs[Character_Name])
                    Mod_IDs[Character_Name] = Mod_IDs[Character_Name]+1

                    data += '\n[Present]\n' + Present_Section.format(Character_Name=Character_Name)

                    set_toggles = "Resource\\NuraThings\\ModManager\\ModToggles = ref ResourceModToggles unless_null"

                    if use_mod_name:
                        data += f'''
 
[ResourceModName]
type = Buffer
data = "{mod_name}"

'''
                    else:
                        data += f'''

[ResourceModName]
;type = Buffer
;data = ""

'''

                    if credits_string != '':
                        data += f'''[ResourceModAuthor]
type = Buffer
data = "{credits_string}"

'''
                    else:
                        data += f'''[ResourceModAuthor]
;type = Buffer
;data = ""

'''

                    data += f'''[ResourceModDesc]
;type = Buffer
;data = ""

[ResourceModLink]
;type = Buffer
;data = ""

[ResourceModLogo]
;filename = 

{"""[ResourceModToggles]
type = buffer
format = R8_UINT
filename = Toggles.txt""" if len(toggles) > 0 else ""}

[CommandListSetResources]
Resource\\NuraThings\\ModManager\\ModPath = ref ResourceModPath unless_null
Resource\\NuraThings\\ModManager\\ModName = ref ResourceModName unless_null
Resource\\NuraThings\\ModManager\\ModAuthor = ref ResourceModAuthor unless_null
Resource\\NuraThings\\ModManager\\ModDescription = ref ResourceModDesc unless_null
Resource\\NuraThings\\ModManager\\ModLink = ref ResourceModLink unless_null
Resource\\NuraThings\\ModManager\\ModLogo = ref ResourceModLogo unless_null

{set_toggles if len(toggles) > 0 else ""}

$Resources_Set = 1
'''

                    data += '\n[ResourceModPath]\ntype= Buffer\nformat = R8_UINT\nfilename = ModPath.txt'

                    with open(os.path.join(folder_path, 'ModPath.txt'), "w+", encoding="utf-8") as mp:
                        mp.write(ini_path)
                        mp.close()
                        print('Generated - '+os.path.join(folder_path, 'ModPath.txt')+'\n')

                    if data != og_data:
                        f.seek(0)
                        f.truncate(0)
                    f.close()

                if not os.path.exists(os.path.join(folder_path, 'DISABLED_ModManagerBackup_'+ini_file)):
                    with open(os.path.join(folder_path, 'DISABLED_ModManagerBackup_'+ini_file), "w", encoding="utf-8") as f:
                        f.write(og_data)
                        f.close()
                        print(f'''Created Backup - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
''')
                else:
                    print(f'''Backup already Exists - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
''')

                if data != og_data:
                    with open(os.path.join(folder_path, ini_file), "w", encoding="utf-8") as f:
                        f.write(data)
                        print(f'''Affected File - {ini_path}
''')
                        f.close()
                else:
                    print(f'''Analyzed File - {ini_path}
''')


        except Exception as e:
            print("Unable to open, skipping")
            print(f"Error: {e}")

def main():
    global Mod_IDs

    if os.path.exists(os.path.join(os.getcwd(), 'ModsIDs.json')):
        with open(os.path.join(os.getcwd(), 'ModsIDs.json'), 'r') as file:
            Mod_IDs = json.load(file)

    collect_ini(os.getcwd())

    with open(os.path.join(os.getcwd(), 'ModsIDs.json'), 'w+') as file:
        json.dump(Mod_IDs, file)
        print('\nGenerated ModsIDs.json inside - '+os.getcwd())


main()