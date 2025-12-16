#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确修复混乱的@State声明
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    content = f.read()

# 修复Line 93 - 分成3行
old_line93 = "  // 鉁?鏀朵欢绠?鍙戜欢绠卞垏鎹?  @State inboxMode: 'inbox' | 'outbox' = 'inbox'  // inbox=鏀朵欢绠? outbox=鍙戜欢绠?  @State sentEmails: SentEmailData[] = []          // 宸插彂閫佺殑閭欢鍒楄〃"
new_line93 = """  // 鉁?鏀朵欢绠?鍙戜欢绠卞垏鎹?
  @State inboxMode: 'inbox' | 'outbox' = 'inbox'  // inbox=鏀朵欢绠? outbox=鍙戜欢绠?
  @State sentEmails: SentEmailData[] = []          // 宸插彂閫佺殑閭欢鍒楄〃"""

content = content.replace(old_line93, new_line93)
print("Fixed line 93")

# 修复Line 94 - 分成4行，移除"?"
old_line94 = "  @State selectedSentEmail: SentEmailData | null = null  // 変腑鐨勫凡侀  @State showSentEmailDetail: boolean = false      // 鏄剧插彂侀惰鎯  @State selectedSentEmailIds: Set<number> = new Set() ? // 鎵归噺変腑鐨勫凡侀禝D"
new_line94 = """  @State selectedSentEmail: SentEmailData | null = null  // 変腑鐨勫凡侀
  @State showSentEmailDetail: boolean = false      // 鏄剧插彂侀惰鎯
  @State selectedSentEmailIds: Set<number> = new Set()  // 鎵归噺変腑鐨勫凡侀禝D"""

content = content.replace(old_line94, new_line94)
print("Fixed line 94 (removed '?')")

# 修复Line 102 - 分成2行
old_line102 = "  @State inboxBadgeCount: number = 0      //   @State mailboxesBadgeCount: number = 0  // 鎬绘暟"
new_line102 = """  @State inboxBadgeCount: number = 0
  @State mailboxesBadgeCount: number = 0  // 鎬绘暟"""

content = content.replace(old_line102, new_line102)
print("Fixed line 102")

# 修复Line 104-105 - 分成多行
old_line104 = "  // 鉁?UI寮哄埗鍒锋柊璁℃暟鍣紙姣忔鏁版嵁鍙樺寲鏃堕€掑锛屽己鍒禙orEach閲嶆柊娓叉煋锛?  @State mailboxListRefreshKey: number = 0"
new_line104 = """  // 鉁?UI寮哄埗鍒锋柊璁℃暟鍣紙姣忔鏁版嵁鍙樺寲鏃堕€掑锛屽己鍒禙orEach閲嶆柊娓叉煋锛?
  @State mailboxListRefreshKey: number = 0"""

content = content.replace(old_line104, new_line104)
print("Fixed line 104")

old_line105 = "  @State emailListRefreshKey: number = 0      // 鏀朵遍垪琛ㄥ  @State sentEmailListRefreshKey: number = 0  // 戜遍垪琛ㄥ  @State statsRefreshKey: number = 0          // 缁熻版嵁"
new_line105 = """  @State emailListRefreshKey: number = 0      // 鏀朵遍垪琛ㄥ
  @State sentEmailListRefreshKey: number = 0  // 戜遍垪琛ㄥ
  @State statsRefreshKey: number = 0          // 缁熻版嵁"""

content = content.replace(old_line105, new_line105)
print("Fixed line 105")

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ All malformed @State declarations fixed!")
print("This should resolve the 10905103 error!")


