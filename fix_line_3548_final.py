#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
最终修复第 3548 行
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

def fix_line_3548_final(filepath):
    """最终修复第 3548 行"""
    print(f"[Start] Reading file: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    original_content = content
    
    # 精确的查找和替换
    old_pattern = "${this.uiTexts['mailboxCount'] || '}`')"
    new_pattern = "${this.uiTexts['mailboxCount'] || 'items'})"
    
    if old_pattern in content:
        print(f"[Found] Pattern found in file")
        content = content.replace(old_pattern, new_pattern)
        print(f"[Fixed] Pattern replaced")
        
        # 写回文件
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        
        print(f"[Complete] File updated")
        return True
    else:
        print(f"[Not Found] Pattern not found in file")
        print(f"[Debug] Searching for similar patterns...")
        
        # 尝试其他可能的变体
        alternatives = [
            "${this.uiTexts['mailboxCount'] || '}`'}",
            '${this.uiTexts["mailboxCount"] || "}"}',
            '${this.uiTexts["mailboxCount"] || "}`"}',
        ]
        
        for alt in alternatives:
            if alt in content:
                print(f"[Found] Alternative pattern found: {alt}")
                break
        
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_line_3548_final(filepath)
    
    if success:
        print("\n[Success] Line 3548 has been fixed!")
    else:
        print("\n[Failed] Could not fix line 3548")

