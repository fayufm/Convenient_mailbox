#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复混乱的@State声明
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# Line 93-95
line_93_original = lines[92]
line_94_original = lines[93]
line_95_original = lines[94]

# 修复Line 93-95
lines[92] = '  // 鉁?鏀朵欢绠?鍙戜欢绠卞垏鎹?\n'
lines.insert(93, '  @State inboxMode: \'inbox\' | \'outbox\' = \'inbox\'  // inbox=鏀朵欢绠? outbox=鍙戜欢绠?\n')
lines.insert(94, '  @State sentEmails: SentEmailData[] = []          // 宸插彂閫佺殑閭欢鍒楄〃\n')
lines[95] = '  @State selectedSentEmail: SentEmailData | null = null  // 変腑鐨勫凡侀\n'
lines.insert(96, '  @State showSentEmailDetail: boolean = false      // 鏄剧插彂侀惰鎯?\n')
lines.insert(97, '  @State selectedSentEmailIds: Set<number> = new Set()  // 鎵归噺変腑鐨勫凡侀禝D\n')
lines[98] = '  @State isSelectMode: boolean = false             // 鏄惁勪簬鎵归噺妯″紡\n'

# Line 102 (现在是107)
line_102_idx = 92 + 5 + 7  # 原来的102 + 新增的5行
if '@State mailboxesBadgeCount' in lines[line_102_idx]:
    lines[line_102_idx] = '  @State inboxBadgeCount: number = 0\n'
    lines.insert(line_102_idx + 1, '  @State mailboxesBadgeCount: number = 0  // 鎬绘暟\n')

# Line 104-105 (现在是110-111)
line_104_idx = 92 + 5 + 7 + 2 + 2  # 原来的104 + 新增的行
if '@State mailboxListRefreshKey' in lines[line_104_idx]:
    lines[line_104_idx] = '  // 鉁?UI寮哄埗鍒锋柊璁℃暟鍣紙姣忔鏁版嵁鍙樺寲鏃堕€掑锛屽己鍒禙orEach閲嶆柊娓叉煋锛?\n'
    lines.insert(line_104_idx + 1, '  @State mailboxListRefreshKey: number = 0\n')
    
line_105_idx = line_104_idx + 2
if '@State emailListRefreshKey' in lines[line_105_idx]:
    lines[line_105_idx] = '  @State emailListRefreshKey: number = 0      // 鏀朵遍垪琛ㄥ?\n'
    lines.insert(line_105_idx + 1, '  @State sentEmailListRefreshKey: number = 0  // 戜遍垪琛ㄥ?\n')
    lines.insert(line_105_idx + 2, '  @State statsRefreshKey: number = 0          // 缁熻版嵁\n')

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

print("Fixed malformed @State declarations")
print(f"Line 93-95 fixed")
print(f"Line 102 fixed")
print(f"Line 104-105 fixed")


