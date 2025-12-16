#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
找出try块内count从2降到更低的位置
"""
import re

def count_braces_ignoring_strings(line):
    line_without_strings = re.sub(r"'[^']*'", '', line)
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    return open_braces, close_braces

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

output = []
output.append("=== 查找try块内count从2降低的位置 ===\n\n")

brace_count = 0
in_try = False
try_start = 0

for i in range(2817, 3027):  # line 2818-3027 (到try结束的}之前)
    line = lines[i]
    line_num = i + 1
    
    line_clean = re.sub(r'[^\x00-\x7F]+', '?', line[:80].strip())
    
    open_br, close_br = count_braces_ignoring_strings(line)
    
    old_count = brace_count
    brace_count += open_br - close_br
    
    # 检测try块开始
    if 'try {' in line:
        in_try = True
        try_start = line_num
        output.append(f"\n>>> TRY BLOCK STARTS at line {line_num}, count should be 2 (method+try)\n")
    
    # 如果在try块内，监控count
    if in_try:
        # 显示所有count变化
        if open_br > 0 or close_br > 0:
            output.append(f"Line {line_num:4d}: count {old_count:2d} -> {brace_count:2d}  (+{open_br} -{close_br})  |  {line_clean}\n")
            
            # 特别标记count降到2以下的情况
            if brace_count < 2 and old_count >= 2:
                output.append(f"    !!! COUNT DROPPED BELOW 2 (from {old_count} to {brace_count}) !!!\n")
                output.append(f"    This is line {line_num}, in try block starting at line {try_start}\n")
                output.append(f"    Line content: {line.strip()}\n\n")

with open('count_drop_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print("Analysis written to count_drop_analysis.txt")

