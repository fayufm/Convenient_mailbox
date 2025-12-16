#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除line 6919的多余}
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("删除前:")
print(f"Line 6918: {lines[6917].rstrip()}")
print(f"Line 6919: {lines[6918].rstrip()}")
print(f"Line 6920: {lines[6919].rstrip()}")

# 检查line 6919是否是孤立的}
if lines[6918].strip() == '}':
    print("\n✓ Line 6919是孤立的 '}'，删除它")
    del lines[6918]
    
    print("\n删除后:")
    print(f"Line 6918: {lines[6917].rstrip()}")
    print(f"Line 6919 (原6920): {lines[6918].rstrip()}")
    
    with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("\n✓ 已删除line 6919的多余}")
else:
    print(f"\n✗ Line 6919不是孤立的}}: {lines[6918].strip()}")

