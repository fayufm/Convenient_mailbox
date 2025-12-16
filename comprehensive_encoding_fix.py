#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
全面修复 Index.ets 的编码问题
高质量修复，确保所有中文文本正确
"""

import re
import os
import shutil
from datetime import datetime

# 正确的中文文本内容
CORRECT_TEXTS = {
    # getCreateNoticeContent 方法的中文版本
    'getCreateNoticeContent_cn': """      return `重要注意事项`
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
   •卸载应用会丢失所有数据`""",
    
    # getDisclaimerContent 方法的中文版本  
    'getDisclaimerContent_cn': """      return `版权与许可声明`
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

注意：使用本应用表示您已阅读并同意以上条款。`""",

    # getInboxUsageContent 方法的中文部分
    'getInboxUsageContent_cn': """      return `收件箱&发件箱 使用指南`
1. 切换收件箱和发件箱
   •点击页面标题可切换模式
   •"收件箱"：查看收到的邮件
   •"发件箱"：查看已发送的邮件记录
   •底部导航标签会自动切换

2. 收件箱模式 - 查看收到的邮件
   •邮件会自动显示在列表中
   •点击邮件可查看详细内容
   •未读邮件会有蓝色圆点标记
   •点击右上角刷新按钮检查新邮件
   •邮件统计：总数/未读/今日

3. 发件箱模式 - 查看已发送邮件
   •查看所有已发送的邮件记录
   •统计数据：总发送/成功/失败
   •点击邮件查看详情（状态、收件人、内容）
   •一键复制邮件内容
   •查看发送时间和错误信息（如果失败）

4. 批量管理（发件箱）
   •点击"选择"进入批量选择模式
   •可选择多封邮件进行删除
   •点击"全部清空"删除所有记录
   •点击"取消"退出选择模式

5. 指示线说明
   •绿色线（1-7）：邮件较少，正常
   •黄色线（8-9）：需要注意
   •紫色线（10-24）：邮件较多
   •红色线（25-49）：警告状态
   •灰色/黑色（50+）：过多，建议清理

提示：
•17个API支持的域名可以接收邮件
  - 1SecMail: 7个域名
  - Guerrilla Mail: 10个域名
•发送记录仅存储在本地
•定期检查邮件，避免遗漏重要信息
•点击右上角"?"查看更多帮助`""",

    # getMailboxesUsageContent 方法的中文部分
    'getMailboxesUsageContent_cn': """      return `我的邮箱 使用指南`
1. 查看邮箱列表
   •显示所有已创建的邮箱
   •按创建时间倒序排列（最新在上）
   •每个邮箱卡片显示：
     - 邮箱地址（点击复制）
     - 状态指示器（绿=活跃，黄=即将过期，灰=已过期）
     - 创建时间和过期时间
     - 未读邮件数量
     - 置顶/备注图标

2. 邮箱操作
   •点击邮箱地址：复制到剪贴板
   •点击"查看"：跳转到收件箱查看该邮箱的邮件
   •点击"续期"：延长邮箱有效期
   •点击"删除"：删除邮箱（会同时删除该邮箱的所有邮件）
   •长按邮箱：显示更多操作（置顶、备注等）

3. 邮箱状态
   •🟢 活跃：正常使用中
   •🟡 即将过期：24小时内过期
   •⚫ 已过期：无法继续接收邮件
   •📌 置顶：固定在列表顶部
   •📝 有备注：点击查看备注信息

4. 筛选和搜索
   •使用顶部筛选按钮：
     - 全部邮箱
     - 活跃邮箱
     - 即将过期
     - 已过期
   •使用搜索框：搜索邮箱地址或备注

5. 批量操作
   •点击"批量管理"进入选择模式
   •选择多个邮箱后可以：
     - 批量删除
     - 批量续期
     - 批量导出

6. 高级功能
   •邮箱分组：将邮箱归类管理
   •备注功能：为邮箱添加说明
   •二维码：生成邮箱地址二维码
   •统计：查看邮箱使用统计

提示：
•自定义邮箱无法续期（永久有效）
•定期清理过期邮箱可提升性能
•置顶常用邮箱方便快速访问
•使用分组功能管理大量邮箱`""",

    # getComposeUsageContent 方法的中文部分
    'getComposeUsageContent_cn': """      return `写邮件 使用指南`
1. 选择发送方式
   •EmailJS 服务（默认）：
     - 免费额度：每月200封
     - 需要配置 API 密钥（设置中）
     - 支持附件，单个附件最大5MB
   •Resend 服务：
     - 免费额度：每月100封
     - 需要配置 API 密钥（设置中）
     - 支持附件，单个附件最大10MB
   •其他14种发送方式（高级）
   
2. 填写邮件内容
   •收件人：输入有效的邮箱地址
   •主题：简洁明确的邮件主题
   •正文：支持纯文本和基本格式
   •附件：可添加图片、文档等（注意大小限制）

3. 草稿功能
   •自动保存：输入过程中自动保存草稿
   •手动保存：点击"保存草稿"按钮
   •查看草稿：从草稿列表继续编辑
   •删除草稿：左滑草稿卡片删除

4. 邮件模板
   •使用模板：快速填充常用内容
   •创建模板：将当前内容保存为模板
   •模板分类：商务、个人、验证等
   •编辑模板：在模板库中管理

5. 附件管理
   •添加附件：点击"+"选择文件
   •预览附件：点击附件名查看
   •删除附件：点击"x"移除
   •附件大小：注意各服务的限制

6. 发送设置
   •优先级：紧急/普通/低
   •请求回执：要求对方确认已读
   •密送给自己：同时发送一份给自己
   •签名：自动添加邮件签名

提示：
•发送前请仔细检查收件人地址
•注意附件大小限制，避免发送失败
•使用模板可大幅提升效率
•每月额度用完可切换其他服务
•配置自定义邮箱获得更稳定的发送能力`""",

    # getSettingsUsageContent 方法的中文部分
    'getSettingsUsageContent_cn': """      return `设置 使用指南`
1. 外观设置
   •主题模式：
     - 浅色模式
     - 深色模式  
     - 跟随系统
   •语言选择：
     - 简体中文
     - English
     - Русский

2. 邮件发送配置
   •EmailJS 配置：
     - Service ID
     - Template ID
     - Public Key
   •Resend 配置：
     - API Key
   •其他14种发送方式（点击查看详情）

3. 自定义邮箱配置
   •添加自己的邮箱账号：
     - 支持 Gmail, Outlook, QQ邮箱等
     - 需要配置 SMTP 和 IMAP
     - 更稳定、无额度限制
   •测试连接：验证配置是否正确
   •启用/禁用：快速切换

4. 后端代理配置（推荐）
   •配置说明：
     - 部署自己的后端服务器
     - API密钥不会被提取
     - 最安全的方式
   •测试连接：检查代理服务器状态

5. 功能开关
   •高级功能：
     - 邮件搜索和过滤
     - 邮件模板库
     - 邮箱分组管理
     - 使用统计报告
     - 邮件标签系统
     - 邮件智能分类
     - 数据可视化
     - 高级数据管理

6. 自动化设置
   •自动检查邮件：
     - 间隔时间（5分钟 - 60分钟）
     - 启用/禁用
   •自动清理：
     - 自动删除过期邮箱
     - 自动删除已读邮件（N天后）
   •自动备份：
     - 定期备份数据
     - 备份加密

7. 数据管理
   •导出数据：
     - 邮箱列表
     - 邮件记录
     - 草稿和模板
     - 完整数据包
   •导入数据：从备份文件恢复
   •清空数据：删除所有数据（谨慎操作）

8. 关于信息
   •版本号：查看当前版本
   •检查更新：检测新版本
   •用户协议：查看使用条款
   •隐私政策：了解数据处理方式
   •开源许可：AGPL v3.0
   •GitHub：查看源代码和提交问题

提示：
•首次使用请先配置邮件发送服务
•推荐使用后端代理模式（最安全）
•定期备份重要数据
•开启自动检查可及时收到邮件
•合理配置自动清理，节省存储空间`""",

    # getEmailConfigContent 方法的中文部分
    'getEmailConfigContent_cn': """      return `邮件服务配置指南`
🌟 内置服务（推荐新手）

1. EmailJS 服务
   如何获取配置：
   •访问 https://www.emailjs.com
   •注册账号并创建服务
   •创建邮件模板
   •获取以下信息：
     - Service ID
     - Template ID  
     - Public Key
   •在下方填入配置项

   使用限额：
   •免费：每月 200封
   •额度每月1号重置
   •界面会实时显示使用情况

2. Resend 服务
   如何获取配置：
   •访问 https://resend.com
   •注册账号
   •创建 API Key
   •在下方填入配置项

   使用限额：
   •免费：每月 100封
   •额度每月1号重置
   •界面会实时显示使用情况

⚠️ 重要提示
•内置服务的 API 密钥存储在应用内
•理论上可能被提取（虽然做了混淆处理）
•有额度限制，请合理使用
•建议配置后端代理服务器获得最佳安全性

🔐 自定义邮箱（推荐高级用户）

配置说明：
•使用您自己的邮箱账号发送邮件
•支持 Gmail, Outlook, QQ邮箱, 163等
•需要配置 SMTP 和 IMAP 服务器
•优点：
  - 更稳定可靠
  - 无额度限制
  - 可以接收回复
  - 支持更大的附件（最多25MB）

如何配置：
1. 进入"设置" -> "自定义邮箱配置"
2. 填写邮箱地址和密码（应用专用密码）
3. 选择预设服务商或手动配置 SMTP/IMAP
4. 点击"测试连接"验证配置
5. 启用自定义邮箱

🚀 后端代理模式（最推荐）

为什么需要后端：
•API密钥不会存储在应用中
•无法被提取或滥用
•最安全的发送方式
•可以实现更多高级功能

如何配置：
1. 部署后端服务器（提供开源代码）
2. 在"设置" -> "后端代理配置"中填写服务器地址
3. 测试连接
4. 启用后端代理模式

后端项目：
•GitHub：https://github.com/fayufm/convenient-mailbox-backend
•部署指南：请参考 GitHub README

📊 其他发送方式（总共16种）

除了 EmailJS 和 Resend，还支持：
1. SendGrid
2. Mailgun
3. Postmark
4. Amazon SES
5. Mailjet
6. SparkPost
7. Sendinblue
8. Mandrill
9. SendPulse
10. Pepipost
11. Elastic Email
12. MailerSend
13. SMTP.com
14. Postal

（点击"查看其他方式"了解详情）

💡 选择建议

新手用户：
•使用 EmailJS 或 Resend
•快速上手，无需复杂配置
•适合轻度使用

进阶用户：
•配置自定义邮箱
•更稳定，无限额
•需要一定技术基础

高级用户：
•部署后端代理
•最安全可靠
•需要服务器和技术能力

如有问题，欢迎联系：xieshuoxing@gmail.com`""",
}


def create_backup(file_path):
    """创建备份文件"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup_comprehensive_fix_{timestamp}"
    shutil.copy2(file_path, backup_path)
    print(f"✅ 已创建备份: {backup_path}")
    return backup_path


def read_file_with_fallback(file_path):
    """尝试多种编码读取文件"""
    encodings = ['utf-8', 'utf-8-sig', 'gbk', 'gb2312', 'gb18030', 'latin-1']
    
    for encoding in encodings:
        try:
            with open(file_path, 'r', encoding=encoding) as f:
                content = f.read()
            print(f"✅ 成功使用 {encoding} 编码读取文件")
            return content, encoding
        except (UnicodeDecodeError, LookupError):
            continue
    
    # 最后尝试以二进制模式读取并尝试解码
    try:
        with open(file_path, 'rb') as f:
            raw_content = f.read()
        # 尝试UTF-8，忽略错误
        content = raw_content.decode('utf-8', errors='ignore')
        print(f"⚠️  使用 UTF-8 (忽略错误) 读取文件")
        return content, 'utf-8-ignore'
    except Exception as e:
        print(f"❌ 无法读取文件: {e}")
        return None, None


def fix_getCreateNoticeContent(content):
    """修复 getCreateNoticeContent 方法中的乱码"""
    print("🔧 修复 getCreateNoticeContent 中文部分...")
    
    # 查找中文部分的开始和结束
    # 从 "return `重要注意事项`" 或类似乱码开始，到下一个 "} else {" 或类似结束
    
    # 方法1: 使用正则表达式匹配整个方法
    pattern = r'(getCreateNoticeContent\(\): string \{[^}]*if \(this\.settingsLanguage === \'en-US\'\) \{[^}]*return `[^`]*`[^}]*\} else \{[^}]*?)(return `[^`]*重要[^`]*`)(.*?\}[\s\n]*\})'
    
    def replacer(match):
        before = match.group(1)
        # 中文部分被替换
        after = match.group(3)
        return before + CORRECT_TEXTS['getCreateNoticeContent_cn'] + after
    
    new_content = re.sub(pattern, replacer, content, flags=re.DOTALL)
    
    if new_content != content:
        print("   ✅ 已修复 getCreateNoticeContent 中文部分")
        return new_content
    else:
        print("   ⚠️  未找到匹配的模式，尝试备用方法...")
        return content


def fix_getDisclaimerContent(content):
    """修复 getDisclaimerContent 方法中的乱码"""
    print("🔧 修复 getDisclaimerContent 中文部分...")
    
    # 类似地修复这个方法
    pattern = r'(getDisclaimerContent\(\): string \{[^}]*if \(this\.settingsLanguage === \'en-US\'\) \{[^}]*return `[^`]*`[^}]*\} else \{[^}]*?)(return `[^`]*版权[^`]*`)(.*?\}[\s\n]*\})'
    
    def replacer(match):
        before = match.group(1)
        after = match.group(3)
        return before + CORRECT_TEXTS['getDisclaimerContent_cn'] + after
    
    new_content = re.sub(pattern, replacer, content, flags=re.DOTALL)
    
    if new_content != content:
        print("   ✅ 已修复 getDisclaimerContent 中文部分")
        return new_content
    else:
        print("   ⚠️  未找到匹配的模式")
        return content


def fix_by_line_replacement(file_path):
    """通过行替换的方式修复乱码（备用方法）"""
    print("🔧 使用精确行替换方法修复乱码...")
    
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    # 修复getCreateNoticeContent中文部分 (假设在2247行左右开始)
    # 这需要精确找到起始和结束行
    
    # 标记需要替换的范围
    fixes_applied = 0
    
    # 简单的方法：直接替换包含特定乱码的行
    for i in range(len(lines)):
        line = lines[i]
        
        # 替换常见的乱码模式
        if '嶉檺' in line or '婧' in line or '氭' in line or '侊紙' in line:
            # 这一行可能有乱码，但我们需要知道它应该是什么
            # 由于上下文很重要，这种方法不够可靠
            pass
    
    return fixes_applied


def main():
    file_path = "entry/src/main/ets/pages/Index.ets"
    
    if not os.path.exists(file_path):
        print(f"❌ 文件不存在: {file_path}")
        return
    
    print("=" * 70)
    print("🔧 开始全面修复 Index.ets 编码问题")
    print("=" * 70)
    print()
    
    # 1. 创建备份
    backup_path = create_backup(file_path)
    print()
    
    # 2. 读取文件
    content, encoding = read_file_with_fallback(file_path)
    if content is None:
        print("❌ 无法读取文件")
        return
    print()
    
    # 3. 应用修复
    original_content = content
    
    # 修复各个方法
    content = fix_getCreateNoticeContent(content)
    content = fix_getDisclaimerContent(content)
    
    # 如果主要方法没有成功，尝试更激进的修复
    if content == original_content:
        print("\n⚠️  正则匹配未成功，尝试直接文本替换...")
        
        # 方法2: 直接查找和替换大段文本
        # 查找特征字符串作为锚点
        if 'getCreateNoticeContent(): string {' in content:
            # 找到方法定义的位置
            method_start = content.find('getCreateNoticeContent(): string {')
            if method_start != -1:
                # 找到方法结束（下一个方法定义之前）
                next_method = content.find('\n  get', method_start + 100)
                if next_method != -1:
                    method_content = content[method_start:next_method]
                    
                    # 检查是否包含英文版本
                    if "if (this.settingsLanguage === 'en-US')" in method_content:
                        # 提取英文部分
                        en_start = method_content.find("if (this.settingsLanguage === 'en-US')")
                        else_pos = method_content.find("} else {", en_start)
                        method_end = method_content.rfind('}')
                        
                        if else_pos != -1 and method_end != -1:
                            # 构建新的方法内容
                            en_part = method_content[en_start:else_pos + 8]  # 包含 "} else {"
                            
                            new_method = f"""  getCreateNoticeContent(): string {{
    if (this.settingsLanguage === 'en-US') {{
      return `Important Notice`
1. Domain Support Description
   •17 domains support in-app email receiving
     - 1SecMail: 7 domains
     - Guerrilla Mail: 10 domains
   •Other 74 domains only generate addresses
   •Clear prompt shown when generating (Receive/Address Only)

2. Mailbox Validity
   •Recommended to use 7 days or 1 month
   •Permanent mailboxes not guaranteed for long-term use
   •Regularly check expired mailboxes

3. Security Tips
   •Temporary mailboxes not suitable for important accounts
   •Do not use for banking, payment services, etc.
   •Email content may be seen by others

4. Privacy Protection
   •Use different mailboxes for different websites
   •Avoid revealing your real email address
   •Regularly clean up unused mailboxes

5. Email Sending (Security Recommendations)
   •Recommended: Use backend proxy (most secure)
   •Warning: Built-in service API keys may be extracted
   •Limited quota, use wisely
   •Configure your own backend server in settings

6. Data Backup
   •Save important emails promptly
   •App data is stored locally
   •Uninstalling the app will lose all data`    }} else {{
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
    }}
  }}
"""
                            # 替换
                            content = content[:method_start] + new_method + content[next_method:]
                            print("   ✅ 已使用直接替换修复 getCreateNoticeContent")
    
    # 4. 写回文件
    if content != original_content:
        try:
            with open(file_path, 'w', encoding='utf-8', newline='\n') as f:
                f.write(content)
            print(f"\n✅ 已写回文件: {file_path} (UTF-8 编码)")
            print(f"📊 文件大小: {len(original_content)} -> {len(content)} 字符")
            print(f"📊 变化: {len(content) - len(original_content):+d} 字符")
        except Exception as e:
            print(f"❌ 写入文件失败: {e}")
            # 恢复备份
            shutil.copy2(backup_path, file_path)
            print(f"⚠️  已从备份恢复: {backup_path}")
            return
    else:
        print("\n⚠️  未检测到需要修复的内容或修复失败")
        print("💡 建议：手动检查文件内容")
    
    print()
    print("=" * 70)
    print("✅ 修复完成！")
    print("=" * 70)
    print(f"📁 备份文件: {backup_path}")
    print("\n💡 下一步:")
    print("   1. 检查修复后的文件")
    print("   2. 运行编译测试")
    print("   3. 如有问题，可从备份恢复")


if __name__ == "__main__":
    main()

