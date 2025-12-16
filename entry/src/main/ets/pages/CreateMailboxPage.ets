/**
 * Create Mailbox Page - 生成邮箱页面
 * 负责随机生成和自定义邮箱地址
 */

import { MailboxData, CustomMailboxSettings } from '../common/DataTypes'
import { MailboxManager } from '../common/MailboxManager'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { DomainManager } from '../services/DomainManager'
import { SystemService } from '../common/SystemService'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'

@Component
export struct CreateMailboxPage {
  // ==================== Props from Parent ====================
  @Link currentMailbox: MailboxData | null
  @Link createMode: 'random' | 'custom'
  @Link selectedDuration: number
  @Link customPrefix: string
  @Link selectedDomain: string
  @Link selectedDomainIndex: number
  @Link customMailboxEnabled: boolean
  @Link customMailboxEmail: string
  @Link customMailboxPassword: string
  @Link customMailboxDisplayName: string
  @Link customMailboxProvider: string
  @Link customMailboxSmtpHost: string
  @Link customMailboxSmtpPort: number
  @Link customMailboxSmtpSecure: boolean
  @Link customMailboxImapHost: string
  @Link customMailboxImapPort: number
  @Link customMailboxImapSecure: boolean
  @Link showCustomMailboxConfig: boolean
  @Link showCustomMailboxDialog: boolean
  @Link showCustomDaysDialog: boolean
  @Link customDaysInput: string
  @Link customDaysType: 'extend' | 'reduce'
  @Link uiTexts: Record<string, string>
  @Link mailboxListRefreshKey: number
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  @Link settingsPrefixLength: number
  
  // Services
  @Prop mailboxManager: MailboxManager
  @Prop i18nService: I18nService
  @Prop domainManager: DomainManager
  @Prop systemService: SystemService
  
  // Callbacks
  onCreateMailbox?: () => void
  onSaveSettings?: () => void
  onRefreshUI?: () => void
  onNavigateToSettings?: () => void
  onDisableCustomMailbox?: () => void
  
  // ==================== Helper Methods ====================
  
  /**
   * 获取动态主色调（根据当前主题）
   */
  getPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#64B5F6'  // 浅蓝色（深色主题）
    } else if (this.settingsTheme === 'light') {
      return '#1976D2'  // 深蓝色（浅色主题）
    } else {
      return '#2196F3'  // 默认蓝色
    }
  }

  /**
   * 获取动态文本颜色（根据当前主题）
   */
  getTextPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#FFFFFF'  // 白色文本（深色主题）
    } else {
      return '#212529'  // 深灰文本（浅色主题）
    }
  }

  /**
   * 获取动态背景颜色（根据当前主题）
   */
  getBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#121212'  // 深色背景
    } else {
      return '#FFFFFF'  // 白色背景
    }
  }

  /**
   * 检查自定义邮箱是否配置完整
   */
  private isCustomMailboxFullyConfigured(): boolean {
    return this.customMailboxEmail.length > 0 &&
           this.customMailboxPassword.length > 0 &&
           this.customMailboxSmtpHost.length > 0 &&
           this.customMailboxImapHost.length > 0
  }
  
  /**
   * 获取邮箱服务商显示文本
   */
  private getProviderDisplayText(): string {
    if (this.customMailboxProvider === 'gmail') {
      return 'Gmail'
    } else if (this.customMailboxProvider === 'outlook') {
      return 'Outlook'
    } else if (this.customMailboxProvider === 'yahoo') {
      return 'Yahoo'
    } else if (this.customMailboxProvider === 'qq') {
      return 'QQ邮箱'
    } else if (this.customMailboxProvider === '163') {
      return '163邮箱'
    } else if (this.customMailboxProvider === 'custom') {
      return this.uiTexts['customMailboxProviderCustom'] || '自定义'
    } else {
      return this.customMailboxProvider
    }
  }
  
  /**
   * 复制当前邮箱地址
   */
  private async copyCurrentEmail(): Promise<void> {
    if (this.currentMailbox) {
      const success: boolean = await this.systemService.copyToClipboard(this.currentMailbox.email)
      if (success) {
        await this.systemService.showToast(this.uiTexts['tipCopySuccess'])
      }
    }
  }
  
  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
  }
  
  /**
   * 获取域名显示选项
   */
  private getDomainDisplayOptions(): SelectOption[] {
    const domainOpts = this.domainManager.getDomainSelectOptions()
    const options: SelectOption[] = []
    for (const opt of domainOpts) {
      const option: SelectOption = { value: opt.text }
      options.push(option)
    }
    return options
  }
  
  /**
   * 获取当前选中域名的显示文本
   */
  private getSelectedDomainDisplayText(): string {
    const options = this.domainManager.getDomainSelectOptions()
    if (this.selectedDomainIndex >= 0 && this.selectedDomainIndex < options.length) {
      return options[this.selectedDomainIndex].text
    }
    return ''
  }
  
  // ==================== Builder Methods ====================
  
  @Builder buildCreatePage(): void {
    Column({ space: 16 }) {
      // 页面标题
      Text(this.uiTexts['pageCreateTitle'])
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 0 })
      
      Text(this.uiTexts['createDescription'])
        .fontSize('0.875rem')
        .fontColor(this.getTextPrimaryColor())
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: -8 })
      
      // 自定义邮箱状态卡片（如果已启用）
      if (this.customMailboxEnabled) {
        this.buildCustomMailboxInfoCard()
      }
      
      // 创建方式选择
      Row({ space: 12 }) {
        this.buildCreateModeCard('random', this.uiTexts['createModeRandom'], this.uiTexts['createDescRandom'])
        this.buildCreateModeCard('custom', this.uiTexts['createModeCustom'], this.uiTexts['createDescCustom'])
      }
      .width('100%')
      
      // 当前邮箱显示
      if (this.currentMailbox) {
        this.buildCurrentMailboxDisplay()
      }
      
      // 自定义输入区域
      if (this.createMode === 'custom') {
        this.buildCustomInputArea()
      }
      
      // 有效期选择
      this.buildDurationSelector()
      
      // 生成按钮
      if (this.customMailboxEnabled) {
        // 自定义邮箱已启用，显示禁用提示
        Column({ space: 12 }) {
          Button(this.uiTexts['btnGenerateRandom'])
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor('#CCCCCC')
            .opacity(0.6)
            .enabled(false)
          
          Column({ space: 8 }) {
            Text(this.uiTexts['customMailboxEnabledTip'])
              .fontSize(13)
              .fontColor(this.getPrimaryColor())
              .textAlign(TextAlign.Center)
              .width('100%')
            
            Button(this.uiTexts['customMailboxGoSettings'])
              .fontSize('0.875rem')
              .height(36)
              .backgroundColor(this.getPrimaryColor())
              .onClick(() => {
                if (this.onSaveSettings) {
                  this.onSaveSettings()
                }
              })
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.settingsTheme === 'dark' ? '#1E3A5F' : '#E3F2FD')
          .borderRadius(8)
        }
        .width('100%')
      } else {
        // 未启用自定义邮箱，正常显示生成按钮
        Button(this.createMode === 'random' ? this.uiTexts['btnGenerateRandom'] : this.uiTexts['btnGenerateCustom'])
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .backgroundColor(ThemeColors.PRIMARY)
          .onClick(() => {
            if (this.onCreateMailbox) {
              this.onCreateMailbox()
            }
          })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 0, bottom: 12 })
  }
  
  @Builder buildCustomMailboxInfoCard(): void {
    Column({ space: 12 }) {
      // 标题和图标
      Row({ space: 8 }) {
        Text(this.isCustomMailboxFullyConfigured() ? 
          this.uiTexts['customMailboxActiveTitle'] : 
          this.uiTexts['customMailboxNotConfigured'])
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.isCustomMailboxFullyConfigured() ? ThemeColors.SUCCESS : ThemeColors.WARNING)
          .layoutWeight(1)
        
        Button(this.uiTexts['customMailboxGoSettings'])
          .fontSize(12)
          .height(28)
          .padding({ left: 12, right: 12, top: 0, bottom: 0 })
          .backgroundColor(ThemeColors.PRIMARY)
          .onClick(() => {
            if (this.onNavigateToSettings) {
              this.onNavigateToSettings()
            }
          })
      }
      .width('100%')
      
      // 描述信息
      Text(this.isCustomMailboxFullyConfigured() ? 
        this.uiTexts['customMailboxActiveDesc'] : 
        this.uiTexts['customMailboxNotConfiguredDesc'])
        .fontSize(13)
        .fontColor(ThemeColors.TEXT_SECONDARY)
        .lineHeight(20)
        .width('100%')
      
      // 如果完整配置，显示当前邮箱信息
      if (this.isCustomMailboxFullyConfigured()) {
        Divider()
          .color(ThemeColors.BORDER_LIGHT)
        
        Column({ space: 8 }) {
          // 邮箱地址
          Row({ space: 8 }) {
            Text(this.uiTexts['customMailboxActiveCurrent'])
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(ThemeColors.TEXT_SECONDARY)
            
            Text(this.customMailboxEmail)
              .fontSize('0.875rem')
              .fontWeight(FontWeight.Bold)
              .fontColor(ThemeColors.SUCCESS)
              .fontFamily('monospace')
              .layoutWeight(1)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            
            Button(this.uiTexts['btnCopy'])
              .fontSize(11)
              .height(24)
              .padding({ left: 10, right: 10, top: 0, bottom: 0 })
              .backgroundColor(ThemeColors.SUCCESS)
              .onClick(() => {
                this.systemService.copyToClipboard(this.customMailboxEmail)
                this.systemService.showToast(this.uiTexts['tipCopySuccess'])
              })
          }
          .width('100%')
          
          // 服务商信息
          Row({ space: 4 }) {
            Text(`${this.getProviderDisplayText()} • SMTP: ${this.customMailboxSmtpHost} • IMAP: ${this.customMailboxImapHost}`)
              .fontSize(11)
              .fontColor(ThemeColors.TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .width('100%')
        }
        .width('100%')
        
        Divider()
          .color(ThemeColors.BORDER_LIGHT)
        
        // 提示信息
        Text(this.uiTexts['customMailboxActiveNote'])
          .fontSize(12)
          .fontColor(ThemeColors.INFO)
          .lineHeight(18)
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.isCustomMailboxFullyConfigured() ? '#E8F5E9' : '#FFF3E0')
    .borderRadius(12)
    .border({
      width: 2,
      color: this.isCustomMailboxFullyConfigured() ? ThemeColors.SUCCESS : ThemeColors.WARNING
    })
  }
  
  @Builder buildCreateModeCard(mode: 'random' | 'custom', title: string, desc: string): void {
    // 启用自定义邮箱后，禁用临时邮箱生成选项
    Column({ space: 8 }) {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.customMailboxEnabled ? '#999999' : 
          (this.createMode === mode ? ThemeColors.PRIMARY : ThemeColors.TEXT_PRIMARY))
      
      Text(desc)
        .fontSize(12)
        .fontColor(this.customMailboxEnabled ? '#AAAAAA' : ThemeColors.TEXT_SECONDARY)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      
      // 禁用状态指示
      if (this.customMailboxEnabled) {
        Text(this.uiTexts['customMailboxEnabledIndicator'] || '(自定义邮箱已启用)')
          .fontSize(10)
          .fontColor(ThemeColors.WARNING)
          .fontStyle(FontStyle.Italic)
      }
    }
    .layoutWeight(1)
    .padding(16)
    .backgroundColor(this.customMailboxEnabled ? '#F5F5F5' : 
      (this.createMode === mode ? '#E3F2FD' : Color.White))
    .borderRadius(12)
    .border({
      width: 2,
      color: this.customMailboxEnabled ? '#CCCCCC' : 
        (this.createMode === mode ? ThemeColors.PRIMARY : ThemeColors.BORDER_LIGHT)
    })
    .opacity(this.customMailboxEnabled ? 0.5 : 1.0)
    .onClick(() => {
      if (!this.customMailboxEnabled) {
        this.createMode = mode
      }
    })
  }
  
  @Builder buildCurrentMailboxDisplay(): void {
    Column({ space: 12 }) {
      Row() {
        Text(this.uiTexts['labelCurrentMailbox'])
          .fontSize('0.875rem')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        
        Button(this.uiTexts['btnCopy'])
          .fontSize(12)
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .backgroundColor(ThemeColors.PRIMARY)
          .onClick(() => this.copyCurrentEmail())
      }
      .width('100%')
      
      Text(this.currentMailbox !== null ? this.currentMailbox.email : this.uiTexts['tipNoMailbox'])
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(ThemeColors.PRIMARY)
        .fontFamily('monospace')
        .width('100%')
      
      Row() {
        Text(`${this.uiTexts['labelExpiryDate']}${this.currentMailbox !== null ? this.formatDate(new Date(this.currentMailbox.expiryTime)) : '-'}`)
          .fontSize(12)
          .fontColor(ThemeColors.TEXT_SECONDARY)
      }
      .width('100%')
      
      // 域名支持提示
      Row({ space: 8 }) {
        if (this.currentMailbox !== null && this.domainManager.hasAPISupport(this.currentMailbox.domain)) {
          Text(this.uiTexts['createCanReceive'])
            .fontSize(12)
            .fontColor(ThemeColors.SUCCESS)
        } else if (this.currentMailbox !== null) {
          Column({ space: '0.25rem' }) {
            Text(this.uiTexts['createAddressOnly'])
              .fontSize(12)
              .fontColor(ThemeColors.WARNING)
            Text(this.uiTexts['createManualCheck'].replace('{domain}', this.currentMailbox.domain))
              .fontSize(11)
              .fontColor(ThemeColors.TEXT_SECONDARY)
          }
          .alignItems(HorizontalAlign.Start)
        }
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#E3F2FD')
    .borderRadius(12)
  }
  
  @Builder buildCustomInputArea(): void {
    Column({ space: 12 }) {
      Text(this.uiTexts['labelPrefix'])
        .fontSize('0.875rem')
        .fontWeight(FontWeight.Medium)
      
      TextInput({ placeholder: this.uiTexts['placeholderPrefix'] })
        .height(44)
        .onChange((value: string) => {
          this.customPrefix = value
        })
      
      Text(this.uiTexts['labelDomain'])
        .fontSize('0.875rem')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 8 })
      
      Select(this.getDomainDisplayOptions())
        .height(44)
        .selected(this.selectedDomainIndex)
        .value(this.getSelectedDomainDisplayText())
        .id('domain-select-' + this.uiTexts['currentLanguage'])
        .onSelect((index: number, value: string) => {
          this.selectedDomainIndex = index
          // 从显示文本反查域名
          const options = this.domainManager.getDomainSelectOptions()
          const found = options.find(opt => opt.text === value)
          if (found) {
            this.selectedDomain = found.value
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
              `域名选择: ${value} -> ${found.value}`)
          }
        })
    }
    .width('100%')
  }
  
  @Builder buildDurationSelector(): void {
    Column({ space: 12 }) {
      Text(this.uiTexts['labelDurationTitle'])
        .fontSize('0.875rem')
        .fontWeight(FontWeight.Medium)
      
      // 第一行：常用选项
      Row({ space: 8 }) {
        this.buildDurationButton(this.uiTexts['duration7Days'], 7)
        this.buildDurationButton(this.uiTexts['duration1Month'], 30)
        this.buildDurationButton(this.uiTexts['duration6Months'], 180)
      }
      .width('100%')
      
      // 第二行：长期选项
      Row({ space: 8 }) {
        this.buildDurationButton(this.uiTexts['duration1Year'], 365)
        this.buildDurationButton(this.uiTexts['durationForever'], 36500)
        this.buildDurationButton(this.uiTexts['durationCustom'], -1)
      }
      .width('100%')
      
      // 自定义输入
      if (this.selectedDuration === -1) {
        TextInput({ placeholder: this.uiTexts['labelDurationCustom'] })
          .type(InputType.Number)
          .height(44)
          .onChange((value: string) => {
            const days: number = parseInt(value)
            if (!isNaN(days) && days >= 1 && days <= 36500) {
              this.selectedDuration = days
            }
          })
      }
    }
    .width('100%')
  }
  
  @Builder buildDurationButton(label: string, duration: number): void {
    Button(label)
      .layoutWeight(1)
      .fontSize('0.875rem')
      .backgroundColor(this.selectedDuration === duration ? ThemeColors.PRIMARY : Color.White)
      .fontColor(this.selectedDuration === duration ? Color.White : ThemeColors.TEXT_PRIMARY)
      .border({
        width: 1,
        color: this.selectedDuration === duration ? ThemeColors.PRIMARY : ThemeColors.BORDER_LIGHT
      })
      .onClick(() => {
        this.selectedDuration = duration
      })
  }
  
  @Builder buildCustomMailboxCard(): void {
    Column({ space: 8 }) {
      // 标题行
      Row() {
        Text(this.uiTexts['customMailboxCardTitle'] || '[自定义] 自定义邮箱')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2196F3')
        
        Blank()
        
        Text(this.uiTexts['customMailboxCardEnabled'] || '已启用')
          .fontSize(12)
          .fontColor('#FFFFFF')
          .padding({ left: 8, right: 8, top: 2, bottom: 2 })
          .backgroundColor('#2196F3')
          .borderRadius(12)
      }
      .width('100%')
      
      // 邮箱地址
      Row() {
        Text(this.customMailboxEmail)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 状态指示
        Circle({ width: 8, height: 8 })
          .fill('#4CAF50')
          .margin({ right: 8 })
        
        Text(this.uiTexts['customMailboxCardConnected'] || '已连接')
          .fontSize(12)
          .fontColor('#4CAF50')
      }
      .width('100%')
      
      // 配置信息
      Row({ space: 16 }) {
        Column({ space: 4 }) {
          Text(this.uiTexts['customMailboxCardSend'] || '发送')
            .fontSize(11)
            .fontColor('#999999')
          Text(`SMTP ${this.customMailboxSmtpHost}:${this.customMailboxSmtpPort}`)
            .fontSize(11)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        
        Column({ space: 4 }) {
          Text(this.uiTexts['customMailboxCardReceive'] || '接收')
            .fontSize(11)
            .fontColor('#999999')
          Text(`IMAP ${this.customMailboxImapHost}:${this.customMailboxImapPort}`)
            .fontSize(11)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
      }
      .width('100%')
      
      // 功能说明
      Text(this.uiTexts['customMailboxCardNote'] || '支持附件发送 | 真实邮箱 | 注意：SMTP/IMAP需服务器支持')
        .fontSize(11)
        .fontColor('#FF9800')
        .width('100%')
      
      // 操作按钮
      Row({ space: 8 }) {
        Button(this.uiTexts['btnViewConfig'] || '查看配置')
          .layoutWeight(1)
          .fontSize(12)
          .height(32)
          .backgroundColor('#2196F3')
          .onClick(() => {
            // 跳转到设置页面
            if (this.onNavigateToSettings) {
              this.onNavigateToSettings()
            }
            // 展开自定义邮箱配置
            this.showCustomMailboxConfig = true
          })
        
        Button(this.uiTexts['btnDisable'] || '禁用')
          .layoutWeight(1)
          .fontSize(12)
          .height(32)
          .backgroundColor('#FF5722')
          .onClick(async () => {
            const confirm: boolean = await this.systemService.showConfirm(
              this.uiTexts['customMailboxDisableTitle'] || '禁用自定义邮箱',
              this.uiTexts['customMailboxDisableConfirm'] || '禁用后将无法使用自定义邮箱发送带附件的邮件，确认禁用吗？'
            )
            if (confirm) {
              this.customMailboxEnabled = false
              if (this.onDisableCustomMailbox) {
                this.onDisableCustomMailbox()
              }
              await this.systemService.showToast(this.uiTexts['tipCustomMailboxDisabled'])
              // 刷新页面
              this.mailboxListRefreshKey++
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#E3F2FD')
    .borderRadius(12)
    .margin({ bottom: 12 })
    .border({ width: 2, color: '#2196F3' })
  }
  
  // ==================== Main Build Method ====================
  
  build() {
    Scroll() {
      Column() {
        this.buildCreatePage()
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getBackgroundColor())
    .align(Alignment.TopStart)
  }
}
