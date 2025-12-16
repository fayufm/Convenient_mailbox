#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析onSendEmail方法的括号结构
"""
import re

def count_braces_ignoring_strings(line):
    """计数花括号,忽略字符串内的"""
    line_without_strings = re.sub(r"'[^']*'", '', line)
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    return open_braces, close_braces

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 分析 onSendEmail 方法 (line 2818-3036)
output = []
output.append("=== onSendEmail() 方法括号分析 (line 2818-3036) ===\n\n")

brace_count = 0
for i in range(2817, 3036):  # line 2818-3036
    line = lines[i]
    line_num = i + 1
    
    open_br, close_br = count_braces_ignoring_strings(line)
    
    if open_br > 0 or close_br > 0:
        old_count = brace_count
        brace_count += open_br - close_br
        
        # 移除中文避免编码问题
        line_preview = re.sub(r'[^\x00-\x7F]+', '?', line[:80].strip())
        
        output.append(f"Line {line_num:4d}: +{open_br} -{close_br} => {old_count:+3d} -> {brace_count:+3d}  |  {line_preview}\n")
        
        if brace_count < 0:
            output.append(f"            ^^^^ WARNING: brace balance is negative!\n")

output.append(f"\nFinal brace_count: {brace_count}\n")
if brace_count == -1:
    output.append("X Method has 1 extra closing brace } (or missing 1 opening brace {)\n")
elif brace_count == 0:
    output.append("OK Braces balanced\n")
else:
    output.append(f"X Braces unbalanced: {brace_count}\n")

# Write to file
with open('onsend_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)
    
print("Analysis written to onsend_analysis.txt")
print(f"Final brace_count: {brace_count}")

