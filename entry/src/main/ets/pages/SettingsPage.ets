/**
 * Settings Page - 设置页面
 * 负责应用设置和配置管理
 */

import { SettingsData, CustomMailboxSettings } from '../common/DataTypes'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { SystemService } from '../common/SystemService'
import { DomainManager } from '../services/DomainManager'
import { QuotaManager } from '../services/QuotaManager'
import { UserEmailConfigManager, ProxyServerConfig } from '../config/UserEmailConfig'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'

@Component
export struct SettingsPage {
  // ==================== Props from Parent ====================
  // Interface settings
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  @Link settingsLanguage: string
  @Link currentLanguage: string
  @Link showLanguageMenu: boolean
  
  // Mailbox settings
  @Link settingsDefaultDomain: string
  @Link settingsAutoCleanup: boolean
  @Link settingsPrefixLength: number
  @Link settingsNewMailboxDelay: number
  
  // Custom mailbox settings
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
  @Link customMailboxSignature: string
  @Link customMailboxReplyTo: string
  @Link customMailboxBccToSelf: boolean
  @Link customMailboxRequestReadReceipt: boolean
  @Link customMailboxPriority: 'high' | 'normal' | 'low'
  @Link customMailboxAutoReplyEnabled: boolean
  @Link customMailboxAutoReplyMessage: string
  @Link customMailboxMaxAttachmentSize: number
  @Link customMailboxConnectionStatus: 'unknown' | 'connected' | 'disconnected' | 'error'
  @Link customMailboxLastTestTime: number
  @Link customMailboxNotes: string
  @Link showCustomMailboxAdvanced: boolean
  
  // Email send settings
  @Link settingsSendMethod: string
  @Link emailjsQuotaUsed: number
  @Link emailjsQuotaTotal: number
  @Link resendQuotaUsed: number
  @Link resendQuotaTotal: number
  @Link proxyEnabled: boolean
  @Link proxyBaseUrl: string
  @Link proxyAuthToken: string
  @Link proxyTimeout: number
  @Link proxyTestResult: string
  
  // Auto-check settings
  @Link settingsAutoCheck: boolean
  @Link settingsCheckInterval: number
  
  // Notification settings
  @Link settingsEmailNotification: boolean
  @Link settingsExpiryNotification: boolean
  @Link settingsDesktopNotification: boolean
  
  // Advanced features
  @Link enableEmailSearch: boolean
  @Link enableTemplates: boolean
  @Link enableFolders: boolean
  @Link enableStatistics: boolean
  
  // Data management
  @Link showExportDialog: boolean
  @Link exportFormat: 'json' | 'txt' | 'html'
  @Link exportMailboxId: number
  
  @Link @Watch('onUITextsChange') uiTexts: Record<string, string>
  
  // Local state
  @State showSendMethodMenu: boolean = false
  @State scrollToSection: string = '' // 用于控制滚动到特定部分
  
  // External service config state
  @State externalEmailJSServiceId: string = ''
  @State externalEmailJSTemplateId: string = ''
  @State externalEmailJSPublicKey: string = ''
  @State externalResendApiKey: string = ''
  @State externalResendFromEmail: string = ''
  @State externalResendFromName: string = ''
  
  // Services
  @Prop i18nService: I18nService
  @Prop systemService: SystemService
  @Prop domainManager: DomainManager
  @Prop quotaManager: QuotaManager
  @Prop emailConfigManager: UserEmailConfigManager
  
  // Callbacks
  onViewRules?: () => void
  
  // ==================== Watch Methods ====================
  
  onUITextsChange(): void {
    // 强制UI重新渲染
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'uiTexts changed, refreshing UI')
  }
  
  /**
   * 获取发送方式的显示文本
   */
  getSendMethodDisplayText(): string {
    const methodMap: Record<string, string> = {
      'custom-smtp': this.uiTexts['sendSmtp'] || 'SMTP Server',
      'emailjs-builtin': this.uiTexts['sendEmailJsBuiltin'] || 'Built-in EmailJS (2/month)',
      'emailjs-external': this.uiTexts['sendEmailJsExternal'] || 'External EmailJS',
      'resend-builtin': this.uiTexts['sendResendBuiltin'] || 'Built-in Resend API (3/month)',
      'resend-external': this.uiTexts['sendResendExternal'] || 'External Resend API'
    }
    return methodMap[this.settingsSendMethod] || this.settingsSendMethod
  }

  /**
   * 获取"配置邮箱服务"按钮的文本，根据配置状态显示不同的文本
   */
  getConfigureServiceButtonText(): string {
    // 检查是否需要配置
    if (this.settingsSendMethod === 'custom-smtp') {
      // SMTP需要检查是否已配置
      if (!this.customMailboxEnabled || !this.customMailboxEmail || !this.customMailboxSmtpHost) {
        return this.uiTexts['btnWaitingConfig'] || 'Waiting for configuration'
      }
    }
    return this.uiTexts['btnConfigureService'] || 'Configure Email Service'
  }

  /**
   * 保存外部EmailJS配置
   */
  async saveExternalEmailJSConfig(): Promise<void> {
    if (!this.externalEmailJSServiceId || !this.externalEmailJSTemplateId || !this.externalEmailJSPublicKey) {
      await this.systemService.showToast(this.uiTexts['tipMissingFields'] || 'Please fill in all required fields')
      return
    }

    try {
      // 保存到emailConfigManager
      if (this.emailConfigManager) {
        const config: Record<string, string> = {}
        config['service_id'] = this.externalEmailJSServiceId
        config['template_id'] = this.externalEmailJSTemplateId
        config['public_key'] = this.externalEmailJSPublicKey
        
        await this.emailConfigManager.saveExternalEmailJSConfig(config)
      }

      await this.systemService.showToast(this.uiTexts['tipSettingsSaved'] || 'Configuration saved successfully')
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'External EmailJS config saved')
    } catch (error) {
      const err = error as Error
      await this.systemService.showToast(this.uiTexts['tipSaveSettingsFailed'] || 'Save failed: ' + err.message)
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Save external EmailJS config error: %{public}s', err.message)
    }
  }

  /**
   * 保存外部Resend配置
   */
  async saveExternalResendConfig(): Promise<void> {
    if (!this.externalResendApiKey || !this.externalResendFromEmail) {
      await this.systemService.showToast(this.uiTexts['tipMissingFields'] || 'Please fill in all required fields')
      return
    }

    try {
      // 保存到emailConfigManager
      if (this.emailConfigManager) {
        const config: Record<string, string> = {}
        config['api_key'] = this.externalResendApiKey
        config['from_email'] = this.externalResendFromEmail
        config['from_name'] = this.externalResendFromName || 'Temporary Mailbox'
        
        await this.emailConfigManager.saveExternalResendConfig(config)
      }

      await this.systemService.showToast(this.uiTexts['tipSettingsSaved'] || 'Configuration saved successfully')
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'External Resend config saved')
    } catch (error) {
      const err = error as Error
      await this.systemService.showToast(this.uiTexts['tipSaveSettingsFailed'] || 'Save failed: ' + err.message)
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Save external Resend config error: %{public}s', err.message)
    }
  }

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
   * 获取动态次背景颜色（根据当前主题）
   */
  getSecondaryBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#1E1E1E'  // 深灰背景
    } else {
      return '#f8f9fa'  // 浅灰背景
    }
  }

  /**
   * 获取动态页面背景颜色（根据当前主题）
   */
  getPageBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#0A0A0A'  // 极深色背景
    } else {
      return '#F5F5F5'  // 浅灰背景
    }
  }

  /**
   * 获取动态卡片背景颜色（根据当前主题）
   */
  getCardBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#1E1E1E'  // 深灰卡片
    } else {
      return '#FFFFFF'  // 白色卡片
    }
  }

  /**
   * 获取动态禁用按钮背景颜色（根据当前主题）
   */
  getDisabledButtonColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#424242'  // 深灰禁用按钮
    } else {
      return '#F0F0F0'  // 浅灰禁用按钮
    }
  }

  /**
   * 获取动态警告颜色（根据当前主题）
   */
  getWarningColor(): string {
    return '#FF6B00'  // 橙色警告（适用于浅色和深色主题）
  }

  /**
   * 获取动态危险颜色（根据当前主题）
   */
  getDangerColor(): string {
    return '#FF3B30'  // 红色危险（适用于浅色和深色主题）
  }
  
  // Callbacks
  onSaveSettings?: () => void
  onResetSettings?: () => void
  onConfigureService?: () => void
  onClearData?: () => void
  onTestConnection?: () => void
  onChangeLanguage?: (lang: string) => void
  
  // ==================== Builder Methods ====================
  
  @Builder buildSettingsPage(): void {
    Scroll() {
      Column() {
        Text(this.uiTexts['pageSettings'] || 'Settings')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .padding(16)
          .fontColor(this.getTextPrimaryColor())
        
        this.buildSettingsSection('interface')
        this.buildSettingsSection('mailbox')
        this.buildSettingsSection('custom_mailbox')
        this.buildSettingsSection('email_send')
        this.buildSettingsSection('auto_check')
        this.buildSettingsSection('notification')
        this.buildSettingsSection('advanced_features')
        this.buildSettingsSection('data_management')
        this.buildSettingsSection('rules')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getPageBackgroundColor())
  }
  
  @Builder buildSettingsSection(sectionId: string): void {
    Column() {
      if (sectionId === 'interface') {
        this.buildInterfaceSettings()
      } else if (sectionId === 'mailbox') {
        this.buildMailboxSettings()
      } else if (sectionId === 'custom_mailbox') {
        this.buildCustomMailboxSettings()
      } else if (sectionId === 'email_send') {
        this.buildEmailSendSettings()
      } else if (sectionId === 'auto_check') {
        this.buildAutoCheckSettings()
      } else if (sectionId === 'notification') {
        this.buildNotificationSettings()
      } else if (sectionId === 'advanced_features') {
        this.buildAdvancedFeaturesSettings()
      } else if (sectionId === 'data_management') {
        this.buildDataManagementSection()
      } else if (sectionId === 'rules') {
        this.buildRulesSection()
      }
    }
    .margin({ bottom: 10 })
  }
  
  @Builder buildInterfaceSettings(): void {
    Column() {
      Text(this.uiTexts['settingsInterface'] || 'Interface Settings')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      // Theme
      Row() {
        Text(this.uiTexts['settingsTheme'] || 'Theme:')
          .fontSize(14)
          .width(120)
          .fontColor(this.getTextPrimaryColor())
        
        Row({ space: 8 }) {
          this.buildThemeOption('light', this.uiTexts['lightTheme'] || 'Light')
          this.buildThemeOption('dark', this.uiTexts['darkTheme'] || 'Dark')
          this.buildThemeOption('auto', this.uiTexts['autoTheme'] || 'Auto')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      
      // Language
      Row() {
        Text(this.uiTexts['settingsLanguage'] || 'Language:')
          .fontSize(14)
          .width(120)
          .fontColor(this.getTextPrimaryColor())
        
        Text(this.currentLanguage)
          .fontSize(14)
          .layoutWeight(1)
          .fontColor(this.getTextPrimaryColor())
        
        Button(this.uiTexts['btnChange'] || 'Change')
          .fontSize(12)
          .onClick(() => {
            this.showLanguageMenu = true
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
      
      // Language selection menu
      if (this.showLanguageMenu) {
        Column({ space: 8 }) {
          Button(this.uiTexts['langChinese'] || '中文 (Chinese)')
            .width('100%')
            .onClick(() => {
              if (this.onChangeLanguage) {
                this.onChangeLanguage('zh-CN')
              }
              this.showLanguageMenu = false
            })
          
          Button(this.uiTexts['langEnglish'] || 'English')
            .width('100%')
            .onClick(() => {
              if (this.onChangeLanguage) {
                this.onChangeLanguage('en-US')
              }
              this.showLanguageMenu = false
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      }
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildThemeOption(value: 'light' | 'dark' | 'auto', label: string): void {
    Text(label)
      .fontSize(12)
      .padding(8)
      .backgroundColor(this.settingsTheme === value ? this.getPrimaryColor() : this.getDisabledButtonColor())
      .fontColor(this.settingsTheme === value ? Color.White : this.getTextPrimaryColor())
      .borderRadius(4)
      .onClick(() => {
        this.settingsTheme = value
        if (this.onSaveSettings) {
          this.onSaveSettings()
        }
      })
  }
  
  @Builder buildMailboxSettings(): void {
    Column() {
      Text(this.uiTexts['settingsMailboxSettings'] || 'Mailbox Settings')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      // Auto cleanup
      Row() {
        Text(this.uiTexts['settingsAutoCleanup'] || 'Auto Cleanup:')
          .fontSize(14)
          .width(140)
          .fontColor(this.getTextPrimaryColor())
        
        Toggle({ type: ToggleType.Switch, isOn: this.settingsAutoCleanup })
          .onChange((isOn: boolean) => {
            this.settingsAutoCleanup = isOn
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      
      // Prefix length
      Row() {
        Text(this.uiTexts['settingsPrefixLength'] || 'Prefix Length:')
          .fontSize(14)
          .width(140)
          .fontColor(this.getTextPrimaryColor())
        
        Slider({
          value: this.settingsPrefixLength,
          min: 4,
          max: 16,
          step: 1
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.settingsPrefixLength = value
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
        
        Text(this.settingsPrefixLength.toString())
          .fontSize(12)
          .width(30)
          .textAlign(TextAlign.End)
          .fontColor(this.getTextPrimaryColor())
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      
      // New mailbox delay
      Row() {
        Text(this.uiTexts['settingsNewMailboxDelay'] || 'New Mailbox Delay (minutes):')
          .fontSize(14)
          .width(140)
          .fontColor(this.getTextPrimaryColor())
        
        Slider({
          value: this.settingsNewMailboxDelay,
          min: 0,
          max: 60,
          step: 5
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.settingsNewMailboxDelay = value
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
        
        Text(this.settingsNewMailboxDelay.toString())
          .fontSize(12)
          .width(30)
          .textAlign(TextAlign.End)
          .fontColor(this.getTextPrimaryColor())
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildCustomMailboxSettings(): void {
    Column() {
      Row() {
        Text(this.uiTexts['customMailbox'] || 'Custom Mailbox')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        Toggle({ type: ToggleType.Switch, isOn: this.customMailboxEnabled })
          .opacity(this.settingsSendMethod === 'custom-smtp' ? 1 : 0.5)
          .onChange((isOn: boolean) => {
            // 只有当发送方式为SMTP时才允许打开开关
            if (this.settingsSendMethod === 'custom-smtp') {
              this.customMailboxEnabled = isOn
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            } else {
              // 如果不是SMTP，显示提示
              this.systemService.showToast(this.uiTexts['tipCustomMailboxRequiresSMTP'] || 'Please select SMTP as send method to enable custom mailbox')
            }
          })
      }
      .width('100%')
      .padding(16)
      
      // 如果发送方式不是SMTP，显示提示信息
      if (this.settingsSendMethod !== 'custom-smtp') {
        Text(this.uiTexts['tipCustomMailboxRequiresSMTP'] || 'Please select SMTP as send method to enable custom mailbox')
          .fontSize(12)
          .fontColor(this.getWarningColor())
          .padding({ left: 16, right: 16, bottom: 10 })
      }
      
      if (this.customMailboxEnabled) {
        Column({ space: 10 }) {
          TextInput({ text: this.customMailboxEmail, placeholder: this.uiTexts['emailPlaceholder'] || 'Email address' })
            .onChange((value: string) => {
              this.customMailboxEmail = value
            })
          
          TextInput({ text: this.customMailboxPassword, placeholder: this.uiTexts['passwordPlaceholder'] || 'Password' })
            .type(InputType.Password)
            .onChange((value: string) => {
              this.customMailboxPassword = value
            })
          
          TextInput({ text: this.customMailboxDisplayName, placeholder: this.uiTexts['displayNamePlaceholder'] || 'Display name' })
            .onChange((value: string) => {
              this.customMailboxDisplayName = value
            })
          
          // Advanced settings toggle
          Row() {
            Text(this.uiTexts['advancedSettings'] || 'Advanced Settings')
              .fontSize(14)
              .fontColor(this.getTextPrimaryColor())
            
            Blank()
            
            Button(this.showCustomMailboxAdvanced ? '▲' : '▼')
              .fontSize(12)
              .onClick(() => {
                this.showCustomMailboxAdvanced = !this.showCustomMailboxAdvanced
              })
          }
          .width('100%')
          
          if (this.showCustomMailboxAdvanced) {
            Column({ space: 10 }) {
              Text(this.uiTexts['smtpSettings'] || 'SMTP Settings')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.getTextPrimaryColor())
              
              TextInput({ text: this.customMailboxSmtpHost, placeholder: this.uiTexts['customMailboxPlaceholderSmtpHost'] || 'SMTP Host' })
                .onChange((value: string) => {
                  this.customMailboxSmtpHost = value
                })
              
              Row() {
                Text(this.uiTexts['labelPort'] || 'Port:')
                  .fontSize(12)
                  .width(60)
                
                TextInput({ text: this.customMailboxSmtpPort.toString() })
                  .type(InputType.Number)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.customMailboxSmtpPort = parseInt(value) || 587
                  })
              }
              
              Row() {
                Text(this.uiTexts['secure'] || 'Secure:')
                  .fontSize(12)
                
                Toggle({ type: ToggleType.Switch, isOn: this.customMailboxSmtpSecure })
                  .onChange((isOn: boolean) => {
                    this.customMailboxSmtpSecure = isOn
                  })
              }
              
              Text(this.uiTexts['imapSettings'] || 'IMAP Settings')
                .fontSize(12)
                .fontWeight(FontWeight.Bold)
                .margin({ top: 10 })
                .fontColor(this.getTextPrimaryColor())
              
              TextInput({ text: this.customMailboxImapHost, placeholder: this.uiTexts['customMailboxPlaceholderImapHost'] || 'IMAP Host' })
                .onChange((value: string) => {
                  this.customMailboxImapHost = value
                })
              
              Row() {
                Text(this.uiTexts['labelPort'] || 'Port:')
                  .fontSize(12)
                  .width(60)
                
                TextInput({ text: this.customMailboxImapPort.toString() })
                  .type(InputType.Number)
                  .layoutWeight(1)
                  .onChange((value: string) => {
                    this.customMailboxImapPort = parseInt(value) || 993
                  })
              }
              
              Row() {
                Text(this.uiTexts['secure'] || 'Secure:')
                  .fontSize(12)
                
                Toggle({ type: ToggleType.Switch, isOn: this.customMailboxImapSecure })
                  .onChange((isOn: boolean) => {
                    this.customMailboxImapSecure = isOn
                  })
              }
              
              Button(this.uiTexts['btnTestConnection'] || 'Test Connection')
                .width('100%')
                .margin({ top: 10 })
                .onClick(() => {
                  if (this.onTestConnection) {
                    this.onTestConnection()
                  }
                })
            }
            .padding(10)
            .backgroundColor(this.getSecondaryBackgroundColor())
            .borderRadius(4)
          }
        }
        .padding({ left: 16, right: 16, bottom: 16 })
      }
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildEmailSendSettings(): void {
    Column() {
      Text(this.uiTexts['emailSendSettings'] || 'Email Send Settings')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      // Send method
      Row() {
        Text(this.uiTexts['sendMethod'] || 'Send Method:')
          .fontSize(14)
          .width(140)
          .fontColor(this.getTextPrimaryColor())
        
        Button(this.getSendMethodDisplayText())
          .fontSize(12)
          .layoutWeight(1)
          .height(36)
          .onClick(() => {
            this.showSendMethodMenu = true
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      
      // Send method selection menu
      if (this.showSendMethodMenu) {
        Column({ space: 8 }) {
          Button(this.uiTexts['sendSmtp'] || 'SMTP Server')
            .width('100%')
            .onClick(() => {
              this.settingsSendMethod = 'custom-smtp'
              this.showSendMethodMenu = false
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
          
          Button(this.uiTexts['sendEmailJsBuiltin'] || 'Built-in EmailJS (2/month)')
            .width('100%')
            .onClick(() => {
              this.settingsSendMethod = 'emailjs-builtin'
              this.showSendMethodMenu = false
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
          
          Button(this.uiTexts['sendEmailJsExternal'] || 'External EmailJS')
            .width('100%')
            .onClick(() => {
              this.settingsSendMethod = 'emailjs-external'
              this.showSendMethodMenu = false
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
          
          Button(this.uiTexts['sendResendBuiltin'] || 'Built-in Resend API (3/month)')
            .width('100%')
            .onClick(() => {
              this.settingsSendMethod = 'resend-builtin'
              this.showSendMethodMenu = false
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
          
          Button(this.uiTexts['sendResendExternal'] || 'External Resend API')
            .width('100%')
            .onClick(() => {
              this.settingsSendMethod = 'resend-external'
              this.showSendMethodMenu = false
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      }
      
      // 根据发送方式动态显示配置
      if (this.settingsSendMethod === 'custom-smtp') {
        // 自定义SMTP - 显示自定义邮箱配置选项
        Text(this.uiTexts['customMailbox'] || 'Custom Mailbox Configuration')
          .fontSize(12)
          .fontColor(this.getTextPrimaryColor())
          .padding({ left: 16, right: 16, top: 10 })
      } else if (this.settingsSendMethod === 'emailjs-builtin') {
        // 内置EmailJS - 显示配额信息
        this.buildEmailJSQuota()
      } else if (this.settingsSendMethod === 'emailjs-external') {
        // 外部EmailJS - 显示配置界面
        this.buildExternalEmailJSConfig()
      } else if (this.settingsSendMethod === 'resend-builtin') {
        // 内置Resend - 显示配额信息
        this.buildResendQuota()
      } else if (this.settingsSendMethod === 'resend-external') {
        // 外部Resend - 显示配置界面
        this.buildExternalResendConfig()
      }
      
      // Email service config button - 根据配置状态显示不同的文本
      Button(this.getConfigureServiceButtonText())
        .width('90%')
        .margin({ top: 10, bottom: 10 })
        .onClick(() => {
          if (this.onConfigureService) {
            this.onConfigureService()
          }
        })
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildEmailJSQuota(): void {
    Column() {
      Row() {
        Text(this.uiTexts['emailjsQuota'] || 'EmailJS Quota:')
          .fontSize(12)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        Text(`${this.emailjsQuotaUsed}/${this.emailjsQuotaTotal}`)
          .fontSize(12)
          .fontColor(this.emailjsQuotaUsed >= this.emailjsQuotaTotal ? this.getWarningColor() : this.getTextPrimaryColor())
      }
      .width('100%')
      
      Progress({ value: this.emailjsQuotaUsed, total: this.emailjsQuotaTotal })
        .width('100%')
        .margin({ top: 5 })
        .color(this.emailjsQuotaUsed >= this.emailjsQuotaTotal ? this.getWarningColor() : this.getPrimaryColor())
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildResendQuota(): void {
    Column() {
      Row() {
        Text(this.uiTexts['resendQuota'] || 'Resend Quota:')
          .fontSize(12)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        Text(`${this.resendQuotaUsed}/${this.resendQuotaTotal}`)
          .fontSize(12)
          .fontColor(this.resendQuotaUsed >= this.resendQuotaTotal ? this.getWarningColor() : this.getTextPrimaryColor())
      }
      .width('100%')
      
      Progress({ value: this.resendQuotaUsed, total: this.resendQuotaTotal })
        .width('100%')
        .margin({ top: 5 })
        .color(this.resendQuotaUsed >= this.resendQuotaTotal ? this.getWarningColor() : this.getPrimaryColor())
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildExternalEmailJSConfig(): void {
    Column() {
      Text(this.uiTexts['externalEmailJSConfig'] || 'External EmailJS Configuration')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      
      Text(this.uiTexts['tipConfigureEmailJS'] || 'Please enter your EmailJS credentials')
        .fontSize(12)
        .fontColor(this.getTextPrimaryColor())
        .opacity(0.7)
        .padding({ left: 16, right: 16, bottom: 10 })
      
      // Service ID输入框
      TextInput({ text: this.externalEmailJSServiceId, placeholder: this.uiTexts['placeholderServiceId'] || 'Service ID' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalEmailJSServiceId = value
        })
      
      // Template ID输入框
      TextInput({ text: this.externalEmailJSTemplateId, placeholder: this.uiTexts['placeholderTemplateId'] || 'Template ID' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalEmailJSTemplateId = value
        })
      
      // Public Key输入框
      TextInput({ text: this.externalEmailJSPublicKey, placeholder: this.uiTexts['placeholderPublicKey'] || 'Public Key' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalEmailJSPublicKey = value
        })
      
      // 保存按钮
      Button(this.uiTexts['btnSave'] || 'Save Configuration')
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .onClick(() => {
          this.saveExternalEmailJSConfig()
        })
    }
    .width('100%')
    .padding({ bottom: 10 })
  }
  
  @Builder buildExternalResendConfig(): void {
    Column() {
      Text(this.uiTexts['externalResendConfig'] || 'External Resend Configuration')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())
        .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      
      Text(this.uiTexts['tipConfigureResend'] || 'Please enter your Resend API key')
        .fontSize(12)
        .fontColor(this.getTextPrimaryColor())
        .opacity(0.7)
        .padding({ left: 16, right: 16, bottom: 10 })
      
      // API Key输入框
      TextInput({ text: this.externalResendApiKey, placeholder: this.uiTexts['placeholderApiKey'] || 'API Key' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalResendApiKey = value
        })
      
      // From Email输入框
      TextInput({ text: this.externalResendFromEmail, placeholder: this.uiTexts['placeholderFromEmail'] || 'From Email' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalResendFromEmail = value
        })
      
      // From Name输入框
      TextInput({ text: this.externalResendFromName, placeholder: this.uiTexts['placeholderFromName'] || 'From Name (Optional)' })
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .padding(8)
        .backgroundColor(this.getCardBackgroundColor())
        .fontColor(this.getTextPrimaryColor())
        .placeholderColor(this.getTextPrimaryColor())
        .border({ width: 1, color: this.getPrimaryColor(), radius: 4 })
        .onChange((value: string) => {
          this.externalResendFromName = value
        })
      
      // 保存按钮
      Button(this.uiTexts['btnSave'] || 'Save Configuration')
        .width('90%')
        .margin({ bottom: 10, left: 16, right: 16 })
        .onClick(() => {
          this.saveExternalResendConfig()
        })
    }
    .width('100%')
    .padding({ bottom: 10 })
  }

  @Builder buildEmailServiceConfig(): void {
    Column() {
      Text(this.uiTexts['emailServiceConfig'] || 'Email Service Configuration')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .fontColor(this.getTextPrimaryColor())
      
      Text(this.uiTexts['configPlaceholder'] || 'Configure your email service provider settings here')
        .fontSize(12)
        .fontColor(this.getTextPrimaryColor())
    }
    .padding(16)
  }
  
  @Builder buildAutoCheckSettings(): void {
    Column() {
      Text(this.uiTexts['settingsAutoCheck'] || 'Auto Check Settings')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      Row() {
        Text(this.uiTexts['settingsEnableAutoCheck'] || 'Enable Auto Check:')
          .fontSize(14)
          .width(160)
          .fontColor(this.getTextPrimaryColor())
        
        Toggle({ type: ToggleType.Switch, isOn: this.settingsAutoCheck })
          .onChange((isOn: boolean) => {
            this.settingsAutoCheck = isOn
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 10 })
      
      if (this.settingsAutoCheck) {
        Row() {
          Text(this.uiTexts['settingsCheckInterval'] || 'Check Interval (min):')
            .fontSize(14)
            .width(160)
            .fontColor(this.getTextPrimaryColor())
          
          Slider({
            value: this.settingsCheckInterval,
            min: 5,
            max: 120,
            step: 5
          })
            .layoutWeight(1)
            .onChange((value: number) => {
              this.settingsCheckInterval = value
              if (this.onSaveSettings) {
                this.onSaveSettings()
              }
            })
          
          Text(this.settingsCheckInterval.toString())
            .fontSize(12)
            .width(40)
            .textAlign(TextAlign.End)
            .fontColor(this.getTextPrimaryColor())
        }
        .width('100%')
        .padding({ left: 16, right: 16 })
      }
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildNotificationSettings(): void {
    Column() {
      Text(this.uiTexts['notificationSettings'] || 'Notification Settings')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      Row() {
        Text(this.uiTexts['emailNotification'] || 'Email Notifications:')
          .fontSize(14)
          .layoutWeight(1)
          .fontColor(this.getTextPrimaryColor())
        
        Toggle({ type: ToggleType.Switch, isOn: this.settingsEmailNotification })
          .onChange((isOn: boolean) => {
            this.settingsEmailNotification = isOn
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, bottom: 10 })
      
      Row() {
        Text(this.uiTexts['expiryNotification'] || 'Expiry Notifications:')
          .fontSize(14)
          .layoutWeight(1)
          .fontColor(this.getTextPrimaryColor())
        
        Toggle({ type: ToggleType.Switch, isOn: this.settingsExpiryNotification })
          .onChange((isOn: boolean) => {
            this.settingsExpiryNotification = isOn
            if (this.onSaveSettings) {
              this.onSaveSettings()
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16, bottom: 10 })
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildAdvancedFeaturesSettings(): void {
    Column() {
      Text(this.uiTexts['advancedFeatures'] || 'Advanced Features')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .padding(16)
        .fontColor(this.getTextPrimaryColor())
      
      this.buildFeatureToggle(this.uiTexts['featureEmailSearch'] || 'Email Search', this.enableEmailSearch, (value: boolean) => {
        this.enableEmailSearch = value
      })
      
      this.buildFeatureToggle(this.uiTexts['featureTemplates'] || 'Templates', this.enableTemplates, (value: boolean) => {
        this.enableTemplates = value
      })
      
      this.buildFeatureToggle(this.uiTexts['featureFolders'] || 'Folders', this.enableFolders, (value: boolean) => {
        this.enableFolders = value
      })
      
      this.buildFeatureToggle(this.uiTexts['featureStatistics'] || 'Statistics', this.enableStatistics, (value: boolean) => {
        this.enableStatistics = value
      })
      
      // 已移除的功能：标签、自动分类、数据可视化、高级备份、浮动按钮
    }
    .backgroundColor(this.getCardBackgroundColor())
    .borderRadius(8)
    .margin({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildFeatureToggle(label: string, value: boolean, onChange: (value: boolean) => void): void {
    Row() {
      Text(label)
        .fontSize(14)
        .layoutWeight(1)
        .fontColor(this.getTextPrimaryColor())
      
      Toggle({ type: ToggleType.Switch, isOn: value })
        .onChange(onChange)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16, bottom: 10 })
  }
  
  @Builder buildDataManagementSection(): void {
    Button(this.uiTexts['btnClearAllData'] || 'Clear All Data')
      .width('90%')
      .backgroundColor(this.getDangerColor())
      .fontColor(Color.White)
      .margin({ left: 16, right: 16, bottom: 10 })
      .onClick(async () => {
        const confirm: boolean = await this.systemService.showConfirm(
          this.uiTexts['confirmClearData'] || 'Clear All Data',
          this.uiTexts['confirmClearDataMessage'] || 'This will delete all your data. Are you sure?'
        )
        if (confirm && this.onClearData) {
          this.onClearData()
        }
      })
  }
  
  @Builder buildRulesSection(): void {
    Button(this.uiTexts['btnViewRules'] || 'View Rules & Limitations')
      .width('90%')
      .backgroundColor(this.getPrimaryColor())
      .fontColor(Color.White)
      .margin({ left: 16, right: 16, bottom: 10 })
      .onClick(() => {
        if (this.onViewRules) {
          this.onViewRules()
        }
      })
  }
  
  // ==================== Main Build Method ====================
  
  build() {
    this.buildSettingsPage()
  }
}
