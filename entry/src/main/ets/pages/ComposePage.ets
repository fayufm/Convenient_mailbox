/**
 * Compose Email Page - 写邮件页面
 * 负责邮件编写和发送功能
 */

import { AttachmentData, EmailTemplate, TemplateCategory, DraftData, MailboxData } from '../common/DataTypes'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { SystemService } from '../common/SystemService'
import { EmailSenderFactory } from '../services/email/EmailSenderFactory'
import { MailboxManager } from '../common/MailboxManager'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'

@Component
export struct ComposePage {
  // ==================== Props from Parent ====================
  @Link composeFrom: string
  @Link composeFromIndex: number
  @Link composeTo: string
  @Link composeSubject: string
  @Link composeBody: string
  @Link composeAttachments: AttachmentData[]
  @Link hasDraft: boolean
  @Link selectedTemplateId: number
  @Link showTemplateDialog: boolean
  @Link showCreateTemplateDialog: boolean
  @Link editingTemplateId: number
  @Link templateName: string
  @Link templateCategory: string
  @Link templateSubject: string
  @Link templateBody: string
  @Link templateDescription: string
  @Link templateFilterCategory: string
  @Link isSendingEmail: boolean
  @Link mailboxes: MailboxData[]
  @Link uiTexts: Record<string, string>
  @Link enableTemplates: boolean
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  
  // Services
  @Prop i18nService: I18nService
  @Prop systemService: SystemService
  @Prop emailSenderFactory: EmailSenderFactory
  @Prop mailboxManager: MailboxManager
  
  // Callbacks
  onSendEmail?: () => void
  onSaveDraft?: () => void
  onAttachFile?: () => void
  onCreateTemplate?: () => void
  onSelectTemplate?: (templateId: number) => void
  
  // ==================== Helper Methods ====================
  
  /**
   * 获取动态主色调（根据当前主题）
   */
  getPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#64B5F6'
    } else if (this.settingsTheme === 'light') {
      return '#1976D2'
    } else {
      return '#2196F3'
    }
  }

  /**
   * 获取动态文本颜色（根据当前主题）
   */
  getTextPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#FFFFFF'
    } else {
      return '#212529'
    }
  }

  /**
   * 获取动态背景颜色（根据当前主题）
   */
  getBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#121212'
    } else {
      return '#FFFFFF'
    }
  }

  /**
   * 获取发件人选项
   */
  private getFromOptions(): SelectOption[] {
    const options: SelectOption[] = []
    for (const mailbox of this.mailboxes) {
      options.push({ value: mailbox.email })
    }
    return options
  }
  
  /**
   * 格式化附件大小
   */
  private formatFileSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`
    }
  }
  
  // ==================== Builder Methods ====================
  
  @Builder buildComposePage(): void {
    Column({ space: 16 }) {
      // Header
      Row() {
        Text(this.uiTexts['pageCompose'] || 'Compose Email')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        if (this.enableTemplates) {
          Button(this.uiTexts['btnTemplates'] || 'Templates')
            .fontSize(12)
            .onClick(() => {
              this.showTemplateDialog = true
            })
        }
      }
      .width('100%')
      .padding({ top: 16 })
      
      // Form
      Column({ space: 12 }) {
        // From
        Row() {
          Text(this.uiTexts['labelFrom'] || 'From:')
            .fontSize(14)
            .width(80)
            .fontColor(this.getTextPrimaryColor())
          
          if (this.mailboxes.length > 0) {
            Select(this.getFromOptions())
              .height(44)
              .selected(this.composeFromIndex)
              .value(this.composeFrom || this.uiTexts['selectSender'] || 'Select sender...')
              .layoutWeight(1)
              .fontColor(this.getTextPrimaryColor())
              .backgroundColor(this.getBackgroundColor())
              .onSelect((index: number, value: string) => {
                this.composeFromIndex = index
                this.composeFrom = value
              })
          } else {
            Text(this.uiTexts['noMailboxes'] || 'No mailboxes available')
              .fontSize(12)
              .fontColor(this.getTextPrimaryColor())
              .layoutWeight(1)
          }
        }
        .width('100%')
        
        // To
        Row() {
          Text(this.uiTexts['labelTo'] || 'To:')
            .fontSize(14)
            .width(80)
            .fontColor(this.getTextPrimaryColor())
          TextInput({ text: this.composeTo, placeholder: this.uiTexts['recipientPlaceholder'] || 'Recipient email...' })
            .layoutWeight(1)
            .fontColor(this.getTextPrimaryColor())
            .placeholderColor(this.getTextPrimaryColor())
            .border({ width: 1, color: this.getTextPrimaryColor() })
            .onChange((value: string) => {
              this.composeTo = value
            })
        }
        .width('100%')
        
        // Subject
        Row() {
          Text(this.uiTexts['labelSubject'] || 'Subject:')
            .fontSize(14)
            .width(80)
            .fontColor(this.getTextPrimaryColor())
          TextInput({ text: this.composeSubject, placeholder: this.uiTexts['subjectPlaceholder'] || 'Email subject...' })
            .layoutWeight(1)
            .fontColor(this.getTextPrimaryColor())
            .placeholderColor(this.getTextPrimaryColor())
            .border({ width: 1, color: this.getTextPrimaryColor() })
            .onChange((value: string) => {
              this.composeSubject = value
            })
        }
        .width('100%')
        
        // Body
        Column() {
          Text(this.uiTexts['labelBody'] || 'Body:')
            .fontSize(14)
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 5 })
            .fontColor(this.getTextPrimaryColor())
          
          TextArea({ text: this.composeBody, placeholder: this.uiTexts['bodyPlaceholder'] || 'Compose your message...' })
            .height(200)
            .fontColor(this.getTextPrimaryColor())
            .placeholderColor(this.getTextPrimaryColor())
            .border({ width: 1, color: this.getTextPrimaryColor() })
            .onChange((value: string) => {
              this.composeBody = value
            })
        }
        .width('100%')
        
        // Attachments Section
        Column() {
          Row() {
            Text(this.uiTexts['labelAttachments'] || 'Attachments:')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.getTextPrimaryColor())
            
            Blank()
            
            Button(this.uiTexts['btnAttach'] || 'Attach')
              .fontSize(12)
              .padding({ left: 16, right: 16 })
              .onClick(() => {
                if (this.onAttachFile) {
                  this.onAttachFile()
                }
              })
          }
          .width('100%')
          .padding({ bottom: 10 })
          
          // Attachments List
          if (this.composeAttachments.length > 0) {
            Column() {
              ForEach(this.composeAttachments, (attachment: AttachmentData, index: number) => {
                Row() {
                  Column() {
                    Text(attachment.filename)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor(this.getTextPrimaryColor())
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    
                    Text(this.formatFileSize(attachment.size))
                      .fontSize(11)
                      .fontColor('#999999')
                      .margin({ top: 4 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                  
                  Button('✕')
                    .fontSize(14)
                    .backgroundColor(Color.Transparent)
                    .fontColor('#FF5252')
                    .padding({ left: 8, right: 8 })
                    .onClick(() => {
                      const idx: number = this.composeAttachments.indexOf(attachment)
                      if (idx > -1) {
                        this.composeAttachments.splice(idx, 1)
                      }
                    })
                }
                .width('100%')
                .padding({ top: 8, bottom: 8, left: 12, right: 12 })
                .backgroundColor(index % 2 === 0 ? '#F5F5F5' : Color.White)
                .borderRadius(4)
                .margin({ bottom: 6 })
                .alignItems(VerticalAlign.Center)
              }, (attachment: AttachmentData) => attachment.id)
            }
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : '#FAFAFA')
            .borderRadius(6)
          } else {
            Text(this.uiTexts['noAttachments'] || 'No attachments')
              .fontSize(12)
              .fontColor('#999999')
              .padding({ top: 8, bottom: 8 })
          }
        }
        .width('100%')
      }
      .width('100%')
      
      // Draft indicator
      if (this.hasDraft) {
        Text(this.uiTexts['draftSaved'] || 'Draft saved')
          .fontSize(12)
          .fontColor('#4CAF50')
      }
      
      // Action buttons
      Row({ space: 12 }) {
        Button(this.uiTexts['btnSaveDraft'] || 'Save Draft')
          .layoutWeight(1)
          .onClick(() => {
            if (this.onSaveDraft) {
              this.onSaveDraft()
            }
          })
        
        Button(this.uiTexts['btnSend'] || 'Send')
          .layoutWeight(1)
          .backgroundColor(this.getPrimaryColor())
          .fontColor(Color.White)
          .enabled(!this.isSendingEmail && this.composeFrom.length > 0 && this.composeTo.length > 0)
          .onClick(() => {
            if (this.onSendEmail) {
              this.onSendEmail()
            }
          })
      }
      .width('100%')
      .margin({ top: 16 })
      
      if (this.isSendingEmail) {
        Row() {
          LoadingProgress()
            .width(20)
            .height(20)
            .margin({ right: 8 })
          Text(this.uiTexts['sending'] || 'Sending...')
            .fontSize(12)
            .fontColor(this.getPrimaryColor())
        }
        .justifyContent(FlexAlign.Center)
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
  }
  
  @Builder buildTemplateDialog(): void {
    if (this.showTemplateDialog) {
      Column() {
        Row() {
          Text(this.uiTexts['emailTemplates'] || 'Email Templates')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
          
          Blank()
          
          Button('+')
            .onClick(() => {
              this.showTemplateDialog = false
              this.showCreateTemplateDialog = true
            })
        }
        .width('100%')
        .margin({ bottom: 15 })
        
        // Category filter
        Row({ space: 8 }) {
          Text(this.uiTexts['labelCategory'] || 'Category:')
            .fontSize(12)
          
          Button(this.uiTexts['templateAll'] || 'All')
            .fontSize(12)
            .padding(8)
            .backgroundColor(this.templateFilterCategory === 'all' ? ThemeColors.PRIMARY : Color.White)
            .fontColor(this.templateFilterCategory === 'all' ? Color.White : Color.Black)
            .borderRadius(4)
            .onClick(() => {
              this.templateFilterCategory = 'all'
            })
          
          Button(this.uiTexts['templateCustom'] || 'Custom')
            .fontSize(12)
            .padding(8)
            .backgroundColor(this.templateFilterCategory === 'custom' ? ThemeColors.PRIMARY : Color.White)
            .fontColor(this.templateFilterCategory === 'custom' ? Color.White : Color.Black)
            .borderRadius(4)
            .onClick(() => {
              this.templateFilterCategory = 'custom'
            })
        }
        .width('100%')
        .margin({ bottom: 10 })
        
        // Template list (placeholder)
        Text(this.uiTexts['noTemplatesAvailable'] || 'No templates available')
          .fontSize(12)
          .fontColor(Color.Gray)
          .margin({ top: 20, bottom: 20 })
        
        Button(this.uiTexts['btnClose'] || 'Close')
          .width('100%')
          .onClick(() => {
            this.showTemplateDialog = false
          })
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .border({ width: 1, color: '#E0E0E0' })
      .width('85%')
      .height('70%')
    }
  }
  
  @Builder buildTemplateItem(template: EmailTemplate): void {
    Column() {
      Row() {
        Text(template.name)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        
        Text(template.category)
          .fontSize(10)
          .fontColor(Color.Gray)
          .padding(4)
          .backgroundColor('#F0F0F0')
          .borderRadius(4)
      }
      .width('100%')
      
      if (template.description) {
        Text(template.description)
          .fontSize(12)
          .fontColor(Color.Gray)
          .margin({ top: 5 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      
      Text(`${this.uiTexts['labelSubject'] || 'Subject'}: ${template.subject}`)
        .fontSize(10)
        .fontColor(Color.Gray)
        .margin({ top: 5 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selectedTemplateId === template.id ? '#E3F2FD' : Color.White)
    .borderRadius(4)
    .border({ width: 1, color: this.selectedTemplateId === template.id ? ThemeColors.PRIMARY : '#E0E0E0' })
    .onClick(() => {
      this.selectedTemplateId = template.id
      this.composeSubject = template.subject
      this.composeBody = template.body
      this.showTemplateDialog = false
      if (this.onSelectTemplate) {
        this.onSelectTemplate(template.id)
      }
    })
  }
  
  @Builder buildCreateTemplateDialog(): void {
    if (this.showCreateTemplateDialog) {
      Column() {
        Text(this.uiTexts['createTemplate'] || 'Create Template')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        TextInput({ placeholder: this.uiTexts['templateNamePlaceholder'] || 'Template name' })
          .onChange((value: string) => {
            this.templateName = value
          })
          .margin({ bottom: 10 })
        
        TextInput({ placeholder: this.uiTexts['categoryPlaceholder'] || 'Category' })
          .onChange((value: string) => {
            this.templateCategory = value
          })
          .margin({ bottom: 10 })
        
        TextInput({ placeholder: this.uiTexts['subjectPlaceholder'] || 'Subject' })
          .onChange((value: string) => {
            this.templateSubject = value
          })
          .margin({ bottom: 10 })
        
        TextArea({ placeholder: this.uiTexts['templateBodyPlaceholder'] || 'Template body...' })
          .height(100)
          .onChange((value: string) => {
            this.templateBody = value
          })
          .margin({ bottom: 10 })
        
        TextInput({ placeholder: this.uiTexts['descriptionPlaceholder'] || 'Description (optional)' })
          .onChange((value: string) => {
            this.templateDescription = value
          })
          .margin({ bottom: 15 })
        
        Row() {
          Button(this.uiTexts['btnCancel'] || '取消')
            .onClick(() => {
              this.showCreateTemplateDialog = false
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnCreate'] || '创建')
            .onClick(() => {
              if (this.onCreateTemplate) {
                this.onCreateTemplate()
              }
              this.showCreateTemplateDialog = false
            })
        }
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .width('85%')
    }
  }
  
  // ==================== Main Build Method ====================
  
  build() {
    Stack() {
      Scroll() {
        this.buildComposePage()
      }
      .width('100%')
      .height('100%')
      
      // Dialogs overlay
      if (this.showTemplateDialog) {
        this.buildTemplateDialog()
      }
      if (this.showCreateTemplateDialog) {
        this.buildCreateTemplateDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
