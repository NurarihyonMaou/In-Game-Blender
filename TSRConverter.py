import os
import re
import json
from concurrent.futures import ThreadPoolExecutor, as_completed

# --- Config ---
IB_MAPPING_FILE = "IBTextureMappings.json"
PROCESSED_FILES_RECORD = "ProcessedInis.txt"
MULTI_SECTIONS = {"Constants", "Present"}
RouteTable = {}

# --- Helpers ---
def _norm(s):
    return s.strip().lower()

def extract_namespace(text):
    m = re.search(r"^\s*namespace\s*=\s*(.+)$", text, re.IGNORECASE | re.MULTILINE)
    return m.group(1).strip() if m else ""

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

def load_processed_files():
    if not os.path.exists(PROCESSED_FILES_RECORD):
        return set()
    with open(PROCESSED_FILES_RECORD, "r", encoding="utf-8") as f:
        return set(line.strip() for line in f.readlines())

def save_processed_files(files_set):
    with open(PROCESSED_FILES_RECORD, "w", encoding="utf-8") as f:
        for path in files_set:
            f.write(path + "\n")

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

# --- Sections ---
def build_sections_dict(lines):
    sections_dict = {}
    multi_sections_dict = {name: [] for name in MULTI_SECTIONS}
    current = None
    buffer = []

    for line in lines:
        sec_match = re.match(r"^\s*\[(.*)\]\s*$", line)
        if sec_match:
            if current:
                if current in MULTI_SECTIONS:
                    multi_sections_dict[current].append(buffer)
                else:
                    sections_dict[current] = buffer
            current = sec_match.group(1)
            buffer = []
        else:
            if current:
                buffer.append(line)

    if current:
        if current in MULTI_SECTIONS:
            multi_sections_dict[current].append(buffer)
        else:
            sections_dict[current] = buffer

    return sections_dict, multi_sections_dict

# --- Process Sections ---
def process_all_sections(sections_dict, multi_sections_dict, ib_mappings, file_namespace):
    def process_section(header, lines, mapping):
        new_lines = []
        has_mapping = bool(mapping)
        if_level = 0
        if_stack = []

        draw_cmd_pattern = re.compile(r"^\s*draw\w*\s*=\s*(auto|\d+)\b", re.IGNORECASE)
        if_start_pattern = re.compile(r"^\s*if\b", re.IGNORECASE)
        endif_pattern = re.compile(r"^\s*endif\b", re.IGNORECASE)
        ps_t_pattern = re.compile(r"ps-t(\d+)\s*=\s*(\S+)", re.IGNORECASE)

        # --- detect direct mapping first ---
        if not has_mapping:
            direct = detect_texture_type_by_ib_and_index("\n".join(lines), ib_mappings)
            if direct:
                mapping = direct
                has_mapping = True

        # --- CommandList RouteTable fallback ---
        if header.lower().startswith("commandlist") and not has_mapping:
            key = _norm(header[len("CommandList"):])
            found = False
            if file_namespace in RouteTable:
                ns_routes = RouteTable[file_namespace]
                for hash_val, cmd_map in ns_routes.items():
                    for cmd_name, idx_val in cmd_map.items():
                        if _norm(cmd_name) == key:
                            entry = ib_mappings.get(hash_val.lower(), {}).get("Objects", {}).get(str(idx_val), {})
                            if entry:
                                mapping = entry
                                has_mapping = True
                                found = True
                                break
                    if found: break
            if not found:
                for ns_name, ns_routes in RouteTable.items():
                    if ns_name == file_namespace: continue
                    for hash_val, cmd_map in ns_routes.items():
                        for cmd_name, idx_val in cmd_map.items():
                            if _norm(cmd_name) == key:
                                entry = ib_mappings.get(hash_val.lower(), {}).get("Objects", {}).get(str(idx_val), {})
                                if entry:
                                    mapping = entry
                                    has_mapping = True
                                    found = True
                                    break
                        if found: break
                    if found: break

        if not has_mapping:
            slots_present = set()
            for l in lines:
                m = ps_t_pattern.search(l)
                if m:
                    try:
                        slots_present.add(int(m.group(1)))
                    except ValueError:
                        pass
            if slots_present:
                if 2 in slots_present:
                    mapping = {
                        "t0": {"type": "NormalMap"},
                        "t1": {"type": "Diffuse"},
                        "t2": {"type": "LightMap"},
                    }
                else:
                    mapping = {
                        "t0": {"type": "Diffuse"},
                        "t1": {"type": "LightMap"},
                    }
                has_mapping = True

        last_resource_indent = ""
        last_resource_if_level = 0
        settextures_pending = False

        for idx, line in enumerate(lines):
            indent = re.match(r"^(\s*)", line).group(1) if re.match(r"^(\s*)", line) else ""

            # keep comments
            if line.strip().startswith(";"):
                new_lines.append(line)
                continue

            # handle if/endif nesting
            if if_start_pattern.match(line):
                if_level += 1
                if_stack.append(len(new_lines))
            elif endif_pattern.match(line):
                if if_level > 0:
                    if_level -= 1
                    if_stack.pop()

            # PS-T replacement -> Resource\GIMI\TSR
            ps_match = ps_t_pattern.search(line)
            if ps_match and has_mapping:
                slot = f"t{ps_match.group(1)}"
                resource = ps_match.group(2).strip()
                if slot in mapping:
                    tex_type = mapping[slot]["type"] if isinstance(mapping[slot], dict) else mapping[slot]
                    if tex_type in ["Diffuse", "LightMap", "NormalMap"]:
                        new_lines.append(
                            f"{indent}Resource\\GIMI\\{tex_type} = ref {resource}" if resource.lower() != "null"
                            else f"{indent}Resource\\GIMI\\{tex_type} = null"
                        )
                        last_resource_indent = indent
                        last_resource_if_level = if_level   # <-- record the IF level where resource appeared
                        settextures_pending = True
                        continue

            # jeśli czeka SetTextures i natrafiamy na kolejny Resource albo draw, wstaw SetTextures
            if settextures_pending and (draw_cmd_pattern.match(line) or ps_t_pattern.search(line)):
                new_lines.append(f"{last_resource_indent}run = CommandList\\GIMI\\SetTextures")
                settextures_pending = False

            # CommandList recursion
            run_match = re.search(r"run\s*=\s*CommandList\\(.+)", line, re.IGNORECASE)
            if run_match:
                inner = run_match.group(1)
                if "global\\orfix" in inner.lower():
                    continue

                new_lines.append(line)
                child_header = "CommandList" + inner
                if child_header in sections_dict:
                    processed_child = process_section(child_header, sections_dict[child_header], mapping)
                    sections_dict[child_header] = processed_child
                continue

            new_lines.append(line)

        # ---------- improved placement for trailing SetTextures ----------
        if settextures_pending:
            run_line = f"{last_resource_indent}run = CommandList\\GIMI\\SetTextures"

            # if last_resource_if_level > 0, try to insert run AFTER the matching endif that closes that IF level
            if last_resource_if_level and last_resource_if_level > 0:
                cur_level = 0
                insert_pos = None
                for i, nl in enumerate(new_lines):
                    # detect if/endif in new_lines (use same regexes)
                    if if_start_pattern.match(nl):
                        cur_level += 1
                    elif endif_pattern.match(nl):
                        # before decrementing, cur_level equals the level that is being closed
                        if cur_level == last_resource_if_level:
                            insert_pos = i + 1  # place after this endif
                            break
                        cur_level -= 1

                if insert_pos is not None:
                    new_lines.insert(insert_pos, run_line)
                else:
                    # fallback: append at end
                    new_lines.append(run_line)
            else:
                # resource was at root level; append at end
                new_lines.append(run_line)

            settextures_pending = False

        return new_lines

    # --- process all normal sections ---
    for header, lines in list(sections_dict.items()):
        direct_mapping = detect_texture_type_by_ib_and_index("\n".join(lines), ib_mappings)
        sections_dict[header] = process_section(header, lines, direct_mapping)

    # --- process multi sections ---
    for header, occurrences in multi_sections_dict.items():
        for i, lines in enumerate(occurrences):
            direct_mapping = detect_texture_type_by_ib_and_index("\n".join(lines), ib_mappings)
            multi_sections_dict[header][i] = process_section(header, lines, direct_mapping)

    return sections_dict, multi_sections_dict


# --- Rebuild INI ---
def rebuild_ini(sections_dict, multi_sections_dict, original_lines):
    new_ini = []
    preamble = []
    multi_counters = {k: 0 for k in MULTI_SECTIONS}

    section_order = []
    for line in original_lines:
        m = re.match(r"^\s*\[(.*)\]\s*$", line)
        if m:
            section_order.append(m.group(1))
    section_order = list(dict.fromkeys(section_order))

    for line in original_lines:
        if re.match(r"^\s*\[", line):
            break
        preamble.append(line)
    new_ini.extend(preamble)

    for header in section_order:
        if header in MULTI_SECTIONS:
            for lines in multi_sections_dict.get(header, []):
                new_ini.append(f"[{header}]")
                new_ini.extend(lines)
        elif header in sections_dict:
            new_ini.append(f"[{header}]")
            new_ini.extend(sections_dict[header])
        else:
            new_ini.append(f"[{header}]")
            new_ini.append("; (Section missing after processing)")

        new_ini.append("")

    return "\n".join(new_ini)

# --- Convert INI Text ---
def convert_ini_text_with_commandlists(text, ib_mappings):
    lines = text.splitlines()
    sections_dict, multi_sections_dict = build_sections_dict(lines)
    file_namespace = _norm(extract_namespace(text) or "")
    processed_sections, processed_multi = process_all_sections(sections_dict, multi_sections_dict, ib_mappings, file_namespace)
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

# --- Build RouteTable ---
def build_route_table_from_sections(sections_dict, namespace=""):
    namespace = _norm(namespace)
    for section_name, lines in sections_dict.items():
        if not section_name.lower().startswith("textureoverride"):
            continue
        for line in lines:
            run_match = re.search(r"run\s*=\s*CommandList\\?(.+)", line, re.IGNORECASE)
            if not run_match:
                continue
            full_path = run_match.group(1)
            parts = full_path.split("\\")
            if len(parts) < 1:
                continue
            key_name = parts[-1].lower()
            hash_match = re.search(r"hash\s*=\s*([a-fA-F0-9]+)", "\n".join(lines), re.IGNORECASE)
            index_match = re.search(r"match_first_index\s*=\s*(\d+)", "\n".join(lines), re.IGNORECASE)
            if not hash_match or not index_match:
                continue
            hash_val = hash_match.group(1).lower()
            index_val = int(index_match.group(1))
            if namespace not in RouteTable:
                RouteTable[namespace] = {}
            if hash_val not in RouteTable[namespace]:
                RouteTable[namespace][hash_val] = {}
            RouteTable[namespace][hash_val][key_name] = index_val

def build_global_routetable(ini_paths):
    for ini_path in ini_paths:
        try:
            with open(ini_path, "r", encoding="utf-8") as f:
                text = f.read()
        except Exception:
            continue
        namespace = extract_namespace(text)
        lines = text.splitlines()
        sections_dict, multi_sections_dict = build_sections_dict(lines)
        build_route_table_from_sections(sections_dict, namespace)
        for multi_name, occurrences in multi_sections_dict.items():
            for section_lines in occurrences:
                build_route_table_from_sections({multi_name: section_lines}, namespace)

# --- Main ---
def process_folders(folder):
    ib_mappings = load_ib_mappings()
    if not ib_mappings:
        print("No IB mappings loaded. Exiting.")
        return

    ini_files, ini_paths = collect_ini_files(folder)
    if not ini_paths:
        print("No new INI files found.")
        return

    build_global_routetable(ini_paths)
    print(RouteTable)

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
            with open(ini_path, "w", encoding="utf-8") as f:
                f.write(converted)
        else:
            print(f"No changes in: {ini_path}")

if __name__ == "__main__":
    process_folders(os.getcwd())