#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除line 6919-6923的孤立catch块
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("删除前:")
for i in range(6917, 6925):
    print(f"Line {i+1}: {lines[i].rstrip()}")

# 删除line 6919-6923 (indices 6918-6922, total 5 lines)
del lines[6918:6923]

print("\n删除后:")
for i in range(6917, min(6922, len(lines))):
    print(f"Line {i+1}: {lines[i].rstrip()}")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("\n✓ 已删除孤立的catch块 (原line 6919-6923)")

