import re

# === SETTINGS ===
input_file = "ModManager.ini"

# Replacement rules (ordered)
replacements = [
    ("y1",  "x46"),
    ("z1",  "y46"),
    ("w1",  "z46"),
    ("x14", "w46"),
    ("x1",  "x49"),
]

# Compile regex patterns for word-boundary and $ variants
patterns = []
for old, new in replacements:
    patterns.append((re.compile(rf"(?<!\w){old}(?!\w)"), new))     # bare variable
    patterns.append((re.compile(rf"\${old}(?!\w)"), f"${new}"))    # $variable

# === APPLY ===
with open(input_file, "r", encoding="utf-8") as f:
    text = f.read()

for pattern, new in patterns:
    text = pattern.sub(new, text)

with open(input_file, "w", encoding="utf-8") as f:
    f.write(text)

print("✅ Replacements complete.")