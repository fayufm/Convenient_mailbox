#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除line 3026-3027 (我之前错误添加的注释和括号)
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("删除前:")
print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026: {lines[3025].rstrip()}")
print(f"Line 3027: {lines[3026].rstrip()}")
print(f"Line 3028: {lines[3027].rstrip()}")

# 删除line 3026和3027 (index 3025和3026)
del lines[3025:3027]

print("\n删除后:")
print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026 (原3028): {lines[3025].rstrip()}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已删除错误添加的注释和括号")

