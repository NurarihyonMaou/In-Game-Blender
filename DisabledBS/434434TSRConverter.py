import os
import re
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Config ---
IB_MAPPING_FILE = "IBTextureMappings.json"
PROCESSED_FILES_RECORD = "ProcessedInis.txt"

MULTI_SECTIONS = {"Constants", "Present"}  # Sections allowed multiple times

# --- Load IB Mappings ---
def load_ib_mappings():
    if not os.path.exists(IB_MAPPING_FILE):
        print(f"File {IB_MAPPING_FILE} does not exist!")
        return {}
    try:
        with open(IB_MAPPING_FILE, "r", encoding="utf-8") as f:
            data = json.load(f)
        return {k.lower(): v for k, v in data.items()}
    except Exception as e:
        print(f"Error reading {IB_MAPPING_FILE}: {e}")
        return {}

# --- Processed Files Tracking ---
def load_processed_files():
    if not os.path.exists(PROCESSED_FILES_RECORD):
        return set()
    with open(PROCESSED_FILES_RECORD, "r", encoding="utf-8") as f:
        return set(line.strip() for line in f.readlines())

def save_processed_files(files_set):
    with open(PROCESSED_FILES_RECORD, "w", encoding="utf-8") as f:
        for path in files_set:
            f.write(path + "\n")

# --- IB Mapping Helper ---
def detect_texture_type_by_ib_and_index(section_text, ib_mappings):
    hash_match = re.search(r"hash\s*=\s*([a-fA-F0-9]+)", section_text, re.IGNORECASE)
    index_match = re.search(r"match_first_index\s*=\s*(\d+)", section_text, re.IGNORECASE)
    if not hash_match or not index_match:
        return {}
    ib = hash_match.group(1).lower()
    idx = int(index_match.group(1))
    ib_entry = ib_mappings.get(ib)
    if not ib_entry:
        return {}
    return ib_entry.get("Objects", {}).get(f"{idx}", {})

# --- Build sections dict ---
def build_sections_dict(lines):
    sections_dict = {}
    multi_sections_dict = {name: [] for name in MULTI_SECTIONS}
    current = None
    buffer = []

    for line in lines:
        sec_match = re.match(r"^\s*\[(.*)\]\s*$", line)
        if sec_match:
            if current:
                header = current
                if header in MULTI_SECTIONS:
                    multi_sections_dict[header].append(buffer)
                else:
                    sections_dict[header] = buffer
            current = sec_match.group(1)
            buffer = []
        else:
            if current:
                buffer.append(line)

    # Final section
    if current:
        if current in MULTI_SECTIONS:
            multi_sections_dict[current].append(buffer)
        else:
            sections_dict[current] = buffer

    return sections_dict, multi_sections_dict


# --- Recursive processing ---
def process_all_sections(sections_dict, multi_sections_dict, ib_mappings):
    processed_sections = set()

    def process_section(header, lines, mapping):
        new_lines = []
        has_mapping = bool(mapping)
        texture_changed = False
        last_texture_change_idx = -1
        if_level = 0
        if_index = -1
        if_indent = ""

        # Preprocess to detect draw commands
        draw_cmd_pattern = re.compile(r"draw\w*\s*=\s*(auto|\d+)", re.IGNORECASE)

        for idx, line in enumerate(lines):
            indent_match = re.match(r"^(\s*)", line)
            indent = indent_match.group(1) if indent_match else ""

            if line.strip().startswith(';'):
                new_lines.append(line)
                continue

            # PS-T replacement
            ps_match = re.search(r"ps-t(\d+)\s*=\s*(\S+)", line, re.IGNORECASE)
            if ps_match and has_mapping:
                slot_key = f"t{ps_match.group(1)}"
                resource_name = ps_match.group(2)
                if slot_key in mapping:
                    tex_type = mapping[slot_key]["type"]
                    if tex_type in ['Diffuse', 'LightMap', 'NormalMap']:
                        new_line = f"{indent}Resource\\TSR\\{tex_type} = ref {resource_name}" if resource_name != 'null' else f"{indent}Resource\\TSR\\{tex_type} = null"
                        new_lines.append(new_line)
                        texture_changed = True
                        last_texture_change_idx = len(new_lines) - 1
                        continue

            if texture_changed:
                if 'endif' in line:
                    if_level -= 1
                elif 'if' in line:
                    if_level += 1
                    if if_level == 1:
                        if_indent_match = re.match(r"^(\s*)", line)
                        if_indent = indent_match.group(1) if if_indent_match else ""
                        if_index = len(new_lines)

            if if_level > 0 and if_index != -1 and draw_cmd_pattern.search(line):
                new_lines[if_index] = f"{if_indent}run = CommandList\\TSR\\SetTextures\n\n" + new_lines[if_index]
                texture_changed = False
                if_level = 0
                if_index = -1

            # CommandList recursion
            run_match = re.search(r"run\s*=\s*CommandList(\S+)", line, re.IGNORECASE)
            if run_match:
                cmd_header = "CommandList" + run_match.group(1)

                if 'global\\ORFix' in run_match.group(1):
                    continue

                elif cmd_header in sections_dict:
                    processed_cmd = process_section(cmd_header, sections_dict[cmd_header], mapping)
                    sections_dict[cmd_header] = processed_cmd

                new_lines.append(line)
                continue

            # Before draw calls, inject SetTextures if needed
            if texture_changed and draw_cmd_pattern.search(line):
                new_lines.append(f"{indent}run = CommandList\\TSR\\SetTextures")
                texture_changed = False

            new_lines.append(line)

        # Inject SetTextures at the end if texture changed but no draw occurred
        if texture_changed:
            indent = ""
            # Try to preserve indentation from last texture change
            if last_texture_change_idx >= 0:
                match = re.match(r"^(\s*)", new_lines[last_texture_change_idx])
                indent = match.group(1) if match else ""

            if lines[-1].strip() == "":
                new_lines.insert(len(lines)-1, f"run = CommandList\\TSR\\SetTextures\n")
            else:
                new_lines.insert(len(lines), f"run = CommandList\\TSR\\SetTextures\n")

        return new_lines

    # Process normal sections
    for header, lines in sections_dict.items():
        mapping = detect_texture_type_by_ib_and_index("\n".join(lines), ib_mappings)
        sections_dict[header] = process_section(header, lines, mapping)

    # Process multi sections
    for header, occurrences in multi_sections_dict.items():
        for i, lines in enumerate(occurrences):
            mapping = detect_texture_type_by_ib_and_index("\n".join(lines), ib_mappings)
            multi_sections_dict[header][i] = process_section(header, lines, mapping)

    return sections_dict, multi_sections_dict


# --- Rebuild INI ---
def rebuild_ini(sections_dict, multi_sections_dict, original_lines):
    new_ini = []
    current = None
    preamble = []
    multi_counters = {k: 0 for k in MULTI_SECTIONS}
    seen_sections = set()

    # Collect section order from original file
    section_order = []
    for line in original_lines:
        m = re.match(r"^\s*\[(.*)\]\s*$", line)
        if m:
            section_order.append(m.group(1))
    section_order = list(dict.fromkeys(section_order))  # keep order unique

    # Capture everything before the first section
    for line in original_lines:
        if re.match(r"^\s*\[", line):
            break
        preamble.append(line)

    new_ini.extend(preamble)

    # Rebuild in original order
    for header in section_order:
        if header in MULTI_SECTIONS:
            for lines in multi_sections_dict.get(header, []):
                new_ini.append(f"[{header}]")
                new_ini.extend(lines)
        elif header in sections_dict:
            new_ini.append(f"[{header}]")
            new_ini.extend(sections_dict[header])
        else:
            # Section vanished somehow — preserve original header if possible
            new_ini.append(f"[{header}]")
            new_ini.append("; (Section missing after processing)")

        new_ini.append("")  # spacing between sections

    return "\n".join(new_ini)


# --- Convert INI Text ---
def convert_ini_text_with_commandlists(text, ib_mappings):
    lines = text.splitlines()
    sections_dict, multi_sections_dict = build_sections_dict(lines)
    processed_sections, processed_multi = process_all_sections(sections_dict, multi_sections_dict, ib_mappings)
    return rebuild_ini(processed_sections, processed_multi, lines)


# --- Collect INI Files ---
def collect_ini_files(root_path):
    ini_files = []
    ini_paths = []

    already_processed = load_processed_files()
    newly_processed = set()

    def process_folder(folder_path):
        local_ini_files = []
        local_ini_paths = []

        for dirpath, _, filenames in os.walk(folder_path):
            if any(x in dirpath.lower() for x in ['buffervalues', 'disabled', 'noigmm']):
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

    save_processed_files(already_processed.union(newly_processed))
    return ini_files, ini_paths

# --- Main Processing ---
def process_folders(folder):
    ib_mappings = load_ib_mappings()
    if not ib_mappings:
        print("No IB mappings loaded. Exiting.")
        return

    ini_files, ini_paths = collect_ini_files(folder)
    if not ini_paths:
        print("No new INI files found.")
        return

    for ini_path in ini_paths:
        print(f"Processing: {ini_path}")

        with open(ini_path, "r", encoding="utf-8") as f:
            text = f.read()

        converted = convert_ini_text_with_commandlists(text, ib_mappings)

        dir_name = os.path.dirname(ini_path)
        base_name = os.path.basename(ini_path)
        backup = os.path.join(dir_name, "Disabled_TSRBackup_" + base_name)

        if converted != text:
            print(f"Modified: {ini_path}")
            if not os.path.exists(backup):
                os.rename(ini_path, backup)
            with open(ini_path, "w", encoding = "utf-8") as f:
                f.write(converted)
        else:
            print(f"No changes in: {ini_path}")


if __name__ == "__main__":
    process_folders(os.getcwd())