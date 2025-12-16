#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析struct Index的花括号闭合位置
"""

def analyze_struct_closure():
    with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    # 找到struct Index的开始位置 (line 82)
    struct_start_line = 82
    print(f"struct Index 开始于 line {struct_start_line}")
    
    # 从struct Index开始计数花括号
    brace_count = 0
    struct_found = False
    
    for i in range(struct_start_line - 1, len(lines)):
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
        
        # 计数花括号
        open_braces = line.count('{')
        close_braces = line.count('}')
        
        if open_braces > 0 or close_braces > 0:
            old_count = brace_count
            brace_count += open_braces - close_braces
            print(f"Line {line_num}: +{open_braces} -{close_braces} => brace_count: {old_count} -> {brace_count}")
            
            # 特别关注一些关键行
            if line_num in [5100, 5104, 5548, 5857, 6564, 6565, 6566, 6570, 7026]:
                print(f"  ** KEY LINE {line_num}: {line.strip()}")
            
            # 如果花括号平衡回到0，说明struct结束了
            if brace_count == 0:
                print(f"\n*** struct Index 在 line {line_num} 结束! ***")
                print(f"Line {line_num}: {line.strip()}")
                print(f"\nbuild() 在 line 6570，所以 build() 在 struct {'内部' if line_num >= 6570 else '外部'}!")
                break
    
    if brace_count != 0:
        print(f"\n警告: 花括号不平衡! brace_count = {brace_count}")

if __name__ == '__main__':
    analyze_struct_closure()

