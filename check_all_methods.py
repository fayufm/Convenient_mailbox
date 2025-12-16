#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查struct Index内所有方法的括号平衡
"""
import re

def count_braces_ignoring_strings(line):
    line_without_strings = re.sub(r"'[^']*'", '', line)
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    return open_braces, close_braces

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 找到所有方法（async或普通方法）
method_pattern = re.compile(r'^\s*(async\s+)?(\w+)\s*\(')
methods = []

for i in range(81, 7027):  # 从struct开始(line 82)到文件结尾
    line = lines[i]
    match = method_pattern.search(line)
    if match:
        methods.append({
            'name': match.group(2),
            'line': i + 1,
            'is_async': match.group(1) is not None
        })

print(f"找到 {len(methods)} 个方法\n")

# 为每个方法计算括号平衡
struct_count = 1  # struct Index开始时count=1

for i, method in enumerate(methods):
    start_line = method['line']
    # 找下一个方法的开始位置，或者到文件结尾
    end_line = methods[i+1]['line'] if i+1 < len(methods) else 7027
    
    brace_count = 0
    for line_num in range(start_line - 1, end_line - 1):
        open_br, close_br = count_braces_ignoring_strings(lines[line_num])
        brace_count += open_br - close_br
    
    method['brace_balance'] = brace_count
    
    # 更新struct的count
    struct_count += brace_count
    
    # 期望值：每个方法应该是0 (方法内的括号应该平衡)
    status = 'OK' if brace_count == 0 else 'ERR'
    
    if brace_count != 0 or struct_count != 1:
        print(f"{status} Line {start_line:4d}: {method['name']:30s} balance={brace_count:+3d}, struct_count after={struct_count:+3d}")

print(f"\n最终 struct_count: {struct_count}")
if struct_count == 1:
    print("✓ Struct仍然开启，所有方法括号平衡")
elif struct_count == 0:
    print("✗ Struct被提前关闭")
else:
    print(f"✗ 括号不平衡: struct_count={struct_count}")

