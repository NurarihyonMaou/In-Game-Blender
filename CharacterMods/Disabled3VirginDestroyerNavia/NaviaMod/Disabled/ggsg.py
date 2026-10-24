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

# Prepare containers
model_parts = {}        # label_cleaned: draw value from new file
old_model_parts = {}    # label_cleaned: (old draw value, line index, match object)

# REGEX patterns
label_pattern = re.compile(r"^\s*;\s*(?P<label>.+?)\s*\(\d+\)\s*$", re.IGNORECASE)
draw_pattern = re.compile(r"(drawindexed\s*=\s*)(?P<draw>[\d,\s]+)", re.IGNORECASE)

modified = False

# Parse new file
try:
    with open(new, 'r', encoding='utf-8') as file:
        current_label = None

        for line in file:
            label_match = label_pattern.match(line)
            if label_match:
                current_label = label_match.group("label").strip()
                continue

            draw_match = draw_pattern.search(line)
            if draw_match and current_label:
                draw_call = draw_match.group("draw").strip()
                label_key = current_label.replace(" ", "").replace("\t", "")
                model_parts[label_key] = draw_call
                current_label = None

except UnicodeDecodeError:
    print("Error Reading New File.")

# Backup old file
try:
    with open(old, 'r', encoding='utf-8') as file:
        old_lines = file.readlines()

    backup_path = old.replace('.ini', f'_Backup{int(time.time())}.ini')
    with open(backup_path, 'w', encoding='utf-8') as file:
        file.writelines(old_lines)
        print(f"\nCreated Backup file - {backup_path}\n")

except UnicodeDecodeError:
    print("Error Creating Backup file.")

# Parse old lines and prepare replacements
current_label = None

for i, line in enumerate(old_lines):
    label_match = label_pattern.match(line)
    if label_match:
        current_label = label_match.group("label").strip()
        continue

    draw_match = draw_pattern.search(line)
    if draw_match and current_label:
        draw_value = draw_match.group("draw")
        label_key = current_label.replace(" ", "").replace("\t", "")
        old_model_parts[label_key] = (i, draw_value, draw_match)
        current_label = None

# Perform replacements
for label_key, (line_idx, old_draw, match) in old_model_parts.items():
    if label_key not in model_parts:
        continue

    new_draw = model_parts[label_key]
    if old_draw.strip() != new_draw.strip():
        # Replace only the draw value
        line = old_lines[line_idx]
        prefix = match.group(1)  # 'drawindexed ='
        new_line = draw_pattern.sub(f"{prefix}{new_draw}", line, count=1)
        old_lines[line_idx] = new_line
        print(label_key, ":", old_draw.strip(), "→", new_draw)
        modified = True

# Write modified content back
try:
    with open(old, 'w', encoding='utf-8') as file:
        file.writelines(old_lines)
        if modified:
            print("\nModified -", old)
        else:
            print("\nNo Changes, Preserved -", old)

except UnicodeDecodeError:
    print("Error Modifying Old File.")