#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
恢复line 3036 - 它是需要的（关闭finally块）
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 恢复line 3036 (index 3035)
lines[3035] = "    }\n"

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("✓ 已恢复line 3036")
print(f"Line 3036: {lines[3035].strip()}")

