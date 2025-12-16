#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
详细跟踪onSendEmail方法的每个控制结构
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

output = []
output.append("=== onSendEmail() 详细跟踪 ===\n\n")

# 从方法开始到结束
brace_count = 0
expected_count = 0  # 期望的括号计数

for i in range(2817, 3038):  # line 2818-3038
    line = lines[i]
    line_num = i + 1
    
    # 移除中文字符
    line_clean = re.sub(r'[^\x00-\x7F]+', '?', line[:100].strip())
    
    open_br, close_br = count_braces_ignoring_strings(line)
    
    old_count = brace_count
    brace_count += open_br - close_br
    
    # 检测关键控制结构
    is_key = False
    note = ""
    
    if 'async onSendEmail()' in line:
        is_key = True
        note = " << METHOD START"
        expected_count = 1
    elif re.search(r'\s*if\s*\(', line) and open_br > 0:
        is_key = True
        note = f" << IF statement, expect +1"
        expected_count += 1
    elif re.search(r'\s*\}\s*else\s*\{', line):
        is_key = True
        note = " << } else {, no change expected"
    elif re.search(r'\s*\}\s*else\s+if\s*\(', line):
        is_key = True
        note = " << } else if {, no change expected"
    elif re.search(r'\s*try\s*\{', line):
        is_key = True
        note = " << TRY block, expect +1"
        expected_count += 1
    elif re.search(r'\s*\}\s*catch\s*\(', line):
        is_key = True
        note = " << } catch {, no change expected"
    elif re.search(r'\s*\}\s*finally\s*\{', line):
        is_key = True
        note = " << } finally {, no change expected"
    elif close_br > 0 and open_br == 0:
        is_key = True
        note = " << CLOSING brace"
        if brace_count < expected_count:
            note += f" WARNING: count={brace_count} < expected={expected_count}"
    
    if is_key or open_br > 0 or close_br > 0:
        output.append(f"Line {line_num:4d}: +{open_br} -{close_br} => {old_count} -> {brace_count}  |  {line_clean}{note}\n")

output.append(f"\n最终 brace_count: {brace_count}\n")
output.append(f"期望 brace_count: 0 (方法结束时应该回到0)\n")

if brace_count == 0:
    output.append("✓ 方法括号平衡\n")
else:
    output.append(f"✗ 方法括号不平衡: {brace_count}\n")
    if brace_count > 0:
        output.append(f"  缺少 {brace_count} 个关闭括号 }}\n")
    else:
        output.append(f"  多余 {-brace_count} 个关闭括号 }} (或缺少 {-brace_count} 个开括号 {{)\n")

with open('onsend_detailed_trace.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print("Detailed trace written to onsend_detailed_trace.txt")
print(f"Final brace_count: {brace_count}")

