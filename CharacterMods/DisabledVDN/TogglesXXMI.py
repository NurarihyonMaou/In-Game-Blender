import os
import random
import re

random_keys = ['T', 'Y', 'U', 'I', 'O', 'P', 'G', 'H', 'I', 'J',' K', 'L']

forbidden_keys = ['A', 'W', 'S', 'D', 'Q', 'R', 'E', 'F', 'C', 'B', 'M']

used_keys = []

inis = []
ini_filenames = []

# Toggles Generator for XXMI by Nurarihyon (NurarihyonMaou)
# Version 1.2-Beta

def give_random(keys):
    global used_keys
    global random_keys

    if len(random_keys) > 0:
        key = random.choice(random_keys)
    else:
        print("No Keys left")
        return

    if key in used_keys:
        random_keys.remove(key)  # Remove the used key from the list
        return give_random(keys)  # Retry with the updated list
    else:
        used_keys.append(key)  # Mark key as used
        random_keys.remove(key)  # Remove the key from random_keys
        return key

    return key


def swap_values(max):
    swapvar = ''
    max += 1
    for value in range(0, max):
        if value == max-1:
            swapvar += str(value)
        else:
            swapvar += f'{value},'
    return swapvar


def collect_ini(folder_path):
    ini = ''
    ini_filename = ''
    Toggles = {}
    Toggle_Lines = []
    Merged_Skelly = False

    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)

        if ".ini" in filename and 'disabled' not in filename.lower() and 'backup' not in filename.lower():
            inis.append(file_path)
            ini_filenames.append(filename)

    print("Choose Ini by Selecting Correct Number:\n")
    for index, Ini in enumerate(inis):
        print(f"{index}) {Ini}")

        # Select old and new files
    input_index = int(input("\nSelect File: "))
    ini = inis[input_index]
    ini_filename = ini_filenames[input_index]

    if ini != '':
        out_lines = []
        add_if = False
        if_part = ''
        tabs = ''
        backup_data = ''

        with open(ini, "r+", encoding="utf-8") as f:
            backup_data = f.read()

            f.seek(0)
            lines = f.readlines()

            for line in lines:

                match = re.search(r"^(\t*)[;\t]\s*([\w\s.]+)\s*\((\d+)\)", line)
                print(match)

                if add_if and 'drawindexed' in line:
                    add_if = False
                    out_lines.append(f'\t{line}{tabs}endif\n\n')
                    if_part = ''
                    tabs = ''
                    continue

                if match:
                    if match not in Toggle_Lines:
                        Toggle_Lines.append(match)

                    part = match.group(2).split()
                    if len(part) == 0:
                        continue
                    part = part[0]

                    tabs = match.group(1)

                    if part in Toggles:
                        Toggles[part] += 1
                    else:
                        Toggles[part] = 1

                    if_part = part
                    add_if = True

                    out_lines.append(f'''{tabs}if ${if_part} == 1
\t{line}''')
                    continue
                
                out_lines.append(line)

            print(out_lines)
            f.seek(0)
            f.truncate(0)
            f.close()

        if 'Disabled_Toggles_Backup'+ini_filename not in os.listdir(folder_path):
            with open(ini.replace(ini_filename, 'Disabled_Toggles_Backup'+ini_filename), "w", encoding="utf-8") as f:
                f.write(backup_data)
                f.close()
                print('Created Backup\n')
        else:
            print('Backup already Exists\n')

        if Toggles != {}:

            with open(ini, "r+", encoding="utf-8") as f:

                global used_keys

                toggle_variables = ''
                for Toggle in Toggles:
                    toggle_variables += f'''global persist ${Toggle} = 1
'''

                if any('[Constants]' in line for line in out_lines):

                    const_index = next(i for i, line in enumerate(out_lines) if '[Constants]' in line)

                    out_lines.insert(const_index+1, f'''; TOGGLES\n\n{toggle_variables}\n; TOGGLES ^\n\n''')
                else:
                    out_lines.append(f'''{line}\n\n\n; TOGGLES\n[Constants]\n{toggle_variables}
''')


                key_for_variable = ''
                out_lines.append('\n\n\n; Keys for Toggles\n\n')
                manual_keys = (input('Do You want to choose Keys used for Toggles Manually? (Y/N)\n').upper() == 'Y')

                for Toggle in Toggles:
                    if manual_keys:
                        key_for_variable = input(f'Choose Key for - ${Toggle}\n')

                    if key_for_variable == '' or key_for_variable == []:
                        if Toggle.upper()[0] not in used_keys:
                            key_for_variable = Toggle.upper()[0]
                            if key_for_variable in forbidden_keys:
                                key_for_variable = give_random(random_keys)
                        else:
                            key_for_variable = give_random(random_keys)
                        print(f'Automatically Assigned Key for ${Toggle} - {key_for_variable}\n')

                    used_keys.append(key_for_variable)
                    out_lines.append(f'''[Key{Toggle}]
condition = $active
type = cycle
key = no_modifiers {key_for_variable}
${Toggle} = {swap_values(Toggles[Toggle])}

''')
                    key_for_variable = ''

                f.writelines(out_lines)
                f.close()
                print('\nDone!\n')

            #with open(ini, "r+", encoding="utf-8") as f:
            #    f.writelines(out_lines)
            #    f.close()
            #


#if current_component in Toggles and part in tuple(Toggles[current_component]):
#    toggles_amount = (Toggles[part]['AmountOfToggles']) + 1
#    Toggles.update({current_component: {'AmountOfToggles': toggles_amount}})
#else:
#    Toggles.update({current_component: {'Part': part, 'AmountOfToggles': 1}})

def main():
    collect_ini(os.getcwd())


main()