#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
最终清理：删除重复的State声明
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 删除Line 104-105 (重复的inboxBadgeCount和mailboxesBadgeCount)
if lines[103].strip().startswith('@State inboxBadgeCount'):
    del lines[103]  # Line 104
    
if lines[103].strip().startswith('@State mailboxesBadgeCount'):
    del lines[103]  # Line 105 (现在是104)

# 删除Line 116 (混乱的行，包含重复的@State)
for i in range(110, 120):
    if i < len(lines) and '@State mailboxListRefreshKey: number = 0' in lines[i] and '// 鉁?UI寮哄埗鍒锋柊璁℃暟鍣' in lines[i]:
        del lines[i]
        break

# 检查Line 117是否有混乱的内容
for i in range(110, 120):
    if i < len(lines) and lines[i].count('@State') > 1:
        del lines[i]
        break

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

with open('fix_result.txt', 'w', encoding='utf-8') as f:
    f.write("Final cleanup complete!\n")
    f.write("- Removed duplicate inboxBadgeCount (Line 104)\n")
    f.write("- Removed duplicate mailboxesBadgeCount (Line 105)\n")
    f.write("- Removed malformed lines with multiple @State\n")

print("Final cleanup complete!")


