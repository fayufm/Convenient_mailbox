#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
分析 Index.ets 文件的 struct Index 作用域
找出是否有提前关闭的大括号
"""

import re

def analyze_struct_scope(filepath):
    """分析struct的作用域"""
    
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    struct_start = None
    struct_depth = 0
    in_struct = False
    brace_stack = []
    
    # 关键方法和属性的位置
    key_items = {
        'aboutToAppear': None,
        'updateUITexts': None,
        'build': None,
        'selectedMailboxIndex_usage': [],
        'selectedMailboxIndex_declaration': None,
    }
    
    print(f"文件总行数: {len(lines)}")
    print("\n" + "=" * 80)
    print("分析 struct Index 作用域...")
    print("=" * 80)
    
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        
        # 检测 struct Index 开始
        if re.match(r'^struct\s+Index\s*\{', stripped):
            struct_start = i
            struct_depth = 1
            in_struct = True
            print(f"\n行 {i}: struct Index {{ -- 开始")
            continue
        
        # 如果在 struct 内部
        if in_struct:
            # 统计大括号
            open_braces = stripped.count('{')
            close_braces = stripped.count('}')
            
            struct_depth += (open_braces - close_braces)
            
            # 检测关键方法
            if 'async aboutToAppear()' in stripped or 'aboutToAppear()' in stripped:
                key_items['aboutToAppear'] = i
                print(f"行 {i}: 找到 aboutToAppear() 方法 (当前深度: {struct_depth})")
            
            if re.match(r'\s*updateUITexts\s*\(', stripped):
                key_items['updateUITexts'] = i
                print(f"行 {i}: 找到 updateUITexts() 方法定义 (当前深度: {struct_depth})")
            
            if 'this.updateUITexts' in stripped:
                print(f"行 {i}: 调用 updateUITexts() (当前深度: {struct_depth})")
            
            if re.match(r'\s*build\s*\(\s*\)\s*\{', stripped):
                key_items['build'] = i
                print(f"行 {i}: 找到 build() 方法 (当前深度: {struct_depth})")
            
            # 检测 selectedMailboxIndex
            if '@State selectedMailboxIndex' in stripped:
                key_items['selectedMailboxIndex_declaration'] = i
                print(f"行 {i}: 找到 selectedMailboxIndex 声明 (当前深度: {struct_depth})")
            
            if 'selectedMailboxIndex' in stripped and '@State' not in stripped:
                key_items['selectedMailboxIndex_usage'].append(i)
            
            # 检测 struct 结束
            if struct_depth == 0:
                print(f"\n行 {i}: struct Index 可能在此结束! (深度回到0)")
                print(f"  内容: {stripped[:100]}")
                in_struct = False
                
                # 检查后续是否还有代码
                remaining_lines = len(lines) - i
                print(f"  struct 结束后还有 {remaining_lines} 行代码")
                
                if key_items['updateUITexts'] is None:
                    print(f"  [WARNING] updateUITexts method not found inside struct!")
                
                if key_items['build'] is None:
                    print(f"  [WARNING] build method not found inside struct!")
            
            # 检测异常的深度变化
            if struct_depth < 0:
                print(f"\n行 {i}: [ERROR] depth becomes negative! ({struct_depth})")
                print(f"  内容: {stripped}")
                struct_depth = 0
            
            # 如果深度回到 1，且有 async 关键字，可能是新的顶层方法
            if struct_depth == 1 and ('async ' in stripped or 'private ' in stripped or '@Builder' in stripped):
                if i > struct_start + 300:  # 跳过属性声明区域
                    pass  # 这是正常的方法定义
    
    print("\n" + "=" * 80)
    print("关键项位置总结")
    print("=" * 80)
    print(f"struct Index 开始: 行 {struct_start}")
    print(f"aboutToAppear 方法: 行 {key_items['aboutToAppear']}")
    print(f"updateUITexts 方法: 行 {key_items['updateUITexts']}")
    print(f"build 方法: 行 {key_items['build']}")
    print(f"selectedMailboxIndex 声明: {key_items['selectedMailboxIndex_declaration']}")
    print(f"selectedMailboxIndex 使用次数: {len(key_items['selectedMailboxIndex_usage'])}")
    if key_items['selectedMailboxIndex_usage']:
        print(f"  前10次使用: {key_items['selectedMailboxIndex_usage'][:10]}")
    
    # 检查异常情况
    print("\n" + "=" * 80)
    print("异常检查")
    print("=" * 80)
    
    if key_items['selectedMailboxIndex_declaration'] is None:
        print("[ERROR] selectedMailboxIndex not declared!")
    
    if key_items['updateUITexts'] is None:
        print("[ERROR] updateUITexts method not found!")
    elif key_items['aboutToAppear'] and key_items['updateUITexts']:
        if key_items['updateUITexts'] < key_items['aboutToAppear']:
            print("[ERROR] updateUITexts defined before aboutToAppear (should be after)")
    
    if key_items['build'] is None:
        print("[ERROR] build method not found!")
    
    # 检查是否在 aboutToAppear 之前有提前关闭
    if key_items['aboutToAppear']:
        print(f"\n检查行 {struct_start} 到 {key_items['aboutToAppear']} 之间是否有异常...")
        
        depth = 0
        for i in range(struct_start - 1, min(key_items['aboutToAppear'], len(lines))):
            line = lines[i]
            depth += line.count('{') - line.count('}')
            
            if depth == 0 and i < key_items['aboutToAppear'] - 1:
                print(f"  [WARNING] Line {i+1}: depth returns to 0 (struct may end prematurely)")
                print(f"    Content: {line.strip()[:100]}")

def main():
    analyze_struct_scope('entry/src/main/ets/pages/Index.ets')

if __name__ == '__main__':
    main()

