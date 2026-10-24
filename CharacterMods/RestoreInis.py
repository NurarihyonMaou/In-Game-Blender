import os
import threading
from concurrent.futures import ThreadPoolExecutor

current_inis = []
backup_inis = []
lock = threading.Lock()


def collect_ini_worker(folder_path):
    try:
        entries = os.scandir(folder_path)
    except PermissionError:
        return []

    ini_files = []
    subdirs = []

    for entry in entries:
        file_path = entry.path
        name_lower = entry.name.lower()

        if 'BufferValues' in file_path:
            continue

        if entry.is_dir() and 'disabled' not in name_lower:
            subdirs.append(file_path)

        elif entry.is_file() and name_lower.endswith(".ini"):
            if "desktop" in name_lower or "ntuser" in name_lower:
                continue

            # BACKUP: Backup_ORFIX_Applier_<name>.txt
            if entry.name.startswith('Backup_ORFIX_Applier_') and name_lower.endswith('.txt'):
                ini_files.append((file_path, "backup"))

            # CURRENT: normal .ini
            elif name_lower.endswith(".ini") and 'disabled' not in name_lower:
                ini_files.append((file_path, "current"))

    with lock:
        for file_path, file_type in ini_files:
            print(file_path)
            if file_type == "backup":
                backup_inis.append(file_path)
            else:
                current_inis.append(file_path)

    return subdirs


def collect_ini(folder_path):
    subdirs_to_scan = [folder_path]

    with ThreadPoolExecutor() as executor:
        while subdirs_to_scan:
            futures = [executor.submit(collect_ini_worker, subdir) for subdir in subdirs_to_scan]

            new_subdirs = []
            for future in futures:
                result = future.result()
                if result:
                    new_subdirs.extend(result)

            subdirs_to_scan = new_subdirs


def delete_ini_file(ini_path):
    base = os.path.splitext(os.path.basename(ini_path))[0]
    backup_name = f'Backup_ORFIX_Applier_{base}.txt'
    backup_path = os.path.join(os.path.dirname(ini_path), backup_name)

    # HARD SAFETY — NIE MA BACKUPU = NIE USUWAJ
    if not os.path.isfile(backup_path):
        print(f"SKIP (no backup) - {ini_path}")
        return

    # dodatkowy safeguard (opcjonalny)
    if os.path.getsize(backup_path) == 0:
        print(f"SKIP (empty backup) - {backup_path}")
        return

    print('Deleting - ' + ini_path)
    try:
        os.remove(ini_path)
    except Exception as e:
        print(f"Error deleting {ini_path}: {e}")


def restore_ini_file(backup_ini):
    filename = os.path.basename(backup_ini)

    base = filename.replace('Backup_ORFIX_Applier_', '')
    target_name = os.path.splitext(base)[0] + '.ini'
    target_path = os.path.join(os.path.dirname(backup_ini), target_name)

    if 'disabled' in target_name.lower():
        return

    # NIE NADPISUJ
    if os.path.exists(target_path):
        print(f"SKIP (already exists) - {target_path}")
        return

    print('Restoring - ' + backup_ini)
    try:
        os.rename(backup_ini, target_path)
    except Exception as e:
        print(f"Error restoring {backup_ini}: {e}")


def delete_inis():
    with ThreadPoolExecutor() as executor:
        executor.map(delete_ini_file, current_inis)


def restore_inis():
    with ThreadPoolExecutor() as executor:
        executor.map(restore_ini_file, backup_inis)


def delete_saved_data():
    for file in ["GroupedHashes.json", "ProcessedFiles.json", "TypeCounts.json"]:
        try:
            os.remove(file)
        except Exception as e:
            print(f"Error deleting {file}: {e}")


def main():
    collect_ini(os.getcwd())

    delete_inis()
    restore_inis()

    delete_saved_data()


if __name__ == "__main__":
    main()