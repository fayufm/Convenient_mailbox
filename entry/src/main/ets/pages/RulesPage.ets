/**
 * Rules Page - 规则限制/使用说明页面
 * 显示应用的各项规则和限制说明
 */

import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import hilog from '@ohos.hilog'

@Component
export struct RulesPage {
  // ==================== Props from Parent ====================
  @Link uiTexts: Record<string, string>
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  
  // Callbacks
  onBack?: () => void
  
  // ==================== Helper Methods ====================
  
  getPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#64B5F6'
    } else if (this.settingsTheme === 'light') {
      return '#1976D2'
    } else {
      return '#2196F3'
    }
  }

  getTextPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#FFFFFF'
    } else {
      return '#212529'
    }
  }

  getBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#121212'
    } else {
      return '#FFFFFF'
    }
  }

  getBorderColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#333333'
    } else {
      return '#E0E0E0'
    }
  }

  // ==================== Main Build Method ====================

  build() {
    Column() {
      // Header
      Row() {
        Button('←')
          .fontSize(20)
          .backgroundColor(Color.Transparent)
          .fontColor(this.getPrimaryColor())
          .onClick(() => {
            if (this.onBack) {
              this.onBack()
            }
          })
        
        Text(this.uiTexts['rulesTitle'] || 'Rules & Limitations')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextPrimaryColor())
          .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      .backgroundColor(this.getBackgroundColor())
      
      Divider()
        .color(this.getBorderColor())
      
      // Content
      Scroll() {
        Column({ space: 16 }) {
          // 前缀规则
          this.buildRuleSection(
            this.uiTexts['rulePrefixTitle'] || 'Prefix Rules',
            [
              this.uiTexts['rulePrefixRule1'] || '• Must be at least 3 characters long',
              this.uiTexts['rulePrefixRule2'] || '• Must contain at least one letter character',
              this.uiTexts['rulePrefixRule3'] || '• Cannot be all numbers',
              this.uiTexts['rulePrefixRule4'] || '• Supports letters, numbers, and hyphens'
            ]
          )
          
          // 域名规则
          this.buildRuleSection(
            this.uiTexts['ruleDomainTitle'] || 'Domain Rules',
            [
              this.uiTexts['ruleDomainRule1'] || '• Select from supported domains',
              this.uiTexts['ruleDomainRule2'] || '• Different domains have different email retention times',
              this.uiTexts['ruleDomainRule3'] || '• Some domains support API integration for email retrieval'
            ]
          )
          
          // 有效期规则
          this.buildRuleSection(
            this.uiTexts['ruleDurationTitle'] || 'Validity Period Rules',
            [
              this.uiTexts['ruleDurationRule1'] || '• Minimum: 7 days',
              this.uiTexts['ruleDurationRule2'] || '• Maximum: 1 year',
              this.uiTexts['ruleDurationRule3'] || '• Custom duration available',
              this.uiTexts['ruleDurationRule4'] || '• Mailbox will be deleted after expiration'
            ]
          )
          
          // 文件夹规则
          this.buildRuleSection(
            this.uiTexts['ruleFolderTitle'] || 'Folder Rules',
            [
              this.uiTexts['ruleFolderRule1'] || '• Create custom folders to organize mailboxes',
              this.uiTexts['ruleFolderRule2'] || '• Move mailboxes between folders',
              this.uiTexts['ruleFolderRule3'] || '• Folder data is automatically saved'
            ]
          )
          
          // 批量操作规则
          this.buildRuleSection(
            this.uiTexts['ruleBatchTitle'] || 'Batch Operations',
            [
              this.uiTexts['ruleBatchRule1'] || '• Batch select mailboxes in outbox',
              this.uiTexts['ruleBatchRule2'] || '• Delete selected sent records',
              this.uiTexts['ruleBatchRule3'] || '• Clear all sent records at once'
            ]
          )
          
          // 自定义邮箱规则
          this.buildRuleSection(
            this.uiTexts['ruleCustomMailboxTitle'] || 'Custom Mailbox Rules',
            [
              this.uiTexts['ruleCustomMailboxRule1'] || '• Configure SMTP and IMAP settings',
              this.uiTexts['ruleCustomMailboxRule2'] || '• Support for real email accounts',
              this.uiTexts['ruleCustomMailboxRule3'] || '• Enable attachment sending',
              this.uiTexts['ruleCustomMailboxRule4'] || '• Only one custom mailbox can be active at a time'
            ]
          )
          
          // 邮件发送规则
          this.buildRuleSection(
            this.uiTexts['ruleSendEmailTitle'] || 'Email Sending Rules',
            [
              this.uiTexts['ruleSendEmailRule1'] || '• Random mailboxes: Can only receive emails, cannot send',
              this.uiTexts['ruleSendEmailRule2'] || '• Custom mailboxes: Can send emails with SMTP configuration',
              this.uiTexts['ruleSendEmailRule3'] || '• Some random mailboxes (1SecMail, Guerrilla Mail) support API email retrieval',
              this.uiTexts['ruleSendEmailRule4'] || '• Requires valid recipient email address for sending'
            ]
          )
          
          // 附件规则
          this.buildRuleSection(
            this.uiTexts['ruleAttachmentTitle'] || 'Attachment Rules',
            [
              this.uiTexts['ruleAttachmentRule1'] || '• Random mailboxes: Cannot send attachments',
              this.uiTexts['ruleAttachmentRule2'] || '• Custom mailboxes: Can send attachments (max 5 files)',
              this.uiTexts['ruleAttachmentRule3'] || '• Requires complete SMTP configuration',
              this.uiTexts['ruleAttachmentRule4'] || '• Supported file types: All common formats',
              this.uiTexts['ruleAttachmentRule5'] || '• File size limit depends on email provider'
            ]
          )
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getBackgroundColor())
  }
  
  @Builder buildRuleSection(title: string, rules: string[]): void {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getPrimaryColor())
      
      Column({ space: 6 }) {
        ForEach(rules, (rule: string) => {
          Text(rule)
            .fontSize(13)
            .fontColor(this.getTextPrimaryColor())
            .lineHeight(20)
            .width('100%')
        }, (rule: string) => rule)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : '#F5F5F5')
      .borderRadius(8)
      .border({
        width: 1,
        color: this.getBorderColor()
      })
    }
    .width('100%')
  }
}
