#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确括号分析 - 分析 struct Index 的括号结构
"""

def analyze_brackets(filepath: str, start_line: int = 1, end_line: int = None):
    """分析指定行范围的括号结构"""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()
    
    if end_line is None:
        end_line = len(lines)
    
    # 括号栈
    curly_depth = 0
    round_depth = 0
    square_depth = 0
    
    # 跟踪状态
    in_string = False
    in_template = False
    string_char = None
    
    print(f"分析文件: {filepath}")
    print(f"行范围: {start_line} - {end_line}")
    print("=" * 80)
    
    for i in range(start_line - 1, min(end_line, len(lines))):
        line_num = i + 1
        line = lines[i]
        
        prev_curly = curly_depth
        
        # 逐字符分析
        j = 0
        while j < len(line):
            char = line[j]
            
            # 处理转义字符
            if j > 0 and line[j-1] == '\\':
                j += 1
                continue
            
            # 处理字符串
            if not in_template:
                if char in ('"', "'") and not in_string:
                    in_string = True
                    string_char = char
                elif in_string and char == string_char:
                    in_string = False
                    string_char = None
            
            # 处理模板字面量
            if char == '`' and not in_string:
                in_template = not in_template
            
            # 只在字符串/模板外计算括号
            if not in_string and not in_template:
                if char == '{':
                    curly_depth += 1
                elif char == '}':
                    curly_depth -= 1
                elif char == '(':
                    round_depth += 1
                elif char == ')':
                    round_depth -= 1
                elif char == '[':
                    square_depth += 1
                elif char == ']':
                    square_depth -= 1
            
            j += 1
        
        # 如果大括号深度发生变化，打印详细信息
        if curly_depth != prev_curly:
            depth_change = curly_depth - prev_curly
            symbol = '+' if depth_change > 0 else ''
            print(f"行 {line_num:5}: {{{depth_change:+2}}} -> 深度={curly_depth:2} | {line.rstrip()[:80]}")
        
        # 特别关注深度回到 0 的情况
        if prev_curly > 0 and curly_depth == 0:
            print(f"{'='*80}")
            print(f"【警告】第 {line_num} 行：大括号深度回到 0！")
            print(f"{'='*80}")
    
    print()
    print("最终深度:")
    print(f"  大括号 {{}}: {curly_depth}")
    print(f"  圆括号 (): {round_depth}")
    print(f"  方括号 []: {square_depth}")
    print()
    
    if curly_depth != 0:
        print(f"【错误】大括号不平衡！深度 = {curly_depth}")
    else:
        print("【正常】大括号平衡")

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    # 分析整个文件
    print("\n分析整个文件的括号结构：\n")
    analyze_brackets(filepath)
    
    # 特别关注 11870-11900 区域
    print("\n" + "="*80)
    print("特别关注 11870-11900 行区域：")
    print("="*80)
    analyze_brackets(filepath, 11870, 11900)

