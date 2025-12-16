#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
重命名 @Builder 方法，避免与 build() 方法冲突
将 buildXxx 改为 renderXxx
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
    backup_path = f"{file_path}.backup_rename_builders_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份: {backup_path}")
    return backup_path

def rename_builder_methods():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🔧 重命名 @Builder 方法")
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
    
    # 定义重命名映射（从 buildXxx 到 renderXxx）
    rename_map = {
        'buildCustomDaysDialog': 'renderCustomDaysDialog',
        'buildStartupAnimation': 'renderStartupAnimation',
        'buildMenuButton': 'renderMenuButton',
        'buildHelpDialog': 'renderHelpDialog',
        'buildHelpSection': 'renderHelpSection',
        'buildFAB': 'renderFAB',
        'buildLoadingState': 'renderLoadingState',
        'buildNavigation': 'renderNavigation',
        'buildInboxNavButton': 'renderInboxNavButton',
        'buildNavButton': 'renderNavButton',
        'buildIndicatorLines': 'renderIndicatorLines',
        'buildEmptyState': 'renderEmptyState',
    }
    
    print("🔄 开始重命名...\n")
    
    for old_name, new_name in rename_map.items():
        count = 0
        
        # 替换 @Builder 方法定义
        pattern1 = f"@Builder {old_name}"
        if pattern1 in content:
            content = content.replace(pattern1, f"@Builder {new_name}")
            count += content.count(f"@Builder {new_name}") - original_content.count(f"@Builder {new_name}")
        
        # 替换方法调用 (this.buildXxx)
        pattern2 = f"this.{old_name}"
        if pattern2 in content:
            before_count = content.count(pattern2)
            content = content.replace(pattern2, f"this.{new_name}")
            count += before_count
        
        if count > 0:
            print(f"   ✅ {old_name:30} -> {new_name:30} ({count}处)")
    
    # 写回文件
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(content)
            print(f"\n✅ 已写回文件")
            print(f"📊 总替换次数: {sum(1 for k, v in rename_map.items() if k in original_content)}")
        except Exception as e:
            print(f"\n❌ 写入失败: {e}")
            # 恢复备份
            shutil.copy2(backup, file_path)
            print(f"⚠️  已恢复备份")
            return
    else:
        print("\n⚠️  未检测到需要重命名的内容")
    
    print("\n" + "=" * 70)
    print("✅ 重命名完成！")
    print("=" * 70)
    print(f"📁 备份: {backup}")
    print("\n💡 下一步：")
    print("   1. 编译测试: 检查 10905103 错误是否消失")
    print("   2. 如果错误消失，继续修复其他错误")
    print("   3. 如果错误仍在，尝试其他方案")

if __name__ == "__main__":
    rename_builder_methods()

