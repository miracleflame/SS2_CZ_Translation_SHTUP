import re
from pathlib import Path

# === CESTY ===
base = Path(".")
en_dir = base / "EnglishSub"
cz_dir = base / "CzechSub"
input_file = base / "loc_english.txt"
output_file = base / "loc_translated_FIXED.txt"

# === NAČÍTANIE MAPY Z .sub A .multisub ===
def extract_map(folder):
    result = {}
    for file in sorted(folder.glob("*.sub")):
        lines = file.read_text(encoding="utf-8", errors="ignore").splitlines()
        i = 0
        while i < len(lines):
            line = lines[i].strip()

            # --- SUB ---
            m_sub = re.match(r'^sub\s+([a-zA-Z0-9_/]+)', line)
            if m_sub:
                var = m_sub.group(1)
                i += 1
                while i < len(lines):
                    m_text = re.search(r'"((?:\\.|[^"\\])*)"', lines[i])
                    if m_text:
                        result[var] = m_text.group(1)
                        break
                    i += 1

            # --- MULTISUB ---
            m_multi = re.match(r'^multisub\s+([a-zA-Z0-9_/]+)\s*{', line)
            if m_multi:
                base_name = m_multi.group(1)
                idx = 1
                i += 1
                while i < len(lines):
                    subline = lines[i].strip()
                    if subline.startswith("}"):
                        break
                    if "text" in subline:
                        key = f"{base_name}_{idx}"
                        m_text = re.search(r'text\s+"((?:\\.|[^"\\])*)"', subline)
                        if m_text:
                            result[key] = m_text.group(1)
                        idx += 1  # <<< dôležité: inkrementuj vždy, ak je v riadku "text"
                    i += 1
            i += 1
    return result

# === NAČÍTANIE MAPY ===
en_map = extract_map(en_dir)
cz_map = extract_map(cz_dir)
common = set(en_map.keys()) & set(cz_map.keys())

# === SPRACOVANIE LOC_ENGLISH.TXT ===
input_lines = input_file.read_text(encoding="utf-8").splitlines()
output_lines = []

for line in input_lines:
    m = re.match(r'^\s*\$([a-zA-Z0-9_/]+)\s*=\s*"((?:\\.|[^"\\])*)"', line)
    if not m:
        output_lines.append(line)
        continue

    var = m.group(1)
    current_text = m.group(2)

    if var in common:
        en_text = en_map[var]
        cz_text = cz_map[var]

        if current_text == en_text:
            cz_escaped = cz_text.replace('\\', '\\\\').replace('"', '\\"')
            new_line = re.sub(r'"((?:\\.|[^"\\])*)"', f'"{cz_escaped}"', line, count=1)
            output_lines.append(new_line)
        else:
            output_lines.append(line)
    else:
        output_lines.append(line)

# === ULOŽENIE ===
output_file.write_text("\n".join(output_lines), encoding="utf-8")
print(f"✅ Hotovo. Výsledok uložený ako {output_file}")
