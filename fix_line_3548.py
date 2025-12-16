#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确修复第 3548 行的字符串闭合错误
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

def fix_line_3548(filepath):
    """修复第 3548 行的字符串闭合错误"""
    print(f"[Start] Reading file: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    print(f"[Info] Total lines: {total_lines}")
    
    if total_lines < 3548:
        print(f"[Error] File has fewer than 3548 lines")
        return False
    
    # 检查第 3548 行（索引 3547）
    line_3548 = lines[3547]
    
    # 检查是否包含错误模式
    if "'mailboxCount'] || '}`'" in line_3548:
        print(f"[Found] Line 3548 contains the error pattern")
        
        # 执行替换
        lines[3547] = line_3548.replace("'mailboxCount'] || '}`'", "'mailboxCount'] || 'items'}")
        
        # 写回文件
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[Fixed] Line 3548: string closing error fixed")
        print(f"[Complete] File updated")
        return True
    else:
        print(f"[Skip] Line 3548 does not contain the expected error pattern")
        print(f"[Debug] Line content: {line_3548[:100]}")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_line_3548(filepath)
    
    if success:
        print("\n[Success] Line 3548 has been fixed!")
    else:
        print("\n[Complete] Check complete")

