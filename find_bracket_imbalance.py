#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确定位括号不平衡的位置
"""

import os

def find_bracket_imbalance(filepath):
    """查找括号不平衡的具体位置"""
    print(f"=== Finding Bracket Imbalance ===\n")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    print(f"[Info] Total lines: {total_lines}\n")
    
    # 跟踪括号平衡
    brace_depth = 0  # {}
    paren_depth = 0  # ()
    bracket_depth = 0  # []
    
    brace_issues = []
    paren_issues = []
    bracket_issues = []
    
    in_string = False
    in_template = False
    string_char = None
    
    for i, line in enumerate(lines, 1):
        prev_brace = brace_depth
        prev_paren = paren_depth
        prev_bracket = bracket_depth
        
        j = 0
        while j < len(line):
            char = line[j]
            
            # 处理转义字符
            if char == '\\' and j + 1 < len(line):
                j += 2
                continue
            
            # 处理字符串
            if char in ["'", '"']:
                if not in_template:
                    if in_string and char == string_char:
                        in_string = False
                        string_char = None
                    elif not in_string:
                        in_string = True
                        string_char = char
            elif char == '`':
                in_template = not in_template
            
            # 只在非字符串上下文中计数括号
            if not in_string and not in_template:
                if char == '{':
                    brace_depth += 1
                elif char == '}':
                    brace_depth -= 1
                    if brace_depth < 0:
                        brace_issues.append((i, brace_depth, line.strip()[:60]))
                elif char == '(':
                    paren_depth += 1
                elif char == ')':
                    paren_depth -= 1
                    if paren_depth < 0:
                        paren_issues.append((i, paren_depth, line.strip()[:60]))
                elif char == '[':
                    bracket_depth += 1
                elif char == ']':
                    bracket_depth -= 1
                    if bracket_depth < 0:
                        bracket_issues.append((i, bracket_depth, line.strip()[:60]))
            
            j += 1
        
        # 记录深度变化较大的行
        if abs(brace_depth - prev_brace) > 3:
            print(f"[Line {i}] Large brace change: {prev_brace} -> {brace_depth}")
        
        if abs(paren_depth - prev_paren) > 5:
            print(f"[Line {i}] Large paren change: {prev_paren} -> {paren_depth}")
        
        if abs(bracket_depth - prev_bracket) > 3:
            print(f"[Line {i}] Large bracket change: {prev_bracket} -> {bracket_depth}")
    
    # 报告最终不平衡
    print(f"\n=== Final Balance ===")
    print(f"Braces {{ }}: {brace_depth} (should be 0)")
    print(f"Parentheses ( ): {paren_depth} (should be 0)")
    print(f"Brackets [ ]: {bracket_depth} (should be 0)")
    
    # 报告负数深度的位置（明显的错误）
    print(f"\n=== Issues Found ===")
    if brace_issues:
        print(f"\nLines with negative brace depth:")
        for line_num, depth, content in brace_issues[:10]:
            print(f"  Line {line_num}: depth={depth}")
    
    if paren_issues:
        print(f"\nLines with negative paren depth:")
        for line_num, depth, content in paren_issues[:10]:
            print(f"  Line {line_num}: depth={depth}")
    
    if bracket_issues:
        print(f"\nLines with negative bracket depth:")
        for line_num, depth, content in bracket_issues[:10]:
            print(f"  Line {line_num}: depth={depth}")
    
    # 建议修复
    print(f"\n=== Suggested Fixes ===")
    if brace_depth > 0:
        print(f"Missing {brace_depth} closing brace(s) {{ }}")
    elif brace_depth < 0:
        print(f"Extra {-brace_depth} closing brace(s) {{ }}")
    
    if paren_depth > 0:
        print(f"Missing {paren_depth} closing paren(s) ( )")
    elif paren_depth < 0:
        print(f"Extra {-paren_depth} closing paren(s) ( )")
    
    if bracket_depth > 0:
        print(f"Missing {bracket_depth} closing bracket(s) [ ]")
    elif bracket_depth < 0:
        print(f"Extra {-bracket_depth} closing bracket(s) [ ]")
    
    return {
        'brace': brace_depth,
        'paren': paren_depth,
        'bracket': bracket_depth,
        'issues': {
            'brace': brace_issues,
            'paren': paren_issues,
            'bracket': bracket_issues
        }
    }

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    result = find_bracket_imbalance(filepath)
    print("\n[Complete] Analysis finished")

