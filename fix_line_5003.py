#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复line 5003的模板字符串语法错误
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("修复前:")
print(f"Line 5003: {lines[5002]}")

# 修复line 5003
# 原始：`畬达紝璇ワ細\n${validation.missingFields.join('\n'`)}`      )
# 修复：`畬达紝璇ワ細\n${validation.missingFields.join('\n')}`

old_line = lines[5002]
# 删除错误的反引号
new_line = old_line.replace("join('\\n'`)}", "join('\\n')}")
# 移除行末多余的空格和)，让它单独成行
new_line = new_line.replace("`      )", "`\n")

lines[5002] = new_line

# 如果line 5003是return，在它之前插入)来关闭showToast
if 'return' in lines[5003]:
    lines.insert(5003, "      )\n")

print("\n修复后:")
print(f"Line 5003: {lines[5002]}")
print(f"Line 5004 (新插入): {lines[5003] if len(lines) > 5003 else 'N/A'}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已修复line 5003的模板字符串语法错误")

