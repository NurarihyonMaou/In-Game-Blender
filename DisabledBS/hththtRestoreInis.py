import os

def build_tree(start_path):
    lines = []

    def walk(path, prefix=""):
        try:
            entries = sorted(os.listdir(path), key=lambda x: x.lower())
        except PermissionError:
            lines.append(prefix + "└── [BRAK DOSTĘPU]")
            return

        for i, name in enumerate(entries):
            full_path = os.path.join(path, name)
            
            if not os.path.isdir(full_path):
                continue

            is_last = (i == len(entries) - 1)

            connector = "└── " if is_last else "├── "
            lines.append(prefix + connector + name)

            if os.path.isdir(full_path):
                new_prefix = prefix + ("    " if is_last else "│   ")
                walk(full_path, new_prefix)

    lines.append(os.path.abspath(start_path))
    walk(start_path)
    return "\n".join(lines)


def main():
    start = os.getcwd()  # możesz zmienić na dowolną ścieżkę
    output_file = "folder_tree.txt"

    tree = build_tree(start)

    with open(output_file, "w", encoding="utf-8") as f:
        f.write(tree)

    print(f"Zapisano do: {output_file}")


if __name__ == "__main__":
    main()