import os
import re
import random
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import Counter

Variables = """[Constants]
; Mod Manager
global $NuraManager_active = 0

global $mod_type_id = {mod_type_id}
global persist $mod_id = -1
global persist $mod_enabled

global $swapped_in = 1

global $IncludedInMaxCount = 0
global $Nura_Manager_First_Run = 1

global $Resources_Set = 0

global $once_per_frame = 1

global persist $id_slot = 0

{Swap_Var}
"""

Present_Section = f'''[Present]
; Mod Manager
if $NuraManager_active > 0
    post $NuraManager_active = $NuraManager_active-1
endif

if $NuraManager_active == 0
    $swapped_in = 1
endif

post $once_per_frame = 1

'''

CommandListContent = """\n\n[CommandListManageMod]       
$NuraManager_active = 10

if $\\NuraThings\\ModManager\\setID == 1
    if $mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID

        if $mod_enabled
    
            if $id_slot == 0
                $\\NuraThings\\ModManager\\ActiveID = $mod_id
    
            else if $id_slot == 1
                $\\NuraThings\\ModManager\\ActiveID1 = $mod_id
    
            else if $id_slot == 2
                $\\NuraThings\\ModManager\\ActiveID2 = $mod_id
    
            else if $id_slot == 3
                $\\NuraThings\\ModManager\\ActiveID3 = $mod_id
    
            else if $id_slot == 4
                $\\NuraThings\\ModManager\\ActiveID4 = $mod_id
    
            else if $id_slot == 5
                $\\NuraThings\\ModManager\\ActiveID5 = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 0
                $\\NuraThings\\ModManager\\ActiveID = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 1
                $\\NuraThings\\ModManager\\ActiveID1 = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 2
                $\\NuraThings\\ModManager\\ActiveID2 = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 3
                $\\NuraThings\\ModManager\\ActiveID3 = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 4
                $\\NuraThings\\ModManager\\ActiveID4 = $mod_id
    
            else if $\\NuraThings\\ModManager\\ChooseActiveID == 5
                $\\NuraThings\\ModManager\\ActiveID5 = $mod_id
            endif
        endif
    endif
endif
   
if $swapped_in || $\\NuraThings\\ModManager\\ResetIDs == 1

    $\\NuraThings\\ModManager\\ModTypeID = $mod_type_id

    run = CustomShader\\NuraThings\\ModManager\\HandleModelIDs

    if $mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID

        if $mod_enabled

            if $id_slot == 0
                $\\NuraThings\\ModManager\\ActiveID = $mod_id

            else if $id_slot == 1
                $\\NuraThings\\ModManager\\ActiveID1 = $mod_id

            else if $id_slot == 2
                $\\NuraThings\\ModManager\\ActiveID2 = $mod_id

            else if $id_slot == 3
                $\\NuraThings\\ModManager\\ActiveID3 = $mod_id

            else if $id_slot == 4
                $\\NuraThings\\ModManager\\ActiveID4 = $mod_id

            else if $id_slot == 5
                $\\NuraThings\\ModManager\\ActiveID5 = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 0
                $\\NuraThings\\ModManager\\ActiveID = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 1
                $\\NuraThings\\ModManager\\ActiveID1 = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 2
                $\\NuraThings\\ModManager\\ActiveID2 = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 3
                $\\NuraThings\\ModManager\\ActiveID3 = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 4
                $\\NuraThings\\ModManager\\ActiveID4 = $mod_id

            else if $\\NuraThings\\ModManager\\ChooseActiveID == 5
                $\\NuraThings\\ModManager\\ActiveID5 = $mod_id
            endif

        ;else if $\\NuraThings\\ModManager\\ModCount == 0
        ;    $\\NuraThings\\ModManager\\ActiveID = 0
        ;    $\\NuraThings\\ModManager\\ActiveID1 = 0
        ;    $\\NuraThings\\ModManager\\ActiveID2 = 0
        ;    $\\NuraThings\\ModManager\\ActiveID3 = 0
        ;    $\\NuraThings\\ModManager\\ActiveID4 = 0
        ;    $\\NuraThings\\ModManager\\ActiveID5 = 0
        endif


        if $\\NuraThings\\ModManager\\Random_Mode == 1
            post $\\NuraThings\\ModManager\\get_random_id_next_frame = 1
        endif

        if $Nura_Manager_First_Run
            if $\\NuraThings\\ModManager\\Random_Mode == 2
                post $\\NuraThings\\ModManager\\get_random_id_next_frame = 1
            endif
            post $Nura_Manager_First_Run = 0
        endif

    endif

    $swapped_in = 0
endif


if $mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID

    if $once_per_frame  

        $\\NuraThings\\ModManager\\AllModsActiveCount = $\\NuraThings\\ModManager\\AllModsActiveCount+1

        $\\NuraThings\\ModManager\\ModCount = $\\NuraThings\\ModManager\\ModCount+1

        if $mod_id == -1 || $\\NuraThings\\ModManager\\ResetIDs == 2
            $mod_id = $\\NuraThings\\ModManager\\ModCount
        endif

        $once_per_frame = 0

        $\\NuraThings\\ModManager\\ModID = $mod_id

        run = CustomShader\\NuraThings\\ModManager\\HandleModIDs
    endif

    if $mod_id == $\\NuraThings\\ModManager\\ActiveID || $mod_id == $\\NuraThings\\ModManager\\ActiveID1 || $mod_id == $\\NuraThings\\ModManager\\ActiveID2 || $mod_id == $\\NuraThings\\ModManager\\ActiveID3 || $mod_id == $\\NuraThings\\ModManager\\ActiveID2 || $mod_id == $\\NuraThings\\ModManager\\ActiveID3 || $mod_id == $\\NuraThings\\ModManager\\ActiveID4 || $mod_id == $\\NuraThings\\ModManager\\ActiveID5
        $mod_enabled = 1

        if $mod_id == $\\NuraThings\\ModManager\\ActiveID
            $id_slot = 0
        else if $mod_id == $\\NuraThings\\ModManager\\ActiveID1
            $id_slot = 1
        else if $mod_id == $\\NuraThings\\ModManager\\ActiveID2
            $id_slot = 2
        else if $mod_id == $\\NuraThings\\ModManager\\ActiveID3
            $id_slot = 3
        else if $mod_id == $\\NuraThings\\ModManager\\ActiveID4
            $id_slot = 4
        else if $mod_id == $\\NuraThings\\ModManager\\ActiveID5
            $id_slot = 5
        endif

{Set_Path}{Set_Toggles}{Set_Author}{Set_Mod_Name}

        {Swap_Var1}
    else
        $mod_enabled = 0
        {Swap_Var2}
    endif
endif


if $once_per_frame  
    $\\NuraThings\\ModManager\\AllModsActiveCount = $\\NuraThings\\ModManager\\AllModsActiveCount+1
    $once_per_frame = 0
endif



"""


def collect_ini_files(root_path):
    """
    Recursively collects .ini files from the given root path,
    excluding unwanted directories and files.
    """
    ini_files = []
    ini_paths = []

    def process_folder(folder_path):
        for dirpath, _, filenames in os.walk(folder_path):
            for filename in filenames:
                if 'BufferValues' in dirpath or 'disabled' in dirpath.lower():
                    continue

                file_path = os.path.join(dirpath, filename)
                if filename.endswith(".ini") and "desktop" not in filename.lower() \
                        and "ntuser" not in filename.lower() and "backup" not in filename.lower() \
                        and "disabled" not in filename.lower():
                    ini_files.append(filename)
                    ini_paths.append(file_path)

    # Use multithreading to improve performance in large directory trees
    with ThreadPoolExecutor() as executor:
        futures = [executor.submit(process_folder, root_path)]
        for future in as_completed(futures):
            future.result()

    return ini_files, ini_paths


def get_common_words(identifiers):
    """
    This function receives a list of identifiers (strings) and returns the longest common sequence of words.
    It splits identifiers into words and then finds the longest common sequence across all identifiers.
    """

    # Split identifiers into words using uppercase letter boundaries and underscores as delimiters
    def split_into_words(identifier):
        return re.findall(r'[A-Z][a-z]*|[a-z]+', identifier)

    # Split each identifier into a list of words
    split_identifiers = [split_into_words(identifier) for identifier in identifiers]

    # Find the longest common sequence of words
    if not split_identifiers:
        return ''

    # Start with the first identifier's words
    common_words = split_identifiers[0]

    # Iterate through the rest of the identifiers to find the common words
    for words in split_identifiers[1:]:
        common_words = [word for word, common_word in zip(common_words, words) if word == common_word]
        if not common_words:
            break  # No common words found

    # Return the joined string of common words
    return ''.join(common_words)


def parse_key_section(match):
    section_name, section_text = match  # Unpack the tuple

    # Extract conditions, key, type, and variables
    conditions = re.search(r'conditions?\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    keys = re.findall(r'key\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    backs = re.findall(r'back\s*=\s*([^\n]+)', section_text, re.IGNORECASE)
    type_ = re.search(r'type\s*=\s*([^\n]+)', section_text, re.IGNORECASE)

    filtered_lines = "\n".join(line for line in section_text.split("\n") if "condition" not in line.lower())
    variable_match = re.search(r'^\s*\$(\w+)\s*=\s*([^\n]+)', filtered_lines, re.IGNORECASE | re.MULTILINE)

    conditions = conditions.group(1).strip() if conditions else None
    keys = " or ".join([key.strip() for key in keys])
    backs = " or ".join([back.strip() for back in backs])
    type_ = type_.group(1).strip() if type_ else None

    variable_name = variable_match.group(1).strip() if variable_match else None
    variable_value = variable_match.group(2).strip() if variable_match else None
    number_count = len(re.findall(r'\d+', variable_value)) if variable_value else 0

    return [section_name, keys, type_, variable_name, variable_value, number_count, conditions, backs]


def get_toggles(data):
    # return re.findall(r'\[(\w+)\]\s+condition\s*=\s*.*\s+key\s*=\s*(\d+)\s+type\s*=\s*(cycle|toggle)\s*\$(\w+)\s*=\s*((?:\d+,?)+)', data, re.IGNORECASE)
    pattern = pattern = r"""
\[(Key[^\]]*)\]              # Match and capture section header (e.g., [Key*])
(                            # Start of group to capture the section's content
(?:\n(?!\[)[^\n]*)*?         # Match lines within the section, excluding lines starting with [
)                            # End of group
(?=\n\[\w|\Z)              # Stop when a new section starts (next [) or at the end of the string
"""

    # Compile the regex pattern with VERBOSE flag (without DOTALL)
    compiled_pattern = re.compile(pattern, flags = re.VERBOSE | re.IGNORECASE)

    # Find all matches
    matches = compiled_pattern.findall(data + '[')
    # print(matches)
    results = [parse_key_section(match) for match in matches]

    return results


def handle_toggles(toggles, file_path):
    folder_path = os.path.dirname(file_path)

    # print(toggles)
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


def parse_ini_sections(file_path):
    """
    Parses the sections of an .ini file, extracting sections that include 'IB = ResourceX',
    creates a backup of the file if it doesn't exist, processes sections, and updates the file,
    while preserving content outside sections.
    """

    toggles = []
    sections = []
    pre_section_content = []  # Content before the first section
    post_section_content = []  # Content after the last section
    ib_sections = []
    ib_array = {}
    repetitive_identifiers = set()

    already_modified = False
    has_author = False
    has_mod_name = False

    ini_content = {}

    namespace = ''
    is_custom_namespace = False
    is_master_file = False

    credits_string = ''

    # Regex patterns
    section_start_regex = re.compile(r"^\[(?!;).*?\]")  # Matches section headers
    ib_regex = re.compile(r"ib\s*=\s*(Resource|null).*", re.IGNORECASE)  # Matches 'IB = ResourceX'
    hash_regex = re.compile(r"hash\s*=\s*(\S+)", re.IGNORECASE)  # Captures 'hash = Hash'

    # Backup file logic
    backup_file_path = os.path.join(
        os.path.dirname(file_path),
        f"DISABLED_ModManagerBackup_{os.path.basename(file_path)}"
    )

    if not os.path.exists(backup_file_path):
        try:
            print(f"Creating backup: {backup_file_path}")
            with open(file_path, 'r', encoding = 'utf-8') as original_file:
                with open(backup_file_path, 'w', encoding = 'utf-8') as backup_file:
                    backup_file.write(original_file.read())
        except Exception as e:
            print(f"Error creating backup: {e}")
            return

    # print(f"Processing file: {file_path}")

    try:
        with open(file_path, 'r', encoding = 'utf-8') as file:
            data = file.read()
            file.seek(0)

            if 'ResourceModAuthor' in data:
                has_author = True

            if 'ResourceModName' in data:
                has_mod_name = True

            lines = file.readlines()
            lines.append('[')

            already_modified = "$NuraManager_active" in data

            toggles = get_toggles(data)

            if len(toggles) > 0:
                handle_toggles(toggles, file_path)

            if match := re.search(r'\[ResourceCreditInfo.*\][\s\S]*?data\s*=\s*\"(.*)\"', data, re.IGNORECASE):
                credits_string = match.group(1)

            current_section = None
            in_section = False

            for line in lines:
                stripped_line = line.strip()

                if stripped_line == '[':
                    continue

                # Namespace detection
                if 'namespace=' in stripped_line.replace(" ", ""):
                    namespace = re.sub(r'namespace\s*=\s*', '', stripped_line)
                    is_custom_namespace = True
                    #
                    if 'mod merger script utilizing namespaces' in data or 'Discord Bot GI_Pack' in data or 'master' in namespace.lower() or '$swapvar' in data or 'JeanneAlter' in namespace:
                        is_master_file = True

                # Detect section headers
                if section_start_regex.match(stripped_line):
                    in_section = True
                    if current_section:  # Save the previous section
                        sections.append(current_section)
                    current_section = {'header': stripped_line, 'content': []}

                elif in_section and current_section:
                    current_section['content'].append(line.rstrip())

                elif not in_section:
                    pre_section_content.append(line.rstrip())

                elif not stripped_line:  # Preserve empty lines
                    if current_section:
                        current_section['content'].append(line.rstrip())

            # If a section was open at the end of the file, save it
            if current_section:
                sections.append(current_section)

    except UnicodeDecodeError:
        print(f"Error decoding file: {file_path}. Retrying with 'latin-1'.")
        with open(file_path, 'r', encoding = 'latin-1') as file:
            data = file.read()
            file.seek(0)

            if 'ResourceModAuthor' in data:
                has_author = True

            if 'ResourceModName' in data:
                has_mod_name = True

            lines = file.readlines()
            lines.append('[')

            already_modified = "$NuraManager_active" in data

            toggles = get_toggles(data)

            if len(toggles) > 0:
                handle_toggles(toggles, file_path)

            if match := re.search(r'\[ResourceCreditInfo.*\][\s\S]*?data\s*=\s*\"(.*)\"', data, re.IGNORECASE):
                credits_string = match.group(1)

            current_section = None
            in_section = False

            for line in lines:
                stripped_line = line.strip()

                if stripped_line == '[':
                    continue

                # Namespace detection
                if 'namespace=' in stripped_line.replace(" ", ""):
                    namespace = re.sub(r'namespace\s*=\s*', '', stripped_line)
                    is_custom_namespace = True
                    #is_master_file = True
                    if 'mod merger script utilizing namespaces' in data or 'Discord Bot GI_Pack' in data or 'master' in namespace.lower() or '$swapvar' in data or 'JeanneAlter' in namespace:
                        is_master_file = True

                # Detect section headers
                if section_start_regex.match(stripped_line):
                    in_section = True
                    if current_section:  # Save the previous section
                        sections.append(current_section)
                    current_section = {'header': stripped_line, 'content': []}

                elif in_section and current_section:
                    current_section['content'].append(line.rstrip())

                elif not in_section:
                    pre_section_content.append(line.rstrip())

                elif not stripped_line:  # Preserve empty lines
                    if current_section:
                        current_section['content'].append(line.rstrip())

            # If a section was open at the end of the file, save it
            if current_section:
                sections.append(current_section)
            # lines = file.readlines()
            # lines.append('[')
    #
    # current_section = None
    # in_section = False
    #
    # for line in lines:
    #    stripped_line = line.strip()
    #
    #    if stripped_line == '[':
    #        continue
    #
    #    # Namespace detection
    #    if 'namespace' in stripped_line:
    #        namespace = stripped_line
    #        continue
    #
    #    # Detect section headers
    #    if section_start_regex.match(stripped_line):
    #        in_section = True
    #        if current_section:  # Save the previous section
    #            sections.append(current_section)
    #        current_section = {'header': stripped_line, 'content': []}
    #
    #    elif in_section and current_section:
    #        current_section['content'].append(line.rstrip())
    #
    #    elif not in_section:
    #        pre_section_content.append(line.rstrip())
    #
    #    elif not stripped_line:  # Preserve empty lines
    #        if current_section:
    #            current_section['content'].append(line.rstrip())
    #
    ## If a section was open at the end of the file, save it
    # if current_section:
    #    sections.append(current_section)

    # Process sections for IB identifiers and hashes
    for section in sections:
        header = section['header']
        content = "\n".join(section['content'])

        # Check for IB entry directly in the section
        if ib_regex.search(content):
            # Handle IB section as before
            ib_sections.append(section)
        elif 'run = CommandListSkinTexture' in content:
            ib_sections.append(section)
        elif re.findall(r"(hash = [a-fA-F0-9]+\nthis = Resource[a-fA-F0-9]+)", content):
            # print("TESTOVERRIDE")
            ib_sections.append(section)
        else:
            # Look for `run = CommandList...` in the section content
            commandlist_matches = re.findall(r"run\s*=\s*(CommandList\S+)", content, re.IGNORECASE)
            found_ib = False  # Flag to determine if IB was found in CommandLists

            for commandlist_name in commandlist_matches:
                # Locate the referenced CommandList section
                commandlist_section = next(
                    (s for s in sections if s['header'].strip("[]") == commandlist_name), None
                )

                if commandlist_section:
                    # Check for IB entry in the CommandList section
                    commandlist_content = "\n".join(commandlist_section['content'])
                    if ib_regex.search(commandlist_content):
                        # If found, treat the original section as an IB section
                        ib_sections.append(section)
                        found_ib = True
                        break  # Stop searching further CommandLists if one is valid

            # If no IB is found in the section or its referenced CommandLists, skip it
            if not found_ib:
                # print(f"Section {header} is not an IB section (no valid `ib = Resource` found).")
                continue

        # Process IB section logic (identical to previous processing for hash, match indexes, etc.)
        hash_match = hash_regex.search(content)
        if hash_match:
            hash_value = hash_match.group(1).strip()

            # Extract optional match_first_index and match_index_count
            match_first_index = None
            match_index_count = None

            match_first_index_match = re.search(r"match_first_index\s*=\s*(\d+)", content)
            if match_first_index_match:
                match_first_index = int(match_first_index_match.group(1).strip())

            match_index_count_match = re.search(r"match_index_count\s*=\s*(\d+)", content)
            if match_index_count_match:
                match_index_count = int(match_index_count_match.group(1).strip())

            # Extract identifier from the header
            identifier = header.strip("[]")  # Remove square brackets
            identifier = re.sub(r"^(TextureOverride|ShaderOverride)", "", identifier).strip()  # Remove prefix

            repetitive_identifiers.add(identifier)

            if namespace == '':
                # Find the index where "Mods" is located and slice the path from there
                mods_index = file_path.lower().find("mods")  # Use lower() for case-insensitive matching
                if mods_index != -1:
                    namespace = file_path[mods_index + len("Mods"):]
                else:
                    namespace = file_path  # If "Mods" is not found, return the whole path

            if namespace not in ib_array:
                ib_array[namespace] = {}  # Initialize the namespace if it doesn't exist

            if identifier not in ib_array[namespace]:
                ib_array[namespace][identifier] = []  # Initialize the identifier if it doesn't exist

            # Check if hash is already in the array for this identifier
            hash_entry = {
                "hash": hash_value,
                "match_first_index": match_first_index,
                "match_index_count": match_index_count
            }

            # Avoid adding duplicates
            if not any(entry["hash"] == hash_value for entry in ib_array[namespace][identifier]):
                ib_array[namespace][identifier].append(hash_entry)
            else:
                print(f"Duplicate hash {repr(hash_value)} ignored for identifier {identifier}")

    custom_namespace = {}

    if is_custom_namespace:
        custom_namespace[os.path.dirname(file_path)] = namespace

    rabbit_thing = False

    if namespace == 'JeanneAlter':
        rabbit_thing = True

    ini_content = [pre_section_content, sections, post_section_content, toggles, credits_string, already_modified,
                   has_author, has_mod_name, is_master_file, rabbit_thing, namespace]

    return sections, ib_sections, ib_array, repetitive_identifiers, ini_content, custom_namespace


from concurrent.futures import ThreadPoolExecutor, as_completed


def process_all_ini_files(ini_paths):
    """
    Processes all .ini files in parallel, parsing their sections and
    extracting identifiers, IB sections, and IB hashes grouped by identifier.
    """
    all_sections = []
    all_ib_sections = []
    all_ib_array = {}
    all_identifiers = set()
    all_ini_content = {}
    mod_type_ids = {}

    all_custom_namespaces = []

    def parse_file(file_path):
        # Your implementation of parse_ini_sections()
        return parse_ini_sections(file_path)

    # Parse files concurrently
    with ThreadPoolExecutor() as executor:
        futures = {executor.submit(parse_file, path): path for path in ini_paths}

        for future in as_completed(futures):
            ini_path = futures[future]
            try:
                sections, ib_sections, ib_array, identifiers, ini_content, custom_namespace = future.result()
                all_sections.extend(sections)
                all_ib_sections.extend(ib_sections)

                if custom_namespace:
                    all_custom_namespaces.append(custom_namespace)
                # Store parsed ini content and IB arrays by path
                all_ini_content[ini_path] = ini_content
                all_ib_array[ini_path] = ib_array

                # Merge identifiers
                all_identifiers.update(identifiers)
            except Exception as e:
                print(f"Error parsing file {ini_path}: {e}")

    # Group hashes and assign IDs
    mod_type_ids = group_hashes_and_assign_ids(all_ib_array, ini_paths)

    # print(mod_type_ids, "Ids")

    # Update INI files with processed content
    def update_file(file_path):
        try:
            ini_content = all_ini_content[file_path]
            ib_array = all_ib_array[file_path]
            update_ini(file_path, ini_content, ib_array, mod_type_ids, all_custom_namespaces)
            # print(f"Successfully Processed: {file_path}")
        except Exception as e:
            print(f"Failed to Update {file_path}: {e}")

    with ThreadPoolExecutor() as executor:
        futures = {executor.submit(update_file, path): path for path in ini_paths}

        for future in as_completed(futures):
            file_path = futures[future]
            try:
                future.result()  # Trigger exception if any
            except Exception as e:
                print(f"Error updating {file_path}: {e}")

    return all_sections, all_ib_sections, all_ib_array, all_identifiers, all_ini_content


def group_hashes_and_assign_ids(ib_array, ini_paths):
    """
    Groups namespaces by overlapping hashes and assigns unique IDs to groups.
    """
    from collections import defaultdict

    namespace_to_group = {}
    group_to_hashes = {}
    group_counter = 0

    # Helper function to find all hashes in a namespace
    def extract_hashes(namespace_data):
        hashes = set()
        for identifier, hash_list in namespace_data.items():
            hashes.update(entry["hash"] for entry in hash_list)
        return hashes

    for ini_path in ini_paths:
        # Grouping logic
        for namespace, namespace_data in ib_array[ini_path].items():
            namespace_hashes = extract_hashes(namespace_data)
            overlapping_groups = [
                group_id
                for group_id, group_hashes in group_to_hashes.items()
                if not group_hashes.isdisjoint(namespace_hashes)
            ]

            if not overlapping_groups:
                # No overlap: Create a new group
                group_counter += 1
                group_to_hashes[group_counter] = namespace_hashes
                namespace_to_group[namespace] = group_counter
            else:
                # Merge overlapping groups
                merged_group = overlapping_groups[0]
                for group_id in overlapping_groups[1:]:
                    group_to_hashes[merged_group].update(group_to_hashes[group_id])
                    # Update namespace-to-group mappings
                    for ns, grp in namespace_to_group.items():
                        if grp == group_id:
                            namespace_to_group[ns] = merged_group
                    # Remove the old group
                    del group_to_hashes[group_id]

                # Add the current namespace's hashes to the merged group
                group_to_hashes[merged_group].update(namespace_hashes)
                namespace_to_group[namespace] = merged_group

    # Assign unique IDs to each group
    final_groups = {}
    final_group_to_hashes = {}
    for new_id, (group_id, group_hashes) in enumerate(group_to_hashes.items(), start = 1):
        final_groups.update({ns: new_id for ns, grp in namespace_to_group.items() if grp == group_id})
        final_group_to_hashes[new_id] = group_hashes

    # print(final_groups, final_group_to_hashes, "faFAWFWVWV")
    return final_group_to_hashes


# , rabbit_thing=False
def process_sections(sections, ib_array, is_master_file, rabbit_thing, custom_namespace, is_related):
    """
    Processes sections in a header-content format to add missing match_priority, allow_duplicate_hash, and conditionals.
    Ensures sections conform to the expected structure with proper indentation, preserving original order.

    Parameters:
        sections (list): List of sections, each a dictionary with 'header' and 'content'.
        rabbit_thing (bool): Whether to apply RabbitThing-specific logic.

    Returns:
        list: List of sections with an added 'modified' flag indicating if they were updated.
    """
    target_strings = ['match_priority', 'allow_duplicate_hash', 'match_first_index', 'match_index_count']
    processed_sections = []

    modified_section = False

    for index, section in enumerate(sections):
        # Validate section structure
        if not isinstance(section, dict) or 'header' not in section or 'content' not in section:
            print(
                f"Skipping section: Expected dictionary with 'header' and 'content', got {type(section).__name__} -> {section}")
            continue

        header = section['header']

        content = section['content']
        original_content = content  # Copy of the original content for comparison

        has_match_priority = any(
            key in line for line in content for key in target_strings
        )
        max_index = -1

        copy_over_target_string = ''

        # Find the max index of target_strings in the content
        if has_match_priority:
            inside_if = 0
            for i, line in enumerate(content):
                if "if" in line:
                    inside_if += 1
                if "endif" in line and inside_if > 0:
                    inside_if -= 1

                if any(target in line for target in target_strings):
                    if inside_if > 0:
                        copy_over_target_string = line
                    else:
                        max_index = max(max_index, i)

        # Find the hash line (excluding comments and duplicate directives)
        hash_index = [i for i, line in enumerate(content) if
                      'hash' in line and ';' not in line and 'allow_duplicate_hash' not in line]

        if not hash_index:
            processed_sections.append({'header': header, 'content': content, 'modified': modified_section})
            continue

        hash_index = hash_index[0]

        if len(copy_over_target_string) > 0:
            content.insert(hash_index + 1, copy_over_target_string)

        # Add match_priority or allow_duplicate_hash if missing
        if not has_match_priority:
            if '[TextureOverride' in header:
                content.insert(hash_index + 1, "match_priority = 0")
            elif '[ShaderOverride' in header:
                content.insert(hash_index + 1, "allow_duplicate_hash = True")

        # Flatten IB_Array to collect all hashes
        ib_hashes = {
            entry["hash"] for namespace in ib_array.values()
            for entries in namespace.values() for entry in entries
        }

        # print(ib_hashes, content[hash_index])

        is_ib_section = False  # Flag to identify IB sections

        if hash_index is not None:
            # Extract the hash value from the line
            match = re.search(r"hash\s*=\s*([a-fA-F0-9]+)", content[hash_index])
            if match:
                section_hash = match.group(1)  # Extracted hash value
                if section_hash in ib_hashes:
                    is_ib_section = True

        # Add if $Mod_Enabled condition if missing
        if not any(f"if ${custom_namespace}Mod_Enabled" in line and not line.strip().startswith(";") for line in content):

            priority_index = max_index if max_index > -1 else hash_index + 1

            content.insert(priority_index + 1, f"if ${custom_namespace}Mod_Enabled")

            if not is_related and (is_ib_section or is_master_file or (rabbit_thing and 'TextureOverrideActive' in header)):
                content.insert(priority_index + 1, "run = CommandListManageMod")
                content.insert(priority_index + 2, "")

        # Adjust indentation for the content
        depth = 0
        indent = ' ' * 4
        indented_content = []

        for line in content:

            conditional = 0
            first_word = line.strip().split(' ')[0].lower()

            if first_word == 'if':
                depth += 1
                conditional = 1
            elif first_word in ['else', 'elif']:
                conditional = 1
            elif first_word == 'endif':
                depth -= 1

            indented_content.append(indent * (depth - conditional) + line.strip())

        depth -= 1
        while depth >= 0:
            indented_content.append(indent * depth + "endif")
            depth -= 1

        content = indented_content

        ## Apply RabbitThing-specific logic if enabled
        # if rabbit_thing and any('$currentOutfit = $nextOutfit' in line for line in content):
        #    content.append("else")
        #    content.append(indent + "$currentOutfit = -1")
        #    content.append("endif")

        ## Remove redundant if $Mod_Enabled...endif pairs
        # content = [
        #    line for line in content
        #    if not (line.strip() == "if $Mod_Enabled" and content[content.index(line) + 1].strip() == "endif")
        # ]

        # Remove redundant if $Mod_Enabled...endif pairs
        i = 0
        while i < len(content):
            line = content[i].strip()
            if line == "if $Mod_Enabled":
                # Check for an immediate 'endif' after 'if $Mod_Enabled'
                j = i + 1
                while j < len(content) and content[j].strip() == "":  # Skip empty lines
                    j += 1
                if j < len(content) and content[j].strip() == "endif":
                    # Remove 'if $Mod_Enabled' and 'endif', including empty lines in between
                    del content[i:j + 1]
                    continue  # Restart loop from the same index
            i += 1

        # Compare content to detect changes
        if content != original_content:
            processed_sections.append({'header': header, 'content': content, 'modified': True})
        else:
            processed_sections.append({'header': header, 'content': content, 'modified': False})

    return processed_sections


def grab_resources(ib_sections, ib_array):
    resources = ''

    for section in ib_sections:
        header = section.get('header', '')
        content = section.get('content', [])

        if not header or not content:
            print("Empty or malformed section:", section)
            continue

        # Extract identifier from the header
        identifier = header.strip("[]")  # Remove square brackets
        identifier = re.sub(r"^(TextureOverride|ShaderOverride)", "", identifier).strip()  # Remove prefix

        # print("Processing identifier:", identifier)

        found = False
        match_first_index = None
        match_index_count = None

        for file_path, section_data in ib_array.items():
            if identifier in section_data:
                found = True
                resource_info = section_data[identifier][0]
                match_first_index = resource_info.get('match_first_index')
                match_index_count = resource_info.get('match_index_count')
                break

        if not found:
            print(f"Identifier {identifier} not found in IB Array.")
            continue

        hash_regex = re.compile(r"hash\s*=\s*(\S+)", re.IGNORECASE)  # Captures 'hash = Hash'
        # Extract hash value from the content
        hash_match = hash_regex.search("\n".join(content))
        if hash_match:
            hash_value = hash_match.group(1).strip()

            # Generate `resource_name`
            resource_name = f"Resource_{hash_value}_{match_first_index if match_first_index is not None else ''}{'_' + match_index_count if match_index_count is not None else ''}"

            # Locate the last `endif` in the section and add the logic above it
            mod_enabled_start = next((i for i, line in enumerate(content) if "if $Mod_Enabled" in line), None)
            mod_enabled_end = next(
                (i for i, line in enumerate(content) if
                 line.strip() == "endif" and (mod_enabled_start is None or i > mod_enabled_start)), None)

            resources += f"[{resource_name}.Diffuse]\n" \
                         f"[{resource_name}.IB]\n" \
                         f"[{resource_name}.Position]\n" \
                         f"[{resource_name}.Texcoord]\n\n"

            resource_logic = [
                f"    if {resource_name}.IB == null",
                f"\t\t{resource_name}.IB = copy ib",
                f"    endif\n",

                f"    if {resource_name}.Position == null",
                f"\t\t{resource_name}.Position = copy vb0",
                f"    endif\n",

                f"    if {resource_name}.Texcoord == null",
                f"\t\t{resource_name}.Texcoord = copy vb1",
                f"    endif\n",

                f"    if {resource_name}.Diffuse == null",
                f"\t\tif ps == 037730.0 || ps == 037730.1",
                f"\t\t    {resource_name}.Diffuse = copy ps-t1",
                f"\t\telse",
                f"\t\t    {resource_name}.Diffuse = copy ps-t0",
                f"\t\tendif",
                f"    endif",
            ]

            # print(f"Adding resource logic for {identifier}: {resource_logic}")

            if mod_enabled_end is not None:
                # Insert the new logic above the last `endif`
                content[mod_enabled_end:mod_enabled_end] = resource_logic
            else:
                # If no `if $Mod_Enabled` exists, append the entire block
                content.append("if $Mod_Enabled")
                content.extend(resource_logic)
                content.append("endif")

        section['content'] = content  # Update the section with the modified content
        # print(f"Updated content for {identifier}:", content)

    return ib_sections, resources


def get_type_id_for_hash(temp_hash, mod_type_ids):
    for type_id, hash_set in mod_type_ids.items():
        if temp_hash in hash_set:
            return type_id
    return -1  # Not found


def update_ini(file_path, ini_content, ib_array, mod_type_ids, all_custom_namespaces):
    # Update the .ini file with processed sections and preserved content
    global Variables
    global Present_Section

    type_id = -1

    is_related = False

    pre_section_content = ini_content[0]
    local_sections = ini_content[1]
    post_section_content = ini_content[2]

    is_master_file = ini_content[8]
    custom_namespace = ''

    local_namespace = ini_content[10]

    if not is_master_file:
        shortest_match = None
        custom_namespace = ''

        for custom_namespace_dict in all_custom_namespaces:
            for path, namespace in custom_namespace_dict.items():
                if path in file_path:
                    if any(namespace in line for line in pre_section_content) or \
                            any(namespace in line for line in post_section_content) or \
                            any(namespace in line for section in local_sections for line in section['content']):

                        if shortest_match is None or len(namespace) < len(shortest_match):
                            shortest_match = namespace
                            custom_namespace = "\\" + namespace + "\\"

                            if local_namespace != namespace:
                                is_related = True

    if not is_related:
        for identifier, hash_list in ib_array.items():
            # print('haafawfwafawfsh', hash_list.items())
            for element in hash_list.items():
                for array_element in element:
                    if isinstance(array_element, list):  # Check if the value is a list
                        for object_element in array_element:
                            temp_hash = object_element['hash']
                            if len(temp_hash) < 3:
                                print("Error - Missing or Invalid Hash")
                                break
                            type_id = get_type_id_for_hash(temp_hash, mod_type_ids)
                            if type_id != -1:
                                break

                    if type_id != -1:
                        break
                if type_id != -1:
                    break

        # for hash_entry in hash_list:

        # if isinstance(hash_entry, dict) and "hash" in hash_entry:
        #    hash_value = hash_entry["hash"]
    #
    #    # Check if the hash_value exists in mod_type_ids
    #    if hash_value in mod_type_ids:
    #        hash_entry["type_id"] = mod_type_ids[hash_value]  # Assign type_id
    #    else:
    #        hash_entry["type_id"] = None  # No matching type_id found
    # else:
    #    print(f"Warning: Unexpected entry format in {identifier}: {hash_entry}")

    toggles = len(ini_content[3]) > 0
    credits_string = f'"{ini_content[4]}"'
    already_modified = ini_content[5]

    has_author = ini_content[6]
    has_mod_name = ini_content[7]

    rabbit_thing = ini_content[9]

    # print(f'{already_modified=}')
    folder_path = os.path.dirname(file_path)
    head, tail = os.path.split(folder_path)
    mod_name = ''

    if tail and len(tail) > 0:
        mod_name = f'"{tail}"'

    swapvar = ''
    swapvar1 = ''
    swapvar2 = ''

    if is_master_file:
        type_id = random.randint(1000, 9999)
        if toggles:
            already_handled = []
            for toggle in ini_content[3]:
                if toggle[3] is None:
                    continue

                if toggle[3] in already_handled:
                    continue

                swapvar += f'global persist $hold_{toggle[3]}\n'

                if swapvar1 != '':
                    swapvar1 += '\t'

                swapvar1 += f"""if ${toggle[3]} == -100
            ${toggle[3]} = $hold_{toggle[3]}
        endif\n\n"""

                swapvar2 += '\n'

                if swapvar2 != '':
                    swapvar2 += '\t'

                swapvar2 += f"""if ${toggle[3]} != -100
            $hold_{toggle[3]} = ${toggle[3]}
        endif

        ${toggle[3]} = -100\n\n"""

                already_handled.append(toggle[3])

    if not already_modified and (type_id != -1 or is_related):
        backup_custom_namespace = ''

        if is_master_file:
            backup_custom_namespace = custom_namespace
            custom_namespace = ''

        try:
            with open(file_path, 'w', encoding = 'utf-8') as file:
                # Write pre-section content

                for line in pre_section_content:

                    if toggles:
                        for toggle in ini_content[3]:
                            if toggle[0] and toggle[6]:
                                if 'condition' in line and 'ActiveTypeID && $mod_enabled == 1' not in line and \
                                        'global $' not in line and 'local $' not in line:

                                    # Ensure we don't add the same condition multiple times
                                    new_condition = f' && ${custom_namespace}mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                    if new_condition not in line:
                                        if toggle[6] in line:
                                            line = line.replace(toggle[6], toggle[6] + new_condition, 1)
                                        else:
                                            line = line.replace(toggle[0] + ']',
                                                                toggle[0] + f']\ncondition ={new_condition}', 1)

                    file.write(line + '\n')

                # print(f'{is_related=}')
                #if not is_related:
                updated_sections = process_sections(local_sections, ib_array, is_master_file,
                                                                            rabbit_thing, custom_namespace, is_related)
                #else:
                #    updated_sections = local_sections

                # updated_sections, resources = grab_resources(updated_sections, ib_array)
                # print("After grab_resources:", updated_sections)

                # Write sections
                target_strings = ['match_priority', 'allow_duplicate_hash', 'match_first_index', 'match_index_count']

                parsed_section_headers = {}

                used_variables = []
                declared_variables = []

                resources = []

                warnings_free_updated_sections = []

                modified_section = False

                for section in updated_sections:
                    if 'resource' in section['header'].lower():
                        resources.append(section['header'].lower())
                        continue

                for index, section in enumerate(updated_sections):
                    header = section['header']
                    content = section['content']

                    #if 'textureoverride' in header.lower() or 'shaderoverride' in header.lower() or 'constants' in header.lower() or 'commandlist' in header.lower() or 'customshader' in header.lower() or 'key' in header.lower():

                    modified_content = []

                    close_endif = 0

                    for line in content:

                        if close_endif > 0 and 'endif' in line:
                            line = ';' + line
                            close_endif -= 1

                        if ('943068897' in line or '857068213' in line) and not line.strip().startswith(';'):
                            if 'if' in line and 'else' not in line and 'elif' not in line:
                                close_endif += 1
                            line = ';' + line

                        match = re.search(r'(?:=\s*(resource[\w\-\.\/\\]+))|(?:\b(resource[\w\-\.\/\\]+)\s*=)',
                                          line.lower())

                        if match:
                            resource_name = "[" + (match.group(1) or match.group(2)).lower() + "]"

                            if '\\' not in resource_name and resource_name not in resources:
                                if re.search(r'.\d+', resource_name):
                                    number = re.search(r'.\d+', resource_name)[0]
                                    if number != '.0':
                                        if resource_name.replace(number, '.0') not in resources:
                                            line = ";" + line  # Comment out the line
                                        else:
                                            line = line.replace(number, '.0')
                                else:
                                    line = ";" + line  # Comment out the line

                                modified_section = True

                        if line.strip().startswith('global') and any(
                                var in declared_variables for var in re.findall(r'\$\w+', line)):
                            line = ";" + line  # Comment out the lin                     modified_section = True e
                            modified_section = True

                        if not line.strip().startswith(";"):
                            if line.strip().startswith(("global", "local", "persist")):
                                declared_variables += re.findall(r'\$\w+', line)
                            elif "$" in line:
                                if not any(var in used_variables for var in re.findall(r'\$\w+', line)):
                                    used_variables += re.findall(r'\$\w+', line)

                        modified_content.append(line)  # Store the modified line

                    # Replace original content with modified content
                    content[:] = modified_content

                    if 'constants' not in header.lower() and 'present' not in header.lower():

                        if header not in parsed_section_headers:
                            # Store the header and its index
                            parsed_section_headers[header] = index
                        else:
                            # Append the index to create a unique header
                            header = header.replace("]", f"{index}]")
                            parsed_section_headers[header] = index
                            modified_section = True

                    warnings_free_updated_sections.append({'header': header, 'content': content, 'modified': modified_section})

                for section in warnings_free_updated_sections:
                    if 'Constants' in section['header']:

                        vars_string = ""
                        for index, var in enumerate(used_variables):
                            new_line = ""
                            if index == len(used_variables) - 1:
                                new_line = "\n"
                            if 'Mod_Enabled' not in var and var.lower() not in (v.lower() for v in declared_variables):
                                vars_string = f"""global {var}"""
                                section['content'].insert(0, vars_string + new_line)

                        break
                    else:
                        continue

                updated_sections = warnings_free_updated_sections

                for section in updated_sections:

                    if 'header' not in section or 'content' not in section:
                        print("Invalid section detected, skipping:", section)
                        continue
                    file.write(section['header'] + '\n')

                    target_string_in = False
                    target_match = False

                    if 'commandlist' in section['header'].lower():
                        target_string_in = True

                    for line in section['content']:

                        line = line.replace('persist global', 'global persist')

                        if toggles:
                            for toggle in ini_content[3]:
                                if toggle[0] and toggle[6]:
                                    if 'condition' in line and 'ActiveTypeID && $mod_enabled == 1' not in line and \
                                            'global $' not in line and 'local $' not in line:

                                        # Ensure we don't add the same condition multiple times
                                        new_condition = f' && ${custom_namespace}mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                        if new_condition not in line:
                                            if toggle[6] in line:
                                                line = line.replace(toggle[6], toggle[6] + new_condition, 1)
                                            else:
                                                line = line.replace(toggle[0] + ']',
                                                                    toggle[0] + f']\ncondition ={new_condition}', 1)

                        if any(target in line for target in target_strings):
                            if target_string_in:
                                if any(target in line for target in ['match_first_index', 'match_index_count']):
                                    if target_match:
                                        if not line.strip().startswith(";"):
                                            line = ';' + line
                                    else:
                                        target_match = True
                                else:
                                    if not line.strip().startswith(";"):
                                        line = ';' + line
                            else:
                                target_string_in = True
                                if any(target in line for target in ['match_first_index', 'match_index_count']):
                                    target_match = True

                        #if (
                        #        'override_vertex_count' in line.strip() or 'override_byte_stride' in line.strip()) and not line.strip().startswith(
                        #        ";"):
                        #    line = ';' + line
                        file.write(line + '\n')
                    file.write('\n')  # Add a blank line between sections

                # Write post-section content
                for line in post_section_content:

                    if toggles:
                        for toggle in ini_content[3]:
                            if toggle[0] and toggle[6]:
                                if 'condition' in line and 'ActiveTypeID && $mod_enabled == 1' not in line and \
                                        'global $' not in line and 'local $' not in line:

                                    # Ensure we don't add the same condition multiple times
                                    new_condition = f' && ${custom_namespace}mod_type_id == $\\NuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                    if new_condition not in line:
                                        if toggle[6] in line:
                                            line = line.replace(toggle[6], toggle[6] + new_condition, 1)
                                        else:
                                            line = line.replace(toggle[0] + ']',
                                                                toggle[0] + f']\ncondition ={new_condition}', 1)
                    file.write(line + '\n')

                # print(resources)
                # file.write('\n\n'+resources)
                #
                # new_variables = []
                # temp_variables = Variables
                #
                # for resource in resources.splitlines():
                #    resource = resource.replace('Resource', 'Model').replace("Diffuse", "").replace("IB", "").replace("Position", "").replace("Texcoord", "").replace(".", "").strip("[]")
                #    if resource is not '' and resource not in new_variables:
                #        new_variables.append(resource)
                #
                # print(resources)
                # for new_variable in new_variables:
                #    temp_variables += f"\n\nglobal ${new_variable} = 1"
                #
                # print(temp_variables, "YEGSEG")
                # file.write('\n\n'+temp_variables)

                if is_master_file:
                    custom_namespace = backup_custom_namespace

                if not is_related:

                    if not toggles:
                        if os.path.exists(os.path.join(folder_path, 'Toggles.txt')):
                            toggles = True

                    file.write('\n\n' + Variables.format(mod_type_id = type_id, Swap_Var = swapvar))

                    Resource_Sections = []
                    # Add Toggles section
                    Resource_Sections.append(f'''[ResourceModPath]
type = Buffer
data = "{file_path}"''')

                    if toggles:
                        Resource_Sections.append("""[ResourceModToggles]
type = Buffer
format = R8_UINT
filename = Toggles.txt""")

                    # Add Author section
                    if credits_string != '""' and not has_author:
                        Resource_Sections.append(f"""[ResourceModAuthor]
type = Buffer
data = {credits_string}""")

                    # Add Name section
                    if mod_name != '""' and not has_mod_name:
                        Resource_Sections.append(f"""[ResourceModName]
type = Buffer
data = {mod_name}""")

                    file.write('\n\n' + Present_Section + '\n\n'.join(Resource_Sections))

                    SetPath = "\n\tResource\\NuraThings\\ModManager\\ModPath = ref ResourceModPath unless_null"
                    SetToggles = "\n\tResource\\NuraThings\\ModManager\\ModToggles = ref ResourceModToggles unless_null" if toggles else ""
                    SetAuthor = "\n\tResource\\NuraThings\\ModManager\\ModAuthor = ref ResourceModAuthor unless_null" if credits_string != '""' else ""
                    SetModName = "\n\tResource\\NuraThings\\ModManager\\ModName = ref ResourceModName unless_null" if mod_name != '""' else ""

                    file.write(
                        CommandListContent.format(Set_Path = SetPath, Set_Toggles = SetToggles, Set_Author = SetAuthor,
                                                  Set_Mod_Name = SetModName, Swap_Var1 = swapvar1,
                                                  Swap_Var2 = swapvar2))

            print(f"Updated .ini file: {file_path}")
        except Exception as e:
            print(f"Error updating .ini file: {e}")

    # print(f"Finished processing file: {file_path}")


if __name__ == "__main__":
    # Starting point for the search
    root_folder = os.getcwd()

    # Step 1: Collect all .ini files
    ini_files, ini_paths = collect_ini_files(root_folder)

    # Step 2: Process all .ini files
    sections, ib_sections, ib_array, identifiers, ini_content = process_all_ini_files(ini_paths)
    print(f"Found {len(ini_files)} INI files.")
    print(f"Parsed {len(sections)} sections in total.")
    print(f"Found {len(ib_sections)} IB sections.")
    # print(f"IB Hashes by Identifier: {ib_array}")
    # print(f"Identifiers: {sorted(identifiers)}")
    # print(f"Ini Content: {ini_content}")

    # Array to store the new strings
    resource_strings = []

    # Helper function to create a unique string entry
    # def create_unique_entry(hash_value, match_first_index, match_index_count, existing_array):
    #    # Build the string based on the provided values
    #    resource_name = f"Resource{hash_value}{match_first_index if match_first_index is not None else ''}{match_index_count if match_index_count is not None else ''}"
    #    texture_override_name = f"TextureOverride{hash_value}{match_first_index if match_first_index is not None else ''}{match_index_count if match_index_count is not None else ''}"
#
#    new_entry = (
#        f"[{resource_name}]\n\n"
#        f"[{texture_override_name}]\n"
#        f"hash = {hash_value}\n"
#        f"match_priority = -100\n"
#        f"{f'match_first_index = {match_first_index}\n' if match_first_index is not None else ''}"
#        f"{f'match_index_count = {match_index_count}\n' if match_index_count is not None else ''}"
#    )
#
#    # Check if the entry is already in the array
#    if new_entry not in existing_array:
#        existing_array.append(new_entry)
#    else:
#        print(f"Skipped duplicate entry for hash: {hash_value}")

## Iterate through the IB array to generate strings
# for namespace, identifiers in ib_array.items():
#    for identifier, hashes in identifiers.items():
#        for entry in hashes:
#            hash_value = entry["hash"]
#            match_first_index = entry.get("match_first_index")
#            match_index_count = entry.get("match_index_count")
#
#            # Create a unique string and add it to the array
#            create_unique_entry(hash_value, match_first_index, match_index_count, resource_strings)