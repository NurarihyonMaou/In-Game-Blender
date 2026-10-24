import os
import time
import re

# Gather all INI files excluding backups
inis = [
    os.path.join(dirpath, filename)
    for dirpath, _, filenames in os.walk(os.getcwd())
    for filename in filenames
    if '.ini' in filename and '_Backup' not in filename
]

# Display INI files
print("Choose Ini by Selecting Correct Number:\n")
for index, ini in enumerate(inis):
    print(f"{index}) {ini}")

# Select files
old = inis[int(input("\nSelect Old File: "))]
new = inis[int(input("Select New File: "))]

# Containers
model_parts = []        # (section, label_key or None, key_type, value)
old_model_parts = []    # (section, label_key or None, key_type, line_index, value, match)

# REGEX patterns
section_pattern = re.compile(r"^\s*\[(.+?)\]\s*$")
label_pattern = re.compile(r"^\s*;\s*(?P<label>.+?)\s*\(\d+\)\s*$")
draw_pattern = re.compile(r"(draw(?:indexed)?\s*=\s*)(?P<value>[\d,\s]+)", re.IGNORECASE)
override_pattern = re.compile(r"(override_(?:vertex_count|byte_stride)\s*=\s*)(?P<value>\d+)", re.IGNORECASE)

modified = False

# === PARSE NEW FILE ===
try:
    with open(new, 'r', encoding='utf-8') as file:
        current_section = None
        current_label = None

        for line in file:
            section_match = section_pattern.match(line)
            if section_match:
                current_section = section_match.group(1).strip()
                continue

            label_match = label_pattern.match(line)
            if label_match:
                current_label = label_match.group("label").strip()
                continue

            # draw / drawindexed
            draw_match = draw_pattern.search(line)
            if draw_match and current_section:
                value = draw_match.group("value").strip()
                key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
                label_key = current_label.replace(" ", "").replace("\t", "") if key_type == "drawindexed" else None
                model_parts.append((current_section, label_key, key_type, value))
                current_label = None
                continue

            # override_*
            override_match = override_pattern.search(line)
            if override_match and current_section:
                value = override_match.group("value").strip()
                key_type = override_match.group(1).split("=")[0].strip()  # full name e.g. override_vertex_count
                model_parts.append((current_section, None, key_type, value))

except UnicodeDecodeError:
    print("Error Reading New File.")

# === BACKUP OLD FILE ===
try:
    with open(old, 'r', encoding='utf-8') as file:
        old_lines = file.readlines()

    backup_path = old.replace('.ini', f'_Backup{int(time.time())}.ini')
    with open(backup_path, 'w', encoding='utf-8') as file:
        file.writelines(old_lines)
        print(f"\nCreated Backup file - {backup_path}\n")

except UnicodeDecodeError:
    print("Error Creating Backup file.")

# === PARSE OLD FILE ===
current_section = None
current_label = None

for i, line in enumerate(old_lines):
    section_match = section_pattern.match(line)
    if section_match:
        current_section = section_match.group(1).strip()
        continue

    label_match = label_pattern.match(line)
    if label_match:
        current_label = label_match.group("label").strip()
        continue

    draw_match = draw_pattern.search(line)
    if draw_match and current_section:
        value = draw_match.group("value").strip()
        key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
        label_key = current_label.replace(" ", "").replace("\t", "") if key_type == "drawindexed" else None
        old_model_parts.append((current_section, label_key, key_type, i, value, draw_match))
        current_label = None
        continue

    override_match = override_pattern.search(line)
    if override_match and current_section:
        value = override_match.group("value").strip()
        key_type = override_match.group(1).split("=")[0].strip()
        old_model_parts.append((current_section, None, key_type, i, value, override_match))

# === REPLACE ===
for old_entry in old_model_parts:
    section, label_key, key_type, line_idx, old_val, match = old_entry

    for new_entry in model_parts:
        n_section, n_label_key, n_key_type, new_val = new_entry
        if n_section == section and n_label_key == label_key and n_key_type == key_type:
            if old_val.strip() != new_val.strip():
                old_line = old_lines[line_idx]
                prefix = match.group(1)
                new_line = re.sub(re.escape(prefix) + re.escape(old_val), f"{prefix}{new_val}", old_line, count=1)

                # Preserve newline if original had it
                if old_line.endswith("\n") and not new_line.endswith("\n"):
                    new_line += "\n"

                old_lines[line_idx] = new_line
                label_display = label_key if label_key else key_type
                print(f"[{section}] {label_display} : {old_val} → {new_val}")
                modified = True
            break  # stop after first match

# === SAVE ===
try:
    with open(old, 'w', encoding='utf-8') as file:
        file.writelines(old_lines)
        if modified:
            print("\nModified -", old)
        else:
            print("\nNo Changes, Preserved -", old)

except UnicodeDecodeError:
    print("Error Modifying Old File.")