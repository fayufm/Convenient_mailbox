#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
只检查真正的方法（以async或方法名开头的）
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

# 只匹配真正的方法：async method() 或 method()，排除if/for/while等
method_pattern = re.compile(r'^\s*(async\s+)?([a-zA-Z_]\w*)\s*\([^)]*\)\s*(?::\s*\w+\s*)?{')
methods = []

for i in range(81, 3040):  # 只检查到onSendEmail结束
    line = lines[i]
    match = method_pattern.search(line)
    if match:
        method_name = match.group(2)
        # 排除明显的关键字
        if method_name not in ['if', 'for', 'while', 'switch', 'catch']:
            methods.append({
                'name': method_name,
                'line': i + 1,
                'is_async': match.group(1) is not None
            })

print(f"找到 {len(methods)} 个真正的方法 (line 82-3040)\n")

# 为每个方法计算括号平衡
for i, method in enumerate(methods):
    start_line = method['line']
    # 找下一个方法的开始位置
    end_line = methods[i+1]['line'] if i+1 < len(methods) else 3040
    
    brace_count = 0
    for line_num in range(start_line - 1, end_line - 1):
        open_br, close_br = count_braces_ignoring_strings(lines[line_num])
        brace_count += open_br - close_br
    
    method['brace_balance'] = brace_count
    
    # 期望值：每个方法应该是0 (方法内的括号应该平衡)
    status = 'OK' if brace_count == 0 else 'ERR'
    print(f"{status} Line {start_line:4d}: {method['name']:35s} balance={brace_count:+3d}")

# 计算累积的不平衡
total_imbalance = sum(m['brace_balance'] for m in methods)
print(f"\n总括号不平衡: {total_imbalance:+d}")
print(f"Struct count应该是: 1 + {total_imbalance} = {1 + total_imbalance}")

