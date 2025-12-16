#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
全面验证 Index.ets 文件，检查剩余问题
"""

import os
import re

def validate_file(filepath):
    """全面验证文件"""
    print(f"=== Comprehensive Validation ===\n")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    print(f"[Info] Total lines: {total_lines}\n")
    
    issues = {
        'garbled_chars': [],
        'unterminated_strings': [],
        'missing_ternary': [],
        'object_syntax': [],
        'bracket_imbalance': []
    }
    
    # 检查 1: 乱码字符
    print("[Check 1] Scanning for garbled Chinese characters...")
    garbled_pattern = re.compile(r'[鏀変戜鐐鏍锛搴瑰熸朵佺勭殑呭婃忔氭犻櫎]')
    for i, line in enumerate(lines):
        if garbled_pattern.search(line):
            issues['garbled_chars'].append((i+1, line.strip()[:60]))
    print(f"  Found {len(issues['garbled_chars'])} lines with garbled characters")
    if issues['garbled_chars']:
        print(f"  First 5 examples:")
        for line_num, content in issues['garbled_chars'][:5]:
            print(f"    Line {line_num}")
    print()
    
    # 检查 2: 未终止的模板字符串（缺少 }`）
    print("[Check 2] Scanning for unterminated template strings...")
    for i, line in enumerate(lines):
        # 检查模板字符串中的 {xxx} 是否缺少 $
        if '`' in line and '{' in line:
            # 简单的模式：检查 {xxx} 但前面没有 $
            if re.search(r'[^$]\{[a-zA-Z_][a-zA-Z0-9_\.]*\}', line):
                issues['unterminated_strings'].append((i+1, line.strip()[:60]))
    print(f"  Found {len(issues['unterminated_strings'])} potential template string issues")
    if issues['unterminated_strings']:
        print(f"  First 5 examples:")
        for line_num, content in issues['unterminated_strings'][:5]:
            print(f"    Line {line_num}")
    print()
    
    # 检查 3: 三元运算符缺少 ?
    print("[Check 3] Scanning for missing ? in ternary operators...")
    # 模式：变量名 + 空格 + 变量.属性 + : + 值
    ternary_pattern = re.compile(r'(\w+)\s+(\w+)\s*\.\s*(\w+)\s*:\s*')
    for i, line in enumerate(lines):
        if ternary_pattern.search(line) and ' ? ' not in line:
            # 排除某些误报（如对象属性定义）
            if '{' not in line or ':' in line.split('{')[0]:
                issues['missing_ternary'].append((i+1, line.strip()[:60]))
    print(f"  Found {len(issues['missing_ternary'])} potential missing ? operators")
    if issues['missing_ternary']:
        print(f"  First 5 examples:")
        for line_num, content in issues['missing_ternary'][:5]:
            print(f"    Line {line_num}")
    print()
    
    # 检查 4: 对象字面量语法（缺少逗号、冒号）
    print("[Check 4] Checking file structure...")
    open_braces = 0
    open_parens = 0
    open_brackets = 0
    in_string = False
    in_template = False
    string_char = None
    
    for i, line in enumerate(lines):
        for j, char in enumerate(line):
            # 跳过字符串内容
            if char in ["'", '"'] and (j == 0 or line[j-1] != '\\'):
                if not in_template:
                    if in_string and char == string_char:
                        in_string = False
                        string_char = None
                    elif not in_string:
                        in_string = True
                        string_char = char
            elif char == '`':
                in_template = not in_template
            
            if not in_string and not in_template:
                if char == '{':
                    open_braces += 1
                elif char == '}':
                    open_braces -= 1
                elif char == '(':
                    open_parens += 1
                elif char == ')':
                    open_parens -= 1
                elif char == '[':
                    open_brackets += 1
                elif char == ']':
                    open_brackets -= 1
    
    print(f"  Brace balance: {open_braces} (should be 0)")
    print(f"  Parenthesis balance: {open_parens} (should be 0)")
    print(f"  Bracket balance: {open_brackets} (should be 0)")
    print()
    
    # 检查 5: struct Index 和 build 方法
    print("[Check 5] Verifying struct Index and build() method...")
    struct_count = 0
    build_count = 0
    
    for i, line in enumerate(lines):
        if re.search(r'^\s*struct\s+Index\s*\{', line):
            struct_count += 1
            print(f"  Found 'struct Index' at line {i+1}")
        if re.search(r'^\s*build\s*\(', line):
            build_count += 1
            print(f"  Found 'build()' method at line {i+1}")
    
    print(f"  Total 'struct Index' declarations: {struct_count} (should be 1)")
    print(f"  Total 'build()' methods: {build_count} (should be 1)")
    print()
    
    # 总结
    print("=== Validation Summary ===")
    total_issues = (len(issues['garbled_chars']) + 
                   len(issues['unterminated_strings']) + 
                   len(issues['missing_ternary']))
    
    print(f"Total potential issues found: {total_issues}")
    print(f"  - Garbled characters: {len(issues['garbled_chars'])}")
    print(f"  - Template string issues: {len(issues['unterminated_strings'])}")
    print(f"  - Missing ternary operators: {len(issues['missing_ternary'])}")
    print(f"\nStructure:")
    print(f"  - Brace balance: {'OK' if open_braces == 0 else 'IMBALANCED'}")
    print(f"  - Struct definition: {'OK' if struct_count == 1 else 'ERROR'}")
    print(f"  - Build method: {'OK' if build_count == 1 else 'ERROR'}")
    
    return issues

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[Error] File not found: {filepath}")
        exit(1)
    
    issues = validate_file(filepath)
    print("\n[Complete] Validation finished")

