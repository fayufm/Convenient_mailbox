#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复所有畸形的字符串模式
"""

import os
import shutil
import re
from datetime import datetime

def backup_file(filepath):
    """创建备份"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"{filepath}.backup_{timestamp}"
    shutil.copy2(filepath, backup_path)
    print(f"[Backup] Created backup: {backup_path}")
    return backup_path

def fix_malformed_strings(filepath):
    """修复畸形的字符串"""
    print(f"[Start] Reading file: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    changes = []
    
    # 修复模式 1: Text(`...${xxx || '}`')`) 
    # 这个模式在模板字符串中有错误的引号闭合
    for i in range(total_lines):
        line = lines[i]
        
        # 检查是否包含 || '}`'
        if "|| '}`'" in line or '|| "`}\'' in line or '|| "}' in line:
            # 简单替换：将 '}`' 替换为 'items'}
            new_line = line
            
            # 尝试各种可能的错误模式
            patterns_to_fix = [
                ("|| '}`')", "|| 'items'})"),
                ('|| "`}\'', "|| 'items'}"),
                ('|| "}\'', "|| 'items'}"),
            ]
            
            for old, new in patterns_to_fix:
                if old in new_line:
                    new_line = new_line.replace(old, new)
                    changes.append((i+1, old))
                    break
            
            if new_line != line:
                lines[i] = new_line
    
    # 修复模式 2: 多余的反引号
    # 检查模式如 `...` `` 或其他重复的反引号
    for i in range(total_lines):
        line = lines[i]
        
        # 检查连续的两个反引号
        if '``' in line and 'return `' not in line:
            new_line = line.replace('``', '`')
            if new_line != line:
                lines[i] = new_line
                changes.append((i+1, '``'))
    
    # 写回文件
    if changes:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[Fixed] Made {len(changes)} changes:")
        for line_num, pattern in changes[:20]:
            print(f"  Line {line_num}: fixed pattern containing '{pattern[:20]}'")
        
        print(f"[Complete] File updated")
        return True
    else:
        print("[Skip] No malformed strings found")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_malformed_strings(filepath)
    
    if success:
        print("\n[Success] Malformed strings have been fixed!")
    else:
        print("\n[Complete] Check finished")

