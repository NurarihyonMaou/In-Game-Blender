import os
import threading
from concurrent.futures import ThreadPoolExecutor

current_inis = []
backup_inis = []
lock = threading.Lock()  # Prevent race conditions


def collect_ini_worker(folder_path):
    """Worker function to process a single folder."""
    try:
        entries = os.scandir(folder_path)  # Faster than os.listdir()
    except PermissionError:
        return  # Skip inaccessible directories

    with lock:
        ini_files = []  # Local storage before adding to global lists

    subdirs = []  # To store directories for parallel processing

    for entry in entries:
        file_path = entry.path

        if 'BufferValues' in file_path:
            continue

        if entry.is_dir() and 'disabled' not in file_path.lower():
            subdirs.append(file_path)  # Process directories later

        elif entry.is_file() and entry.name.lower().endswith(".ini"):
            if "desktop" in entry.name.lower() or "ntuser" in entry.name.lower():
                continue

            # Check if it's a backup .ini file
            if 'Disabled_TSRBackup_' in entry.name:
                ini_files.append((file_path, "backup"))
            elif 'disabled' not in entry.name.lower():
                ini_files.append((file_path, "current"))

    with lock:  # Lock once to modify shared lists
        for file_path, file_type in ini_files:
            print(file_path)
            if file_type == "backup":
                backup_inis.append(file_path)
            else:
                current_inis.append(file_path)

    return subdirs  # Return subdirectories for further processing


def collect_ini(folder_path):
    """Collect .ini files using multi-threading."""
    subdirs_to_scan = [folder_path]

    with ThreadPoolExecutor() as executor:
        while subdirs_to_scan:
            futures = [executor.submit(collect_ini_worker, subdir) for subdir in subdirs_to_scan]
            subdirs_to_scan = [subdir for future in futures for subdir in future.result() if future.result()]


def delete_ini_file(ini_path):
    backup_ini = 'Disabled_TSRBackup_' + os.path.basename(ini_path)

    if os.path.exists(os.path.join(os.path.dirname(ini_path), backup_ini)):
        """Delete a single .ini file."""
        print('Deleting - ' + ini_path)
        try:
            os.remove(ini_path)
        except Exception as e:
            print(f"Error deleting {ini_path}: {e}")


def restore_ini_file(backup_ini):
    """Restore a single backup .ini file."""
    backup2 = backup_ini.replace('Disabled_TSRBackup_', '')

    if 'disabled' in backup2.lower():
        return

    print('Restoring - ' + backup_ini)
    try:
        os.rename(backup_ini, backup2)
    except Exception as e:
        print(f"Error restoring {backup_ini}: {e}")


def delete_inis():
    """Delete all collected .ini files using multi-threading."""
    with ThreadPoolExecutor() as executor:
        executor.map(delete_ini_file, current_inis)


def restore_inis():
    """Restore all backup .ini files using multi-threading."""
    with ThreadPoolExecutor() as executor:
        executor.map(restore_ini_file, backup_inis)


def delete_saved_data():
    try:
        os.remove("ProcessedInis.txt")
    except Exception as e:
        print(f"Error deleting ProcessedInis.txt: {e}")


def main():
    collect_ini(os.getcwd())

    delete_inis()
    restore_inis()

    delete_saved_data()


if __name__ == "__main__":
    main()
