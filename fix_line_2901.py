#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复line 2901的模板字符串语法错误
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("修复前:")
print(f"Line 2901: {lines[2900]}")

# 修复：移除错误的反引号和多余的部分
# 原始：`缂哄皯: ${validation.missingFields.join(', '`)}\n\n` +`            `璇峰墠寰"璁剧"屽杽`
# 修复：`缂哄皯: ${validation.missingFields.join(', ')}\n\n璇峰墠寰"璁剧"屽杽`

old_line = lines[2900]
# 替换错误的部分
new_line = old_line.replace("join(', '`)}\\n\\n` +`            `", "join(', ')}\\n\\n")

lines[2900] = new_line

print("\n修复后:")
print(f"Line 2901: {lines[2900]}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已修复line 2901的模板字符串语法错误")

