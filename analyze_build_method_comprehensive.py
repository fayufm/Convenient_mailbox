#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
全面分析build()方法的结构和语法
"""
import re

def count_braces_ignoring_strings(line):
    line_without_strings = re.sub(r"'[^']*'", '', line)
    line_without_strings = re.sub(r'"[^"]*"', '', line_without_strings)
    line_without_strings = re.sub(r'`[^`]*`', '', line_without_strings)
    
    open_braces = line_without_strings.count('{')
    close_braces = line_without_strings.count('}')
    open_parens = line_without_strings.count('(')
    close_parens = line_without_strings.count(')')
    return open_braces, close_braces, open_parens, close_parens

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

output = []
output.append("=== build() 方法全面分析 (line 6573-6918) ===\n\n")

brace_count = 0
paren_count = 0
issues = []

for i in range(6572, 6919):  # line 6573-6918
    line = lines[i]
    line_num = i + 1
    
    open_br, close_br, open_par, close_par = count_braces_ignoring_strings(line)
    
    old_brace = brace_count
    old_paren = paren_count
    brace_count += open_br - close_br
    paren_count += open_par - close_par
    
    # 检测异常
    issue = None
    if brace_count < 0:
        issue = f"!!! BRACE NEGATIVE: {brace_count}"
    elif paren_count < 0:
        issue = f"!!! PAREN NEGATIVE: {paren_count}"
    
    # 检测关键结构
    line_clean = re.sub(r'[^\x00-\x7F]+', '?', line[:100].strip())
    
    is_key = False
    if 'build()' in line:
        is_key = True
        issue = issue or "<<< METHOD START"
    elif re.search(r'\s*if\s*\(', line) and open_br > 0:
        is_key = True
    elif re.search(r'\s*\}\s*else\s*\{', line):
        is_key = True
    elif 'Column(' in line or 'Row(' in line or 'Stack(' in line:
        is_key = True
    elif '.build()' in line:
        is_key = True
        issue = "!!! SUSPICIOUS: .build() call in build() method"
    elif open_br > 0 or close_br > 0:
        is_key = True
    
    if is_key or issue:
        output.append(f"Line {line_num:4d}: br[{old_brace:2d}->{brace_count:2d}] par[{old_paren:2d}->{paren_count:2d}]")
        if issue:
            output.append(f" {issue}")
        output.append(f"  |  {line_clean}\n")
        
        if issue and "!!!" in issue:
            issues.append({
                'line': line_num,
                'issue': issue,
                'content': line_clean
            })

output.append(f"\n=== 最终统计 ===\n")
output.append(f"Brace count: {brace_count} (期望: 0)\n")
output.append(f"Paren count: {paren_count} (期望: 0)\n")
output.append(f"\n=== 发现的问题 ({len(issues)}) ===\n")
for issue in issues:
    output.append(f"Line {issue['line']}: {issue['issue']}\n")
    output.append(f"  {issue['content']}\n\n")

with open('build_method_analysis.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print(f"Analysis written to build_method_analysis.txt")
print(f"Final brace_count: {brace_count}")
print(f"Final paren_count: {paren_count}")
print(f"Issues found: {len(issues)}")


