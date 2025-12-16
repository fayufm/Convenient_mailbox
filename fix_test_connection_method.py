#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在line 5067和5068之间添加缺失的}来关闭外层try块
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("修复前:")
print(f"Line 5066: {lines[5065].rstrip()}")
print(f"Line 5067: {lines[5066].rstrip()}")
print(f"Line 5068: {lines[5067].rstrip()}")
print(f"Line 5069: {lines[5068].rstrip()}")

# 在line 5068之前（index 5067）插入关闭外层try的}
new_line = "    }\n"
lines.insert(5067, new_line)

print("\n修复后:")
print(f"Line 5066: {lines[5065].rstrip()}")
print(f"Line 5067: {lines[5066].rstrip()}")
print(f"Line 5068 (新): {lines[5067].rstrip()}")
print(f"Line 5069 (原5068): {lines[5068].rstrip()}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已添加缺失的}来关闭外层try块")

