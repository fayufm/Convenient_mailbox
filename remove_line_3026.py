#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除line 3026（我之前添加的可能多余的}）
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("删除前:")
print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026: {lines[3025].rstrip()}")
print(f"Line 3027: {lines[3026].rstrip()}")

# 检查line 3026是否只是一个}
if lines[3025].strip() == '}':
    print("\n✓ Line 3026是孤立的 '}'，删除它")
    del lines[3025]
    
    print("\n删除后:")
    print(f"Line 3025: {lines[3024].rstrip()}")
    print(f"Line 3026 (原3027): {lines[3025].rstrip()}")
    
    with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("\n✓ 已删除line 3026")
else:
    print(f"\n✗ Line 3026不是孤立的}}: {lines[3025].strip()}")

