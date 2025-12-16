#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
按行号直接修复
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 修复Line 93 - 替换整行并插入新行
lines[92] = '  // 鉁?鏀朵欢绠?鍙戜欢绠卞垏鎹?\n'
lines.insert(93, '  @State inboxMode: \'inbox\' | \'outbox\' = \'inbox\'  // inbox=鏀朵欢绠? outbox=鍙戜欢绠?\n')
lines.insert(94, '  @State sentEmails: SentEmailData[] = []          // 宸插彂閫佺殑閭欢鍒楄〃\n')

# Line 94 (现在是95) - 替换整行并插入新行，移除"?"
lines[95] = '  @State selectedSentEmail: SentEmailData | null = null  // 変腑鐨勫凡侀\n'
lines.insert(96, '  @State showSentEmailDetail: boolean = false      // 鏄剧插彂侀惰鎯?\n')
lines.insert(97, '  @State selectedSentEmailIds: Set<number> = new Set()  // 鎵归噺変腑鐨勫凡侀禝D\n')

# Line 102 (现在是105) - 替换整行并插入新行
idx_102 = 92 + 5 + 3 + 2  # 原Line 102 + 新增5行
lines[idx_102] = '  @State inboxBadgeCount: number = 0\n'
lines.insert(idx_102 + 1, '  @State mailboxesBadgeCount: number = 0  // 鎬绘暟\n')

# Line 104 (现在是108) - 替换整行并插入新行
idx_104 = 92 + 5 + 3 + 2 + 2 + 2  # 原Line 104 + 新增行
lines[idx_104] = '  // 鉁?UI寮哄埗鍒锋柊璁℃暟鍣紙姣忔鏁版嵁鍙樺寲鏃堕€掑锛屽己鍒禙orEach閲嶆柊娓叉煋锛?\n'
lines.insert(idx_104 + 1, '  @State mailboxListRefreshKey: number = 0\n')

# Line 105 (现在是110) - 替换整行并插入新行
idx_105 = idx_104 + 2
lines[idx_105] = '  @State emailListRefreshKey: number = 0      // 鏀朵遍垪琛ㄥ?\n'
lines.insert(idx_105 + 1, '  @State sentEmailListRefreshKey: number = 0  // 戜遍垪琛ㄥ?\n')
lines.insert(idx_105 + 2, '  @State statsRefreshKey: number = 0          // 缁熻版嵁\n')

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

with open('fix_result.txt', 'w', encoding='utf-8') as f:
    f.write("All malformed @State declarations fixed!\n")
    f.write("Line 93: Split into 3 lines\n")
    f.write("Line 94: Split into 4 lines, removed '?'\n")
    f.write("Line 102: Split into 2 lines\n")
    f.write("Line 104: Split into 2 lines\n")
    f.write("Line 105: Split into 4 lines\n")

print("Fixed! Check fix_result.txt")


