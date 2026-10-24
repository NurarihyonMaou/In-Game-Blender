import os
import time
import re
from collections import defaultdict

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

# Regex patterns
section_pattern = re.compile(r"^\s*\[(.+?)\]\s*$")
label_pattern = re.compile(r"^\s*;\s*(?P<label>.+?)\s*\(\d+\)\s*$")
draw_pattern = re.compile(r"(draw(?:indexed)?\s*=\s*)(?P<value>[\d,\s]+)", re.IGNORECASE)
override_pattern = re.compile(r"(override_(?:vertex_count|byte_stride)\s*=\s*)(?P<value>\d+)", re.IGNORECASE)

# === PARSE NEW FILE ===
model_parts = defaultdict(list)  # key: (section, label, key_type) → list of values

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

            draw_match = draw_pattern.search(line)
            if draw_match and current_section:
                value = draw_match.group("value").strip()
                key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
                label_key = current_label.replace(" ", "").replace("\t", "") if key_type == "drawindexed" else None
                model_parts[(current_section, label_key, key_type)].append(value)
                if key_type == "drawindexed":
                    current_label = None  # clear only if drawindexed matched
                continue

            override_match = override_pattern.search(line)
            if override_match and current_section:
                value = override_match.group("value").strip()
                key_type = override_match.group(1).split("=")[0].strip()
                model_parts[(current_section, None, key_type)].append(value)

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

# === PARSE + REPLACE OLD FILE ===
current_section = None
current_label = None
modified = False
replacement_counters = defaultdict(int)  # how many replacements per key

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
        old_val = draw_match.group("value").strip()
        key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
        label_key = current_label.replace(" ", "").replace("\t", "") if key_type == "drawindexed" else None
        key = (current_section, label_key, key_type)
        idx = replacement_counters[key]

        if idx < len(model_parts.get(key, [])):
            new_val = model_parts[key][idx]
            if old_val.strip() != new_val.strip():
                prefix = draw_match.group(1)
                new_line = re.sub(re.escape(prefix) + re.escape(old_val), f"{prefix}{new_val}", line, count=1)
                if line.endswith("\n") and not new_line.endswith("\n"):
                    new_line += "\n"
                old_lines[i] = new_line
                label_disp = label_key if label_key else key_type
                print(f"[{current_section}] {label_disp}: {old_val} → {new_val}")
                modified = True
            replacement_counters[key] += 1

        if key_type == "drawindexed":
            current_label = None  # consume label only if used

        continue

    override_match = override_pattern.search(line)
    if override_match and current_section:
        old_val = override_match.group("value").strip()
        key_type = override_match.group(1).split("=")[0].strip()
        key = (current_section, None, key_type)
        idx = replacement_counters[key]

        if idx < len(model_parts.get(key, [])):
            new_val = model_parts[key][idx]
            if old_val.strip() != new_val.strip():
                prefix = override_match.group(1)
                new_line = re.sub(re.escape(prefix) + re.escape(old_val), f"{prefix}{new_val}", line, count=1)
                if line.endswith("\n") and not new_line.endswith("\n"):
                    new_line += "\n"
                old_lines[i] = new_line
                print(f"[{current_section}] {key_type}: {old_val} → {new_val}")
                modified = True
            replacement_counters[key] += 1

# === SAVE MODIFIED FILE ===
try:
    with open(old, 'w', encoding='utf-8') as file:
        file.writelines(old_lines)
        if modified:
            print("\n✅ Modified -", old)
        else:
            print("\n⏸️ No Changes, Preserved -", old)

except UnicodeDecodeError:
    print("Error Modifying Old File.")