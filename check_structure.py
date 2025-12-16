#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
检查Index.ets的class结构和括号平衡
"""

import os
import sys

# 设置输出编码
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'ignore')

def check_structure():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🔍 检查Index.ets的结构完整性")
    print("=" * 70)
    
    # 读取文件
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
        print(f"✅ 读取文件成功，共 {len(lines)} 行\n")
    except Exception as e:
        print(f"❌ 读取失败: {e}")
        return
    
    # 检查struct Index的定义
    struct_line = -1
    build_line = -1
    
    for i, line in enumerate(lines):
        if 'struct Index {' in line:
            struct_line = i + 1  # 转换为1-based
            print(f"✅ 找到 'struct Index {{' 在第 {struct_line} 行")
        if '  build()' in line and build_line == -1:
            build_line = i + 1
            print(f"✅ 找到 '  build()' 在第 {build_line} 行")
    
    if struct_line == -1:
        print("❌ 未找到 'struct Index {}'")
        return
    if build_line == -1:
        print("❌ 未找到 'build()' 方法")
        return
    
    print()
    
    # 检查括号平衡
    print("🔍 检查括号平衡...")
    
    # 从struct Index开始计数
    brace_count = 0
    paren_count = 0
    bracket_count = 0
    
    in_string = False
    in_comment = False
    in_template = False
    
    for i in range(struct_line - 1, len(lines)):
        line = lines[i]
        
        # 简化的字符检查（不考虑字符串和注释中的括号）
        for char in line:
            if char == '{':
                brace_count += 1
            elif char == '}':
                brace_count -= 1
            elif char == '(':
                paren_count += 1
            elif char == ')':
                paren_count -= 1
            elif char == '[':
                bracket_count += 1
            elif char == ']':
                bracket_count -= 1
        
        # 如果花括号回到0，说明struct结束了
        if brace_count == 0 and i > struct_line:
            struct_end_line = i + 1
            print(f"✅ struct Index 在第 {struct_end_line} 行结束")
            print(f"   struct 跨度: {struct_end_line - struct_line + 1} 行")
            break
    else:
        print(f"❌ struct Index 未正确结束！")
        print(f"   当前花括号计数: {brace_count}")
        return
    
    print()
    
    # 检查build方法的范围
    print("🔍 检查build()方法...")
    
    build_brace_count = 0
    build_start_brace_line = -1
    
    for i in range(build_line - 1, struct_end_line):
        line = lines[i]
        
        for char in line:
            if char == '{':
                if build_start_brace_line == -1:
                    build_start_brace_line = i + 1
                build_brace_count += 1
            elif char == '}':
                build_brace_count -= 1
                if build_brace_count == 0:
                    build_end_line = i + 1
                    print(f"✅ build() 方法在第 {build_end_line} 行结束")
                    print(f"   build() 跨度: {build_end_line - build_line + 1} 行")
                    print(f"   开始花括号在第 {build_start_brace_line} 行")
                    break
        
        if build_brace_count == 0 and build_start_brace_line != -1:
            break
    else:
        print(f"❌ build() 方法未正确结束！")
        print(f"   当前花括号计数: {build_brace_count}")
        return
    
    print()
    
    # 检查是否有多个build方法
    print("🔍 检查是否有多个build方法...")
    
    build_count = 0
    for i, line in enumerate(lines):
        if '  build()' in line or '  build (' in line:
            build_count += 1
            print(f"   找到build方法（或类似）在第 {i+1} 行: {line.strip()}")
    
    if build_count == 1:
        print(f"✅ 只有一个build()方法")
    elif build_count > 1:
        print(f"⚠️  发现 {build_count} 个可能的build方法！")
    else:
        print(f"❌ 未找到build()方法！")
    
    print()
    
    # 最终总结
    print("=" * 70)
    print("📊 结构检查总结")
    print("=" * 70)
    print(f"struct Index: 第 {struct_line} - {struct_end_line} 行 ({struct_end_line - struct_line + 1} 行)")
    print(f"build() 方法: 第 {build_line} - {build_end_line} 行 ({build_end_line - build_line + 1} 行)")
    print(f"build() 方法数量: {build_count}")
    
    if build_count == 1 and brace_count == 0:
        print("\n✅ 结构看起来正常，但编译器仍报错")
        print("💡 可能的原因：")
        print("   1. build()方法内部有语法错误")
        print("   2. @Component或@Entry装饰器有问题")
        print("   3. 方法签名不正确（应该是 build()，没有参数）")
    else:
        print("\n❌ 结构有问题")

if __name__ == "__main__":
    check_structure()

