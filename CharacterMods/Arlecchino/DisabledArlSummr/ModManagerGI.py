# This is a sample Python script.

# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.
import os

Characters = {'df65bb00': 'Albedo', '3ef08385': 'Alhaitham', '46de82f3': 'Aloy', 'a2ea4b2d': 'Amber', '557b2eff': 'AmberCN', '0107925f': 'Ayaka', 'b473c856': 'Ayato',
              '17baa562': 'Baizhu', '85282151': 'Barbara', '8b9e7c22': 'BarbaraSummertime', '51197c51': 'Beidou', '6cff51b4': 'Bennett', '9cee8711': 'Candace',
              'c5a6d98e': 'Charlotte', '4d8d965a': 'Chevreuse', '186eac84': 'Childe', 'c8e25747': 'Chiori', '489e3621': 'Chongyun', '07f8ad68': 'Clorinde',
              '348e58c4': 'Collei', '226f076e': 'Cyno', '9aeecbcb': 'Dehya', '71625c4d': 'Diluc', 'a2d909c8': 'DilucFlamme', 'e8083f19': 'Diona', '2a2a63ab': 'Dori',
              '107ba6e7': 'Eula', '6162188c': 'Faruzan', 'bf6aef4d': 'Fischl', '8f473224': 'FischlHighness', 'd2bfc751': 'Freminet', '8294fe98': 'Furina',
              'b94ef036': 'GaMing', 'a5169f1d': 'Ganyu', '9b3f356e': 'GanyuTwilight', '3ce94cac': 'Gorou', '51a75ba6': 'Heizou', 'dd16576c': 'HuTao', '3e61a41f': 'Itto',
              '191af650': 'Jean', '93bb2522': 'JeanCN', '16fef1eb': 'JeanSea', '8a081f34': 'Kaeya', 'b9b77eff': 'KaeyaSailwind', 'b56fd424': 'Kaveh', '7c0c47b3': 'Kazuha',
              '3aaf3e94': 'Keqing', '0d7e3cc5': 'KeqingOpulent', 'b57d7fe2': 'Kirara', 'dcd74904': 'Klee', '0f5fedb4': 'KleeBlossomingStarlight', 'dde4750a': 'Kokomi',
              'b82eaa26': 'KujouSara', '2656ccca': 'Layla', '2a557add': 'Lisa', '37c70461': 'LisaStudent', '98eb2db4': 'Lynette', '6f7b7740': 'Lyney', '1876e82e': 'Mika',
              '7a1dc890': 'Mona', '515f3ce6': 'MonaCN', '7106f05d': 'Nahida', 'f4e09bd7': 'Navia', 'cad3a022': 'Neuvillette', 'b2acc1df': 'Nilou', 'f9e1b52b': 'Ningguang',
              'db37b198': 'NingguangOrchid', 'd1384d15': 'Noelle', 'cad5bebb': 'Qiqi', 'e48c61f3': 'RaidenShogun', '4662c505': 'Razor', '748f40a5': 'Rosaria',
              '59a1f8b1': 'RosariaCN', 'c70b7fce': 'Sayu', 'e44b58b5': 'Shenhe', 'ee0980eb': 'ShenheFrostFlower', '7cfb62ea': 'Shinobu', 'b655c335': 'Sucrose',
              '24ecd71a': 'Thoma', 'ed2e7d59': 'Tighnari', 'c77e380b': 'TravelerBoy', '8239be13': 'TravelerGirl', '09a91a5c': 'Venti', '0110e1c7': 'Wanderer',
              'aa6f1268': 'Wriothesley', '9427917d': 'Xiangling', '39838e8f': 'Xianyun', '9464bf2d': 'Xiao', '25aed172': 'Xingqiu', 'cc158a1e': 'XingqiuBamboo',
              '76ed85f0': 'Xinyan', '3a7f71f5': 'Yae', 'eb8b62d3': 'Yanfei', '293449d6': 'YaoYao', 'c58c76f9': 'Yelan', '65618289': 'Yoimiya', '221f052e': 'YunJin',
              'a75ba32e': 'Zhongli', '6895f405': 'Arlecchino'}

Character_Name = ''
Character_ID = 0

Variables = """global $Mod_Enabled = 0
global $ModID = -1
global $CharacterID = {Character_ID}

global $IncludedInMaxCount = 0
global $First_Run = 1

"""

Present_Section = """if $\\NuraThings\\ModManager\\CharacterModData\\Active_{Character_Name} == 1
    if $First_Run == 1
        pre $\\NuraThings\\ModManager\\first_run = 1
        $First_Run = 0
    endif

    if $\\NuraThings\\ModManager\\config_mode == 1
        if $\\NuraThings\\ModManager\\charSwap == 1
            $IncludedInMaxCount = 0
        endif

        if $IncludedInMaxCount == 0
            ;$\\NuraThings\\ModManager\\currentCharacterID = $CharacterID
            $\\NuraThings\\ModManager\\currentCharMaxID = $\\NuraThings\\ModManager\\currentCharMaxID + 1
            $IncludedInMaxCount = 1
            $ModID = -1
        endif

        if $ModID == -1
            $ModID = $\\NuraThings\\ModManager\\currentCharMaxID
        endif

    endif

else if $IncludedInMaxCount == 1
    ;$ModID = -1
    $IncludedInMaxCount = 0
    run = CommandList\\NuraThings\\ModManager\\Reset
endif

if $\\NuraThings\\ModManager\\CharacterModData\\{Character_Name} == $ModID
    post $Mod_Enabled = 1
else
    post $Mod_Enabled = 0
endif


"""

def collect_ini(folder_path):
    ini_files = []
    ini_paths = []
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isdir(file_path):
            collect_ini(file_path)
        elif (os.path.splitext(filename)[1] == ".ini"
            and "desktop" not in filename.lower()
            and "ntuser" not in filename.lower()
            and "disabled_backup" not in filename.lower()):
            ini_files.append(filename)
            ini_paths.append(file_path)

    for ini_file, ini_path in zip(ini_files, ini_paths):
        try:
            out_lines = []
            with open(os.path.join(folder_path, ini_file), "r+", encoding="utf-8") as f:
                data = f.read()

                Have_Const = '[Constants]' in data
                Have_Present = '[Present]' in data

                for Hash in Characters:
                    if Hash in data:
                        Character_Name = Characters[Hash]
                        Character_ID = list(Characters.keys()).index(Hash)+1


                if ('TextureOverride' in data or 'ShaderOverride' in data) and 'global $ModID = -1' not in data:
                    f.seek(0)
                    lines = f.readlines()
                    addTab = False
                    skipIf = False
                    for line in lines:
                        appended = False

                        if not Have_Const:
                            out_lines.append(f'''[Constants]
{Variables.format(Character_ID=Character_ID)}''')
                            Have_Const = True
                            appended = True

                        elif '[Constants]' in line:
                            out_lines.append(f'''{line}
{Variables.format(Character_ID=Character_ID)}''')
                            appended = True

                        if not Have_Present:
                            out_lines.append(f'''[Present]
{Present_Section.format(Character_Name=Character_Name)}''')
                            Have_Present = True
                            appended = True

                        elif '[Present]' in line:
                            out_lines.append(f'''{line}
{Present_Section.format(Character_Name=Character_Name)}''')
                            appended = True

                        if addTab and ('[' in line or '; CommandList' in line or '; Resources' in line):
                            addTab = False
                            out_lines.append(f'endif\n\n{line}')
                            appended = True

                       # if appendIf and line is len(line.rstrip()) != 0 and '[' not in line and '; CommandList' not in line and '; Resources' not in line:
                       #     out_lines.append('if $Mod_Enabled == 1\n\n')
                       #     addTab = True
                       #     appended = True
                       #     appendIf = False
                       # elif appendIf and len(line.rstrip()) == 0:
                       #     appended = True
                       # elif appendIf:
                       #     addTab = False
                       #     out_lines.append(line)
                       #     appended = True
                       #     appendIf = False


                        #if appendIf and line != '\n':
                        #     out_lines.append(f'if $Mod_Enabled == 1\n\n{line}')
                        #     addTab = True
                        #     appended = True
                        #     appendIf = False
                        #elif appendIf and ('[' in line or '; CommandList' in line or '; Resources' in line):
                        #     out_lines.append(line)
                        #     appended = True
                        #     appendIf = False
                        if 'VertexLimitRaise' in line:
                            skipIf = True


                        if 'hash' in line:
                            out_lines.append(line)
                            if not skipIf:
                                out_lines.append(f'if $Mod_Enabled == 1\n\n')
                                addTab = True
                            else:
                                skipIf = False
                        else:
                            if not appended:
                                if addTab:
                                    out_lines.append(f'''   {line}''')
                                else:
                                    out_lines.append(line)

                    f.truncate(0)
                    f.close()

                with open(os.path.join(folder_path, ini_file), "w", encoding="utf-8") as f:
                    f.writelines(out_lines)
                    print(f'''Affected File - {ini_path}''')
                    f.close()


        except Exception as e:
            print("Unable to open, skipping")
            print(f"Error: {e}")

def main():
    inis = collect_ini(os.getcwd())



main();