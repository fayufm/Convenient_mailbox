#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除/替换行 7701-7763 的大段乱码
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

def fix_garbled_section(filepath):
    """删除/替换行 7701-7763 的大段乱码"""
    print(f"[开始] 读取文件: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    total_lines = len(lines)
    print(f"[信息] 文件总行数: {total_lines}")
    
    # 检查目标行的内容
    if total_lines < 7763:
        print(f"[错误] 文件行数不足 7763 行，无法继续")
        return False
    
    # 找到问题区域的开始和结束
    # 第 7701 行：•Indicator lines show the other mode's message count`'`    } else {
    # 第 7702 行开始是大段乱码
    # 第 7763 行：   •婃椂勭悊閲嶈``    }
    # 第 7764 行：  }
    
    start_line_idx = 7700  # 索引（第7701行）
    end_line_idx = 7762    # 索引（第7763行）
    
    # 检查是否包含乱码
    problem_detected = False
    for i in range(start_line_idx, min(end_line_idx + 1, total_lines)):
        line = lines[i]
        # 检查是否包含乱码字符
        if any(char in line for char in ['鏀', '変', '戜', '鐐', '鏍', '锛', '搴', '瑰', '熸', '朵', '佺', '勭', '殑', '呭', '婃', '忔', '氭', '犻', '櫎']):
            problem_detected = True
            break
    
    if not problem_detected:
        print("[跳过] 未在目标区域检测到乱码")
        return False
    
    print(f"[检测] 在行 {start_line_idx+1}-{end_line_idx+1} 检测到乱码")
    
    # 读取第7701行，检查其结构
    line_7701 = lines[7700]
    print(f"[调试] 正在检查第7701行...")
    
    # 方案：删除第7702-7763行的乱码内容，替换为英文注释
    replacement_text = '''      // [This section contained corrupted Chinese text and has been replaced]
      // This was a Chinese language version of inbox usage guide.
      // The English version above provides the same functionality.
      return `Inbox Usage Guide (Chinese version temporarily unavailable - please refer to English version above)`
    }
  }
'''
    
    # 统计删除的行数
    lines_to_delete = end_line_idx - start_line_idx  # 7762 - 7700 = 62 行
    
    # 执行替换
    # 保留第7701行（因为它包含 } else { 的开始），从7702行开始替换
    # 实际上，让我重新分析结构
    
    # 检查第7701行是否以 `'`    } else { 结尾
    if "`'`    } else {" in line_7701 or "} else {" in line_7701:
        # 这是一个问题：第7701行有额外的 `'` 
        # 正确的应该是 `` } else {
        # 修复第7701行，然后替换7702-7763
        
        # 修复第7701行
        lines[7700] = "•Indicator lines show the other mode's message count`\n    } else {\n"
        
        # 替换7702-7763（索引7701-7762）为新内容
        new_lines = [
            "      // [This section contained corrupted Chinese text and has been replaced]\n",
            "      // This was a Chinese language version of inbox usage guide.\n",
            "      // The English version above provides the same functionality.\n",
            "      return `收件与发件使用方法（简体中文版本暂不可用 - 请参考上方英文版本）`\n",
            "    }\n",
            "  }\n",
            "  \n"
        ]
        
        # 删除索引7701-7762的内容（第7702-7763行），插入新内容
        del lines[7701:7763]
        
        # 在索引7701处插入新内容
        for i, new_line in enumerate(new_lines):
            lines.insert(7701 + i, new_line)
        
        deleted_count = (7763 - 7702 + 1)  # 62行
        added_count = len(new_lines)  # 7行
        net_change = added_count - deleted_count  # -55行
        
        print(f"[修复] 删除了 {deleted_count} 行乱码，添加了 {added_count} 行注释")
        print(f"[修复] 净减少 {-net_change} 行")
        
        # 写回文件
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.writelines(lines)
        
        print(f"[完成] 文件已更新")
        print(f"[完成] 新的文件行数: {len(lines)}")
        return True
    else:
        print("[错误] 第7701行结构不符合预期，请手动检查")
        return False

if __name__ == '__main__':
    filepath = 'entry/src/main/ets/pages/Index.ets'
    
    if not os.path.exists(filepath):
        print(f"[错误] 文件不存在: {filepath}")
        exit(1)
    
    # 创建备份
    backup_file(filepath)
    
    # 执行修复
    success = fix_garbled_section(filepath)
    
    if success:
        print("\n[成功] 乱码区域已修复！")
        print("\n预计减少约 160+ 个 Invalid character 错误")
    else:
        print("\n[失败] 修复未成功，请检查日志")

