#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确修复 Index.ets 文件末尾的问题
"""

import os
import shutil
from datetime import datetime

def backup_file(filepath):
    """创建备份"""
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_path = f"{filepath}.backup_{timestamp}"
    shutil.copy2(filepath, backup_path)
    print(f"[备份] 已创建备份: {backup_path}")
    return backup_path

def fix_file_end(filepath):
    """修复文件末尾的问题"""
    print(f"[开始] 读取文件: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    print(f"[信息] 文件总行数: {total_lines}")
    
    changes = []
    
    # 修复第 12027 行：模板字符串语法错误
    if total_lines >= 12027:
        line_12027 = lines[12026]  # 索引是 12026
        if '愬姛' in line_12027 or 'toLocaleTimeString()}' in line_12027:
            # 替换整行
            lines[12026] = '        this.proxyTestResult = `[成功] ${result.message}\\n服务器：${this.proxyBaseUrl}\\n连接时间：${new Date().toLocaleTimeString()}`\n'
            changes.append('第12027行：修复模板字符串（乱码+缺少$）')
    
    # 修复第 12035 行：三元运算符缺少 ?
    if total_lines >= 12035:
        line_12035 = lines[12034]  # 索引是 12034
        if "result.success  '" in line_12035 or "result.success  \"" in line_12035:
            # 替换为正确的三元运算符
            lines[12034] = "        '代理连接测试结果: %{public}s', result.success ? '成功' : '失败')\n"
            changes.append('第12035行：修复三元运算符（添加缺失的?）')
    
    # 修复第 12038 行：模板字符串语法错误
    if total_lines >= 12038:
        line_12038 = lines[12037]  # 索引是 12037
        if '{error.message}' in line_12038 and '${error.message}' not in line_12038:
            # 修复缺少 $ 的模板字符串
            lines[12037] = '      this.proxyTestResult = `[失败] 测试失败：${(error as Error).message}`\n'
            changes.append('第12038行：修复模板字符串（添加缺失的$）')
    
    # 删除第 12047-12053 行的多余大括号（7个）
    if total_lines >= 12053:
        # 检查这些行是否都是单独的 }
        extra_braces_start = 12046  # 索引
        extra_braces_count = 0
        
        for i in range(extra_braces_start, min(extra_braces_start + 10, total_lines)):
            if lines[i].strip() == '}':
                extra_braces_count += 1
            else:
                break
        
        if extra_braces_count >= 7:
            # 保留第一个（关闭 struct Index），删除后面的7个
            # 第12046行: } 关闭 testProxyConnection() 方法
            # 第12047行: } 关闭 struct Index（保留）
            # 第12048-12054行: 多余的（删除）
            
            # 删除多余的大括号（保留前两个，删除后7个）
            del lines[12047:12054]  # 删除索引12047到12053（第12048到12054行）
            changes.append('第12048-12054行：删除7个多余的闭合大括号')
    
    # 写回文件
    if changes:
        print(f"[修复] 共进行了 {len(changes)} 项修复：")
        for i, change in enumerate(changes, 1):
            print(f"  {i}. {change}")
        
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[完成] 文件已更新")
        return True
    else:
        print("[跳过] 未发现需要修复的问题")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[错误] 文件不存在: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_file_end(filepath)
    
    if success:
        print("\n[成功] 文件末尾问题已修复！")
        print("\n建议：现在可以运行编译测试验证修复效果")
    else:
        print("\n[完成] 检查完成")

