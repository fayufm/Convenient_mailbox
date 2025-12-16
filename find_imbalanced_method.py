#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
找出第一个导致struct提前关闭的方法
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

# 从struct开始逐行计数，找出第一个让count降到0的位置
print("=== 追踪struct Index的闭合 ===\n")

brace_count = 1  # struct Index { 开始，count=1

for i in range(82, 7027):  # 从line 83开始（struct开始后）到文件结尾
    line = lines[i]
    line_num = i + 1
    
    open_br, close_br = count_braces_ignoring_strings(line)
    
    if open_br > 0 or close_br > 0:
        old_count = brace_count
        brace_count += open_br - close_br
        
        # 显示count的变化
        if brace_count <= 0 or (brace_count == 1 and old_count == 2):
            line_preview = re.sub(r'[^\x00-\x7F]+', '?', line[:80].strip())
            print(f"Line {line_num:4d}: count {old_count:2d} -> {brace_count:2d}  |  {line_preview}")
            
            if brace_count == 0:
                print(f"\n*** STRUCT CLOSES at line {line_num} ***\n")
                # 找出这是哪个方法
                for j in range(i, max(82, i-200), -1):
                    if re.search(r'^\s*(async\s+)?([a-zA-Z_]\w*)\s*\([^)]*\)\s*(?::\s*\w+\s*)?\{', lines[j]):
                        method_name = re.search(r'([a-zA-Z_]\w*)\s*\(', lines[j]).group(1)
                        print(f"This is inside or at the end of method: {method_name} (started at line {j+1})")
                        break
                break

if brace_count > 0:
    print(f"\nStruct is still open, count={brace_count}")

