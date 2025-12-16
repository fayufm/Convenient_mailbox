#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
查找所有的build方法定义
"""
import re

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

output = []
output.append("=== 查找所有build方法 ===\n\n")

build_methods = []
builder_decorators = []

for i, line in enumerate(lines):
    line_num = i + 1
    
    # 查找 build() 方法定义
    if re.search(r'^\s*build\s*\(\s*\)', line):
        context_start = max(0, i - 2)
        context_end = min(len(lines), i + 3)
        build_methods.append({
            'line': line_num,
            'context': lines[context_start:context_end]
        })
    
    # 查找 @Builder 装饰器（可能被误认为build方法）
    if '@Builder' in line:
        builder_decorators.append({
            'line': line_num,
            'content': line.strip()
        })
    
    # 查找可能的 .build() 调用
    if '.build()' in line:
        output.append(f"Line {line_num}: .build() call found: {line.strip()[:100]}\n")

output.append(f"\n=== build()方法定义 ({len(build_methods)}) ===\n\n")
for method in build_methods:
    output.append(f">>> Line {method['line']} <<<\n")
    for ctx_line in method['context']:
        output.append(f"  {ctx_line}")
    output.append("\n")

output.append(f"\n=== @Builder装饰器 ({len(builder_decorators)}) ===\n")
output.append(f"总共发现 {len(builder_decorators)} 个 @Builder 方法\n")
if len(builder_decorators) > 0:
    output.append(f"前10个:\n")
    for i, decorator in enumerate(builder_decorators[:10]):
        output.append(f"  Line {decorator['line']}: {decorator['content']}\n")

# 检查struct Index的范围
struct_start = -1
struct_end = -1
for i, line in enumerate(lines):
    if re.search(r'@Entry\s*$', line) or re.search(r'@Component\s*$', line):
        # 找到struct定义
        for j in range(i, min(i + 5, len(lines))):
            if 'struct Index' in lines[j]:
                struct_start = j + 1
                break
    if struct_start > 0 and i == len(lines) - 1:
        struct_end = i + 1

output.append(f"\n=== struct Index 范围 ===\n")
output.append(f"Start: Line {struct_start}\n")
output.append(f"End: Line {struct_end}\n")

# 检查build方法是否在struct范围内
output.append(f"\n=== build()方法位置验证 ===\n")
for method in build_methods:
    if struct_start < method['line'] < struct_end:
        output.append(f"✓ Line {method['line']}: 在struct内部\n")
    else:
        output.append(f"✗ Line {method['line']}: 在struct外部！！！\n")

with open('all_build_methods.txt', 'w', encoding='utf-8') as f:
    f.writelines(output)

print(f"Analysis written to all_build_methods.txt")
print(f"Build methods found: {len(build_methods)}")
print(f"@Builder decorators found: {len(builder_decorators)}")


