#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试：用最简化的build方法替换当前的build方法
目的：验证10905103错误是否是由build方法内部的语法错误引起的
"""

import os
import sys
import shutil
from datetime import datetime

# 设置输出编码
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'ignore')

def create_backup(file_path):
    """创建备份"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_test_build_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份: {backup_path}")
    return backup_path

def test_simplified_build():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🧪 测试：替换为简化的build方法")
    print("=" * 70)
    
    # 创建备份
    backup = create_backup(file_path)
    
    # 读取文件
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
        print(f"✅ 读取文件成功，共 {len(lines)} 行\n")
    except Exception as e:
        print(f"❌ 读取失败: {e}")
        return
    
    # 找到build()方法的开始和结束
    build_start = -1
    build_end = -1
    
    for i, line in enumerate(lines):
        if '  build()' in line and build_start == -1:
            build_start = i
            print(f"✅ 找到 build() 方法开始于第 {i+1} 行")
        
    if build_start == -1:
        print("❌ 未找到 build() 方法")
        return
    
    # 从build()开始计数括号
    brace_count = 0
    started = False
    
    for i in range(build_start, len(lines)):
        for char in lines[i]:
            if char == '{':
                started = True
                brace_count += 1
            elif char == '}':
                brace_count -= 1
                if started and brace_count == 0:
                    build_end = i
                    print(f"✅ 找到 build() 方法结束于第 {i+1} 行")
                    print(f"   build() 跨度: {build_end - build_start + 1} 行\n")
                    break
        
        if build_end != -1:
            break
    
    if build_end == -1:
        print("❌ 未找到 build() 方法的结束")
        return
    
    # 创建一个最简化的build方法
    simplified_build = """  build() {
    Column() {
      Text('测试：简化的build方法')
        .fontSize(20)
        .fontColor(Color.Red)
        .width('100%')
        .height('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height('100%')
  }
"""
    
    print("🔄 替换build()方法...")
    print(f"   原方法: 第{build_start+1}-{build_end+1}行 ({build_end-build_start+1}行)")
    print(f"   新方法: 11行（简化版本）\n")
    
    # 替换
    new_lines = lines[:build_start] + [simplified_build + '\n'] + lines[build_end+1:]
    
    # 写回文件
    try:
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(new_lines)
        print(f"✅ 已写回文件")
        print(f"📊 新文件行数: {len(new_lines)}")
    except Exception as e:
        print(f"❌ 写入失败: {e}")
        # 恢复备份
        shutil.copy2(backup, file_path)
        print(f"⚠️  已恢复备份")
        return
    
    print("\n" + "=" * 70)
    print("✅ 测试build方法已替换！")
    print("=" * 70)
    print(f"📁 备份: {backup}")
    print("\n💡 下一步：")
    print("   1. 编译项目")
    print("   2. 检查 10905103 错误是否消失")
    print("   3. 如果消失，说明原build方法有语法错误")
    print("   4. 如果仍在，说明问题不在build方法内部")
    print("   5. 之后恢复原build方法：")
    print(f"      copy {backup} entry/src/main/ets/pages/Index.ets")

if __name__ == "__main__":
    test_simplified_build()

