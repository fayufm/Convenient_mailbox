#!/usr/bin/env python3
"""
删除Index.ets中已迁移到新组件的@Builder方法
"""

import re

# 需要删除的方法列表 (52个)
METHODS_TO_REMOVE = [
    # CreateMailboxPage (8个)
    'buildCreatePage',
    'buildCustomMailboxInfoCard',
    'buildCreateModeCard',
    'buildCurrentMailboxDisplay',
    'buildCustomInputArea',
    'buildDurationSelector',
    'buildDurationButton',
    'buildCustomMailboxCard',
    
    # InboxPage (11个)
    'buildInboxPage',
    'buildInboxContent',
    'buildEmailSearchBar',
    'buildTagFilterBar',
    'buildCategoryFilterBar',
    'buildOutboxContent',
    'buildSentEmailItem',
    'buildEmailItem',
    'buildEmailDetailDialog',
    'buildSentEmailDetailDialog',
    'buildImagePreviewDialog',
    
    # MailboxesPage (16个)
    'buildMailboxesPage',
    'buildMailboxItem',
    'buildMailboxActionsMenu',
    'buildFolderView',
    'buildFolderItem',
    'buildStatisticsReport',
    'buildStatCard',
    'buildCreateFolderDialog',
    'buildMoveFolderDialog',
    'buildCreateTagDialog',
    'buildAddTagDialog',
    'buildStatsDialog',
    'buildStatsSection',
    'buildDomainStatsSection',
    'buildEmailTrendSection',
    'buildTagStatsSection',
    'buildNoteDialog',
    'buildQRCodeDialog',
    
    # ComposePage (4个)
    'buildComposePage',
    'buildTemplateDialog',
    'buildTemplateItem',
    'buildCreateTemplateDialog',
    
    # SettingsPage (13个)
    'buildSettingsPage',
    'buildSettingsSection',
    'buildInterfaceSettings',
    'buildMailboxSettings',
    'buildCustomMailboxSettings',
    'buildEmailSendSettings',
    'buildEmailJSQuota',
    'buildResendQuota',
    'buildEmailServiceConfig',
    'buildAutoCheckSettings',
    'buildNotificationSettings',
    'buildAdvancedFeaturesSettings',
    'buildDataManagementSection',
]

def find_method_bounds(lines, method_name):
    """
    找到方法的起始和结束行号
    """
    start_line = -1
    end_line = -1
    brace_count = 0
    in_method = False
    
    pattern = rf'^\s*@Builder\s+{re.escape(method_name)}\s*\('
    
    for i, line in enumerate(lines):
        if not in_method and re.search(pattern, line):
            start_line = i
            in_method = True
            # 计算这一行的大括号
            brace_count += line.count('{') - line.count('}')
            continue
        
        if in_method:
            brace_count += line.count('{') - line.count('}')
            if brace_count == 0:
                end_line = i
                break
    
    return start_line, end_line

def remove_methods(input_file, output_file):
    """
    删除指定的方法并保存到新文件
    """
    print(f"读取文件: {input_file}")
    with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    print(f"原始行数: {len(lines)}")
    
    # 收集要删除的行号范围
    ranges_to_delete = []
    
    for method_name in METHODS_TO_REMOVE:
        start, end = find_method_bounds(lines, method_name)
        if start != -1 and end != -1:
            ranges_to_delete.append((start, end, method_name))
            print(f"找到方法 {method_name}: 行 {start+1} 到 {end+1}")
        else:
            print(f"WARNING: Method not found: {method_name}")
    
    # 按起始行号排序（倒序，从后往前删除）
    ranges_to_delete.sort(reverse=True)
    
    # 删除方法
    deleted_lines = 0
    for start, end, name in ranges_to_delete:
        del lines[start:end+1]
        deleted_lines += (end - start + 1)
        print(f"OK Deleted {name}: {end - start + 1} lines")
    
    print(f"\n删除总行数: {deleted_lines}")
    print(f"最终行数: {len(lines)}")
    
    # 保存新文件
    print(f"\n保存到: {output_file}")
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print("DONE!")
    return len(ranges_to_delete), deleted_lines

if __name__ == '__main__':
    input_file = 'entry/src/main/ets/pages/Index.ets'
    output_file = 'entry/src/main/ets/pages/Index.ets'
    
    # 创建备份
    import shutil
    from datetime import datetime
    backup_file = f'entry/src/main/ets/pages/Index.ets.backup_before_cleanup_{datetime.now().strftime("%Y%m%d_%H%M%S")}'
    print(f"创建备份: {backup_file}")
    shutil.copy(input_file, backup_file)
    
    # 执行删除
    removed_count, removed_lines = remove_methods(input_file, output_file)
    
    print(f"\nSUMMARY:")
    print(f"  - Methods removed: {removed_count} / {len(METHODS_TO_REMOVE)}")
    print(f"  - Lines removed: {removed_lines}")
    print(f"  - Backup file: {backup_file}")

