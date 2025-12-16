#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
找到缺失的开括号 - 检查每个async方法的括号平衡
"""
import re

def count_braces_ignoring_strings(line):
    """计数花括号,忽略字符串内的"""
    line_without_strings = re.sub(r"'[^']*'", '', line)
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    return open_braces, close_braces

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

# 找到所有async方法
method_pattern = re.compile(r'^\s*async\s+(\w+)\s*\(')
methods = []

for i, line in enumerate(lines[82:3040], start=83):  # 从struct开始到line 3040
    match = method_pattern.search(line)
    if match:
        methods.append({
            'name': match.group(1),
            'line': i,
            'start_line': i
        })

output = []
output.append(f"找到 {len(methods)} 个async方法 (line 83-3040):\n\n")

# 为每个方法计算括号平衡
for i, method in enumerate(methods):
    start_line = method['line']
    # 找下一个方法的开始位置，或者到line 3040
    end_line = methods[i+1]['line'] if i+1 < len(methods) else 3040
    
    brace_count = 0
    for line_num in range(start_line - 1, end_line - 1):
        open_br, close_br = count_braces_ignoring_strings(lines[line_num])
        brace_count += open_br - close_br
    
    method['brace_balance'] = brace_count
    
    # 期望值：每个方法应该是0 (方法内的括号应该平衡)
    status = 'OK' if brace_count == 0 else 'ERR'
    output.append(f"{status} Line {start_line:4d}: {method['name']:30s} balance={brace_count:+3d}\n")
    
    if brace_count != 0:
        output.append(f"     ^^^^ 问题! 这个方法的括号不平衡 ({brace_count:+d})\n")
        output.append(f"     方法范围: line {start_line} - {end_line-1}\n")
        
        # 如果是负数，说明有多余的}, 如果是正数，说明缺少}
        if brace_count > 0:
            output.append(f"     → 缺少 {brace_count} 个关闭括号 }}\n")
        else:
            output.append(f"     → 多余 {-brace_count} 个关闭括号 }} (或缺少开括号 {{)\n")
        output.append("\n")

with open('method_balance_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print("Analysis written to method_balance_analysis.txt")

