#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
精确修复 Index.ets 的编码问题 - 使用行号定位
"""

import os
import sys
import shutil
from datetime import datetime

# 设置输出编码为UTF-8
if sys.platform == 'win32':
    import codecs
    sys.stdout = codecs.getwriter('utf-8')(sys.stdout.buffer, 'ignore')
    sys.stderr = codecs.getwriter('utf-8')(sys.stderr.buffer, 'ignore')

def create_backup(file_path):
    """创建备份"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_precise_fix_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 备份: {backup_path}")
    return backup_path

def fix_encoding():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    print("=" * 70)
    print("🔧 开始精确修复编码问题（基于行号）")
    print("=" * 70)
    
    # 创建备份
    backup = create_backup(file_path)
    
    # 读取文件
    try:
        with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
            lines = f.readlines()
        print(f"✅ 读取文件成功，共 {len(lines)} 行")
    except Exception as e:
        print(f"❌ 读取失败: {e}")
        return
    
    # 定义需要替换的内容（基于行号）
    fixes = [
        {
            'name': 'getCreateNoticeContent 中文部分',
            'start_line': 2246,  # } else { 这一行 (line 2247 in 1-indexed)
            'end_line': 2267,    # 下一个 } 这一行 (line 2268 in 1-indexed)
            'new_content': """    } else {
      return `重要注意事项`
1. 域名支持说明
   •17个域名支持应用内收信
     - 1SecMail: 7个域名
     - Guerrilla Mail: 10个域名
   •其他74个域名仅生成地址
   •生成时会显示明确提示（可收信/仅地址）

2. 邮箱有效期
   •建议选择7天或1个月
   •永久邮箱不保证长期可用
   •请及时检查过期邮箱

3. 安全提示
   •临时邮箱不适合重要账号
   •请勿用于银行、支付等服务
   •邮件内容可能被他人查看

4. 隐私保护
   •不同网站使用不同邮箱
   •避免泄露真实邮箱地址
   •请及时清理过期邮箱

5. 邮件发送（安全建议）：
   •推荐：后端代理（最安全）
   •警告：内置服务API密钥可能被提取
   •有额度限制，请合理使用
   •请在设置中配置自定义的后端代理服务器

6. 数据备份
   •重要邮件请及时保存
   •应用数据存储在本地
   •卸载应用会丢失所有数据`
    }
"""
        },
        {
            'name': 'getDisclaimerContent 中文部分', 
            'start_line': 2319,  # } else { 这一行
            'end_line': 2355,    # 下一个 } 这一行
            'new_content': """    } else {
      return `版权与许可声明`
版权所有 © 2024-2025 谢硕星(Xie Shuoxing). 保留所有权利。

1. 软件所有权
   "便捷邮箱"软件及其所有相关内容（包括源代码、界面设计、文档等）
   的全部知识产权归谢硕星个人所有。

2. 开源许可 - 非商业用途
   •本软件遵循 AGPL v3.0 许可协议开源
   •您可以自由使用、学习、修改和分发源代码
   •衍生作品必须同样开源且免费
   •必须保留原始版权声明

3. 商业使用禁止
   •本软件及其衍生作品仅供免费、非商业使用
   •禁止用于商业目的（包括但不限于出售、付费服务、商业应用）
   •商业使用需获得版权所有者的单独书面授权

4. 商业收益分成条款
   若任何个人或组织未经授权将本软件、其技术或衍生作品用于商业用途：
   •所产生的全部商业收入的 80% 必须支付给谢硕星
   •版权所有者保留采取法律途径的权利
   •违反者须承担侵权赔偿责任

5. 免责声明
   •本应用提供临时邮箱服务，仅供符合法律用途使用
   •因使用本应用造成的任何损失，开发者不承担责任
   •用户应遵守相关法律法规
   •用户数据仅存储在设备本地，不会上传到任何服务器

6. 联系方式
   开发者：谢硕星(Xie Shuoxing)
   
   商业授权、技术合作：
   •邮箱：xieshuoxing@gmail.com
   •QQ邮箱：342602677@qq.com
   •个人网站：www.xieshuoxing.vip
   
   开源项目：
   •GitHub：https://github.com/fayufm/Convenient_mailbox
   •许可证：AGPL v3.0
   
   问题反馈和建议：
   •GitHub Issues：https://github.com/fayufm/Convenient_mailbox/issues

注意：使用本应用表示您已阅读并同意以上条款。`
    }
"""
        }
    ]
    
    # 应用修复（从后往前，避免行号偏移）
    total_fixes = 0
    for fix in reversed(fixes):
        try:
            start_idx = fix['start_line'] - 1  # 转换为0-indexed
            end_idx = fix['end_line']  # end_idx是要保留的最后一行的下一行
            
            print(f"\n🔧 修复: {fix['name']}")
            print(f"   行范围: {fix['start_line']} - {fix['end_line']}")
            
            # 替换行
            new_lines = fix['new_content'].splitlines(keepends=True)
            lines[start_idx:end_idx] = new_lines
            
            print(f"   ✅ 成功替换 {len(new_lines)} 行")
            total_fixes += 1
            
        except Exception as e:
            print(f"   ❌ 失败: {e}")
    
    # 写回文件
    if total_fixes > 0:
        try:
            with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
                f.writelines(lines)
            print(f"\n✅ 已写回文件，应用了 {total_fixes} 个修复")
            print(f"📊 总行数: {len(lines)}")
        except Exception as e:
            print(f"\n❌ 写入失败: {e}")
            # 恢复备份
            shutil.copy2(backup, file_path)
            print(f"⚠️  已恢复备份")
            return
    
    print("\n" + "=" * 70)
    print("✅ 编码修复完成！")
    print("=" * 70)
    print(f"📁 备份: {backup}")
    print("\n💡 下一步：")
    print("   1. 编译测试: hvigorw assembleHap")
    print("   2. 检查错误数量变化")

if __name__ == "__main__":
    fix_encoding()

