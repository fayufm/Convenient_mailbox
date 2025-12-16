#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复字符串闭合问题和对象字面量语法错误
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
    print(f"[备份] 已创建备份: {backup_path}")
    return backup_path

def fix_string_and_syntax_errors(filepath):
    """修复字符串和语法错误"""
    print(f"[开始] 读取文件: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    original_content = content
    changes = []
    
    # 修复 1: ${this.uiTexts['...'] || '}`') 类型的字符串错误
    # 示例：${this.uiTexts['mailboxCount'] || '}`') → ${this.uiTexts['mailboxCount'] || 'items'}`)
    pattern1 = r"\$\{this\.uiTexts\['([^']+)'\]\s*\|\|\s*'\}`'\)"
    matches1 = re.findall(pattern1, content)
    if matches1:
        for key in matches1:
            # 使用字符串拼接避免 f-string 的 {{ }} 转义问题
            old_pattern = "${this.uiTexts['" + key + "'] || '}`')"
            new_pattern = "${this.uiTexts['" + key + "'] || '" + key + "')"
            content = content.replace(old_pattern, new_pattern)
        changes.append(f"修复了 {len(matches1)} 处 uiTexts 字符串闭合错误")
    
    # 修复 2: 模板字符串中缺少 $ 的情况
    # 示例：锛{error.message}` → ：${(error as Error).message}`
    pattern2 = r"([：])\{([a-zA-Z_][a-zA-Z0-9_]*\.message)\}`"
    matches2 = re.findall(pattern2, content)
    if matches2:
        for prefix, expr in matches2:
            old_text = prefix + "{" + expr + "}`"
            # 判断是否是 error.message 并需要类型转换
            if 'error.message' in expr:
                new_text = prefix + "${(error as Error).message}`"
            else:
                new_text = prefix + "${" + expr + "}`"
            content = content.replace(old_text, new_text)
        changes.append(f"修复了 {len(matches2)} 处模板字符串缺少 $ 的错误")
    
    # 修复 3: hilog 调用中的多余引号和括号
    # 示例：%{public}d')', tag.name, tagId)' → %{public}d', tag.name, tagId)
    pattern3 = r"%\{public\}[sd]'\)'\s*,\s*([^,]+)\s*,\s*([^)]+)\)'"
    matches3 = re.findall(pattern3, content)
    if matches3:
        for match in matches3:
            # 这个模式比较复杂，需要更精确的处理
            pass  # 暂时跳过，需要手动处理
    
    # 修复 4: 对象字面量中缺少逗号的情况
    # 示例：name}\n叉爣璁扮殑嶄會琚垹闄ゃ俙,` → name}\n此标签记录的邮件会被删除。`,
    # 这个需要更复杂的分析，暂时跳过
    
    # 修复 5: 三元运算符缺少 ?（已在前面修复，这里再检查一次）
    pattern5 = r'(\w+)\s+(\w+)\s*\.\s*(\w+)\s*:\s*(-?\d+)'
    # 这个模式可能匹配正常代码，需要更精确
    
    # 写回文件
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        
        print(f"[修复] 共进行了 {len(changes)} 类修复：")
        for i, change in enumerate(changes, 1):
            print(f"  {i}. {change}")
        
        print(f"[完成] 文件已更新")
        return True
    else:
        print("[跳过] 未发现需要修复的问题")
        return False

def fix_specific_lines(filepath):
    """修复特定行的错误"""
    print(f"\n[开始] 修复特定行的错误")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    changes = []
    
    # 修复第 3548 行（索引 3547）
    if total_lines > 3548:
        line = lines[3547]
        if "'mailboxCount'] || '}`'" in line:
            lines[3547] = line.replace("'mailboxCount'] || '}`'", "'mailboxCount'] || 'items'}")
            changes.append("第3548行：修复字符串闭合错误")
    
    # 修复第 9645 行附近的乱码字符串（如果存在）
    # 需要先找到这一行
    for i, line in enumerate(lines):
        if 'tagName' in line and '叉爣璁' in line:
            # 替换乱码
            new_line = re.sub(r'\\n叉爣璁扮殑嶄會琚垹闄ゃ俙,`', r'\\n此标签记录的邮件会被删除。`,', line)
            if new_line != line:
                lines[i] = new_line
                changes.append(f"第{i+1}行：修复乱码字符串")
    
    # 修复类似 '..%{public}d')', var1, var2)' 的错误
    for i, line in enumerate(lines):
        if re.search(r"%\{public\}[sd]'\)'\s*,", line):
            # 移除多余的 ')' 和引号
            new_line = re.sub(r"'\)'\s*,\s*([^,]+)\s*,\s*([^)]+)\)'", r"', \\1, \\2)", line)
            if new_line != line:
                lines[i] = new_line
                changes.append(f"第{i+1}行：修复hilog调用语法")
    
    # 写回文件
    if changes:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[修复] 共修复了 {len(changes)} 个特定行错误：")
        for change in changes:
            print(f"  - {change}")
        
        return True
    else:
        print("[跳过] 未发现需要修复的特定行错误")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[错误] 文件不存在: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success1 = fix_string_and_syntax_errors(filepath)
    success2 = fix_specific_lines(filepath)
    
    if success1 or success2:
        print("\n[成功] 字符串和语法错误已修复！")
    else:
        print("\n[完成] 检查完成")

