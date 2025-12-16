#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确分析struct Index的花括号闭合位置 (忽略字符串内的花括号)
"""
import re

def count_braces_ignoring_strings(line):
    """计数花括号,忽略字符串内的"""
    # 移除字符串内容 (简化处理: 移除单引号和双引号字符串)
    # 注意: 这个实现不处理转义,但对于这个案例足够了
    line_without_strings = re.sub(r"'[^']*'", '', line)  # 移除单引号字符串
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)  # 移除双引号字符串
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)  # 移除模板字符串
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    return open_braces, close_braces

def analyze_struct_closure():
    with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    # 找到struct Index的开始位置 (line 82)
    struct_start_line = 82
    print(f"struct Index \u5f00\u59cb\u4e8e line {struct_start_line}")
    
    # 从struct Index开始计数花括号
    brace_count = 0
    struct_found = False
    
    key_lines = [5100, 5104, 5548, 5857, 6564, 6565, 6566, 6570, 7026]
    
    for i in range(struct_start_line - 1, min(len(lines), 7100)):
        line = lines[i]
        line_num = i + 1
        
        # 在struct Index那一行找到开始的{
        if line_num == struct_start_line:
            if '{' in line:
                brace_count = 1
                struct_found = True
                print(f"Line {line_num}: struct Index {{ - brace_count = {brace_count}")
            continue
        
        if not struct_found:
            continue
        
        # 计数花括号 (忽略字符串内的)
        open_braces, close_braces = count_braces_ignoring_strings(line)
        
        if open_braces > 0 or close_braces > 0:
            old_count = brace_count
            brace_count += open_braces - close_braces
            
            # 只打印关键行或brace_count变化较大的行
            if line_num in key_lines or old_count <= 1 or brace_count <= 1:
                print(f"Line {line_num}: +{open_braces} -{close_braces} => brace_count: {old_count} -> {brace_count}")
                if line_num in key_lines:
                    # 只打印前100个字符避免编码问题
                    print(f"  ** KEY LINE {line_num}: {line[:100].strip()}")
            
            # 如果花括号平衡回到0，说明struct结束了
            if brace_count == 0:
                print(f"\n*** struct Index \u5728 line {line_num} \u7ed3\u675f! ***")
                print(f"Line {line_num}: {line[:100].strip()}")
                print(f"\nbuild() \u5728 line 6570\uff0c\u6240\u4ee5 build() \u5728 struct {'\u5185\u90e8' if line_num >= 6570 else '\u5916\u90e8'}!")
                
                # 如果build()在外部，找出问题
                if line_num < 6570:
                    print(f"\n\u95ee\u9898: struct Index \u5728 line {line_num} \u5173\u95ed\uff0c\u4f46 build() \u5728 line 6570")
                    print(f"\u9700\u8981\u5220\u9664 line {line_num} \u7684\u82b1\u62ec\u53f7\uff0c\u6216\u8005\u5728\u66f4\u65e9\u7684\u5730\u65b9\u6dfb\u52a0\u5de6\u82b1\u62ec\u53f7")
                break
    
    if brace_count != 0:
        print(f"\n\u8b66\u544a: \u82b1\u62ec\u53f7\u4e0d\u5e73\u8861! brace_count = {brace_count}")

if __name__ == '__main__':
    analyze_struct_closure()

