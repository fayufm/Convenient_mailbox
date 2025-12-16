#!/usr/bin/env python3
# -*- coding: utf-8 -*-

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Line 12293 (index 12292)
line = lines[12292]
print(f'Line 12293 hex dump:')
for i, char in enumerate(line, start=1):
    hex_code = f'U+{ord(char):04X}'
    if char == '\n':
        char_display = '<LF>'
    elif char == '\t':
        char_display = '<TAB>'
    elif ord(char) < 32:
        char_display = '<CTRL>'
    else:
        char_display = char
    print(f'{i:3d}: {hex_code}  {repr(char):6s} {char_display}')

