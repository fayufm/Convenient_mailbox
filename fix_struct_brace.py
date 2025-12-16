#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复struct Index的花括号问题
根据分析，struct在line 3035意外关闭，需要找到并修复缺失的开括号
"""

# 策略：在line 3035之后添加一个注释，然后在文件末尾验证是否还有内容
# 如果line 3035确实关闭了struct,那么line 3036之后的所有方法都在struct外部

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print(f"文件总行数: {len(lines)}")
print(f"\nLine 3035: {lines[3034].strip()}")
print(f"Line 3036: {lines[3035].strip()}")
print(f"Line 3037: {lines[3036].strip()}")

# 检查line 3035是否只是一个孤立的}
if lines[3034].strip() == '}':
    print("\n✓ Line 3035确实只有一个'}'")
    print("\n分析：如果这个}关闭了struct Index，那么line 3036之后的方法都是错误的")
    print("解决方案：删除line 3035的}，并在文件末尾(line 7026附近)添加struct的结束}")
    
    # 方案：注释掉line 3035，并在build()方法结束后添加struct的结束}
    print("\n执行修复：")
    print("1. 注释掉line 3035")
    print("2. 在文件末尾(现在的最后一行)添加struct Index的结束}")
    
    # 修改line 3035
    lines[3034] = "  // } // <--- REMOVED: 这个}错误地关闭了struct Index (应该在文件末尾)\n"
    
    # 在文件末尾添加struct的结束}
    if not lines[-1].endswith('\n'):
        lines[-1] += '\n'
    lines.append("} // struct Index 结束\n")
    
    # 保存
    with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("\n✓ 修复完成!")
    print(f"  - Line 3035: 已注释掉错误的}}")
    print(f"  - Line {len(lines)}: 已添加struct Index的结束}}")
else:
    print(f"\n✗ Line 3035不是孤立的}}，是: {lines[3034].strip()}")
    print("需要手动检查")

