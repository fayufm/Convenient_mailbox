#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, sys, shutil
from datetime import datetime

if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')

file_path = "entry/src/main/ets/pages/Index.ets"
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
backup_path = f"{file_path}.backup_comment_undefined_{timestamp}"
shutil.copy2(file_path, backup_path)
print(f"✅ 备份: {backup_path}")

with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
    lines = f.readlines()

# 未定义的方法列表
undefined = [
    'buildEmailDetailDialog', 'buildSentEmailDetailDialog', 'buildImagePreviewDialog',
    'buildTemplateDialog', 'buildCreateTemplateDialog', 'buildCreateFolderDialog',
    'buildMoveFolderDialog', 'buildCreateTagDialog', 'buildAddTagDialog',
    'buildStatsDialog', 'buildNoteDialog', 'buildQRCodeDialog', 'buildMailboxActionsMenu'
]

count = 0
i = 0
while i < len(lines):
    # 检查是否调用了未定义的方法
    if any(f'this.{method}()' in lines[i] for method in undefined):
        # 向上找到if语句（最多回溯5行）
        j = i
        while j >= max(0, i-5) and 'if (' not in lines[j]:
            j -= 1
        
        if 'if (' in lines[j]:
            # 找到了if语句，注释从if到下一个}的所有行
            k = j
            while k <= min(len(lines)-1, i+5):
                if not lines[k].strip().startswith('//'):
                    lines[k] = '      // ' + lines[k].lstrip()
                k += 1
                if '}' in lines[k-1]:
                    break
            count += 1
            i = k
            continue
    i += 1

with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
    f.writelines(lines)

print(f"✅ 注释了 {count} 个未定义方法的调用块")
print(f"📁 备份: {backup_path}")

