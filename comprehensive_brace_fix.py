#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
最终策略：基于我们已知的问题，直接修复
我们知道：
1. struct Index在line 3036关闭（应该在line 7026）
2. onSendEmail()方法有brace不平衡
3. 问题出在line 82-3040之间

直接策略：删除line 3036的多余闭括号
"""

with open('entry/src/main/ets/pages/Index.ets', 'r', encoding='utf-8', errors='ignore') as f:
    lines = f.readlines()

print("=== 检查当前状态 ===\n")
print(f"Line 3034: {lines[3033].strip()}")
print(f"Line 3035: {lines[3034].strip()}")
print(f"Line 3036: {lines[3035].strip()}")
print(f"Line 3037: {lines[3036].strip()}")
print(f"Line 3038: {lines[3037].strip()}")

# 检查line 3036是否是孤立的}
if lines[3035].strip() == '}':
    print("\n✓ Line 3036是孤立的 '}'")
    print("这个}是多余的，应该删除")
    
    # 策略：将line 3036替换为空行（保持行号不变）
    lines[3035] = "  // } // <--- REMOVED: Extra closing brace that was closing struct Index early\n"
    
    with open('entry/src/main/ets/pages/Index.ets', 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("\n✓ 已将line 3036的多余}注释掉")
    print("现在struct Index应该会在正确的位置关闭（文件末尾）")
else:
    print(f"\n✗ Line 3036不是孤立的}}: {lines[3035].strip()}")
    
# 同时检查文件末尾是否有struct的结束}
print(f"\n=== 检查文件末尾 ===")
print(f"Line 7024: {lines[7023].strip()}")
print(f"Line 7025: {lines[7024].strip()}")
print(f"Line 7026: {lines[7025].strip()}")

if lines[7025].strip() == '}':
    print("\n✓ 文件末尾有 '}' （应该是struct Index的结束）")
else:
    print(f"\n⚠ 文件末尾不是}}: {lines[7025].strip()}")

