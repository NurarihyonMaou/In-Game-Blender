import math
import os
import re
import random
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from collections import Counter, defaultdict
from pathlib import Path

PROCESSED_TRACKER = "ProcessedFiles.json"
TYPE_COUNTS_FILE = "TypeCounts.json"


def _has_textures_ini(dds: Path) -> bool:
    if not dds.is_dir():
        return False
    # only check immediate children of DDS (adjust to recurse if you want)
    return any(child.is_file() and child.name.lower() in ("textures.ini", "texture.ini")
               for child in dds.iterdir())


def is_caverabbit_root(folder: Path) -> bool:
    if not folder.is_dir():
        return False

    if not any(folder.glob("*.ini")):
        return False

    subs = {p.name.lower() for p in folder.iterdir() if p.is_dir()}
    if not {"dds", "mod"}.issubset(subs):
        #print("❌ Missing DDS or MOD subfolders in:", folder, "found:", subs)
        return False

    dds_folder = folder / "DDS"
    if not dds_folder.is_dir():
        #print("❌ DDS folder missing:", dds_folder)
        return False

    has_tex_ini = any(
        child.is_file() and child.name.lower() in ("textures.ini", "texture.ini")
        for child in dds_folder.iterdir()
    )
    if not has_tex_ini:
        #print("❌ No textures.ini in DDS:", dds_folder)
        return False

    #print("✅ CaveRabbit root confirmed:", folder)
    return True



def load_processed_files(path=PROCESSED_TRACKER):
    if not os.path.exists(path):
        return set()
    with open(path, "r", encoding="utf-8") as f:
        return set(json.load(f))


def save_processed_files(processed_files, path=PROCESSED_TRACKER):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(sorted(processed_files), f, indent=2)


def load_type_counts(path=TYPE_COUNTS_FILE):
    if not os.path.exists(path):
        return defaultdict(Counter)
    with open(path, "r", encoding="utf-8") as f:
        data = json.load(f)
    return defaultdict(Counter, {k: Counter(v) for k, v in data.items()})


def save_type_counts(local_type_id_to_candidate_counts, path=TYPE_COUNTS_FILE):
    to_save = {k: dict(v) for k, v in local_type_id_to_candidate_counts.items()}
    with open(path, "w", encoding="utf-8") as f:
        json.dump(to_save, f, indent=2, ensure_ascii=False)


Variables = """[Constants]
; Mod Manager
global $NuraManager_active = 0

global $run_manage = 0

global $mod_type_id = {mod_type_id}
global persist $mod_id = -1
global persist $mod_enabled

global persist $bound_mod_type
global persist $bound_mod_id

global $swapped_in = 1
global $set_random = 1

global $IncludedInMaxCount = 0
global $Nura_Manager_First_Run = 1
global $Nura_Manager_Init = 1

global $Resources_Set = 0

global $once_per_frame = 1

global $add_mod_name = 0

global $run_counter = 0

global $QueuePos

post $\\zzzzzNuraThings\\ModManager\\tempModID = $mod_id
post $\\zzzzzNuraThings\\ModManager\\tempModTypeID = $mod_type_id
post Resource\\zzzzzNuraThings\\ModManager\\TempModName = ref ResourceModName unless_null
  
post run = CustomShader\\zzzzzNuraThings\\ModManager\\AllModsNames

post $\\zzzzzNuraThings\\ModManager\\AllModsCount = $\\zzzzzNuraThings\\ModManager\\AllModsCount+1

post run = CommandListAddBound
{Swap_Var}
"""

Present_Section = f'''[Present]
; Mod Manager
if $NuraManager_active > 0
    $NuraManager_active = $NuraManager_active-1
endif

if $NuraManager_active == 0
    $swapped_in = 1
    $set_random = 1
endif

$once_per_frame = 1

if $run_counter == 2
	$run_counter = 0
endif

if $run_counter == 1
	$run_counter = 2
endif

if $\\zzzzzNuraThings\\ModManager\\BindMod
    if $mod_type_id == $\\zzzzzNuraThings\\ModManager\\to_y_type_id && $mod_id == $\\zzzzzNuraThings\\ModManager\\to_y
        run = CommandListSetBoundMod
    endif
endif

if $\\zzzzzNuraThings\\ModManager\\unbind_type == $mod_type_id && $\\zzzzzNuraThings\\ModManager\\unbind_id == $mod_id
    $bound_mod_type = 0
    $bound_mod_id = 0
    
    $\\zzzzzNuraThings\\ModManager\\bound_mod_type = 0
    $\\zzzzzNuraThings\\ModManager\\bound_mod_id = 0
    $\\zzzzzNuraThings\\ModManager\\ReloadBoundModsList = 3
endif

if $\\zzzzzNuraThings\\ModManager\\bound_mod_type == $mod_type_id
    if $\\zzzzzNuraThings\\ModManager\\bound_mod_id == $mod_id
        $mod_enabled = 1
        
        if $mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID
            run = CommandList\\zzzzzNuraThings\\ModManager\\ResetResources
            $\\zzzzzNuraThings\\ModManager\\ActiveID = $mod_id
        endif
    else
        $mod_enabled = 0
    endif
endif

if $run_manage
    run = CommandListManageMod
    $run_manage = 0
endif

if $\\zzzzzNuraThings\\ModManager\\ReloadBoundModsList == 2
    run = CommandListAddBound
endif

if $Nura_Manager_Init && $mod_id == -1
    $\\zzzzzNuraThings\\ModManager\\init_mod_type_id = $mod_type_id
    run = CommandList\\zzzzzNuraThings\\ModManager\\HandleInit
    $mod_id = $\\zzzzzNuraThings\\ModManager\\init_mod_count

    $\\zzzzzNuraThings\\ModManager\\tempModID = $mod_id
    Resource\\zzzzzNuraThings\\ModManager\\TempModName = ref ResourceModName unless_null
     
    run = CustomShader\\zzzzzNuraThings\\ModManager\\AddModName

    $Nura_Manager_Init = 0
endif


'''

CommandListContent = """\n\n[CommandListAddBound]
if $bound_mod_type > 0 && $bound_mod_id > 0
    $\\zzzzzNuraThings\\ModManager\\temp_mod_type_id = $mod_type_id
    $\\zzzzzNuraThings\\ModManager\\temp_mod_id = $mod_id

    $\\zzzzzNuraThings\\ModManager\\temp_bound_mod_type = $bound_mod_type
    $\\zzzzzNuraThings\\ModManager\\temp_bound_mod_id = $bound_mod_id
    
    run = CustomShader\\zzzzzNuraThings\\ModManager\\BoundPairs
endif

[CommandListSetBoundMod]
$bound_mod_type = $\\zzzzzNuraThings\\ModManager\\bind_x_type_id
$bound_mod_id = $\\zzzzzNuraThings\\ModManager\\bind_x

$\\zzzzzNuraThings\\ModManager\\BindMod = 0
$\\zzzzzNuraThings\\ModManager\\ReloadBoundModsList = 3
\n\n[CommandListSetActive]
if $mod_enabled
    $\\zzzzzNuraThings\\ModManager\\ActiveID = $mod_id
    $\\zzzzzNuraThings\\ModManager\\ChangedID = 0
endif
\n\n[CommandListManageMod]       
$NuraManager_active = 10

if $mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID
    if $\\zzzzzNuraThings\\ModManager\\SetActive == 1
        run = CommandListSetActive
    endif
    
    if $\\zzzzzNuraThings\\ModManager\\ResetNames == 1
        $\\zzzzzNuraThings\\ModManager\\tempModID = $mod_id
        Resource\\zzzzzNuraThings\\ModManager\\TempModName = ref ResourceModName unless_null
            
        run = CustomShader\\zzzzzNuraThings\\ModManager\\AddModName
    endif
endif


if ($run_counter == 0) && ($swapped_in || $\\zzzzzNuraThings\\ModManager\\ResetIDs == 1)

    $run_counter = $run_counter+1

    $\\zzzzzNuraThings\\ModManager\\ModTypeID = $mod_type_id

    run = CustomShader\\zzzzzNuraThings\\ModManager\\HandleModelIDs

    if $mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID

        if $\\zzzzzNuraThings\\ModManager\\ResetNames == 0
            $\\zzzzzNuraThings\\ModManager\\tempModID = $mod_id
            Resource\\zzzzzNuraThings\\ModManager\\TempModName = ref ResourceModName unless_null
                
            run = CustomShader\\zzzzzNuraThings\\ModManager\\AddModName
        endif
        
        run = CommandListSetActive

        if $set_random
            if $\\zzzzzNuraThings\\ModManager\\Random_Mode == 1
                $\\zzzzzNuraThings\\ModManager\\get_random_id = 1
            endif

            if $Nura_Manager_First_Run
                if $\\zzzzzNuraThings\\ModManager\\Random_Mode == 2
                    $\\zzzzzNuraThings\\ModManager\\get_random_id = 1
                endif
                $Nura_Manager_First_Run = 0
            endif
            $set_random = 0
        endif
    endif

    if $swapped_in
        $\\zzzzzNuraThings\\ModManager\\modded_objects_detections = $\\zzzzzNuraThings\\ModManager\\modded_objects_detections + 1
    endif

    $swapped_in = 0
endif


if $mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID

    $\\zzzzzNuraThings\\ModManager\\ModCount = $\\zzzzzNuraThings\\ModManager\\ModCount+1

    if $mod_id == -1 || $\\zzzzzNuraThings\\ModManager\\ResetIDs == 2
        $mod_id = $\\zzzzzNuraThings\\ModManager\\ModCount
    endif

    $\\zzzzzNuraThings\\ModManager\\ModID = $mod_id

    run = CustomShader\\zzzzzNuraThings\\ModManager\\HandleModIDs
    
    if !$\\zzzzzNuraThings\\ModManager\\ChangedID
        run = CommandListSetActive
    endif
    
    $\\zzzzzNuraThings\\ModManager\\holding_var = $mod_id
    run = CommandList\\zzzzzNuraThings\\ModManager\\CountIDsSum
    
    if $mod_id == $\\zzzzzNuraThings\\ModManager\\ActiveID
        $mod_enabled = 1

        {Set_Path}{Set_Toggles}{Set_Author}{Set_Mod_Name}{Set_Description}

        {Swap_Var1}
    else
        $mod_enabled = 0
        {Swap_Var2}
    endif
endif

$\\zzzzzNuraThings\\ModManager\\AllModsActiveCount = $\\zzzzzNuraThings\\ModManager\\AllModsActiveCount+1

if $mod_enabled
    if $bound_mod_type > 0 && $bound_mod_id > 0
        if $QueuePos == 0
            $\\zzzzzNuraThings\\ModManager\\BindQueue = $\\zzzzzNuraThings\\ModManager\\BindQueue + 1
            $QueuePos = $\\zzzzzNuraThings\\ModManager\\BindQueue
        endif
    
        if $\\zzzzzNuraThings\\ModManager\\BindQueuePos == $QueuePos
            $\\zzzzzNuraThings\\ModManager\\bound_mod_type = $bound_mod_type
            $\\zzzzzNuraThings\\ModManager\\bound_mod_id = $bound_mod_id

            $QueuePos = 0
        endif
    endif
endif
"""

mod_type_to_name = {}
type_id_to_candidate_counts = load_type_counts()


def cut_path_after_mods(path):
    # Normalize path separators
    norm_path = os.path.normpath(path)
    parts = norm_path.split(os.sep)

    if "Mods" in parts:
        idx = parts.index("Mods")
        return os.path.join(*parts[idx+1:])
    else:
        return norm_path  # fallback: return full path if 'Mods' not found


def base40_encode_chunk(chunk):
    base40_chars = " 123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ+-."
    char_to_val = {c: i for i, c in enumerate(base40_chars)}

    vals = []
    for ch in chunk:
        val = char_to_val.get(ch.upper(), 0)
        vals.append(val)

    # Pad to 4 chars with spaces (val=0)
    while len(vals) < 4:
        vals.append(0)

    code = vals[0] + vals[1] * 40 + vals[2] * 40**2 + vals[3] * 40**3
    return code


def base40_encode(name):
    # Split the name into 4-char chunks
    chunks = [name[i:i+4] for i in range(0, len(name), 4)]

    encoded_ints = []
    for chunk in chunks:
        encoded_ints.append(base40_encode_chunk(chunk))
    return encoded_ints


def format_mod_name(name):
    name = name.strip()
    lower = name.lower()

    if lower.startswith("master") and len(name) > 6:
        name = "Master" + name[6:7].upper() + name[7:]
    else:
        name = name[0].upper() + name[1:]

    # Normalize special suffixes
    name = re.sub(r'(effect)$', 'EFFECT', name, flags=re.IGNORECASE)
    name = re.sub(r'(fx)$', 'FX', name, flags=re.IGNORECASE)

    return name


def generate_setname_command_with_resources():
    out = ["namespace = yyyyyNuraThings\\ModManager\\ModelName\n"]

    # Build the basic mod_type_to_name mapping
    for type_id, counter in type_id_to_candidate_counts.items():
        best_candidate, _ = counter.most_common(1)[0]
        mod_type_to_name[type_id] = best_candidate

    # Sort by the formatted name
    sorted_items = sorted(
        mod_type_to_name.items(),
        key=lambda kv: format_mod_name(kv[1]).lower()
    )

    # Constants & initialization
    out += [
        "[Constants]\n",
        "global $init = 1\n",
        f"global $Amount = {len(mod_type_to_name)}\n",
        "\n[CommandListSetName]\n",
        "if $init == 1"
    ]

    # First pass: run the AddAllModelNames shader for each type in sorted order
    for modtype_id, name in sorted_items:
        safe_name = format_mod_name(name)
        resource_name = f"Resource{safe_name}"
        out += [
            f"\n\t$\\zzzzzNuraThings\\ModManager\\tempModTypeID = {modtype_id}",
            f"\tResource\\zzzzzNuraThings\\ModManager\\TempModelName = {resource_name}",
            "\trun = CustomShader\\zzzzzNuraThings\\ModManager\\AddAllModelNames"
        ]

    out += [
        "\n\trun = CustomShader\\zzzzzNuraThings\\ModManager\\AddCountToModelNames",
        "\n\t$init = 0",
        "endif\n"
    ]

    # Second pass: build the if/elif chain for ActiveTypeID → ModelName resource
    for idx, (modtype_id, name) in enumerate(sorted_items):
        prefix = "if" if idx == 0 else "elif"
        safe_name = format_mod_name(name)
        resource_name = f"Resource{safe_name}"
        out += [
            f"{prefix} $\\zzzzzNuraThings\\ModManager\\ActiveTypeID == {modtype_id}",
            f"    Resource\\zzzzzNuraThings\\ModManager\\ModelName = {resource_name}"
        ]

    out.append("endif\n")

    # Third pass: declare each ResourceXXX section exactly once, in sorted order
    generated = set()
    for _, name in sorted_items:
        safe_name = format_mod_name(name)
        if safe_name not in generated:
            resource_name = f"Resource{safe_name}"
            out += [
                f"[{resource_name}]",
                "type = Buffer",
                f'data = "{name}"',
                ""  # blank line
            ]
            generated.add(safe_name)

    return "\n".join(out)


def save_setname_ini():
    content = generate_setname_command_with_resources()

    base_path = os.getcwd()
    full_path = os.path.join(base_path, 'BufferValues', 'NuraThings', 'ModManager')

    file_path = os.path.join(full_path, 'SetModelName.ini')
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
        print(f"SetModelName.ini saved to: {file_path}")

    save_type_counts(type_id_to_candidate_counts)


def extract_model_name(file_path, folder_name, ini_string):
    candidates = []

    # Helper to split camelCase/PascalCase parts better
    def split_camel_case(s):
        return re.findall(r'[A-Z][a-z]*|[a-z]+', s)

    # 1. Highest Priority: Check for full namespace path
    match = re.search(r'namespace\s*=\s*(.+)', ini_string)
    if match:
        full_namespace = match.group(1).strip()
        #last_segment = os.path.basename(full_namespace.replace("\\", "/"))  # handles both \ and /
        words = split_camel_case(full_namespace)
        if words:
            return ''.join(words)

    # From folder name
    folder_base = os.path.basename(folder_name)
    candidates += split_camel_case(folder_base)

    # From filenames in ini content
    filenames = re.findall(r'filename\s*=\s*(.+)', ini_string)
    for path in filenames:
        parts = os.path.normpath(path).split(os.sep)
        for part in parts:
            words = split_camel_case(part)
            candidates.extend(words)

    # From section headers
    section_headers = re.findall(r'\[(.*?)\]', ini_string)
    for header in section_headers:
        words = split_camel_case(header)
        candidates.extend(words)

    blacklist = {
        'resource', 'position', 'blend', 'texcoord', 'body', 'dress', 'head', 'extra', 'face', 'fx', 'nata', 'hood',
        'ib', 'vb', 'buffer', 'file', 'override', 'texture', 'natlan',
        'limit', 'raise', 'vertex', 'index', 'shader', 'effect',
        'sub', 'alter', 'none', 'normal', 'map', 'diffuse', 'light',
        'buf', 'dds', 'png'
    }

    filtered = [w for w in candidates if len(w) >= 3 and w.lower() not in blacklist]

    if not filtered:
        return folder_base

    counts = Counter(filtered)
    return counts.most_common(1)[0][0]


def collect_ini_files(root_path):
    """
    Recursively collects new .ini files from the given root path,
    excluding unwanted directories and already processed files.
    """
    ini_files = []
    ini_paths = []

    already_processed = load_processed_files()
    newly_processed = set()

    def process_folder(folder_path):
        local_ini_files = []
        local_ini_paths = []

        for dirpath, _, filenames in os.walk(folder_path):
            if 'BufferValues' in dirpath or 'disabled' in dirpath.lower() or "noigmm" in dirpath.lower():
                continue

            for filename in filenames:
                file_path = os.path.join(dirpath, filename)

                if filename.endswith(".ini") and \
                   all(x not in filename.lower() for x in ["desktop", "ntuser", "backup", "disabled", "noigmm"]) and \
                   file_path not in already_processed:

                    local_ini_files.append(filename)
                    local_ini_paths.append(file_path)
                    newly_processed.add(file_path)

        return local_ini_files, local_ini_paths

    with ThreadPoolExecutor() as executor:
        futures = [executor.submit(process_folder, root_path)]
        for future in as_completed(futures):
            local_files, local_paths = future.result()
            ini_files.extend(local_files)
            ini_paths.extend(local_paths)

    # Update the record of processed files
    save_processed_files(already_processed.union(newly_processed))

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


# Monospace settings
CHAR_WIDTH = 10  # pixels per character (used for comment only)
GAP_CHARS = 2    # space characters between columns
MAX_LINE_CHARS = 44  # max full row width in characters (800 px at 10px/char)

def smart_split(text: str) -> list[str]:
    """Keep grouped phrases like 'or VK_LEFT' together."""
    return re.findall(r'(?:or\s+\S+|\S+)', text)

def wrap_to(text: str, max_chars: int) -> list[str]:
    """
    Wrap text so each line length ≤ max_chars.
    Avoid orphaning small trailing characters unless word is much too long.
    """
    if len(text) < max_chars:
        return [text]
    words = smart_split(text)
    lines = []
    curr = ""
    i = 0
    while i < len(words):
        w = words[i]
        i += 1
        needed = len(w) if not curr else len(curr) + 1 + len(w)
        if needed <= max_chars:
            curr = w if not curr else curr + ' ' + w
        else:
            if curr:
                lines.append(curr)
                curr = ""
            if len(w) > max_chars:
                # Hard-break only if long enough
                start = 0
                while start < len(w):
                    part = w[start:start+max_chars]
                    lines.append(part)
                    start += max_chars
            else:
                curr = w
    if curr:
        lines.append(curr)
    return lines



def pad_left(text: str, max_chars: int) -> str:
    return text + ' ' * max(0, max_chars - len(text))

def pad_center(text: str, max_chars: int) -> str:
    total = max(0, max_chars - len(text))
    left = total // 2
    return ' ' * left + text + ' ' * (total - left)

def sep_piece(width_chars: int) -> str:
    return '-' * width_chars

def handle_toggles(toggles, file_path):
    folder = os.path.dirname(file_path)

    # Gather toggle rows
    rows, hold_rows = [], []
    for name, keys, typ, var, val, count, cond, backs in toggles:
        if not (name and keys and typ and val):
            continue
        t = typ.lower()
        if t == "cycle":
            t = "Cycle"
        elif t is None:
            t = "Default"
        act = var.capitalize() if isinstance(var, str) else str(var)
        ext = f" + {backs}" if backs else ''
        if t == 'Hold':
            hold_rows.append((act, keys))
        else:
            amt = 2 if t == 'Toggle' else (count if isinstance(count, int) else 0)
            rows.append((act, t, keys + ext, str(amt)))

    if not rows and not hold_rows:
        return

    headers = ('Action', 'Type', 'Keys', 'Amt')
    cols = list(zip(*rows)) if rows else [(), (), (), ()]

    # Step 1: Determine raw content widths
    raw_max_chars = []
    for i, head in enumerate(headers):
        items = [head] + list(cols[i])
        raw_max_chars.append(max(len(it) for it in items))

    # Step 2: Clamp Amt column to max 3
    raw_max_chars[3] = min(raw_max_chars[3], 3)

    # Step 3: Distribute width within MAX_LINE_CHARS
    total_gap = GAP_CHARS * (len(headers) - 1)
    available_width = MAX_LINE_CHARS - total_gap

    total_raw = sum(raw_max_chars)
    if total_raw <= available_width:
        max_chars = raw_max_chars[:]
    else:
        # Minimum widths: Action, Type, Keys, Amt
        min_widths = [max(5, x) for x in [6, 5, 8, 3]]
        scale = available_width / total_raw
        max_chars = [max(min_w, int(raw * scale)) for raw, min_w in zip(raw_max_chars, min_widths)]

        # Ensure Amt is no more than 3
        if max_chars[3] > 3:
            freed = max_chars[3] - 3
            max_chars[3] = 3
            # Redistribute freed space to other columns
            other_cols = [(max_chars[i], i) for i in range(3)]
            other_cols.sort(reverse=True)  # prioritize wider columns
            i = 0
            while freed > 0 and other_cols:
                width, idx = other_cols[i % len(other_cols)]
                max_chars[idx] += 1
                freed -= 1
                i += 1

        # Re-check total fit and shrink if necessary
        while sum(max_chars) > available_width:
            # Shrink biggest column (except Amt at index 3)
            biggest = max(range(3), key=lambda i: max_chars[i])
            if max_chars[biggest] > min_widths[biggest]:
                max_chars[biggest] -= 1
            else:
                break

    # Step 4: Fix 1-character overflows in any column
    for col_idx in range(4):
        col_data = cols[col_idx] if cols else []
        curr_width = max_chars[col_idx]
        for cell in col_data:
            if len(cell) == curr_width + 1:
                max_chars[col_idx] += 1
                # Compensate by shrinking other columns
                for j in range(4):
                    if j != col_idx and max_chars[j] > min_widths[j]:
                        max_chars[j] -= 1
                        break
                break

    # --- Output table ---

    gap = ' ' * GAP_CHARS
    hdr = gap.join(pad_center(headers[i], max_chars[i]) for i in range(4))
    sep = gap.join(sep_piece(max_chars[i]) for i in range(4))
    lines = [hdr, sep]

    for a, t, k, m in rows:
        parts = [
            wrap_to(a, max_chars[0]),
            wrap_to(t, max_chars[1]),
            wrap_to(k, max_chars[2]),
            wrap_to(m, max_chars[3]),
        ]
        max_lines = max(len(p) for p in parts)
        for i in range(4):
            while len(parts[i]) < max_lines:
                parts[i].append('')

        for li in range(max_lines):
            c0 = pad_left  (parts[0][li], max_chars[0])
            c1 = pad_center(parts[1][li], max_chars[1]) if li == 0 else pad_left(parts[1][li], max_chars[1])
            c2 = pad_center(parts[2][li], max_chars[2]) if li == 0 else pad_left(parts[2][li], max_chars[2])
            c3 = pad_center(parts[3][li], max_chars[3]) if li == 0 else pad_left(parts[3][li], max_chars[3])
            lines.append(gap.join((c0, c1, c2, c3)))

    if hold_rows:
        lines.append('')
        lines.append('Hold controls:')
        for a, k in hold_rows:
            lines.append(f"- {pad_left(a, max_chars[0])}: {k}")

    out = os.path.join(folder, "Toggles.txt")
    with open(out, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"Generated Toggles.txt in: {folder}")



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
    has_mod_description = False

    ini_content = {}

    namespace = ''
    is_custom_namespace = False
    is_master_file = False

    credits_string = ''

    # Regex patterns
    section_start_regex = re.compile(r"^\[(?!;).*?\]")  # Matches section headers
    ib_regex = re.compile(r"(ib|vb0)\s*=\s*(Resource|null).*", re.IGNORECASE)  # Matches 'IB = ResourceX'
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

            if 'ResourceModDescription' in data:
                has_mod_description = True

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

            p = Path(file_path)

            if not is_master_file:
                if is_caverabbit_root(p.parent):
                    is_master_file = True
                    namespace = str(p)
                    is_custom_namespace = True

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

            if 'ResourceModDescription' in data:
                has_mod_description = True

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

            p = Path(file_path)

            if not is_master_file:
                if is_caverabbit_root(p.parent):
                    is_master_file = True
                    namespace = str(p)
                    is_custom_namespace = True

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
        elif re.findall(r"hash\s*=\s*([a-fA-F0-9]+)\r?\nthis\s*=\s*(Resource\w+)", content):
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
                   has_author, has_mod_name, is_master_file, rabbit_thing, namespace, is_custom_namespace, has_mod_description]

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


def group_hashes_and_assign_ids(ib_array, ini_paths, save_path="GroupedHashes.json"):
    """
    Groups namespaces by overlapping hashes and assigns unique IDs to groups.
    """
    from collections import defaultdict

    namespace_to_group = {}
    group_to_hashes = load_grouped_hashes(save_path)
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
    save_grouped_hashes(save_path, final_group_to_hashes)
    return final_group_to_hashes


def save_grouped_hashes(filepath, group_to_hashes):
    serializable = {str(k): list(v) for k, v in group_to_hashes.items()}
    with open(filepath, "w", encoding="utf-8") as f:
        json.dump(serializable, f, indent = 2)


def load_grouped_hashes(filepath):
    if not os.path.exists(filepath):
        return {}
    with open(filepath, "r", encoding="utf-8") as f:
        raw = json.load(f)
    return {int(k): set(v) for k, v in raw.items()}


# , rabbit_thing=False
def process_sections(sections, ib_array, is_master_file, rabbit_thing, custom_namespace, is_related, type_id):
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
                content.insert(hash_index + 1, f"match_priority = {type_id}")
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
                content.insert(priority_index + 1, "$run_manage = 1")
                #content.insert(priority_index + 1, "if $once_per_frame")
                #content.insert(priority_index + 2, "\trun = CommandListManageMod")
                #content.insert(priority_index + 3, "$once_per_frame = 0")
                #content.insert(priority_index + 4, "endif")
                #content.insert(priority_index + 5, "")
                #content.insert(priority_index + 1, "run = CommandListManageMod")
                #content.insert(priority_index + 2, "")

        # Adjust indentation for the content
        depth = 0
        indent = ' ' * 4
        indented_content = []

        disable_section = False

        for line in content:
            line = re.sub(
                r'(\bmatch_priority\s*=\s*)-?\d+',
                rf'\1{type_id}',
                line,
                flags = re.IGNORECASE
            )

            if disable_section and not any(target in line for target in target_strings):
                line = ';'+line

            if 'hash=ebac056e' in line.replace(" ", "").lower():
                disable_section = True

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

    with open(file_path, 'r', encoding="utf-8") as f:
        ini_data = [line.strip() for line in f.readlines()]

    model_name = extract_model_name(file_path, file_path.split('\\')[-1], "\n".join(ini_data))
   # print(model_name)
    type_id = -1

    is_related = False

    pre_section_content = ini_content[0]
    local_sections = ini_content[1]
    post_section_content = ini_content[2]

    is_master_file = ini_content[8]
    custom_namespace = ''

    local_namespace = ini_content[10]

    is_custom_namespace = ini_content[11]

    p = Path(file_path)

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

    if not is_master_file:
        folder = p.parent
        root = folder

        if folder.parent.exists():
            #print("Parent exists, checking CaveRabbit root:", folder.parent)
            if is_caverabbit_root(folder.parent):
               # print("Detected CaveRabbit root at", folder.parent)
                root = folder.parent
            #else:
            #    print("Not a CaveRabbit root:", folder.parent)

        if is_caverabbit_root(root):
            #print("Confirmed root:", root)
            try:
                rel = p.relative_to(root)
                #print("Relative path:", rel)
            except ValueError:
                print("ValueError in relative_to:", p, root)
                rel = None

            if rel:
                parts = [x.lower() for x in rel.parts]
                if parts and parts[0] in ("dds", "mod"):
                    is_related = True
                    shortest_match = None
                    custom_namespace = ''
                    #print(all_custom_namespaces)
                    for custom_namespace_dict in all_custom_namespaces:
                        for master_path, master_namespace in custom_namespace_dict.items():
                            # Check if this file is under the master file's folder (CaveRabbit root)
                            master_folder = Path(master_path).parent
                            if str(master_folder) in file_path:  # file_path is the current INI
                                    custom_namespace = "\\Mods\\" + cut_path_after_mods(master_namespace) + "\\"

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
    has_mod_description = ini_content[12]

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

    if type_id != -1 and model_name:
        type_id_to_candidate_counts[type_id][model_name] += 1
    #print(type_id_to_candidate_counts)
    if not already_modified and (type_id != -1 or is_related) and 'HideUID' not in custom_namespace:
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
                                    new_condition = f' && !$\\zzzzzNuraThings\\ModManager\\LockToggles && ${custom_namespace}mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                    if new_condition not in line:
                                        if toggle[6] in line:
                                            line = line.replace(toggle[6], f'({toggle[6]})' + new_condition, 1)
                                        else:
                                            line = line.replace(toggle[0] + ']',
                                                                toggle[0] + f']\ncondition ={new_condition}', 1)

                    file.write(line + '\n')

                # print(f'{is_related=}')
                #if not is_related:
                updated_sections = process_sections(local_sections, ib_array, is_master_file,
                                                                            rabbit_thing, custom_namespace, is_related, type_id)
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

                        #match = re.search(r'^(?!\s*filename\s*=)(?!.*\.hlsl\s*$).*?(?:=\s*(resource[\w\-\.\/\\]+)|\b(resource[\w\-\.\/\\]+)\s*=)',
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
                                if var == '$once_per_frame' or var == '$run_manage':
                                    continue
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
                    target_match_index = False
                    target_match_count = False
                    override_already_in = False

                    override_vertex_count_seen = False
                    override_byte_stride_seen = False

                    if 'commandlist' in section['header'].lower():
                        target_string_in = True

                    for line in section['content']:

                        line = line.replace('persist global', 'global persist')

                        line = line.replace('cylce', 'cycle')

                        if toggles:
                            for toggle in ini_content[3]:
                                if toggle[0] and toggle[6]:
                                    if 'condition' in line and 'ActiveTypeID && $mod_enabled == 1' not in line and \
                                            'global $' not in line and 'local $' not in line:

                                        # Ensure we don't add the same condition multiple times
                                        new_condition = f' && !$\\zzzzzNuraThings\\ModManager\\LockToggles && ${custom_namespace}mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                        if new_condition not in line:
                                            if toggle[6] in line:
                                                line = line.replace(toggle[6], f'({toggle[6]})' + new_condition, 1)
                                            else:
                                                line = line.replace(toggle[0] + ']',
                                                                    toggle[0] + f']\ncondition ={new_condition}', 1)

                        if any(target in line for target in target_strings):
                            if target_string_in:
                                if 'match_first_index' in line:
                                    if target_match_index:
                                        if not line.strip().startswith(";"):
                                            line = ';' + line  # Comment out duplicate
                                    else:
                                        target_match_index = True  # Mark the first occurrence

                                elif 'match_index_count' in line:
                                    if target_match_count:
                                        if not line.strip().startswith(";"):
                                            line = ';' + line  # Comment out duplicate
                                    else:
                                        target_match_count = True  # Mark the first occurrence

                                else:
                                    if not line.strip().startswith(";"):
                                        line = ';' + line  # Comment unrelated lines inside the block

                            else:
                                target_string_in = True
                                if 'match_first_index' in line:
                                    target_match_index = True
                                if 'match_index_count' in line:
                                    target_match_count = True

                        if 'override_vertex_count' in line.strip() and not line.strip().startswith(";"):
                            match = re.search(r'\d+', line)
                            count = int(match.group()) if match else 0

                            if count < 100:
                                override_vertex_count_seen = True
                                override_byte_stride_seen = True

                            if override_vertex_count_seen:
                                line = ';' + line  # Comment out duplicate
                            else:
                                override_vertex_count_seen = True  # Mark first occurrence

                        elif 'override_byte_stride' in line.strip() and not line.strip().startswith(";"):
                            if override_byte_stride_seen:
                                line = ';' + line  # Comment out duplicate
                            else:
                                override_byte_stride_seen = True  # Mark first occurrence

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
                                    new_condition = f' && !$\\zzzzzNuraThings\\ModManager\\LockToggles && ${custom_namespace}mod_type_id == $\\zzzzzNuraThings\\ModManager\\ActiveTypeID && ${custom_namespace}mod_enabled == 1'

                                    if new_condition not in line:
                                        if toggle[6] in line:
                                            line = line.replace(toggle[6], f'({toggle[6]})' + new_condition, 1)
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
data = "{cut_path_after_mods(file_path)}"''')

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

                    if not has_mod_description:
                        Resource_Sections.append(f""";[ResourceModDescription]
;type = Buffer
;data = """"")

                    file.write('\n\n' + Present_Section + '\n\n'.join(Resource_Sections))

                    SetPath = "\n\t\tResource\\zzzzzNuraThings\\ModManager\\ModPath = ref ResourceModPath unless_null"
                    SetToggles = "\n\t\tResource\\zzzzzNuraThings\\ModManager\\ModToggles = ref ResourceModToggles unless_null" if toggles else ""
                    SetAuthor = "\n\t\tResource\\zzzzzNuraThings\\ModManager\\ModAuthor = ref ResourceModAuthor unless_null" if credits_string != '""' else ""
                    SetModName = "\n\t\tResource\\zzzzzNuraThings\\ModManager\\ModName = ref ResourceModName unless_null" if mod_name != '""' else ""
                    SetModDescription = "\n\t\tResource\\zzzzzNuraThings\\ModManager\\ModDescription = ref ResourceModDescription unless_null" if has_mod_description else ""

                    file.write(
                        CommandListContent.format(Set_Path = SetPath, Set_Toggles = SetToggles, Set_Author = SetAuthor,
                                                  Set_Mod_Name = SetModName, Set_Description = SetModDescription,
                                                  Swap_Var1 = swapvar1, Swap_Var2 = swapvar2))

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

    save_setname_ini()
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
#common_words = get_common_words(identifiers)
#print("CWords", common_words)
#for namespace, identifiers in ib_array.items():
#   for identifier, hashes in identifiers.items():
#       print("idf", identifier)

       #or entry in hashes:
       #   hash_value = entry["hash"]
           #match_first_index = entry.get("match_first_index")
           #match_index_count = entry.get("match_index_count")

           # Create a unique string and add it to the array
           #create_unique_entry(hash_value, match_first_index, match_index_count, resource_strings)