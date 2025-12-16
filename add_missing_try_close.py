#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在line 3025和3026之间添加缺失的}来关闭try块
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("添加前:")
print(f"Line 3024: {lines[3023].rstrip()}")
print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026: {lines[3025].rstrip()}")

# 在line 3026之前（index 3025）插入一个新行来关闭try块
new_line = "    }\n"
lines.insert(3025, new_line)

print("\n添加后:")
print(f"Line 3024: {lines[3023].rstrip()}")
print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026 (新): {lines[3025].rstrip()}")
print(f"Line 3027 (原3026): {lines[3026].rstrip()}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已添加缺失的}来关闭try块")

