#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复Index.ets中的语法错误
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
    backup_path = f"{file_path}.backup_syntax_fix_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份: {backup_path}")
    return backup_path

def fix_syntax_errors():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🔧 修复语法错误")
    print("=" * 70)
    
    # 创建备份
    backup = create_backup(file_path)
    
    # 读取文件
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            content = f.read()
        print(f"✅ 读取文件成功")
    except Exception as e:
        print(f"❌ 读取失败: {e}")
        return
    
    original_content = content
    fixes_count = 0
    
    # 修复1: build()方法中的语法错误（第983行）
    # 查找并替换错误的debug行
    print("\n🔧 修复1: build()方法中的语法错误...")
    
    # 查找特征字符串
    bad_pattern = "DEBUG: build(`)"
    if bad_pattern in content:
        # 找到这一行并替换整个日志语句
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'DEBUG: build(`)' in line and 'hilog.info' in lines[i-1] if i > 0 else False:
                # 替换这两行
                lines[i-1] = "    // 🔒 DEBUG: 记录build()执行状态"
                lines[i-1] += "\n    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,"
                lines[i] = "      `🔒 DEBUG: build()执行 - isLoading=${this.isLoading}, currentPage=${this.currentPage}, errorMessage=${this.errorMessage || 'none'}`)"
                print(f"   ✅ 已修复第{i+1}行的语法错误")
                fixes_count += 1
                break
        content = '\n'.join(lines)
    
    # 修复2: 其他乱码的debug行
    print("\n🔧 修复2: 其他乱码的debug日志...")
    
    # 替换常见的乱码debug字符串
    replacements = [
        ("鏄剧鐘", "显示加载状态"),
        ("鏄剧荤晫闈", "显示主界面"),
        ("椤堕儴瀵艰埅鏍", "顶部导航栏"),
        ("涓诲唴瀹瑰尯鍩", "主内容区域"),
        ("鏍规嵁褰撳墠椤甸潰鏄剧ず涓嶅悓鍐呭", "根据当前页面显示不同内容"),
    ]
    
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            print(f"   ✅ 替换: {old} -> {new}")
            fixes_count += 1
    
    # 修复3: 修复俄语部分的编码问题（如果还有的话）
    print("\n🔧 修复3: 检查俄语文本...")
    # 这部分需要具体定位，暂时跳过
    
    # 写回文件
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(content)
            print(f"\n✅ 已写回文件，应用了 {fixes_count} 个修复")
        except Exception as e:
            print(f"\n❌ 写入失败: {e}")
            # 恢复备份
            shutil.copy2(backup, file_path)
            print(f"⚠️  已恢复备份")
            return
    else:
        print("\n⚠️  未检测到需要修复的内容")
    
    print("\n" + "=" * 70)
    print("✅ 语法错误修复完成！")
    print("=" * 70)
    print(f"📁 备份: {backup}")

if __name__ == "__main__":
    fix_syntax_errors()

