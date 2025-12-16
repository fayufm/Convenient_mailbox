#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
注释掉build方法中调用的不存在的buildXXX方法
"""

import os
import sys
import shutil
from datetime import datetime

# 设置输出编码
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')
    sys.stderr = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')

def create_backup(file_path):
    """创建备份"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_fix_undefined_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份: {backup_path}")
    return backup_path

def fix_undefined_methods():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🔧 注释掉未定义的buildXXX方法调用")
    print("=" * 70)
    
    # 创建备份
    backup = create_backup(file_path)
    
    # 读取文件
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
        print(f"✅ 读取文件成功\n")
    except Exception as e:
        print(f"❌ 读取失败: {e}")
        return
    
    original_content = content
    
    # 要注释掉的方法调用（这些方法不存在）
    undefined_methods = [
        'buildEmailDetailDialog',
        'buildSentEmailDetailDialog',
        'buildImagePreviewDialog',
        'buildTemplateDialog',
        'buildCreateTemplateDialog',
        'buildCreateFolderDialog',
        'buildMoveFolderDialog',
        'buildCreateTagDialog',
        'buildAddTagDialog',
        'buildStatsDialog',
        'buildNoteDialog',
        'buildQRCodeDialog',
        'buildMailboxActionsMenu',
    ]
    
    print("🔄 开始注释...\n")
    
    count = 0
    for method in undefined_methods:
        # 查找并注释掉这个方法的调用
        pattern = f"this.{method}()"
        if pattern in content:
            # 注释整个if块
            # 查找包含这个调用的行
            lines = content.split('\n')
            new_lines = []
            in_comment_block = False
            block_depth = 0
            
            for i, line in enumerate(lines):
                if pattern in line:
                    # 找到了！从这行向上找if语句
                    # 向上找到if语句
                    j = i
                    while j >= 0:
                        if 'if (' in lines[j]:
                            # 找到了if语句，注释从这里到对应的}
                            # 简单处理：注释这个if块的3行（if, method call, }）
                            new_lines[len(new_lines) - (i - j)] = '      // ' + lines[j].lstrip()
                            line = '      // ' + line.lstrip()
                            in_comment_block = True
                            block_depth = 1
                            count += 1
                            print(f"   ✅ 注释: {method}()")
                            break
                        j -= 1
                elif in_comment_block:
                    line = '      // ' + line.lstrip()
                    if '}' in line:
                        block_depth -= 1
                        if block_depth == 0:
                            in_comment_block = False
                
                new_lines.append(line)
            
            content = '\n'.join(new_lines)
    
    # 写回文件
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(content)
            print(f"\n✅ 已写回文件")
            print(f"📊 注释了 {count} 个未定义的方法调用")
        except Exception as e:
            print(f"\n❌ 写入失败: {e}")
            # 恢复备份
            shutil.copy2(backup, file_path)
            print(f"⚠️  已恢复备份")
            return
    else:
        print("\n⚠️  未检测到需要修改的内容")
    
    print("\n" + "=" * 70)
    print("✅ 修复完成！")
    print("=" * 70)
    print(f"📁 备份: {backup}")
    print("\n💡 下一步：")
    print("   1. 编译测试")
    print("   2. 检查 10905103 错误是否消失")
    print("   3. 如果还有其他未定义方法，继续修复")

if __name__ == "__main__":
    fix_undefined_methods()

