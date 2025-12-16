#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
综合错误分析工具 - 分析7624个编译错误
结合修复历史，识别根本原因
"""

import re
from collections import defaultdict, Counter
from typing import Dict, List, Tuple

def parse_errors(error_text: str) -> List[Dict[str, str]]:
    """解析错误信息"""
    errors = []
    lines = error_text.strip().split('\n')
    
    current_error = {}
    for line in lines:
        if line.startswith('Error Message:'):
            if current_error:
                errors.append(current_error)
            current_error = {'message': line.replace('Error Message:', '').strip()}
        elif line.startswith('At File:'):
            match = re.search(r'At File: (.+?):(\d+):(\d+)', line)
            if match:
                current_error['file'] = match.group(1)
                current_error['line'] = int(match.group(2))
                current_error['col'] = int(match.group(3))
    
    if current_error:
        errors.append(current_error)
    
    return errors

def categorize_errors(errors: List[Dict[str, str]]) -> Dict[str, List[Dict[str, str]]]:
    """分类错误"""
    categories = defaultdict(list)
    
    for error in errors:
        msg = error.get('message', '')
        
        # ArkTS 严格模式错误
        if 'arkts-no-classes-as-obj' in msg:
            categories['ArkTS: Classes as Objects'].append(error)
        elif 'arkts-no-any-unknown' in msg:
            categories['ArkTS: Any/Unknown Types'].append(error)
        elif 'arkts-no-implicit-return-types' in msg:
            categories['ArkTS: Implicit Return Types'].append(error)
        elif 'arkts-no-untyped-obj-literals' in msg:
            categories['ArkTS: Untyped Object Literals'].append(error)
        elif 'arkts-no-standalone-this' in msg:
            categories['ArkTS: Standalone This'].append(error)
        elif 'arkts-no-polymorphic-unops' in msg:
            categories['ArkTS: Polymorphic Unary Operators'].append(error)
        elif 'arkts-no-comma-outside-loops' in msg:
            categories['ArkTS: Comma Operator'].append(error)
        elif 'arkts-no-in' in msg:
            categories['ArkTS: In Operator'].append(error)
        elif 'arkts-no-with' in msg:
            categories['ArkTS: With Statement'].append(error)
        elif 'arkts-no-delete' in msg:
            categories['ArkTS: Delete Operator'].append(error)
        elif 'arkts-no-destruct-decls' in msg:
            categories['ArkTS: Destructuring Declarations'].append(error)
        elif 'arkts-no-props-by-index' in msg:
            categories['ArkTS: Indexed Access'].append(error)
        elif 'arkts-no-inferred-generic-params' in msg:
            categories['ArkTS: Inferred Generic Params'].append(error)
        
        # 废弃 API
        elif 'has been deprecated' in msg:
            categories['Deprecated APIs'].append(error)
        
        # 属性/方法不存在
        elif "does not exist on type 'Index'" in msg:
            categories['Property/Method Missing on Index'].append(error)
        elif 'does not exist on type' in msg:
            categories['Property/Method Missing (Other)'].append(error)
        
        # 无法找到名称
        elif 'Cannot find name' in msg:
            # 进一步细分
            if re.search(r"Cannot find name '[^']{20,}", msg):
                categories['Cannot Find Name: Garbled'].append(error)
            elif "Cannot find name '$'" in msg:
                categories['Cannot Find Name: $ (Template Literal Issue)'].append(error)
            else:
                categories['Cannot Find Name: Normal'].append(error)
        
        # UI 组件错误
        elif 'UI component' in msg and 'cannot be used in this place' in msg:
            categories['UI Component Placement'].append(error)
        
        # 对象可能未定义
        elif "Object is possibly 'undefined'" in msg:
            categories['Object Possibly Undefined'].append(error)
        
        # 类型错误
        elif 'is not assignable to type' in msg:
            categories['Type Mismatch'].append(error)
        elif 'only refers to a type, but is being used as a value' in msg:
            categories['Type Used as Value'].append(error)
        
        # 语法错误
        elif "';' expected" in msg or "',' expected" in msg or "')' expected" in msg:
            categories['Syntax: Expected Token'].append(error)
        elif 'Unexpected keyword or identifier' in msg:
            categories['Syntax: Unexpected Token'].append(error)
        elif 'Identifier expected' in msg:
            categories['Syntax: Identifier Expected'].append(error)
        elif 'Declaration or statement expected' in msg:
            categories['Syntax: Declaration/Statement Expected'].append(error)
        elif 'Expression expected' in msg:
            categories['Syntax: Expression Expected'].append(error)
        
        # 字符串/模板字面量问题
        elif 'Unterminated string' in msg or 'Unterminated template' in msg:
            categories['Unterminated String/Template'].append(error)
        
        # ES6 对象简写语法
        elif 'No value exists in scope for the shorthand property' in msg:
            categories['ES6 Shorthand Property'].append(error)
        
        # 重复声明
        elif 'Duplicate identifier' in msg:
            categories['Duplicate Identifier'].append(error)
        
        # 变量声明前使用
        elif 'used before its declaration' in msg:
            categories['Variable Used Before Declaration'].append(error)
        
        # 函数签名错误
        elif 'Expected' in msg and 'arguments, but got' in msg:
            categories['Function Argument Mismatch'].append(error)
        elif 'Function implementation is missing' in msg:
            categories['Function Implementation Missing'].append(error)
        
        # 运算符错误
        elif 'cannot be applied to types' in msg or 'Operator' in msg:
            categories['Operator Type Error'].append(error)
        
        # 比较错误
        elif 'This comparison appears to be unintentional' in msg:
            categories['Comparison Warning'].append(error)
        
        # 其他
        else:
            categories['Other'].append(error)
    
    return categories

def analyze_line_distribution(errors: List[Dict[str, str]]) -> Dict[str, int]:
    """分析错误行分布"""
    line_ranges = {
        '1-1000': 0,
        '1001-2000': 0,
        '2001-3000': 0,
        '3001-4000': 0,
        '4001-5000': 0,
        '5001-6000': 0,
        '6001-7000': 0,
        '7001-8000': 0,
        '8001-9000': 0,
        '9001-10000': 0,
        '10001-11000': 0,
        '11001-12000': 0,
        '12001+': 0
    }
    
    for error in errors:
        line = error.get('line', 0)
        if line <= 1000:
            line_ranges['1-1000'] += 1
        elif line <= 2000:
            line_ranges['1001-2000'] += 1
        elif line <= 3000:
            line_ranges['2001-3000'] += 1
        elif line <= 4000:
            line_ranges['3001-4000'] += 1
        elif line <= 5000:
            line_ranges['4001-5000'] += 1
        elif line <= 6000:
            line_ranges['5001-6000'] += 1
        elif line <= 7000:
            line_ranges['6001-7000'] += 1
        elif line <= 8000:
            line_ranges['7001-8000'] += 1
        elif line <= 9000:
            line_ranges['8001-9000'] += 1
        elif line <= 10000:
            line_ranges['9001-10000'] += 1
        elif line <= 11000:
            line_ranges['10001-11000'] += 1
        elif line <= 12000:
            line_ranges['11001-12000'] += 1
        else:
            line_ranges['12001+'] += 1
    
    return line_ranges

def identify_hotspots(errors: List[Dict[str, str]], window_size: 100) -> List[Tuple[int, int, int]]:
    """识别错误热点区域"""
    line_counts = Counter()
    for error in errors:
        line = error.get('line', 0)
        if line > 0:
            # 将行号归到100行窗口
            window_start = (line // window_size) * window_size
            line_counts[window_start] += 1
    
    # 返回前10个错误最多的区域
    return line_counts.most_common(10)

def compare_with_history(categories: Dict[str, List[Dict[str, str]]]) -> Dict[str, str]:
    """与修复历史对比分析"""
    insights = {}
    
    # 检查之前修复的问题是否仍然存在
    if categories.get('Unterminated String/Template'):
        insights['String/Template Issues'] = f"仍有 {len(categories['Unterminated String/Template'])} 个未终止的字符串/模板字面量错误。之前的修复可能不完整或引入了新问题。"
    
    if categories.get('Cannot Find Name: Garbled'):
        insights['Garbled Characters'] = f"仍有 {len(categories['Cannot Find Name: Garbled'])} 个乱码相关的 'Cannot find name' 错误。双编码问题可能未完全解决。"
    
    if categories.get('Property/Method Missing on Index'):
        insights['Missing Properties'] = f"有 {len(categories['Property/Method Missing on Index'])} 个属性/方法缺失错误。这表明 @State 属性声明或方法定义仍然缺失。"
    
    if categories.get('UI Component Placement'):
        insights['UI Component Issues'] = f"有 {len(categories['UI Component Placement'])} 个 UI 组件放置错误。这通常是由于未正确关闭的字符串导致编译器误解代码结构。"
    
    if categories.get('ArkTS: Standalone This'):
        insights['ArkTS This Issues'] = f"有 {len(categories['ArkTS: Standalone This'])} 个 'this' 使用错误。这是 ArkTS 严格模式的限制，需要重构代码。"
    
    if categories.get('ES6 Shorthand Property'):
        insights['ES6 Shorthand'] = f"有 {len(categories['ES6 Shorthand Property'])} 个 ES6 对象简写属性错误。这表明对象字面量语法仍有问题。"
    
    return insights

def generate_report(categories: Dict[str, List[Dict[str, str]]], 
                   line_dist: Dict[str, int],
                   hotspots: List[Tuple[int, int, int]],
                   insights: Dict[str, str],
                   total_errors: int):
    """生成分析报告"""
    print("=" * 80)
    print(" 7624 编译错误综合分析报告 - 结合修复历史")
    print("=" * 80)
    print()
    
    print(f"[总计] 共 {total_errors} 个错误")
    print()
    
    # 按类别统计
    print("[分类统计] 错误类型分布")
    print("-" * 80)
    sorted_categories = sorted(categories.items(), key=lambda x: len(x[1]), reverse=True)
    
    for category, errors in sorted_categories:
        count = len(errors)
        percentage = (count / total_errors) * 100
        print(f"  {category:45} {count:5} ({percentage:5.1f}%)")
    print()
    
    # 行分布
    print("[行分布] 错误在文件中的分布")
    print("-" * 80)
    for range_name, count in sorted(line_dist.items(), key=lambda x: x[0]):
        if count > 0:
            bar = '#' * (count // 20)
            print(f"  行 {range_name:12} {count:5} {bar}")
    print()
    
    # 错误热点
    print("[错误热点] 错误密集区域 (Top 10)")
    print("-" * 80)
    for i, (window_start, count) in enumerate(hotspots, 1):
        window_end = window_start + 99
        print(f"  {i:2}. 行 {window_start:5}-{window_end:5}: {count:4} 个错误")
    print()
    
    # 与修复历史对比
    print("[修复历史对比] 关键发现")
    print("-" * 80)
    for issue_type, insight in insights.items():
        print(f"  [{issue_type}]")
        print(f"    {insight}")
        print()
    
    # 详细分类示例
    print("[详细示例] 各类别代表性错误")
    print("-" * 80)
    for category, errors in sorted_categories[:10]:  # 只显示前10类
        if errors:
            print(f"\n  [{category}] (共 {len(errors)} 个)")
            for error in errors[:3]:  # 每类显示前3个
                line = error.get('line', '?')
                col = error.get('col', '?')
                msg = error.get('message', '')[:100]
                print(f"    行 {line}:{col} - {msg}...")
    print()
    
    print("=" * 80)
    print(" 报告结束")
    print("=" * 80)

def main():
    # 读取错误信息（这里需要实际的错误文本）
    # 由于错误信息在对话中，我们需要从文件读取或直接粘贴
    
    print("分析脚本已准备就绪。")
    print("请提供完整的错误信息文本进行分析。")
    print()
    print("使用方法：")
    print("1. 将错误信息保存到 errors_7624.txt")
    print("2. 运行脚本进行分析")

if __name__ == '__main__':
    main()

