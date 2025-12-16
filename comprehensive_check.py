#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
全面检查 Index.ets 文件的所有潜在问题
"""

import re
from collections import defaultdict

def check_all_issues(filepath):
    """全面检查所有问题"""
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    issues = {
        '编码问题': [],
        '字符串问题': [],
        '括号不平衡': [],
        '模板字面量问题': [],
        '对象简写语法问题': [],
        '类型定义问题': [],
        '其他语法问题': []
    }
    
    # 统计信息
    stats = {
        '总行数': len(lines),
        '非空行': 0,
        '注释行': 0,
        '代码行': 0,
        '中文字符行': 0,
        '乱码字符行': 0
    }
    
    # 乱码模式
    garbled_patterns = [
        r'[涓临鏂伴閭欢妫€鏌檪鍙戦€佽缃€氱煡鎮ㄦ湁灏佹潵鑷墍鏈夐偖绠?]',
        r'[鈥锔馃敡鈼鈻]',
        r'[\u4e00-\u9fff]{3,}(?![a-zA-Z])'  # 连续3个以上汉字但后面不跟英文（可能是乱码）
    ]
    
    # 字符串和模板字面量检查
    in_string = False
    in_template = False
    string_quote = None
    bracket_stack = []
    
    for line_num, line in enumerate(lines, 1):
        line = line.rstrip('\n')
        
        # 统计
        if line.strip():
            stats['非空行'] += 1
            if line.strip().startswith('//') or line.strip().startswith('/*'):
                stats['注释行'] += 1
            else:
                stats['代码行'] += 1
        
        # 检查中文和乱码
        has_chinese = bool(re.search(r'[\u4e00-\u9fff]', line))
        if has_chinese:
            stats['中文字符行'] += 1
            
            # 检查是否是乱码
            for pattern in garbled_patterns:
                if re.search(pattern, line):
                    stats['乱码字符行'] += 1
                    issues['编码问题'].append(f"Line {line_num}: 检测到乱码字符")
                    break
        
        # 检查未闭合的字符串
        i = 0
        while i < len(line):
            char = line[i]
            
            # 跳过转义字符
            if char == '\\' and i + 1 < len(line):
                i += 2
                continue
            
            # 检查字符串
            if not in_template and char in ['"', "'", '`']:
                if not in_string:
                    in_string = True
                    string_quote = char
                    if char == '`':
                        in_template = True
                elif char == string_quote:
                    in_string = False
                    string_quote = None
                    if char == '`':
                        in_template = False
            
            # 检查括号
            if not in_string and not in_template:
                if char in '({[':
                    bracket_stack.append((char, line_num))
                elif char in ')}]':
                    expected = {')': '(', '}': '{', ']': '['}
                    if bracket_stack:
                        last_bracket, last_line = bracket_stack[-1]
                        if expected.get(char) == last_bracket:
                            bracket_stack.pop()
                        else:
                            issues['括号不平衡'].append(
                                f"Line {line_num}: 括号不匹配，期望闭合 {last_bracket} (来自 line {last_line})"
                            )
                    else:
                        issues['括号不平衡'].append(
                            f"Line {line_num}: 多余的闭合括号 '{char}'"
                        )
            
            i += 1
        
        # 检查对象简写语法问题
        # 查找可能的对象字面量
        if not line.strip().startswith('//'):
            # 检查是否有 { identifier, identifier } 这样的模式
            obj_shorthand_pattern = r'\{\s*\w+\s*,\s*\w+\s*[,}]'
            if re.search(obj_shorthand_pattern, line):
                # 提取标识符
                matches = re.findall(r'\{\s*(\w+)\s*,', line)
                if matches:
                    issues['对象简写语法问题'].append(
                        f"Line {line_num}: 可能的对象简写语法: {matches}"
                    )
        
        # 检查特定的问题模式
        
        # 1. 未闭合的字符串（单行）
        if line.count("'") % 2 != 0 and '//' not in line:
            issues['字符串问题'].append(f"Line {line_num}: 单引号数量不平衡")
        
        if line.count('"') % 2 != 0 and '//' not in line:
            issues['字符串问题'].append(f"Line {line_num}: 双引号数量不平衡")
        
        # 2. 未闭合的模板字面量（单行）
        if line.count('`') % 2 != 0 and '//' not in line:
            issues['模板字面量问题'].append(f"Line {line_num}: 反引号数量不平衡")
        
        # 3. 类型定义问题
        if 'NotificationOptions' in line and '=' in line:
            # 检查赋值的对象
            if '{' in line and '}' not in line:
                issues['类型定义问题'].append(f"Line {line_num}: NotificationOptions 对象可能跨多行")
    
    # 检查未闭合的括号
    if bracket_stack:
        for bracket, line_num in bracket_stack:
            issues['括号不平衡'].append(f"未闭合的 '{bracket}' 来自 line {line_num}")
    
    return issues, stats

def print_report(issues, stats):
    """打印报告"""
    print("=" * 80)
    print("INDEX.ETS 全面问题检查报告")
    print("=" * 80)
    print()
    
    print("[统计] 文件统计:")
    print("-" * 80)
    for key, value in stats.items():
        print(f"  {key:20s}: {value:>10,}")
    print()
    
    print("[分类] 问题分类:")
    print("-" * 80)
    total_issues = 0
    for category, problems in issues.items():
        count = len(problems)
        total_issues += count
        print(f"  {category:20s}: {count:>6} 个问题")
    print(f"  {'总计':20s}: {total_issues:>6} 个问题")
    print()
    
    print("[详细] 详细问题列表:")
    print("=" * 80)
    
    for category, problems in issues.items():
        if problems:
            print(f"\n【{category}】 ({len(problems)} 个)")
            print("-" * 80)
            
            # 只显示前20个问题，避免输出过长
            for i, problem in enumerate(problems[:20], 1):
                print(f"  {i}. {problem}")
            
            if len(problems) > 20:
                print(f"  ... 还有 {len(problems) - 20} 个类似问题")
    
    print()
    print("=" * 80)
    print("关键发现:")
    print("-" * 80)
    
    # 计算乱码比例
    if stats['中文字符行'] > 0:
        garbled_ratio = (stats['乱码字符行'] / stats['中文字符行']) * 100
        print(f"  * 乱码比例: {garbled_ratio:.1f}% ({stats['乱码字符行']}/{stats['中文字符行']} 行)")
    
    # 分析最严重的问题
    if issues['编码问题']:
        print(f"  * [警告] 编码问题严重: {len(issues['编码问题'])} 行受影响")
    
    if issues['括号不平衡']:
        print(f"  * [警告] 括号不平衡: {len(issues['括号不平衡'])} 处")
    
    if issues['字符串问题']:
        print(f"  * [警告] 字符串未闭合: {len(issues['字符串问题'])} 处")
    
    print()
    print("=" * 80)
    
    # 估计错误数量
    estimated_errors = 0
    
    # 每个乱码行可能导致 5-10 个错误
    estimated_errors += stats['乱码字符行'] * 7
    
    # 每个括号不平衡可能导致 50-100 个错误
    estimated_errors += len(issues['括号不平衡']) * 75
    
    # 每个字符串问题可能导致 100-500 个错误
    estimated_errors += len(issues['字符串问题']) * 300
    
    print(f"预估编译错误数: {estimated_errors:,} 个")
    print(f"实际报告错误数: 8,237 个")
    print(f"差异: {abs(8237 - estimated_errors):,} 个")
    print()

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    issues, stats = check_all_issues(filepath)
    print_report(issues, stats)

