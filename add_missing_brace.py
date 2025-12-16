#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
在line 3025之后添加缺失的关闭括号
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print(f"Line 3025: {lines[3024].rstrip()}")
print(f"Line 3026: {lines[3025].rstrip()}")

# 在line 3025之后插入一个新行，内容是关闭if (result.success)的括号
new_line = "      // ✅ 关闭 if (result.success) 块\n    }\n"

# 插入到index 3025 (即line 3026之前)
lines.insert(3025, new_line)

# 保存
with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print(f"\n✓ 已在line 3026添加缺失的括号")
print(f"  新的line 3026: {new_line.strip()}")

