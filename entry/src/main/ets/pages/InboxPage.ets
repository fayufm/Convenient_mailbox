/**
 * Inbox Page - 收件箱页面
 * 负责显示收件箱和发件箱邮件列表
 */

import { EmailData, SentEmailData, AttachmentData, EmailTag, EmailCategory } from '../common/DataTypes'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { SystemService } from '../common/SystemService'
import { MailboxManager } from '../common/MailboxManager'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'

@Component
export struct InboxPage {
  // ==================== Props from Parent ====================
  @Link inboxMode: 'inbox' | 'outbox'
  @Link emails: EmailData[]
  @Link sentEmails: SentEmailData[]
  @Link selectedEmail: EmailData | null
  @Link selectedSentEmail: SentEmailData | null
  @Link showEmailDetail: boolean
  @Link showSentEmailDetail: boolean
  @Link selectedSentEmailIds: Set<number>
  @Link isSelectMode: boolean
  @Link showImagePreview: boolean
  @Link previewImageUri: string
  @Link previewImageName: string
  @Link searchKeyword: string
  @Link searchResults: EmailData[]
  @Link filterType: 'all' | 'unread' | 'verification' | 'today'
  @Link sortBy: 'time' | 'sender'
  @Link showFilterPanel: boolean
  @Link filterByTagId: number
  @Link filterByCategory: string
  @Link emailListRefreshKey: number
  @Link sentEmailListRefreshKey: number
  @Link inboxBadgeCount: number
  @Link uiTexts: Record<string, string>
  @Link enableEmailSearch: boolean
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  
  // Services
  @Prop i18nService: I18nService
  @Prop systemService: SystemService
  @Prop mailboxManager: MailboxManager
  
  // Callbacks
  onEmailClick?: (email: EmailData) => void
  onSentEmailClick?: (sentEmail: SentEmailData) => void
  onDeleteEmail?: (emailId: number) => void
  onMarkAsRead?: (emailId: number) => void
  onRefreshEmails?: () => void
  onDeleteSelectedSentEmails?: () => void
  onClearAllSentEmails?: () => void
  onImagePreview?: (uri: string, name: string) => void
  
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
   * 获取动态边框颜色（根据当前主题）
   */
  getBorderColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#333333'
    } else {
      return '#E0E0E0'
    }
  }

  /**
   * 获取指示器线条段数
   */
  private getIndicatorSegments(count: number): number {
    if (count <= 0) return 0
    if (count >= 8) return 5
    return Math.min(count, 5)
  }
  
  /**
   * 获取指示器颜色
   */
  private getIndicatorColor(count: number): ResourceColor {
    if (count === 0) return '#E0E0E0'
    if (count < 3) return ThemeColors.SUCCESS
    if (count < 6) return ThemeColors.WARNING
    return ThemeColors.DANGER
  }
  
  /**
   * 获取过滤后的邮件列表
   */
  private getFilteredEmails(): EmailData[] {
    let filteredEmails: EmailData[] = this.emails
    
    // 应用搜索过滤
    if (this.searchKeyword && this.searchKeyword.length > 0) {
      const keyword = this.searchKeyword.toLowerCase()
      filteredEmails = filteredEmails.filter((email: EmailData) => {
        return email.from.toLowerCase().includes(keyword) ||
               email.subject.toLowerCase().includes(keyword) ||
               (email.body && email.body.toLowerCase().includes(keyword))
      })
    }
    
    // 应用过滤类型
    if (this.filterType === 'unread') {
      filteredEmails = filteredEmails.filter((email: EmailData) => !email.isRead)
    } else if (this.filterType === 'today') {
      const today = new Date()
      today.setHours(0, 0, 0, 0)
      filteredEmails = filteredEmails.filter((email: EmailData) => {
        const emailDate = new Date(email.receivedTime)
        emailDate.setHours(0, 0, 0, 0)
        return emailDate.getTime() === today.getTime()
      })
    }
    
    return filteredEmails
  }
  
  /**
   * 格式化邮件时间
   */
  private formatEmailTime(date: Date): string {
    const now: Date = new Date()
    const diff: number = now.getTime() - date.getTime()
    const minutes: number = Math.floor(diff / 60000)
    const hours: number = Math.floor(diff / 3600000)
    const days: number = Math.floor(diff / 86400000)
    
    if (days > 0) return `${days}天前`
    if (hours > 0) return `${hours}小时前`
    if (minutes > 0) return `${minutes}分钟前`
    return '刚刚'
  }
  
  // ==================== Builder Methods ====================
  
  @Builder buildIndicatorLines(badgeCount: number): void {
    Row({ space: 2 }) {
      // 渲染线条段（最大5段）
      ForEach(Array.from({ length: this.getIndicatorSegments(badgeCount) }), (item: Object, index: number) => {
        // 每段线条
        Row()
          .width(6)
          .height(3)
          .backgroundColor(this.getIndicatorColor(badgeCount))
          .borderRadius(1.5)
      }, (item: Object, index: number) => `segment-${index}`)
    }
    .margin({ top: 2 })
    .justifyContent(FlexAlign.Center)
  }
  
  @Builder buildInboxPage(): void {
    Column({ space: 16 }) {
      // 页面标题和切换（点击文字切换）
      Row() {
        // 可点击的标题文字
        Column({ space: '0.25rem' }) {
          Text(this.inboxMode === 'inbox' ? this.uiTexts['pageInbox'] : this.uiTexts['pageOutbox'])
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTextPrimaryColor())
            .margin({ top: 0 })
            .onClick(() => {
              // 点击切换模式
              this.inboxMode = this.inboxMode === 'inbox' ? 'outbox' : 'inbox'
            })
          
          // 线条指示器：显示另一个模式的未读数
          if (this.inboxMode === 'inbox' && this.sentEmails.length > 0) {
            // 当前在收件箱，显示发件箱的消息数
            this.buildIndicatorLines(this.sentEmails.length)
          } else if (this.inboxMode === 'outbox' && this.inboxBadgeCount > 0) {
            // 当前在发件箱，显示收件箱的未读数
            this.buildIndicatorLines(this.inboxBadgeCount)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Row({ space: 8 }) {
          if (this.inboxMode === 'inbox') {
            Text(this.uiTexts['inboxAllMailboxes'])
              .fontSize(12)
              .fontColor(this.getTextPrimaryColor())
          
            Button(this.uiTexts['btnCheckNew'])
              .fontSize(12)
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .backgroundColor(this.getPrimaryColor())
              .onClick(() => {
                if (this.onRefreshEmails) {
                  this.onRefreshEmails()
                }
              })
          } else {
            // 发件箱操作按钮
            if (this.isSelectMode) {
              // 批量选择模式下的按钮
              Button(this.uiTexts['btnDeleteSelected'])
                .fontSize(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#FF3B30')
                .enabled(this.selectedSentEmailIds.size > 0)
                .onClick(() => {
                  if (this.onDeleteSelectedSentEmails) {
                    this.onDeleteSelectedSentEmails()
                  }
                })
              
              Button(this.uiTexts['btnCancel'])
                .fontSize(12)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#6c757d')
                .onClick(() => {
                  this.isSelectMode = false
                  this.selectedSentEmailIds.clear()
                })
            } else {
              // 普通模式下的按钮
              Button(this.uiTexts['btnBatchSelect'])
                .fontSize(12)
                .fontColor(Color.White)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor(this.getPrimaryColor())
                .enabled(this.sentEmails.length > 0)
                .onClick(() => this.isSelectMode = true)
              
              Button(this.uiTexts['btnClearAll'])
                .fontSize(12)
                .fontColor(Color.White)
                .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                .backgroundColor('#FF3B30')
                .enabled(this.sentEmails.length > 0)
                .onClick(() => {
                  if (this.onClearAllSentEmails) {
                    this.onClearAllSentEmails()
                  }
                })
            }
          }
        }
      }
      .width('100%')
      .margin({ top: 0 })
      
      // 邮件搜索和过滤栏
      if (this.enableEmailSearch && this.inboxMode === 'inbox') {
        this.buildEmailSearchBar()
      }
      
      // 标签和分类功能已移除
      
      // 根据模式显示不同内容
      if (this.inboxMode === 'inbox') {
        this.buildInboxContent()
      } else {
        this.buildOutboxContent()
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  @Builder buildInboxContent(): void {
    if (this.getFilteredEmails().length === 0) {
      Column() {
        Text(this.searchKeyword && this.searchKeyword.length > 0 ? 
             (this.uiTexts['searchNoResults'] || 'No search results') : 
             this.uiTexts['inboxEmpty'])
          .fontSize(14)
          .fontColor(this.getTextPrimaryColor())
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.getFilteredEmails(), (email: EmailData) => {
          ListItem() {
            this.buildEmailItem(email)
          }
        }, (email: EmailData) => `${email.id}_${this.emailListRefreshKey}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: this.getBorderColor() })
    }
  }
  
  @Builder buildEmailSearchBar(): void {
    Column({ space: 8 }) {
      Row() {
        TextInput({ placeholder: this.uiTexts['searchPlaceholder'] || 'Search emails...' })
          .layoutWeight(1)
          .onChange((value: string) => {
            this.searchKeyword = value
          })
      }
      .width('100%')
      
      if (this.showFilterPanel) {
        Row({ space: 8 }) {
          Button(this.uiTexts['filterAll'] || 'All')
            .fontSize(12)
            .backgroundColor(this.filterType === 'all' ? this.getPrimaryColor() : this.getBackgroundColor())
            .fontColor(this.filterType === 'all' ? Color.White : this.getTextPrimaryColor())
            .onClick(() => this.filterType = 'all')
          
          Button(this.uiTexts['filterUnread'] || 'Unread')
            .fontSize(12)
            .backgroundColor(this.filterType === 'unread' ? this.getPrimaryColor() : this.getBackgroundColor())
            .fontColor(this.filterType === 'unread' ? Color.White : this.getTextPrimaryColor())
            .onClick(() => this.filterType = 'unread')
          
          Button(this.uiTexts['filterToday'] || 'Today')
            .fontSize(12)
            .backgroundColor(this.filterType === 'today' ? this.getPrimaryColor() : this.getBackgroundColor())
            .fontColor(this.filterType === 'today' ? Color.White : this.getTextPrimaryColor())
            .onClick(() => this.filterType = 'today')
        }
      }
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 8 })
  }
  
  @Builder buildTagFilterBar(): void {
    Row() {
      Text(this.uiTexts['labelTags'] || 'Tags:')
        .fontSize(12)
        .margin({ right: 10 })
        .fontColor(this.getTextPrimaryColor())
      
      Button(this.uiTexts['filterAll'] || 'All')
        .fontSize(12)
        .padding(8)
        .backgroundColor(this.filterByTagId === 0 ? this.getPrimaryColor() : this.getBackgroundColor())
        .fontColor(this.filterByTagId === 0 ? Color.White : this.getTextPrimaryColor())
        .borderRadius(4)
        .onClick(() => {
          this.filterByTagId = 0
        })
      
      Text(this.uiTexts['tipTagFiltering'] || '(Tag filtering)')
        .fontSize(10)
        .margin({ left: 10 })
        .fontColor(this.getTextPrimaryColor())
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 8 })
  }
  
  @Builder buildCategoryFilterBar(): void {
    Row() {
      Text(this.uiTexts['labelCategory'] || 'Category:')
        .fontSize(12)
        .margin({ right: 10 })
        .fontColor(this.getTextPrimaryColor())
      
      Button(this.uiTexts['filterAll'] || 'All')
        .fontSize(12)
        .padding(8)
        .backgroundColor(this.filterByCategory === 'all' ? this.getPrimaryColor() : this.getBackgroundColor())
        .fontColor(this.filterByCategory === 'all' ? Color.White : this.getTextPrimaryColor())
        .borderRadius(4)
        .onClick(() => {
          this.filterByCategory = 'all'
        })
      
      Text(this.uiTexts['tipCategoryFiltering'] || '(Category filtering)')
        .fontSize(10)
        .margin({ left: 10 })
        .fontColor(this.getTextPrimaryColor())
    }
    .width('100%')
    .padding({ left: 0, right: 0, top: 0, bottom: 8 })
  }
  
  @Builder buildOutboxContent(): void {
    if (this.sentEmails.length === 0) {
      Column() {
        Text(this.uiTexts['outboxEmpty'] || 'No sent emails')
          .fontSize(14)
          .fontColor(this.getTextPrimaryColor())
      }
      .width('100%')
      .height(200)
      .justifyContent(FlexAlign.Center)
    } else {
      List() {
        ForEach(this.sentEmails, (sentEmail: SentEmailData) => {
          ListItem() {
            this.buildSentEmailItem(sentEmail)
          }
        }, (sentEmail: SentEmailData) => `${sentEmail.id}_${this.sentEmailListRefreshKey}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#E0E0E0' })
    }
  }
  
  @Builder buildSentEmailItem(sentEmail: SentEmailData): void {
    Row() {
      // 选择框（批量选择模式）
      if (this.isSelectMode) {
        Checkbox()
          .select(this.selectedSentEmailIds.has(sentEmail.id))
          .onChange((isChecked: boolean) => {
            if (isChecked) {
              this.selectedSentEmailIds.add(sentEmail.id)
            } else {
              this.selectedSentEmailIds.delete(sentEmail.id)
            }
          })
          .margin({ right: 12 })
      }
      
      Column() {
        Row() {
          Text(`To: ${sentEmail.to}`)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
          Blank()
          Text(this.formatEmailTime(new Date(sentEmail.sentTime)))
            .fontSize(10)
            .fontColor(Color.Gray)
        }
        .width('100%')
        
        Text(sentEmail.subject)
          .fontSize(12)
          .margin({ top: 5 })
        
        Row() {
          Text(`${this.uiTexts['labelStatus'] || 'Status'}: ${sentEmail.success ? this.uiTexts['statusSent'] || 'sent' : this.uiTexts['statusFailed'] || 'failed'}`)
            .fontSize(10)
            .fontColor(sentEmail.success ? Color.Green : Color.Orange)
          
          if (sentEmail.attachments && sentEmail.attachments.length > 0) {
            Text('[Attachment]')
              .fontSize(10)
              .margin({ left: 8 })
          }
        }
        .margin({ top: 5 })
      }
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .onClick(() => {
      if (!this.isSelectMode && this.onSentEmailClick) {
        this.onSentEmailClick(sentEmail)
      }
    })
  }
  
  @Builder buildEmailItem(email: EmailData): void {
    Column() {
      Row() {
        Text(email.from)
          .fontSize(14)
          .fontWeight(email.isRead ? FontWeight.Normal : FontWeight.Bold)
          .layoutWeight(1)
        
        Blank()
        
        Text(this.formatEmailTime(new Date(email.receivedTime)))
          .fontSize(10)
          .fontColor(Color.Gray)
      }
      .width('100%')
      
      Text(email.subject)
        .fontSize(12)
        .margin({ top: 5 })
        .fontColor(email.isRead ? Color.Gray : Color.Black)
      
      if (email.body && email.body.length > 0) {
        Text(email.body.substring(0, 100))
          .fontSize(10)
          .fontColor(Color.Gray)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 5 })
      }
      
      Row() {
        if (email.attachments && email.attachments.length > 0) {
          Text(`📎 ${this.uiTexts['labelAttachments'] || 'Attachments'}`)
            .fontSize(10)
            .fontColor(ThemeColors.SECONDARY)
        }
        
        if (!email.isRead) {
          Text(this.uiTexts['statusNew'] || 'NEW')
            .fontSize(10)
            .fontColor(Color.White)
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor(ThemeColors.DANGER)
            .borderRadius(4)
            .margin({ left: 8 })
        }
      }
      .margin({ top: 5 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor(email.isRead ? Color.White : '#F0F8FF')
    .onClick(() => {
      if (this.onEmailClick) {
        this.onEmailClick(email)
      }
    })
  }
  
  @Builder buildEmailDetailDialog(): void {
    // Dialog will be rendered in parent's Stack overlay
  }
  
  @Builder buildSentEmailDetailDialog(): void {
    // Dialog will be rendered in parent's Stack overlay
  }
  
  @Builder buildImagePreviewDialog(): void {
    // Dialog will be rendered in parent's Stack overlay
  }
  
  // ==================== Main Build Method ====================
  
  build() {
    this.buildInboxPage()
  }
}
