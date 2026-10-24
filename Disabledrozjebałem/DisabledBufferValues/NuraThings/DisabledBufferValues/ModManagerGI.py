# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import os
import re
import json
from collections import defaultdict

# Characters = {'df65bb00': 'Albedo', '3ef08385': 'Alhaitham', '46de82f3': 'Aloy', 'a2ea4b2d': 'Amber', '557b2eff': 'AmberCN', '0107925f': 'Ayaka', 'b473c856': 'Ayato',
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
'Chasca': ['16', 'b5a29a7d', '980cee65', '399df744', 'cea113ae'], 'Chevreuse': ['17', '4d8d965a', '77208d51', '8e8fe0e3', '350c5b58'], 'Childe': ['18', '186eac84', '531d9358', 'fff25ec8', '7e7aeada'],
'Chiori': ['19', 'c8e25747', '65d5b68c', 'c4ed0dcd', 'af52cb39'], 'Chongyun': ['20', '489e3621', '0c6dd2d6', '2f997aab', '93136ff7'], 'Clorinde': ['21', '07f8ad68', 'd6371da1', 'f672845e', 'f0b6d3f1'],
'Collei': ['22', '348e58c4', '3da6f8c7', 'e5fe748c', '1b2f9d1b'], 'Cyno': ['23', '226f076e', 'af184471', '6867e0b8', '9ea96ce5'], 'Dehya': ['24', '9aeecbcb', '63e3e58e', '31ea99dd', '3feafd9a'],
'Diluc': ['25', '71625c4d', 'e16fa548', 'afb527f6', '6d0e22f0'], 'DilucFlamme': ['26', 'a2d909c8', 'a5323853', '105887c0', '16350d1b'], 'Diona': ['27', 'e8083f19', '740a72e3', '558b43fe', '9fb434ae'],
'Dori': ['28', '2a2a63ab', '04929496', 'b0c49997', '1339b941'], 'Emilie': ['29', '62679081', 'ad5364a7', '6325e18b', '31e21e6f'], 'Eula': ['30', '107ba6e7', '660399d1', '9ab68521', 'f8e35031'],
'Faruzan': ['31', '6162188c', 'faad3720', '1ed4dc04', '3ceab969'], 'Fischl': ['32', 'bf6aef4d', '6428104d', '0d1c1932', 'd451d8d8'], 'FischlHighness': ['33', '8f473224', 'ad6be7a1', 'dbd6a5c3', 'a800a294'],
'Freminet': ['34', 'd2bfc751', '6d40de64', '4443153c', '333aa56c'], 'Furina': ['35', '8294fe98', '045e580b', 'd8c43862', 'a327ea5e'], 'GaMing': ['36', 'b94ef036', 'b5eb19b6', 'cd9b5130', '968dba13'],
'Ganyu': ['37', 'a5169f1d', '1575ec63', '6f47a39d', 'cf27251f'], 'GanyuTwilight': ['38', '9b3f356e', 'cb283c86', '9a5c01d2', '5ff2f1d1'], 'Gorou': ['39', '3ce94cac', 'b2e57c84', 'f4db799d', 'a144269e'],
'Heizou': ['40', '51a75ba6', 'd4c9bab4', 'c121cffe', '889d1e64'], 'HuTao': ['41', 'dd16576c', '3de1efe2', '153dba3f', '51afdfcf'], 'Itto': ['42', '3e61a41f', 'be597118', 'f186e87b', '5bcab405'],
'Jean': ['43', '191af650', '115737ff', '3cb8153c', '1722136c'], 'JeanCN': ['44', '93bb2522', 'aad861e0', 'd159bf31', '0ffefb98'], 'JeanSea': ['45', '16fef1eb', '69c0c24e', 'ac801371', '3ffb0363'],
'Kachina': ['46', '888c4b7c', '8f29c0bb', '29ca2f46', '55af12ce'], 'Kaeya': ['47', '8a081f34', '2b3f575a', '763b60b9', 'fb2eff2a'], 'KaeyaSailwind': ['48', 'b9b77eff', '59f2a0f2', 'e026c9ae', '74dce34a'],
'Kaveh': ['49', 'b56fd424', '5966a63f', 'db2490d6', 'd09a3948'], 'Kazuha': ['50', '7c0c47b3', '356cdbde', '28a1fab0', '5f7534b6'], 'Keqing': ['51', '3aaf3e94', 'cbf1894b', '0bf8e621', '723848fe'],
'KeqingOpulent': ['52', '0d7e3cc5', '7c6fc8c3', '6f010b58', '52f78cb7'], 'Kirara': ['53', 'b57d7fe2', 'f6e9af7d', '01d54938', '33b3d6e5'], 'KiraraBoots': ['54', 'f8013ba9', '846979e2', '53a2502b', '596e8fe0'],
'Klee': ['55', 'dcd74904', '073c71f5', 'aec1d55e', 'c3448489'], 'KleeBlossomingStarlight': ['56', '0f5fedb4', '4cf8240a', '652497c2', '4d6c496b'], 'Kokomi': ['57', 'dde4750a', '74900c81', '7b61fb15', '4ed0c9f8'],
'KujouSara': ['58', 'b82eaa26', '109b3f6c', '1c97dd7c', 'af472687'], 'Layla': ['59', '2656ccca', '8ec3c0d8', '72f035f8', 'fa03c149'], 'Lisa': ['60', '2a557add', '518a6840', '8bfa989d', '92b87c71'],
'LisaStudent': ['61', '37c70461', 'f30eece6', '5db2f8f4', 'd77ffc4f'], 'Lynette': ['62', '98eb2db4', '39d89255', '42addacd', 'f828b5be'], 'Lyney': ['63', '6f7b7740', '09bcb0fd', 'd62090f5', '0df88f2e'],
'Mika': ['64', '1876e82e', '41760901', 'b8a027a1', '285f6696'], 'Mona': ['65', '7a1dc890', 'd75308d8', 'b043715a', 'a8191396'], 'MonaCN': ['66', '515f3ce6', 'd5ad8084', 'bad2731b', 'e543af5d'],
'Mualani': ['67', '03872d46', 'c511e979', 'bd92b322', 'b59d9219'], 'Nahida': ['68', '7106f05d', '9b13c166', 'de60b92f', '902b57ef'], 'Navia': ['69', 'f4e09bd7', '7321d0b1', 'bc0e2536', '8a666020'],
'Neuvillette': ['70', 'cad3a022', 'f055eadd', 'f060f732', 'ea5c17ee'], 'Nilou': ['71', 'b2acc1df', '1e8a5e3c', 'fda8e783', '583fba29'], 'NilouBreeze': ['72', '7d53d78f', '00439fbb', '49bede49', 'b976b848'],
'Ningguang': ['73', 'f9e1b52b', 'ad75352c', '735eaea4', '1f0ab400'], 'NingguangOrchid': ['74', 'db37b198', 'c904f198', 'a8246d4a', '396aa3ec'], 'Noelle': ['75', 'd1384d15', '9cf0789e', '1517291d', '8f1eff2c'],
'Qiqi': ['76', 'cad5bebb', '56057a2c', 'cf928b89', '85c5b5ed'], 'RaidenShogun': ['77', 'e48c61f3', '7a583c12', '1a495487', '0c37fc86'], 'Razor': ['78', '4662c505', '1b36c8c9', 'd34d79bc', '93e1752e'],
'Rosaria': ['79', '748f40a5', '65ccd309', '4de959bd', '06b8fbf5'], 'RosariaCN': ['80', '59a1f8b1', 'bdca273e', 'a7bee046', '86e0d16b'], 'Sayu': ['81', 'c70b7fce', 'd26fddb8', '52457202', '9f8a009c'],
'Sethos': ['82', '60d33d25', '2faea4e4', '495a9ec3', '71b6a523'], 'Shenhe': ['83', 'e44b58b5', '33a92492', '541cf273', '86c4f5ec'], 'ShenheFrostFlower': ['84', 'ee0980eb', '83a9116d', '263019b8', 'd36f368d'],
'Shinobu': ['85', '7cfb62ea', 'ff16c309', '93ed7092', '7073386b'], 'Sucrose': ['86', 'b655c335', '06e86a68', '52230792', 'c43b5b80'], 'Thoma': ['87', '24ecd71a', 'b2155854', '1fb4b2dd', '1b428e0a'],
'Tighnari': ['88', 'ed2e7d59', '69a807fc', 'c8b9f094', '4831b8f1'], 'TravelerBoy': ['89', 'c77e380b', '8ed7c5f0', '4dfdf2be', '517e5e7e'], 'TravelerGirl': ['90', '8239be13', 'e7612ed8', '8772fa81', '8d2c7c7c'],
'Venti': ['91', '09a91a5c', '1afcf31d', 'a6823bb3', '6568ac68'], 'Wanderer': ['92', '0110e1c7', '6bba515c', 'a716d4f2', '798f0feb'], 'Wriothesley': ['93', 'aa6f1268', '9e62b4e7', '9f5dc53b', 'f7242288'],
'Xiangling': ['94', '9427917d', '6bb79582', '2b663556', '29744879'], 'Xianyun': ['95', '39838e8f', '7f79ea6e', 'd853ccb4', '3e5e310f'], 'Xiao': ['96', '9464bf2d', 'ced409c1', '258ab074', '8ddd3ae9'],
'Xilonen': ['97', 'a4571ede', '4c2fa96d', 'd2562637', '5401abf4'], 'Xingqiu': ['98', '25aed172', '82c97b1c', '8f0e9948', '4c25bd5f'], 'XingqiuBamboo': ['99', 'cc158a1e', '76df4025', '07c7c5b6', '41426386'],
'Xinyan': ['100', '76ed85f0', '97f78c9b', 'f4b3fc47', 'c07f3de3'], 'Yae': ['101', '3a7f71f5', '5d09aa00', 'd9ee433a', '4aebeee0'], 'Yanfei': ['102', 'eb8b62d3', '776c5330', '3a67db3a', '145f48e9'],
'YaoYao': ['103', '293449d6', '6c14db37', '139a19fb', 'bea7a2f7'], 'Yelan': ['104', 'c58c76f9', '82e14ea2', 'f6e01e3c', '428b836c'], 'Yoimiya': ['105', '65618289', '85777bb6', '40299082', 'c67e30fd'],
'YunJin': ['106', '221f052e', 'c632b8df', '65220c80', '1207d3e9'], 'Zhongli': ['107', 'a75ba32e', '4c8480f5', 'f0a40042', 'eb3aaca2'], 'Citlali': ['108', '362dc30c', 'f81f893c', '3e939d2e', '3421fed9'],
'Mavuika': ['109', '80b13a2f', '43f8af29', '4e654846', '3af262c1']
}

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
    'Chasca': 1,
    'Chevreuse': 1,
    'Childe': 1,
    'Chiori': 1,
    'Chongyun': 1,
    'Citlali': 1,
    'Clorinde': 1,
    'Collei': 1,
    'Cyno': 1,
    'Dehya': 1,
    'Diluc': 1,
    'DilucFlamme': 1,
    'Diona': 1,
    'Dori': 1,
    'Emilie': 1,
    'Eula': 1,
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
    'Kachina': 1,
    'Kaeya': 1,
    'KaeyaSailwind': 1,
    'Kaveh': 1,
    'Kazuha': 1,
    'Keqing': 1,
    'KeqingOpulent': 1,
    'Kirara': 1,
    'KiraraBoots': 1,
    'Klee': 1,
    'KleeBlossomingStarlight': 1,
    'Kokomi': 1,
    'KujouSara': 1,
    'Layla': 1,
    'Lisa': 1,
    'LisaStudent': 1,
    'Lynette': 1,
    'Lyney': 1,
    'Mavuika': 1,
    'Mika': 1,
    'Mona': 1,
    'MonaCN': 1,
    'Mualani': 1,
    'Nahida': 1,
    'Navia': 1,
    'Neuvillette': 1,
    'Nilou': 1,
    'NilouBreeze': 1,
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
    'Xilonen': 1,
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
global $ModManager_First_Run = 1

global $Resources_Set = 0
"""

Present_Section = """; Mod Manager
if $\\NuraThings\\ModManager\\CharacterModData\\Active_{Character_Name} == 1
    if $ModManager_First_Run == 1
        pre $\\NuraThings\\ModManager\\first_run = 1
        $ModManager_First_Run = 0
    endif

    if $\\NuraThings\\ModManager\\config_mode == 1
        if $\\NuraThings\\ModManager\\charSwap == 1
            $IncludedInMaxCount = 0
            $Resources_Set = 0
        endif

        if $IncludedInMaxCount == 0
            if $\\NuraThings\\ModManager\\currentCharMaxID < $ModID
                $\\NuraThings\\ModManager\\currentCharMaxID = $ModID
            endif
            $IncludedInMaxCount = 1
        endif
        
        if $\\NuraThings\\ModManager\\leftID == $ModID || $\\NuraThings\\ModManager\\middleID == $ModID || $\\NuraThings\\ModManager\\rightID == $ModID
            if $\\NuraThings\\ModManager\\leftID == $ModID
                x79 = -0.875
                z79 = 2.5
            endif

            if $\\NuraThings\\ModManager\\middleID == $ModID
                x79 = 0.0
                z79 = 2.25
            endif

            if $\\NuraThings\\ModManager\\rightID == $ModID
                x79 = 0.875
                z79 = 2.5
            endif
            
            if $\\NuraThings\\ModManager\\gallery_mode
                clear = ps-u3
                clear = vs-t0
                clear = vs-t1
                clear = ib
                clear = ps-t12
                run = CustomShaderDrawModel
            endif
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

gallery_resources = ''


import regex
from collections import defaultdict




def find_if_blocks(text):
    Nest_Layers = 0
    new_lines = []

    lines = text.splitlines()

    for line in lines:

        lower_line = line.lower()
        #print(f"{Nest_Layers} - {line}")
        if ';' not in line and lower_line.strip().startswith('if'):
            Nest_Layers += 1
            new_lines.append(line)
        elif ';' not in line and lower_line.strip().startswith('endif'):
            Nest_Layers -= 1
            new_lines.append(line)
        elif Nest_Layers > 0:
            new_lines.append(line)

    return new_lines



def get_drawindexed(ini_data, command_lists):
    # Updated pattern to capture sections up to the next line starting with `[`
    section_pattern = r"(\[TextureOverride[^\]]+\][\s\S]*?)(?=^\[|\Z)"
    drawindexed_pattern = r"^\s*(drawindexed\s*=\s*(auto|[\d,\s]+))"
    if_block_pattern = r"(?s)(if.*?(?:(?R).*?)?endif)"

    # Extract all sections
    sections = re.findall(section_pattern, ini_data, re.MULTILINE)

    # Dictionary to store each section's drawindexed and if blocks
    section_data = defaultdict(dict)

    # Process each section
    for section in sections:
        # Extract the section header
        header = re.match(r"^\[([^\]]+)\]", section)
        if header:
            section_name = header.group(1)
        else:
            continue  # Skip if header not found

        # Extract all if blocks to separate them
        if_blocks = find_if_blocks(section)
        #if_blocks = re.findall(if_block_pattern, section, re.DOTALL)

        # Remove if blocks temporarily to capture only top-level drawindexed commands

        #section_without_if_blocks = section.replace("\n".join(if_blocks), '')

        out_lines = []
        lines = section.splitlines()
        for line in lines:
            if line in if_blocks:
                continue
            out_lines.append(line)

        section_without_if_blocks = "\n".join(out_lines)

        # Extract standalone drawindexed commands (outside if blocks)
        standalone_drawindexed = [match[0] for match in re.findall(drawindexed_pattern, section_without_if_blocks, re.MULTILINE)]
        #print(standalone_drawindexed)
        # Store data in dictionary
        section_data[section_name] = {
            "header": section_name,
            "standalone_drawindexed": standalone_drawindexed,
            "if_blocks": if_blocks
        }


    draw_command_list = ''

    for section_lines in sections:
        out_lines = ''
        #print(section_lines)

        section = section_data[section_lines.splitlines()[0].replace('[', '').replace(']', '')]
        #print(section_lines)
        for line in section_lines.splitlines():
            #print("AAAA", section)
            #for if_block in section['if_blocks']:
            #    out_lines = section_lines.replace(if_block, '')
    #
            #for drawindexed in section['standalone_drawindexed']:
            #    out_lines = section_lines.replace(drawindexed, '')
            if any(line.strip() == item.strip() for item in section['if_blocks']):
                continue
            if any(line.strip() == item.strip() for item in section['standalone_drawindexed']):
                continue

            out_lines += line+'\n'

        if len(section['standalone_drawindexed']) > 0 or len(section['if_blocks']) > 0:
            out_lines += (f"run = CommandList{section['header']}\n\n\n")

            # Create a new list to store the lines for draw_command_list
            draw_command_list += f"\n[CommandList{section['header']}]\n"

            # Check if 'drawindexed = auto' is in standalone_drawindexed
            if any(line.strip() == "drawindexed = auto" for line in section['standalone_drawindexed']):
                # Add 'drawindexed = auto' 5 times before other lines
                draw_command_list += "\n".join(["drawindexed = auto"] * 5) + '\n'
            else:
                draw_command_list += "".join(section['standalone_drawindexed'])
            # Append the rest of the standalone_drawindexed and if_blocks to draw_command_list
            draw_command_list += '\n'.join(section['if_blocks']) + '\n'

        ini_data = ini_data.replace(section_lines, out_lines)
       #"".join(out_lines))

    #ini_data = "\n".join(out_lines)+"\n\n\n"
    for command in command_lists[:]:  # Use a copy of the list to avoid modification during iteration
        if command in draw_command_list:
                continue
        draw_command_list += f"\n[{command}]\ndrawindexed = auto\ndrawindexed = auto\ndrawindexed = auto" \
                             f"\ndrawindexed = auto\ndrawindexed = auto\n\n"

    ini_data += draw_command_list
   # print(ini_data, draw_command_list)

    return ini_data


def generate_default_resources(new_sections):
    path = os.path.join(os.getcwd(), r'BufferValues\NuraThings\ModManager\DefaultResources.Ini')

    with open(path, 'r+') as ini_file:
        data = ini_file.read()
        #ini_file.write("namespace = NuraThings\\ModManager\\DefaultResources\n")
        for section in new_sections:
            if section not in data:
                ini_file.write(section + "\n")


def prioritize_positions(res_dict, model_name):
    # Attempt to find the prioritized resources
    positions = res_dict.get('Position', [])
    # First priority: Resource{Character}Position
    position_priority = f"Resource{model_name}Position"
    if position_priority in positions:
        return position_priority

    # Second priority: Resource{Character}PositionBase
    position_base_priority = f"Resource{model_name}PositionBase"
    if position_base_priority in positions:
        return position_base_priority

    # Fall back to the first available Position if none of the priorities match
    if positions:
        return positions[0]

    # If no positions are available, return None or handle as needed
    return None


def get_matching_resource(results, target_variable):
    matching_resource = None

    for result in results:
        # Check if the target_variable is part of the ps-t1_resource in the result
        if target_variable in result.get("ps-t1_resource", ""):
            matching_resource = result["ps-t1_resource"]
            break  # Stop at the first match

    return matching_resource


def handle_resources(data, pst1):
    global gallery_resources

    command_lists = []

    new_sections = []
    resources = defaultdict(dict)

    # Regex to match Resource sections with optional suffixes
    pattern = re.compile(
        r"\[(Resource(?P<name>[\w]+)(?P<suffix>\.\d+)?)\](?:\s*\n)"
        r"(type\s*=\s*(?P<type>\w+)\s*)?"
        r"(format\s*=\s*(?P<format>DXGI_FORMAT_\w+)\s*)?"
        r"(stride\s*=\s*(?P<stride>\d+)\s*)?"
        r"(filename\s*=\s*(?P<filename>[^\s]+))",
        re.MULTILINE
    )

    models = []
    pattern2 = r'\[Resource(?P<name>\w+)Position(\.\d+)?\]'

    # Collect model names
    matches = re.finditer(pattern2, data)
    for match in matches:
        if match.group('name') not in models:
            models.append(match.group('name'))

    # Process each resource match
    for match in pattern.finditer(data):
        result = match.groupdict()
        name = result["name"]
        suffix = result["suffix"] or ""
        prefix_key = ""

        if 'Face' in name:
            continue

        #print("NAM", match)"Position" in name or
        if "Texcoord" in name:
            og_section = match.group(0)
            modified_section = og_section
            modified_section = re.sub(r"type\s*=\s*Buffer", "type = StructuredBuffer", modified_section)
            modified_section = re.sub(r"(filename\s*=)", "bind_flags = SHADER_RESOURCE\n\\1", modified_section)
            data = data.replace(og_section, modified_section)
        # Determine the model prefix to use
        for model in models:
            if model in name:
                prefix_key = model

        # Store resources in the dictionary
        if prefix_key:
            # Helper function to check uniqueness, ignoring the suffix
            def is_unique(resource_list, new_item):
                # Strip suffix from the new item
                base_name = re.sub(r'\.\d+$', '', new_item)
                # Check if a similar item already exists in the list
                return all(re.sub(r'\.\d+$', '', existing) != base_name for existing in resource_list)

            # Append resources only if unique (ignoring suffix)
            if "IB" in name:
                if is_unique(resources[prefix_key].setdefault("IB", []), f"Resource{name}{suffix}"):
                    resources[prefix_key]["IB"].append(f"Resource{name}{suffix}")
            elif "Diffuse" in name:
                if is_unique(resources[prefix_key].setdefault("Diffuse", []), f"Resource{name}{suffix}"):
                    resources[prefix_key]["Diffuse"].append(f"Resource{name}{suffix}")
            elif "Position" in name:
                if is_unique(resources[prefix_key].setdefault("Position", []), f"Resource{name}{suffix}"):
                    resources[prefix_key]["Position"].append(f"Resource{name}{suffix}")
            elif "Texcoord" in name:
                if is_unique(resources[prefix_key].setdefault("Texcoord", []), f"Resource{name}{suffix}"):
                    resources[prefix_key]["Texcoord"].append(f"Resource{name}{suffix}")

    output_str = ''

    is_VD_Navia = 'Virgin_Destroyer_Navia_Texture_Edit_Menu' in data

    # Iterate through the resources and construct new sections
    for model, res_dict in resources.items():
       # print("B", res_dict)
        missing_pairs = find_missing_pairs(res_dict)
        existing_pairs = find_existing_pairs(res_dict)
        #print(f"Missing pairs for {model}: {missing_pairs}")  # Debug print
        #print(res_dict)
        #print("ARARA", missing_pairs, existing_pairs, res_dict)
        prioritized_position = prioritize_positions(res_dict, prefix_key)
        texcoord_list = res_dict.get('Texcoord', [])

        output_str += f"vs-t0 = copy {prioritized_position}\n"
        output_str += f"vs-t1 = {texcoord_list[0]}\n\n"

        for ib, diffuse in existing_pairs:
            # Remove optional .Number suffix from names
            #print("ARA", ib, diffuse, existing_pairs)

            diffuse_clean = re.sub(r"\.\d+$", "", diffuse).replace("Resource", "").replace("Diffuse", "")

            matching_resource = get_matching_resource(pst1, diffuse_clean)
            if matching_resource:
                diffuse = matching_resource

            if is_VD_Navia and diffuse == 'ResourceNaviaBodyDiffuse':
                diffuse = 'ResourceNaviaDressDiffuse'

            output_str += f"ib = {ib}\n"
            output_str += f"ps-t12 = {diffuse}\n\n"
            output_str += f"run = CommandListTextureOverride{diffuse_clean}\n" \
                          f"run = CommandListTextureOverride{diffuse_clean}\n" \
                          f"run = CommandListTextureOverride{diffuse_clean}\n" \
                          f"run = CommandListTextureOverride{diffuse_clean}\n" \
                          f"run = CommandListTextureOverride{diffuse_clean}\n\n"

        for part_name, missing_type in missing_pairs:
            part_name_clean = re.sub(r"\.\d+$", "", part_name.replace('Resource', ''))

            if missing_type == "IB":
                part_name += 'Diffuse'

                matching_resource = get_matching_resource(pst1, part_name)
                if matching_resource:
                    part_name = matching_resource

                output_str += (
                    f"ib = Resource\\NuraThings\\ModManager\\DefaultResources\\{part_name_clean}IB\n"
                    f"ps-t12 = {part_name}\n\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n\n"
                )
            elif missing_type == "Diffuse":
                part_name += 'IB'
                output_str += (
                    f"ib = {part_name}\n"
                    f"ps-t12 = Resource\\NuraThings\\ModManager\\DefaultResources\\{part_name_clean}Diffuse\n\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n"
                    f"run = CommandListTextureOverride{part_name_clean}\n\n"
                )

        #print(output_str)
        gallery_resources = output_str

        pattern = r"CommandListTextureOverride\w+"

        command_lists = []
        # Use re.findall() to find all matches of the pattern
        command_lists = re.findall(pattern, gallery_resources)

        for part_name, missing_type in missing_pairs:
            part_name = part_name.replace('Resource', '')
            hash_value, match_first_index = extract_section_and_hash(data, part_name)

            #print(f"Extracted for {part_name}: hash={hash_value}, match_first_index={match_first_index}")  # Debug print
           #print("HS", hash_value, match_first_index, part_name)
            if hash_value and match_first_index:
                new_section = create_new_section(part_name, hash_value, match_first_index, missing_type)
                new_sections.append(new_section)
                #print(part_name, missing_type)
                # Initialize the resource if missing
                resource_name = f"Resource{part_name}{missing_type}"
                if missing_type == "IB":
                    new_sections.append(f"if {resource_name} == null\n    {resource_name} = copy IB\nendif\n\n")
                elif missing_type == "Diffuse":
                    new_sections.append(f"\nif {resource_name} == null\n"
                                        f"\tif ps == 037730.0 || ps == 037730.1\n"
                                        f"\t\t{resource_name} = copy ps-t1\n"
                                        f"\telse\n"
                                        f"\t\t{resource_name} = copy ps-t0\n"
                                        f"\tendif\n"
                                        f"endif\n")

    # Debug: Print new sections to be added
    #print("New Sections to be Added:")
    #for section in new_sections:
    #    print(section)

    # Write new sections to the INI file
    if new_sections:
        generate_default_resources(new_sections)
    #else:
    #    print("No new sections to add.")

    return data, command_lists


def find_existing_pairs(res_dict):
    pairs = []
    # Get lists of IB and Diffuse resources
    ib_resources = res_dict.get("IB", [])
    diffuse_resources = res_dict.get("Diffuse", [])

    # Create a set of base names for the IB and Diffuse resources
    ib_base_names = {name.replace('IB', '') for name in ib_resources}
    diffuse_base_names = {name.replace('Diffuse', '') for name in diffuse_resources}

    # Find common base names indicating existing pairs
    common_base_names = ib_base_names.intersection(diffuse_base_names)

    # Collect pairs of IB and Diffuse resources
    for base_name in common_base_names:
        ib_name = f"{base_name}IB"
        if '.0IB' in ib_name:
            ib_name = ib_name.replace('.0IB', 'IB.0')
        diffuse_name = f"{base_name}Diffuse"
        if '.0Diffuse' in diffuse_name:
            diffuse_name = diffuse_name.replace('.0Diffuse', 'Diffuse.0')
        pairs.append((ib_name, diffuse_name))

    return pairs


def find_missing_pairs(res_dict):
    missing = []
    # Get lists of IB and Diffuse resources
    ib_resources = res_dict.get("IB", [])
    diffuse_resources = res_dict.get("Diffuse", [])

    # Create a set of base names for the IB and Diffuse resources
    ib_base_names = {name.replace('IB', '') for name in ib_resources}
    diffuse_base_names = {name.replace('Diffuse', '') for name in diffuse_resources}

    # Check for missing Diffuse resources for each IB resource
    for ib_name in ib_base_names:
        #print("IB", ib_name, diffuse_resources)

        if '.0' in ib_name:
            ib_name = ib_name.replace('.0', 'Diffuse.0')

            if ib_name not in diffuse_resources:
                missing.append((ib_name, "Diffuse"))

        elif ib_name + "Diffuse" not in diffuse_resources:
            missing.append((ib_name, "Diffuse"))



    # Check for missing IB resources for each Diffuse resource
    for diffuse_name in diffuse_base_names:
        #print("Diffuse", diffuse_name, ib_resources)

        if '.0' in diffuse_name:
            diffuse_name = diffuse_name.replace('.0', 'IB.0')

            if diffuse_name not in ib_resources:
                missing.append((diffuse_name, "IB"))

        elif diffuse_name + "IB" not in ib_resources:
            missing.append((diffuse_name, "IB"))

    return missing


def extract_section_and_hash(data, part_name):
    # Build the section name to search for
    section_name = f"TextureOverride{part_name}"
    #print(f"Looking for section: {section_name}")  # Debug print

    # Search for the section in the provided data
    section_pattern = re.compile(rf"\[{section_name}\](.*?)\n\s*\[", re.DOTALL)
    match = section_pattern.search(data)

    if match:
        section_content = match.group(1).strip()
        #print(f"Found section content: {section_content}")  # Debug print

        # Extract the hash and match_first_index
        hash_pattern = re.search(r"hash\s*=\s*([^\s;]+)", section_content)
        match_first_index_pattern = re.search(r"match_first_index\s*=\s*([^\s;]+)", section_content)

        # Use the found hash and match_first_index, default to None or 0 if not found
        hash_value = hash_pattern.group(1) if hash_pattern else None
        match_first_index = match_first_index_pattern.group(1) if match_first_index_pattern else 0
        #print("SS", hash_value, match_first_index)
        return hash_value, match_first_index

    # Return None, None if the section is not found
    return None, None


def create_new_section(part_name, hash_value, match_first_index, missing_type):
    # Determine the section name based on the missing type
    section_name = f"TextureOverride{part_name}"

    # Create the new section
    new_section = (
        f"[Resource{part_name}{missing_type}]\n\n"
        f"[{section_name}]\n"
        f"hash = {hash_value}\n"
        f"match_priority = -100\n"
        f"match_first_index = {match_first_index}\n"
    )

    return new_section


def get_sections(data):

    sections = re.findall(r'(\[.*\][^\[]*?\n\s*hash\s*=\s*[a-f0-9]{8}[\s\S]*?)(?=\s*(?:\s*;.*\n)*\s*\[)\s*', data + '[',
                      re.IGNORECASE)

    # Filter sections based on the presence of ps-t1 and ps-t2 tags
    results = []
    for section in sections:
        ps_t0 = re.search(r'ps-t0\s*=\s*(Resource\w+)', section)
        ps_t1 = re.search(r'ps-t1\s*=\s*(Resource\w+)', section)
        ps_t2 = re.search(r'ps-t2\s*=\s*(Resource\w+)', section)

        # Check if both ps-t1 and ps-t2 exist
        if ps_t1 and ps_t2:
            # Capture the section name and ps-t1 resource
            section_name = re.search(r'\[(.*?)\]', section).group(1)
            results.append({
                "section": section_name,
                "ps-t1_resource": ps_t1.group(1)
            })

    return sections, results

def parse_key_section(match):
    section_name, section_text = match  # Unpack the tuple

    # Extract conditions, key, type, and variables
    conditions = re.search(r'conditions?\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    keys = re.findall(r'key\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    backs = re.findall(r'back\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    type_ = re.search(r'type\s*=\s*([^\n]+)', section_text, re.IGNORECASE)

    # Remove the condition line from section_text to avoid capturing its variables
    section_text_no_condition = re.sub(r'conditions?\s*=\s*([^\n]+)', '', section_text, flags = re.IGNORECASE)

    # Match the first uncommented variable declaration (ignoring lines starting with ;)
    variable_match = re.search(r'^\s*\$(\w+)\s*=\s*([^\n]+)', section_text_no_condition, re.IGNORECASE | re.MULTILINE)

    conditions = conditions.group(1).strip() if conditions else None
    keys = " or ".join([key.strip() for key in keys]) if keys else None
    backs = " or ".join([back.strip() for back in backs]) if backs else None
    type_ = type_.group(1).strip() if type_ else None

    variable_name = variable_match.group(1).strip() if variable_match else None
    variable_value = variable_match.group(2).strip() if variable_match else None
    number_count = len(re.findall(r'\d+', variable_value)) if variable_value else 0

    return [section_name, keys, type_, variable_name, variable_value, number_count, conditions, backs]


def get_toggles(data):
    pattern = r"""
    \[(Key[^\]]*)\]              # Match and capture section header (e.g., [Key*])
    (                            # Start of group to capture the section's content
    (?:\n(?!\[)[^\n]*)*?         # Match lines within the section, excluding lines starting with [
    )                            # End of group
    (?=\n\[\w|\Z)                # Stop when a new section starts (next [) or at the end of the string
    """

    # Compile the regex pattern with VERBOSE flag (without DOTALL)
    compiled_pattern = re.compile(pattern, flags = re.VERBOSE | re.IGNORECASE)

    # Find all matches
    matches = compiled_pattern.findall(data + '[')

    # Parse each matched section
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

    global gallery_resources

    ini_files = []
    ini_paths = []

    if 'OutfitTracker.ini' in os.listdir(folder_path):
        rabbit_path = folder_path
        with open(os.path.join(folder_path, 'OutfitTracker.ini'), "r", encoding = "utf-8") as f:
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

        elif (os.path.splitext(filename)[
                  1] == ".ini" and "desktop" not in filename.lower() and "ntuser" not in filename.lower()
              and 'disabled' not in filename.lower() and "backup" not in filename.lower()):
            ini_files.append(filename)
            ini_paths.append(file_path)

    for ini_file, ini_path in zip(ini_files, ini_paths):

        gallery_resources = ''

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
            with open(os.path.join(folder_path, ini_file), "r+", encoding = "utf-8") as f:
                data = f.read()

                for Chara in Characters:
                    if Characters[Chara][1] in data and Characters[Chara][2] in data and Characters[Chara][
                        3] in data and Characters[Chara][4] in data:
                        Character_Name = Chara
                        Character_ID = Characters[Chara][0]
                        if mod_name is Chara + 'Mod':
                            use_mod_name = False
                        preserve_data = True

                if 'Mod_Enabled' not in data and rabbit_namespace != '':
                    if not os.path.exists(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)):
                        with open(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file), "w",
                                  encoding = "utf-8") as f2:
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
                            line = line.replace('\n', '').replace('$active', '$\\' + rabbit_namespace + '\\active')
                            out_lines.append(f'''{line} && $\\{rabbit_namespace}\\Mod_Enabled == 1
''')

                        elif 'condition = $active == 1' in line:
                            line = line.replace('\n', '').replace('$active', '$\\' + rabbit_namespace + '\\active')
                            out_lines.append(f'''{line} && $\\{rabbit_namespace}\\Mod_Enabled == 1
''')

                        else:
                            out_lines.append(line)
                    f.truncate(0)
                    print(f'''Affected File - {ini_path}
''')
                    with open(os.path.join(folder_path, ini_file), "w", encoding = "utf-8") as f:
                        f.writelines(out_lines)
                        f.close()
                else:
                    print(f'''Analyzed File - {ini_path}
                    ''')

                f.close()
                continue

    #    try:
        out_lines = []
        data = ''
        with open(os.path.join(folder_path, ini_file), "r+", encoding = "utf-8") as f:
            data = f.read()
            toggles = get_toggles(data)

            if len(toggles) > 0:
                #print(toggles)
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
                                toggles_info += f'''\n{toggle[0].replace('Key', '').capitalize()}/{toggle[3].capitalize()} ({amount_of_toggles}): {toggle[1]}{" and " + toggle[7] if toggle[7] else ""}'''
                            else:
                                toggles_info += f'''\n{toggle[3].capitalize()} ({amount_of_toggles}): {toggle[1]}{" and " + toggle[7] if toggle[7] else ""}'''

                if add_other_controls:
                    toggles_info += '\n\n\nHold: Key(s)\n'
                    for toggle in toggles:
                        if (toggle[0] and toggle[1] and toggle[2] and toggle[4]) and (toggle[2] == 'hold'):
                            if toggle[0].replace('Key', '').capitalize() != toggle[3].capitalize():
                                toggles_info += f'''\n{toggle[0].replace('Key', '').capitalize()}/{toggle[3].capitalize()}: {toggle[1]}'''
                            else:
                                toggles_info += f'''\n{toggle[3].capitalize()}: {toggle[1]}'''

                if toggles_info != 'Toggle (Amount) - Key\n':
                    with open(os.path.join(folder_path, 'Toggles.txt'), "w", encoding = "utf-8") as ft:
                        ft.write(toggles_info)
                        ft.close()
                        print('Generated Toggles.txt inside - ' + folder_path + '\n')

            og_data = data

            data_lines = data.splitlines()
            credits_string = ''
            if match := re.search(r'\[ResourceCreditInfo.*\][\s\S]*?data\s*=\s*\"(.*)\"', data, re.IGNORECASE):
                credits_string = match.group(1)

            for condition_line in data_lines:
                if 'condition = ' in condition_line and '$Mod_Enabled' not in condition_line:
                    if condition_line not in Key_Conditions:
                        Key_Conditions.append(condition_line)

            RabbitThing = 'OutfitTracker' in ini_file

            if not RabbitThing:
                for Chara in Characters:
                    if Characters[Chara][1] in data and Characters[Chara][2] in data and Characters[Chara][
                        3] in data and Characters[Chara][4] in data:
                        Character_Name = Chara
                        Character_ID = Characters[Chara][0]
                        if mod_name is Chara + 'Mod':
                            use_mod_name = False
            else:
                reset_next = True

            if 'global $ModID =' not in data and (RabbitThing or (Character_Name != '' and (
                    'TextureOverride' in data or 'ShaderOverride' in data) and 'namespace = NuraThings' not in data and '$\\NuraThings\\SkillCounter' not in data)):

                Sections, Sections30 = get_sections(data)

                if not RabbitThing:
                    data, command_lists = handle_resources(data, Sections30)
                    data = get_drawindexed(data, command_lists)

                if len(Key_Conditions) > 0:
                    for condition in Key_Conditions:
                        if '$active' in condition or '$object_detected' in condition:
                            data = data.replace(condition, condition + ' && $Mod_Enabled')
                        elif '$active' in data:
                            data = data.replace(condition, condition + ' && $active && $Mod_Enabled')
                        else:
                            data = data.replace(condition, condition + ' && $Mod_Enabled')

                Sections, Sections30 = get_sections(data)

                print(Sections30)
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

                        # print('1', Section)
                        if RabbitThing and '$currentOutfit = $nextOutfit' in Section:
                            Section += '\nelse\n\t$currentOutfit = -1\nendif'
                        else:
                            Section += '\nendif'

                        if 'if $Mod_Enabled\nendif' in Section:
                            Section = Section.replace('if $Mod_Enabled\nendif', '')

                    data = data.replace(OldSection, Section, 1)

                data += '\n[Constants]\n' + Variables.format(Character_ID = Character_ID,
                                                             Mod_ID = Mod_IDs[Character_Name])
                Mod_IDs[Character_Name] = Mod_IDs[Character_Name] + 1

                data += '\n[Present]\n' + Present_Section.format(Character_Name = Character_Name)

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


[ResourceDMap]
type = RWTexture2D
format = R32_FLOAT
width = 1920
height = 1080
array = 1
msaa = 1

[CustomShaderDrawModel]
run = BuiltInCommandListUnbindAllRenderTargets

cs = Mods/BufferValues/NuraThings/Shaders/DrawMesh.hlsl
hs = null
ds = null
gs = null
vs = Mods/BufferValues/NuraThings/Shaders/DrawMesh.hlsl
ps = Mods/BufferValues/NuraThings/Shaders/DrawMesh.hlsl

o0 = set_viewport bb

if $\\NuraThings\\ModManager\\gallery_draw_count < 3
    clear = ResourceDMap
    $\\NuraThings\\ModManager\\gallery_draw_count = $\\NuraThings\\ModManager\\gallery_draw_count+1
endif

ps-u3 = ResourceDMap

blend = ADD SRC_ALPHA INV_SRC_ALPHA
topology = triangle_list

fill = Solid
cull = Back
front = Clockwise

'''+gallery_resources+'''

'''

                data += '\n[ResourceModPath]\ntype= Buffer\nformat = R8_UINT\nfilename = ModPath.txt'

                with open(os.path.join(folder_path, 'ModPath.txt'), "w+", encoding = "utf-8") as mp:
                    mp.write(ini_path)
                    mp.close()
                    print('Generated - ' + os.path.join(folder_path, 'ModPath.txt') + '\n')

                if data != og_data:
                    f.seek(0)
                    f.truncate(0)
                f.close()

            if not os.path.exists(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)):
                with open(os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file), "w",
                          encoding = "utf-8") as f:
                    f.write(og_data)
                    f.close()
                    print(f'''Created Backup - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
''')
            else:
                print(
                    f'''Backup already Exists - {os.path.join(folder_path, 'DISABLED_ModManagerBackup_' + ini_file)}
''')

            if data != og_data:
                with open(os.path.join(folder_path, ini_file), "w", encoding = "utf-8") as f:
                    f.write(data)
                    print(f'''Affected File - {ini_path}
''')
                    f.close()
            else:
                print(f'''Analyzed File - {ini_path}
''')


      #  except Exception as e:
      #      print("Unable to open, skipping")
      #      print(f"Error: {e}")
      #      print(f"Try Using RestoreInis.py First - Contact me if it still fails")


def main():
    global Mod_IDs

    if os.path.exists(os.path.join(os.getcwd(), 'ModsIDs.json')):
        with open(os.path.join(os.getcwd(), 'ModsIDs.json'), 'r') as file:
            Mod_IDs = json.load(file)

    collect_ini(os.getcwd())

    with open(os.path.join(os.getcwd(), 'ModsIDs.json'), 'w+') as file:
        json.dump(Mod_IDs, file)
        print('\nGenerated ModsIDs.json inside - ' + os.getcwd())


main()
