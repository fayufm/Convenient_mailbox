#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确分析混乱的行
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

output = []
output.append("=== 问题行分析 ===\n\n")

problem_lines = [92, 93, 94, 101, 103, 104]

for idx in problem_lines:
    if idx < len(lines):
        line = lines[idx]
        line_num = idx + 1
        output.append(f"Line {line_num}:\n")
        output.append(f"  Raw: {repr(line[:200])}\n")
        output.append(f"  @State count: {line.count('@State')}\n")
        output.append(f"  Contains '?': {'?' in line}\n")
        output.append(f"\n")

with open('malformed_lines_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print("Analysis written to malformed_lines_analysis.txt")


