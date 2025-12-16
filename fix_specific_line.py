#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
使用行号精确修复特定行
"""

import os
import shutil
from datetime import datetime

def backup_file(filepath):
    """创建备份"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"{filepath}.backup_{timestamp}"
    shutil.copy2(filepath, backup_path)
    print(f"[Backup] Created backup: {backup_path}")
    return backup_path

def fix_specific_lines(filepath):
    """修复特定行"""
    print(f"[Start] Reading file: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    changes = []
    
    # 修复第 3548 行（索引 3547）
    if total_lines > 3548:
        line = lines[3547]
        # 无论内容是什么，只要包含 mailboxCount，就替换整行
        if 'mailboxCount' in line:
            # 直接替换为正确的行
            lines[3547] = "              Text(`${domainStat.count} ${this.uiTexts['mailboxCount'] || 'items'}`)\n"
            changes.append(3548)
            print(f"[Fixed] Line 3548")
    
    # 写回文件
    if changes:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[Complete] Fixed {len(changes)} line(s)")
        return True
    else:
        print("[Skip] No changes needed")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_specific_lines(filepath)
    
    if success:
        print("\n[Success] Specific lines have been fixed!")
    else:
        print("\n[Complete] Check finished")

