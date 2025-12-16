#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
自动修复 Index.ets 的编码问题和 ArkTS 语法错误
"""

import re
import os
import shutil
from datetime import datetime

def create_backup(file_path):
    """创建备份文件"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_encoding_fix_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 已创建备份: {backup_path}")
    return backup_path

def fix_garbled_text(content):
    """修复乱码的帮助文本"""
    
    # 定义正确的三语言帮助文本
    correct_text_cn = """   •避免泄露真实地址
   •适时清理过期邮箱
5. 安全性（重要建议）：
   •推荐：后端代理（最安全）
   •备选：客户端 API 密钥被限制，请合理使用
   •在设置中配置自定义邮箱的后端代理服务器
6. 数据备份：
   •重要邮件及时保存
   •应将数据存储在本地   •需要时应及时备份重要数据"""

    correct_text_en = """   •Avoid leaking real addresses
   •Clean up expired mailboxes regularly
5. Security (Important Recommendations):
   •Recommended: Backend proxy (most secure)
   •Alternative: Client-side API keys are restricted, use reasonably
   •Configure backend proxy server for custom mailboxes in Settings
6. Data Backup:
   •Save important emails promptly
   •Data should be stored locally   •Backup important data when needed"""

    correct_text_ru = """   •Избегайте раскрытия настоящих адресов
   •Своевременно очищайте устаревшие почтовые ящики
5. Безопасность (важные рекомендации):
   •Рекомендуется: серверный прокси (наиболее безопасно)
   •Альтернатива: клиентские ключи API ограничены, используйте разумно
   •Настройте прокси-сервер для пользовательских почтовых ящиков в Настройках
6. Резервное копирование данных:
   •Своевременно сохраняйте важные письма
   •Данные должны храниться локально   •При необходимости создавайте резервные копии важных данных"""

    # 查找并替换乱码部分（使用正则匹配周围的稳定文本）
    # 匹配模式：从某个乱码行开始到 "}" 之前
    
    # 中文版本修复
    pattern_cn = r'(•避免|•閬垮厤).*?(?=}\s*}\s*getDisclaimerContent)'
    if re.search(pattern_cn, content, re.DOTALL):
        content = re.sub(
            pattern_cn,
            correct_text_cn + '\n    }',
            content,
            flags=re.DOTALL
        )
        print("✅ 已修复中文版本乱码")
    
    return content

def fix_this_context_errors(content):
    """修复 arkts-no-standalone-this 错误"""
    
    # 模式1: 将箭头函数中的 this 改为传参
    # 例如: .map(() => this.xxx) -> .map((item) => item.xxx)
    
    # 模式2: 将独立函数改为类方法
    # 查找所有使用 this 但不在类方法中的函数
    
    fixes_count = 0
    
    # 这里需要具体分析代码结构，暂时返回原内容
    # 实际修复需要逐个位置手动处理
    
    return content, fixes_count

def fix_comma_operator(content):
    """修复 arkts-no-comma-outside-loops 错误"""
    
    # 查找并修复逗号运算符误用
    # 模式: (expr1, expr2, expr3) -> expr3
    
    fixes_count = 0
    
    # 示例修复
    # content = re.sub(
    #     r'\(([^,]+),\s*([^,]+),\s*([^)]+)\)',
    #     r'\3',  # 只保留最后一个表达式
    #     content
    # )
    
    return content, fixes_count

def fix_in_operator(content):
    """修复 arkts-no-in 错误"""
    
    # 将 'prop' in obj 替换为 obj.hasOwnProperty('prop')
    # 或 obj.prop !== undefined
    
    fixes_count = 0
    
    # pattern = r"'(\w+)'\s+in\s+(\w+)"
    # replacement = r"\2.hasOwnProperty('\1')"
    # content = re.sub(pattern, replacement, content)
    
    return content, fixes_count

def fix_deprecated_apis(content):
    """修复废弃的 API 调用"""
    
    fixes_count = 0
    
    # showToast 已废弃，但通常不需要修改（只是警告）
    # 如果需要修复，可以添加相应的参数
    
    return content, fixes_count

def main():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        return
    
    print("🔧 开始修复 Index.ets...")
    print("=" * 60)
    
    # 1. 创建备份
    backup_path = create_backup(file_path)
    
    # 2. 读取文件（尝试多种编码）
    content = None
    for encoding in ['utf-8', 'utf-8-sig', 'gbk', 'gb2312', 'gb18030']:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                content = f.read()
            print(f"✅ 成功使用 {encoding} 编码读取文件")
            break
        except UnicodeDecodeError:
            continue
    
    if content is None:
        print("❌ 无法读取文件，尝试了所有常见编码")
        return
    
    # 3. 应用修复
    print("\n📝 应用修复...")
    
    original_content = content
    
    # 修复1: 编码问题（乱码文本）
    content = fix_garbled_text(content)
    
    # 修复2: this 上下文错误
    # content, this_fixes = fix_this_context_errors(content)
    # print(f"   - 修复 this 上下文: {this_fixes} 处")
    
    # 修复3: 逗号运算符
    # content, comma_fixes = fix_comma_operator(content)
    # print(f"   - 修复逗号运算符: {comma_fixes} 处")
    
    # 修复4: in 运算符
    # content, in_fixes = fix_in_operator(content)
    # print(f"   - 修复 in 运算符: {in_fixes} 处")
    
    # 4. 写回文件（强制 UTF-8）
    try:
        with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)
        print(f"\n✅ 已写回文件: {file_path} (UTF-8 编码)")
    except Exception as e:
        print(f"❌ 写入文件失败: {e}")
        # 恢复备份
        shutil.copy2(backup_path, file_path)
        print(f"⚠️  已从备份恢复: {backup_path}")
        return
    
    # 5. 统计修改
    if content != original_content:
        print("\n📊 修复统计:")
        print(f"   - 文件大小: {len(original_content)} -> {len(content)} 字符")
        print(f"   - 变化: {len(content) - len(original_content):+d} 字符")
    else:
        print("\n⚠️  未检测到需要修复的内容")
    
    print("\n" + "=" * 60)
    print("✅ 修复完成！")
    print(f"📁 备份文件: {backup_path}")
    print("\n💡 下一步:")
    print("   1. 检查修复后的文件")
    print("   2. 运行编译: hvigorw assembleHap")
    print("   3. 如果有问题，可以从备份恢复")

if __name__ == "__main__":
    main()

