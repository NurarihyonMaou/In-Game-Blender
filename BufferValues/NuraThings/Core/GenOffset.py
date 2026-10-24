answers_file = "Answers.txt"

banks = []
current = []

with open(answers_file, encoding="utf-8") as f:
    for line in f:

        if line.startswith("~"):
            if current:
                banks.append(current)
                current = []
            current.append(line + "|")
        else:
            current.append(line + "|")

    if current:
        banks.append(current)

# flatten bank strings
bank_strings = []
for bank in banks:
    # first line has ~
    first = bank[0]
    first = first
    rest = bank[1:]

    bank_str = first + "".join(rest)
    bank_strings.append(bank_str)

offsets = []
pos = 0

for bank in bank_strings:
    offsets.append(pos)
    pos += len(bank)

print("data = R32_UINT", *offsets)