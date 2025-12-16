#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
清理重复的State声明并恢复缺失的
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 删除Line 112-113的重复行
if '  // 鉁?UI寮哄埗鍒锋柊璁℃暟鍣紙姣忔鏁版嵁鍙樺寲鏃堕€掑锛屽己鍒禙orEach閲嶆柊娓叉煋锛?  @State mailboxListRefreshKey' in lines[111]:
    del lines[111]
    
if '  @State emailListRefreshKey: number = 0      // 鏀朵遍垪琛ㄥ  @State sentEmailListRefreshKey' in lines[111]:
    del lines[111]

# 恢复previewImageUri的声明（在Line 103之后插入）
# 找到"@State showImagePreview"所在行
for i in range(100, 110):
    if '@State showImagePreview' in lines[i]:
        # 在下一行插入previewImageUri
        lines.insert(i + 1, '  @State previewImageUri: string = \'\'              // 棰勮鍥剧墖鐨刄RI\n')
        break

# 移动inboxBadgeCount和mailboxesBadgeCount到正确位置
# 它们应该在"// 寰界珷璁℃暟"注释之后，而不是在"// 鍥剧墖棰勮"下面

# 找到并删除错误位置的inboxBadgeCount和mailboxesBadgeCount
for i in range(100, 115):
    if i < len(lines) and '@State inboxBadgeCount: number = 0' in lines[i] and '// 鉁?鍥剧墖棰勮' in lines[i-1]:
        del lines[i]  # 删除inboxBadgeCount
        if i < len(lines) and '@State mailboxesBadgeCount' in lines[i]:
            del lines[i]  # 删除mailboxesBadgeCount
        break

# 在正确位置添加它们（"// 寰界珷璁℃暟"之后）
for i in range(100, 120):
    if i < len(lines) and '// 寰界珷璁℃暟' in lines[i]:
        lines.insert(i + 1, '  @State inboxBadgeCount: number = 0\n')
        lines.insert(i + 2, '  @State mailboxesBadgeCount: number = 0  // 鎬绘暟\n')
        lines.insert(i + 3, '\n')
        break

with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
    f.writelines(lines)

with open('fix_result.txt', 'w', encoding='utf-8') as f:
    f.write("Cleaned duplicate State declarations!\n")
    f.write("- Removed duplicate lines 112-113\n")
    f.write("- Restored previewImageUri declaration\n")
    f.write("- Moved badge count declarations to correct position\n")

print("Cleaned duplicates! Check fix_result.txt")


