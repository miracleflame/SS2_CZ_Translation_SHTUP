# -*- coding: utf-8 -*-
from Npp import editor, notepad
from difflib import SequenceMatcher
import re

def get_lines(tab_index):
    notepad.activateIndex(0, tab_index)
    text = editor.getText()
    return text.split('\n')  # nemení \n na reálny zlom ako splitlines()

def extract_quoted(text):
    match = re.search(r'"((?:\\.|[^"\\])*)"', text)  # správne zachytí únikové znaky
    return match.group(1) if match else None

def replace_quoted(original, new_text):
    # zachová escape sekvencie ako \n, \t atď.
    new_text_escaped = new_text.replace('\\', '\\\\').replace('"', '\\"')
    return re.sub(r'"((?:\\.|[^"\\])*)"', '"{}"'.format(new_text_escaped), original, count=1)

def normalize(text):
    return text.replace('_', '').replace(' ', '').lower()

# Načítaj všetky tri súbory
lines_a = get_lines(0)
lines_b = get_lines(1)
lines_x = get_lines(2)

# Priprav referenčné páry
ref_pairs = []
for a_line, b_line in zip(lines_a, lines_b):
    qa = extract_quoted(a_line)
    qb = extract_quoted(b_line)
    if qa and qb:
        ref_pairs.append((qa, qb))

result_lines = lines_x[:]
threshold = 0.90

for i, x_line in enumerate(lines_x):
    qx = extract_quoted(x_line)
    if not qx:
        continue

    best_ratio = 0
    best_translated = None
    for src_text, translated_text in ref_pairs:
        ratio = SequenceMatcher(None, normalize(qx), normalize(src_text)).ratio()
        if ratio > best_ratio:
            best_ratio = ratio
            best_translated = translated_text

    if best_ratio >= threshold and best_translated:
        result_lines[i] = replace_quoted(x_line, best_translated)

notepad.activateIndex(0, 2)
editor.setText('\n'.join(result_lines))  # použije explicitne \n ako oddelovač
