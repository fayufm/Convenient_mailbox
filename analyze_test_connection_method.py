#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析onTestCustomMailboxConnection方法的括号平衡
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
output.append("=== onTestCustomMailboxConnection() 方法括号分析 (line 4997-5075) ===\n\n")

brace_count = 0

for i in range(4996, 5076):  # line 4997-5076
    line = lines[i]
    line_num = i + 1
    
    line_clean = re.sub(r'[^\x00-\x7F]+', '?', line[:80].strip())
    
    open_br, close_br = count_braces_ignoring_strings(line)
    
    if open_br > 0 or close_br > 0:
        old_count = brace_count
        brace_count += open_br - close_br
        
        output.append(f"Line {line_num:4d}: +{open_br} -{close_br} => {old_count:2d} -> {brace_count:2d}  |  {line_clean}\n")
        
        # 标记关键结构
        if 'try {' in line:
            output.append(f"         ^^^ TRY block starts\n")
        elif '} catch' in line:
            output.append(f"         ^^^ CATCH block\n")
        elif brace_count < 0:
            output.append(f"         !!! WARNING: Negative count!\n")

output.append(f"\n最终 brace_count: {brace_count}\n")
if brace_count == 0:
    output.append("✓ 方法括号平衡\n")
else:
    output.append(f"✗ 方法括号不平衡: {brace_count}\n")

with open('test_connection_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print("Analysis written to test_connection_analysis.txt")
print(f"Final brace_count: {brace_count}")

