import os
import time
import re
from collections import defaultdict

# NtO (New to Old) by Nurarihyon
# Version - 0.9B
# Transfers Draw Values from a New Ini to the Old one

# Normalize label for matching (e.g., ignore spaces and case)
def normalize_label(label):
    return re.sub(r"[\s\t]", "", label.strip().lower())

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
model_parts = defaultdict(list)  # key: (section, normalized_label, key_type) → list of values

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
                current_label = label_match.group("label").strip().lstrip(";")
                continue

            draw_match = draw_pattern.search(line)
            if draw_match and current_section:
                value = draw_match.group("value").strip()
                key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
                label_key = normalize_label(current_label) if key_type == "drawindexed" and current_label else None
                model_parts[(current_section, label_key, key_type)].append(value)
                if key_type == "drawindexed":
                    current_label = None
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
        print(f"\n📦 Created Backup file - {backup_path}\n")

except UnicodeDecodeError:
    print("Error Creating Backup file.")

# === PARSE + REPLACE OLD FILE ===
current_section = None
current_label = None
modified = False
replacement_counters = defaultdict(int)

for i, line in enumerate(old_lines):
    section_match = section_pattern.match(line)
    if section_match:
        current_section = section_match.group(1).strip()
        continue

    label_match = label_pattern.match(line)
    if label_match:
        current_label = label_match.group("label").strip().lstrip(";")
        continue

    draw_match = draw_pattern.search(line)
    if draw_match and current_section:
        old_val = draw_match.group("value").strip()
        key_type = "drawindexed" if "drawindexed" in draw_match.group(1).lower() else "draw"
        label_key = normalize_label(current_label) if key_type == "drawindexed" and current_label else None
        key = (current_section, label_key, key_type)
        group = model_parts.get(key)

        # Fallback: try matching label across all sections
        if not group and label_key:
            for alt_key, val in model_parts.items():
                if alt_key[1] == label_key and alt_key[2] == key_type:
                    group = val
                    key = alt_key  # Update key so reuse/index works
                    print(f"\n🔄 Cross-section fallback match for: '{current_label}' in section [{alt_key[0]}]")
                    break

        if not group:
            print(f"❌ No match found in NEW for key: {key}")
        else:
            idx = replacement_counters[key]
            idx = min(idx, len(group) - 1)
            new_val = group[idx]
            if old_val.strip() != new_val.strip():
                prefix = draw_match.group(1)
                new_line = re.sub(re.escape(prefix) + re.escape(old_val), f"{prefix}{new_val}", line, count=1)
                if line.endswith("\n") and not new_line.endswith("\n"):
                    new_line += "\n"
                old_lines[i] = new_line
                label_disp = current_label if current_label else key_type
                print(f"✅ [{current_section}] {label_disp}: {old_val} → {new_val}")
                modified = True
            replacement_counters[key] += 1

        if key_type == "drawindexed":
            current_label = None
        continue

    override_match = override_pattern.search(line)
    if override_match and current_section:
        old_val = override_match.group("value").strip()
        key_type = override_match.group(1).split("=")[0].strip()
        key = (current_section, None, key_type)
        group = model_parts.get(key)

        # No fallback needed here since overrides are not label-dependent
        if not group:
            print(f"❌ No match found in NEW for key: {key}")
        else:
            idx = replacement_counters[key]
            idx = min(idx, len(group) - 1)
            new_val = group[idx]
            if old_val.strip() != new_val.strip():
                prefix = override_match.group(1)
                new_line = re.sub(re.escape(prefix) + re.escape(old_val), f"{prefix}{new_val}", line, count=1)
                if line.endswith("\n") and not new_line.endswith("\n"):
                    new_line += "\n"
                old_lines[i] = new_line
                print(f"✅ [{current_section}] {key_type}: {old_val} → {new_val}")
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

# === REPORT UNUSED KEYS FROM NEW ===
print("\n🔍 Unused Keys in NEW File:")
for key, values in model_parts.items():
    used = replacement_counters.get(key, 0)
    if used < len(values):
        print(f"  {key} → {len(values) - used} unused")