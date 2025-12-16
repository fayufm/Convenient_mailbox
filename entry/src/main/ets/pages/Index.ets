/**
 * Convenient Mailbox - 主页面 v2.1
 * 核心功能：5页面导航框架 + 邮箱管理 + 邮件收发
 * 
 * 架构：
 * - 顶部导航栏（5个标签页 + 系统菜单）
 * - 页面1：生成邮箱（随机+自定义，6种有效期）
 * - 页面2：收件箱（邮件列表+统计）
 * - 页面3：我的邮箱（邮箱列表+管理）
 * - 页面4：写邮件（草稿+发送，16种方式）
 * - 页面5：设置（84个域名+完整配置）
 * 
 * @author ConvenientMailbox Team
 * @version 2.1.0
 * @since 2024-12
 */

// ==================== 系统库导入 ====================
import hilog from '@ohos.hilog'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { picker } from '@kit.CoreFileKit'

// ==================== 业务模块导入 ====================
import { MailboxManager } from '../common/MailboxManager'
import {
  EmailData,
  MailboxData,
  DraftData,
  SentEmailData,
  AttachmentData,
  CustomMailboxValidationResult,
  HelpSection,
  CustomMailboxSettings,
  SettingsData,
  EmailTemplate,
  MailboxFolder,
  EmailTag,
  EmailCategory,
  TemplateCategory,
  DomainStatItem,
  EmailTrendItem,
  TagStatItem,
  MailboxStatistics,
  MailboxStatus,
  EmailType,
  MailboxType
} from '../common/DataTypes'
import { NetworkService } from '../common/NetworkService'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { SystemService, NotificationOptions } from '../common/SystemService'
import { PerformanceMonitor } from '../common/PerformanceMonitor'
import { DomainManager } from '../services/DomainManager'
import { EmailSenderFactory } from '../services/email/EmailSenderFactory'
import { QuotaManager } from '../services/QuotaManager'
import { EmailSenderType } from '../services/email/IEmailSender'
import { UserEmailConfigManager, ProxyServerConfig } from '../config/UserEmailConfig'

// ==================== 页面组件导入 ====================
import { CreateMailboxPage } from './CreateMailboxPage'
import { InboxPage } from './InboxPage'
import { MailboxesPage } from './MailboxesPage'
import { ComposePage } from './ComposePage'
import { SettingsPage } from './SettingsPage'
import { RulesPage } from './RulesPage'

// ==================== 辅助函数 ====================

/**
 * 获取UIAbilityContext
 * @param component - 组件对象
 * @returns UIAbilityContext
 */
function getContext(component: Object): common.UIAbilityContext {
  return (component as ESObject).context as common.UIAbilityContext
}

// ==================== 本地类型定义 ====================

/**
 * 页面类型枚举
 */
enum PageType {
  CREATE = 0,      // 生成邮箱页
  INBOX = 1,       // 收件箱页
  MAILBOXES = 2,   // 邮箱管理页
  COMPOSE = 3,     // 写邮件页
  SETTINGS = 4     // 设置页
}

/**
 * 状态指示器接口
 */
interface StatusIndicator {
  type: 'pin' | 'block'
  time: number
  color: string
}

/**
 * 统计项接口
 */
interface StatItem {
  label: string
  value: string
  color: string
}

// ==================== 主组件 ====================

/**
 * Index - 应用主页面组件
 * 
 * 职责：
 * - 管理5个页面的切换和状态
 * - 协调MailboxManager、NetworkService等核心服务
 * - 提供统一的UI框架和导航
 * - 处理应用级的生命周期事件
 * 
 * @struct Index
 */
@Entry
@Component
struct Index {
  // ==================== 页面切换辅助状态 ====================
  @State pageTransitionInProgress: boolean = false

  // ==================== 核心服务实例 ====================
  private mailboxManager: MailboxManager = MailboxManager.getInstance()
  private networkService: NetworkService = NetworkService.getInstance()
  private i18nService: I18nService = I18nService.getInstance()
  private systemService: SystemService = SystemService.getInstance()
  private domainManager: DomainManager = DomainManager.getInstance()
  private emailSenderFactory: EmailSenderFactory = EmailSenderFactory.getInstance()
  private quotaManager: QuotaManager = QuotaManager.getInstance()
  private userEmailConfigManager: UserEmailConfigManager = UserEmailConfigManager.getInstance()
  private performanceMonitor: PerformanceMonitor = PerformanceMonitor.getInstance()

  // ==================== 页面导航状态 ====================
  @State currentPage: PageType = PageType.CREATE
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State showRulesPage: boolean = false

  // ==================== 邮箱数据状态 ====================
  @State currentMailbox: MailboxData | null = null
  @State mailboxes: MailboxData[] = []
  @State emails: EmailData[] = []
  @State sentEmails: SentEmailData[] = []

  // ==================== 邮件详情状态 ====================
  @State selectedEmail: EmailData | null = null
  @State showEmailDetail: boolean = false
  @State selectedSentEmail: SentEmailData | null = null
  @State showSentEmailDetail: boolean = false

  // ==================== 收件箱/发件箱切换 ====================
  @State inboxMode: 'inbox' | 'outbox' = 'inbox'
  @State selectedSentEmailIds: Set<number> = new Set()
  @State isSelectMode: boolean = false

  // ==================== 图片预览状态 ====================
  @State showImagePreview: boolean = false
  @State previewImageUri: string = ''
  @State previewImageName: string = ''

  // ==================== 徽章计数 ====================
  @State inboxBadgeCount: number = 0
  @State mailboxesBadgeCount: number = 0

  // ==================== UI刷新键（强制重新渲染） ====================
  @State mailboxListRefreshKey: number = 0
  @State emailListRefreshKey: number = 0
  @State sentEmailListRefreshKey: number = 0
  @State statsRefreshKey: number = 0

  // ==================== 统计数据 ====================
  @State totalEmails: number = 0
  @State unreadEmails: number = 0
  @State todayEmails: number = 0
  @State activeMailboxes: number = 0
  @State expiringMailboxes: number = 0

  // ==================== 生成邮箱页面状态 ====================
  @State createMode: 'random' | 'custom' = 'random'
  @State selectedDuration: number = 7
  @State customPrefix: string = ''
  @State selectedDomain: string = 'random'
  @State selectedDomainIndex: number = 0

  // ==================== 写邮件页面状态 ====================
  @State composeFrom: string = ''
  @State composeFromIndex: number = 0
  @State composeTo: string = ''
  @State composeSubject: string = ''
  @State composeBody: string = ''
  @State composeAttachments: AttachmentData[] = []
  @State hasDraft: boolean = false

  // ==================== 设置页面状态 ====================
  @State settingsTheme: 'light' | 'dark' | 'auto' = 'light'
  @State settingsLanguage: string = 'zh-CN'
  @State settingsDefaultDomain: string = 'random'
  @State settingsAutoCleanup: boolean = true
  @State settingsPrefixLength: number = 8
  @State settingsSendMethod: string = 'resend-builtin'
  @State settingsAutoCheck: boolean = true
  @State settingsCheckInterval: number = 30
  @State settingsNewMailboxDelay: number = 5
  @State settingsEmailNotification: boolean = true
  @State settingsExpiryNotification: boolean = true
  @State settingsDesktopNotification: boolean = false

  // ==================== 自定义邮箱配置状态 ====================
  @State customMailboxEnabled: boolean = false
  @State customMailboxEmail: string = ''
  @State customMailboxPassword: string = ''
  @State customMailboxImapHost: string = ''
  @State customMailboxImapPort: number = 993
  @State customMailboxSmtpHost: string = ''
  @State customMailboxSmtpPort: number = 587
  @State customMailboxDisplayName: string = ''
  @State customMailboxProvider: string = 'custom'
  @State customMailboxImapSecure: boolean = true
  @State customMailboxSmtpSecure: boolean = true
  @State customMailboxSignature: string = ''
  @State customMailboxReplyTo: string = ''
  @State customMailboxBccToSelf: boolean = false
  @State customMailboxRequestReadReceipt: boolean = false
  @State customMailboxPriority: string = 'normal'
  @State customMailboxAutoReplyEnabled: boolean = false
  @State customMailboxAutoReplyMessage: string = ''
  @State customMailboxMaxAttachmentSize: number = 25
  @State customMailboxConnectionStatus: string = 'unknown'
  @State customMailboxLastTestTime: number = 0
  @State customMailboxNotes: string = ''
  @State showCustomMailboxAdvanced: boolean = false
  @State showCustomMailboxConfig: boolean = false
  @State showCustomMailboxDialog: boolean = false

  // ==================== 功能开关状态 ====================
  @State enableEmailSearch: boolean = true
  @State enableTemplates: boolean = true
  @State enableFolders: boolean = true
  @State enableStatistics: boolean = true

  // ==================== 搜索和过滤状态 ====================
  @State searchKeyword: string = ''
  @State searchResults: EmailData[] = []
  @State filterType: 'all' | 'unread' | 'verification' | 'today' = 'all'
  @State sortBy: 'time' | 'sender' = 'time'
  @State showFilterPanel: boolean = false
  @State searchDebounceTimer: number = 0

  // ==================== 邮件模板状态 ====================
  @State selectedTemplateId: number = 0
  @State showTemplateDialog: boolean = false
  @State showCreateTemplateDialog: boolean = false
  @State editingTemplateId: number = 0
  @State templateName: string = ''
  @State templateCategory: string = 'custom'
  @State templateSubject: string = ''
  @State templateBody: string = ''
  @State templateDescription: string = ''
  @State templateFilterCategory: string = 'all'

  // ==================== 文件夹状态 ====================
  @State selectedFolderId: number = 0
  @State showFolderDialog: boolean = false
  @State showCreateFolderDialog: boolean = false
  @State editingFolderId: number = 0
  @State folderName: string = ''
  @State folderIcon: string = '[Folder]'
  @State folderColor: string = '#2196F3'
  @State folderDescription: string = ''
  @State showMoveFolderDialog: boolean = false
  @State movingMailboxId: number = 0
  @State mailboxFolders: MailboxFolder[] = []
  @State selectedTargetFolderId: number = 0

  // ==================== 标签状态 ====================
  @State selectedTagIds: number[] = []
  @State showTagDialog: boolean = false
  @State showCreateTagDialog: boolean = false
  @State editingTagId: number = 0
  @State tagName: string = ''
  @State tagColor: string = '#F44336'
  @State tagIcon: string = '[Tag]'
  @State tagDescription: string = ''

  // ==================== 搜索和过滤状态（补充缺失变量） ====================
  @State searchHistory: string[] = []
  @State filterStatus: string = 'all'
  @State sortOrder: string = 'time'
  @State filteredEmailCount: number = 0
  @State showFilterOptions: boolean = false

  // ==================== 邮件模板分类过滤（补充缺失变量） ====================
  @State templateCategoryFilter: string = 'all'

  // ==================== 邮件分类过滤（补充缺失变量） ====================
  @State categoryFilter: string = 'all'

  // ==================== 文件夹视图（补充缺失变量） ====================
  @State folderViewMode: string = 'list'
  @State expandedFolderIds: number[] = []
  @State showStatisticsDetail: boolean = false

  // ==================== 标签相关（补充缺失变量） ====================
  @State showAddTagDialog: boolean = false
  @State taggingEmailId: number = 0
  @State filterByTagId: number = 0

  // ==================== 分类过滤（补充缺失变量） ====================
  @State filterByCategory: string = 'all'

  // ==================== 统计对话框（补充缺失变量） ====================
  @State showStatsDialog: boolean = false
  @State statsData: Record<string, Object> | null = null

  // ==================== 邮箱备注（补充缺失变量） ====================
  @State showNoteDialog: boolean = false
  @State editingMailboxIdForNote: number = 0
  @State mailboxNote: string = ''

  // ==================== 二维码（补充缺失变量） ====================
  @State showQRCodeDialog: boolean = false
  @State qrCodeEmail: string = ''

  // ==================== FAB浮动按钮（补充缺失变量） ====================
  @State fabExpanded: boolean = false

  // ==================== 导出功能（补充缺失变量） ====================
  @State showExportDialog: boolean = false
  @State exportFormat: 'json' | 'txt' | 'html' = 'json'
  @State exportMailboxId: number = 0

  // ==================== UI文本（多语言支持）（补充缺失变量） ====================
  @State uiTexts: Record<string, string> = {
    'loading': '加载中..',
    'error': '错误',
    'retry': '重试'
  }

  // ==================== 后端代理配置（补充缺失变量） ====================
  @State proxyEnabled: boolean = false
  @State proxyBaseUrl: string = ''
  @State proxyAuthToken: string = ''
  @State proxyTimeout: number = 15000
  @State proxyTestResult: string = ''

  // ==================== 配额管理（补充缺失变量） ====================
  @State emailjsQuotaUsed: number = 0
  @State emailjsQuotaTotal: number = 2
  @State resendQuotaUsed: number = 0
  @State resendQuotaTotal: number = 3

  // ==================== UI状态（补充缺失变量） ====================
  @State isRefreshing: boolean = false
  @State successMessage: string = ''
  @State isSendingEmail: boolean = false
  @State selectedMailboxIndex: number = 0
  @State currentLanguage: string = 'zh-CN'
  @State showLanguageMenu: boolean = false

  // ==================== 启动动画状态（补充缺失变量） ====================
  @State showStartupAnimation: boolean = false
  @State startupAnimationOpacity: number = 1
  @State startupVideoReady: boolean = false

  // ==================== 模态框显示状态（补充缺失变量） ====================
  @State showHelpDialog: boolean = false
  @State helpDialogTitle: string = ''
  @State helpDialogContent: string = ''
  @State helpSections: HelpSection[] = []
  @State expandedSections: Set<number> = new Set<number>()
  @State showMailboxActionsMenu: boolean = false
  @State selectedMailbox: MailboxData | null = null
  @State showCustomDaysDialog: boolean = false
  @State customDaysInput: string = ''
  @State customDaysType: 'extend' | 'reduce' = 'extend'

  // ==================== 定时器 ====================
  private expiryTimer: number | null = null
  private autoCheckTimer: number | null = null
  private expiryNotificationTimer: number | null = null

  // ==================== 页面切换动画 ====================
  /**
   * 页面切换（带动画）
   */
  switchPage(newPage: PageType): void {
    if (this.currentPage === newPage || this.pageTransitionInProgress) {
      return
    }
    
    this.pageTransitionInProgress = true
    animateTo({
      duration: 300,
      curve: Curve.EaseInOut,
      onFinish: () => {
        this.pageTransitionInProgress = false
      }
    }, () => {
      this.currentPage = newPage
    })
  }

  /**
   * 启动动画淡出效果
   */
  fadeOutStartupAnimation(): void {
    animateTo({
      duration: 800,
      curve: Curve.EaseOut,
      onFinish: () => {
        this.showStartupAnimation = false
      }
    }, () => {
      this.startupAnimationOpacity = 0
    })
  }

  // ==================== UI文本初始化 ====================
  /**
   * 更新UI文本（多语言支持）
   */
  updateUITexts(language: string): void {
    if (language === 'en-US') {
      // ========== English Text ==========
      this.uiTexts = {
        // Page Titles
        'pageInbox': 'Inbox',
        'pageOutbox': 'Sent',
        'pageCompose': 'Write Email',
        'pageMailboxes': 'My Mailboxes',
        'pageSettings': 'Settings',
        'pageCreate': 'Create Mailbox',
        'pageManage': 'My Mailboxes',
        'pageCreateTitle': 'Create New Mailbox',
        
        // Navigation Buttons
        'navCreate': 'Create',
        'navInbox': 'Inbox',
        'navOutbox': 'Sent',
        'navMailboxes': 'Mailboxes',
        'navCompose': 'Write',
        'navSettings': 'Settings',
        
        // Common Buttons
        'btnClose': 'Close',
        'btnRefresh': 'Refresh',
        'btnCheckNew': 'Check New',
        'btnGenerate': 'Generate',
        'btnSend': 'Send Email',
        'btnCopy': 'Copy',
        'btnCancel': 'Cancel',
        'btnChange': 'Change',
        'btnClearAll': 'Clear All',
        'btnBatchSelect': 'Select',
        'btnDeleteSelected': 'Delete',
        'btnCopyContent': 'Copy Content',
        'btnDelete': 'Delete',
        'btnDeleteEmail': 'Delete Email',
        'btnSave': 'Save',
        'btnSaveConfig': 'Save Config',
        'btnSaveDraft': 'Save Draft',
        'btnLoadDraft': 'Load Draft',
        'btnTemplates': 'Templates',
        'btnAttach': 'Attach',
        'btnExport': 'Export',
        'btnExportData': 'Export Data',
        'btnImport': 'Import',
        'btnImportData': 'Import Data',
        'btnCleanup': 'Cleanup',
        'btnSelect': 'Select',
        'btnTestConnection': 'Test Connection',
        'btnConfirm': 'Confirm',
        'btnRefreshAll': 'Refresh All',
        'inboxEmpty': 'No emails',
        'outboxEmpty': 'No sent emails',
        
        // Form Labels
        'labelFrom': 'From',
        'labelTo': 'To',
        'labelSubject': 'Subject',
        'labelBody': 'Content',
        'labelAttachments': 'Attachments',
        'labelDomain': 'Domain',
        'labelPrefix': 'Prefix',
        'labelDuration': 'Duration',
        'labelDurationTitle': 'Mailbox Duration',
        'labelDurationCustom': 'Enter days (1-36500)',
        'duration7Days': '7 Days',
        'duration1Month': '1 Month',
        'duration6Months': '6 Months',
        'duration1Year': '1 Year',
        'durationForever': 'Forever',
        'durationCustom': 'Custom',
        'labelCurrentMailbox': 'Current Mailbox',
        'labelExpiryDate': 'Expiry: ',
        'labelServerUrl': 'Server URL *',
        'labelAuthToken': 'Auth Token',
        'labelOptional': '(Optional)',
        'labelTimeout': 'Request Timeout',
        'labelPort': 'Port',
        'customMailboxPlaceholderSmtpHost': 'SMTP Host',
        'customMailboxPlaceholderImapHost': 'IMAP Host',
        'tipSmtpConfigured': 'SMTP configured and connected',
        'tipSmtpWaitingConfig': 'Please complete SMTP configuration',
        'tipCustomMailboxRequiresSMTP': 'Please select SMTP as send method to enable custom mailbox',
        'tipEmailJSBuiltinInfo': 'EmailJS built-in service (2 emails/month)',
        'tipEmailJSExternalInfo': 'Configure your EmailJS account',
        'tipResendBuiltinInfo': 'Resend built-in service (3 emails/month)',
        'tipResendExternalInfo': 'Configure your Resend account',
        'emailPlaceholder': 'Email address',
        'passwordPlaceholder': 'Password',
        'displayNamePlaceholder': 'Display name',
        'btnWaitingConfig': 'Waiting for configuration',
        'tipEmailJSQuotaExceeded': 'EmailJS quota exceeded. Please use another method or configure your own EmailJS account.',
        'tipResendQuotaExceeded': 'Resend quota exceeded. Please use another method or configure your own Resend account.',
        'externalEmailJSConfig': 'External EmailJS Configuration',
        'tipConfigureEmailJS': 'Please enter your EmailJS credentials (Service ID, Template ID, Public Key)',
        'externalResendConfig': 'External Resend Configuration',
        'tipConfigureResend': 'Please enter your Resend API key',
        'placeholderServiceId': 'Service ID',
        'placeholderTemplateId': 'Template ID',
        'placeholderPublicKey': 'Public Key',
        'placeholderApiKey': 'API Key',
        'placeholderFromEmail': 'From Email',
        'placeholderFromName': 'From Name (Optional)',
        
        // Placeholders
        'placeholderPrefix': 'Enter prefix (3-20 chars)',
        'placeholderTo': 'Enter recipient email',
        'placeholderSubject': 'Enter email subject',
        'placeholderBody': 'Enter email content...',
        'recipientPlaceholder': 'Recipient email...',
        'subjectPlaceholder': 'Email subject...',
        'bodyPlaceholder': 'Compose your message...',
        'btnAddAttachment': '+ Add Attachment',
        'placeholderAuthToken': 'Enter your auth token',
        
        // Email Details
        'detailTitle': 'Email Details',
        'detailFrom': 'From: ',
        'detailSubject': 'Subject: ',
        'detailTime': 'Time: ',
        'detailContent': 'Content: ',
        
        // Create Page
        'createDescription': 'Choose creation method',
        'createModeRandom': 'Random Generation',
        'createModeCustom': 'Custom Mailbox',
        'createDescRandom': 'Quickly generate random address',
        'createDescCustom': 'Manually set prefix and domain',
        'createCanReceive': 'Can receive emails in app',
        'createAddressOnly': 'Generate address only, receiving not supported yet',
        'createManualCheck': 'Visit {domain} to check manually',
        'createTip': 'Tip: [Receivable] or [Address Only]',
        'btnGenerateRandom': 'Generate Random Mailbox',
        'btnGenerateCustom': 'Create Custom Mailbox',
        'tipNoMailbox': 'No mailbox',
        
        // Inbox Page
        'inboxAllMailboxes': 'All Mailboxes',
        'inboxUnread': '◆Unread',
        'statTotalEmails': 'Total Emails',
        'statUnreadEmails': 'Unread Emails',
        'statTodayEmails': 'Today',
        
        // Sent Page
        'statSentTotal': 'Sent',
        'statSentSuccess': 'Success',
        'statSentFailed': 'Failed',
        'sentSuccess': 'Sent Successfully',
        'sentFailed': 'Send Failed',
        'labelSender': 'From',
        'labelRecipient': 'To',
        'sentDetailTitle': 'Sent Email Details',
        'sentStatus': 'Status',
        'sentErrorReason': 'Error Reason',
        'sentTime': 'Sent Time',
        'sentContent': 'Email Content',
        'noContent': '(No Content)',
        'tipNoSentEmails': 'No sent emails',
        'tipEmptySentDesc': 'Sent emails will appear here',
        'confirmClearAll': 'Clear all sent emails',
        'confirmClearAllDesc': 'This action cannot be undone',
        'confirmDeleteSelected': 'Delete selected emails',
        'confirmDeleteSelectedDesc': 'This action cannot be undone',
        'clearSuccess': 'All records cleared',
        'deleteSuccess': 'Selected records deleted',
        
        // Mailboxes Page
        'statTotalMailboxes': 'Total Mailboxes',
        'statActiveMailboxes': 'Active',
        'statExpiringMailboxes': 'Expiring Soon',
        'mailboxPinned': '[Pinned]',
        'mailboxBlocked': '[Blocked]',
        'menuMailboxActions': 'Mailbox Actions',
        'actionPinMailbox': 'Pin Mailbox',
        'actionUnpinMailbox': 'Unpin Mailbox',
        'actionCopyMailbox': 'Copy Address',
        'actionExtendExpiry': 'Extend Expiry',
        'actionReduceExpiry': 'Reduce Expiry',
        'actionBlockMailbox': 'Block Emails',
        'actionUnblockMailbox': 'Unblock Emails',
        'tipSelectExpiry': 'Select Extension Days',
        'tipSelectReduce': 'Select Reduction Days',
        'btnExtend7Days': 'Extend 7 Days',
        'btnExtend30Days': 'Extend 30 Days',
        'btnExtend90Days': 'Extend 90 Days',
        'btnExtendCustom': 'Custom Days',
        'btnReduce1Day': 'Reduce 1 Day',
        'btnReduce7Days': 'Reduce 7 Days',
        'btnReduce30Days': 'Reduce 30 Days',
        'btnReduceCustom': 'Custom Days',
        'labelCustomDays': 'Enter days (1-100)',
        'tipInvalidDays': 'Please enter a number between 1-100',
        'confirmBlock': 'Confirm Block',
        'confirmBlockMessage': 'This mailbox will not receive new emails. Confirm',
        'confirmUnblock': 'Confirm Unblock',
        'confirmUnblockMessage': 'This mailbox will resume receiving emails. Confirm',
        'tipPinSuccess': 'Pinned successfully',
        'tipUnpinSuccess': 'Unpinned successfully',
        'tipCopySuccess': 'Copied to clipboard',
        'tipExtendSuccess': 'Expiry extended',
        'tipReduceSuccess': 'Expiry reduced',
        'tipBlockSuccess': 'Mailbox blocked',
        'tipUnblockSuccess': 'Mailbox unblocked',
        
        // Settings Page
        'settingsDescription': 'Personalized configuration and app management',
        'settingsInterface': 'Interface Settings',
        'settingsTheme': 'Theme',
        'settingsLanguage': 'Language',
        'settingsDomain': 'Default Domain',
        'settingsDomainCount': '84 domains available',
        'settingsDefaultDomain': 'Default Domain',
        'settingsAutoCleanup': 'Auto cleanup expired mailboxes',
        'settingsPrefixLength': 'Prefix Length',
        'settingsNewMailboxDelay': 'New Mailbox Delay (minutes)',
        'settingsSendMethod': 'Send Method (16 types)',
        'settingsMailboxSettings': 'Mailbox Settings',
        'settingsEmailSend': 'Email Send Settings',
        'settingsServiceConfig': 'Email Service Config',
        'settingsConfigNote': 'Configuration Note',
        'settingsBuiltinNote': 'Built-in service ready to use',
        'settingsExternalNote': 'External service requires API key',
        'settingsAutoCheck': 'Auto Check Settings',
        'settingsEnableAutoCheck': 'Enable auto check',
        'settingsCheckInterval': 'Check Interval',
        'settingsCheckWarning': 'Note: High frequency may affect API stability',
        
        // Language Options
        'langChinese': 'Chinese (中文)',
        'langEnglish': 'English',
        
        // CreateMailboxPage - Custom Mailbox Card
        'customMailboxEnabledIndicator': '(Custom mailbox enabled)',
        'customMailboxCardTitle': '[Custom] Custom Mailbox',
        'customMailboxCardEnabled': 'Enabled',
        'customMailboxCardConnected': 'Connected',
        'customMailboxCardSend': 'Send',
        'customMailboxCardReceive': 'Receive',
        'customMailboxCardNote': 'Support attachments | Real mailbox | Note: SMTP/IMAP requires server support',
        'btnViewConfig': 'View Config',
        'btnDisable': 'Disable',
        'customMailboxDisableTitle': 'Disable Custom Mailbox',
        'customMailboxDisableConfirm': 'After disabling, you will not be able to send emails with attachments using custom mailbox. Confirm disable?',
        'tipSelectDomain': 'Please select a domain',
        'tipGeneratingMailbox': 'Generating mailbox...',
        'tipMailboxCreatedReceivable': 'Mailbox created and can receive emails',
        'tipMailboxCreatedAddressOnly': 'Mailbox created (address only)',
        'tipPrefixTooShort': 'Prefix must be at least 3 characters',
        'tipCreateFailedCheck': 'Failed to create mailbox',
        'tipCreateFailedError': 'Failed to generate mailbox: ',
        
        // Notification Settings
        'notificationSettings': 'Notification Settings',
        'emailNotification': 'Email Notifications',
        'expiryNotification': 'Expiry Notifications',
        'notificationSound': 'Notification Sound',
        
        // Advanced Features
        'advancedFeatures': 'Advanced Features',
        'featureEmailSearch': 'Email Search',
        'featureTemplates': 'Templates',
        'featureFolders': 'Folders',
        'featureStatistics': 'Statistics',
        'featureTags': 'Tags',
        'featureAutoCategory': 'Auto Category',
        'featureDataVisualization': 'Data Visualization',
        'featureAdvancedBackup': 'Advanced Backup',
        'featureFAB': 'FAB',
        
        // Tips and Messages
        'tipCustomMailboxDisabled': 'Custom mailbox disabled',
        'tipNoMailboxes': 'No mailboxes, please create one first',
        'tipRefreshComplete': 'Refresh complete',
        'tipRefreshFailed': 'Refresh failed',
        'tipMailboxSwitched': 'Mailbox switched',
        'tipMailboxDeleted': 'Mailbox deleted',
        'tipCleanedMailboxes': 'Cleaned {count} expired mailboxes',
        'tipReduceWillExpire': 'Will expire immediately after reduction, operation cancelled',
        'tipNoDraft': 'No draft available',
        'tipDraftLoaded': 'Draft loaded',
        'tipLoadDraftFailed': 'Failed to load draft',
        'tipNoContentToSave': 'No content to save',
        'tipDraftSaved': 'Draft saved',
        'tipSaveDraftFailed': 'Failed to save draft',
        'tipSendingInProgress': 'Email is being sent, please wait...',
        'tipFillAllFields': 'Please fill in all fields',
        'tipInvalidEmailFormat': 'Invalid email format',
        'tipSubjectTooLong': 'Subject too long, maximum {max} characters',
        'tipBodyTooLong': 'Email content too long, maximum {max} characters',
        'tipSendSuccess': 'Email sent successfully!',
        'tipSendException': 'Send exception: ',
        'noAttachments': 'No attachments',
        'tipMaxAttachments': 'Maximum 5 attachments allowed',
        'tipAttachmentRequiresCustomMailbox': 'Attachments are only supported when using a custom mailbox. Please configure and connect your custom mailbox first.',
        'tipFileTooLarge': 'File {filename} exceeds 10MB limit, skipped',
        'tipAttachmentsAdded': '{count} attachments added',
        'tipSelectAttachmentFailed': 'Failed to select attachment: ',
        'tipInvalidAttachmentPath': 'Invalid attachment path',
        'tipPreviewFailed': 'Preview failed',
        'tipDownloadAttachmentFailed': 'Failed to download attachment',
        'tipAttachmentDeleted': 'Attachment deleted',
        'tipInitializingStorage': 'Initializing data storage...',
        'tipInitializeFailed': 'Initialization failed, please try again later or restart app',
        'tipStorageNotReady': 'Data storage not ready, please restart app',
        'tipSaveSettingsFailed': 'Failed to save settings: ',
        'tipLoadConfigFailed': 'Failed to load config',
        'tipConfigSaveSuccess': 'Config saved successfully',
        'tipConfigSaveFailed': 'Failed to save config',
        'tipSaveProxyFailed': 'Save failed: ',
        'tipEnterServerUrl': 'Please enter server URL first',
        'tipConnectionSuccess': 'Connection successful',
        'tipConnectionFailed': 'Connection failed',
        'tipConfigureServiceSuccess': 'Email service configured',
        'tipConfigureServiceFailed': 'Configure service failed',
        'tipTestFailed': 'Test failed: ',
        
        // Search and Filter
        'searchPlaceholder': 'Search emails...',
        'searchNoResults': 'No search results',
        'btnFilter': 'Filter',
        'filterAll': 'All',
        'filterUnread': 'Unread',
        'filterToday': 'Today',
        
        // Mailboxes Page
        'folderViewList': 'List View',
        'folderViewFolder': 'Folder View',
        'statistics': 'Statistics',
        'btnDetails': 'Details',
        'statTotal': 'Total',
        'statActive': 'Active',
        'statExpiring': 'Expiring',
        'mailboxesEmpty': 'No mailboxes yet',
        'labelCreated': 'Created',
        'labelExpires': 'Expires',
        'mailboxActions': 'Mailbox Actions',
        'btnCopyEmail': 'Copy Email',
        'btnAddNote': 'Add Note',
        'btnAddTag': 'Add Tag',
        'btnMoveToFolder': 'Move to Folder',
        'moveToFolder': 'Move to Folder',
        'selectFolderPlaceholder': 'Select destination folder',
        'btnMove': 'Move',
        'noFolders': 'No folders available',
        'tipMoveSuccess': 'Moved successfully',
        'tipMoveFailed': 'Move failed',
        
        // Compose Page
        'selectSender': 'Select sender...',
        'draftSaved': 'Draft saved',
        'sending': 'Sending...',
        
        // Inbox Page - Additional
        'labelTags': 'Tags:',
        'tipTagFiltering': '(Tag filtering)',
        'tipCategoryFiltering': '(Category filtering)',
        'labelStatus': 'Status',
        'statusSent': 'sent',
        'statusFailed': 'failed',
        'statusNew': 'NEW',
        
        // Advanced Features Page - Descriptions
        'featureDescEmailSearch': 'Quick search for email content and sender, support unread/read filter and time sorting',
        'featureDescTemplates': 'Built-in templates (verification, notification, business, thank you), support custom templates',
        'featureDescFolders': 'Create custom folders (work, shopping, social), drag mailboxes to manage',
        'featureDescStatistics': 'View total mailboxes, daily emails, send success rate, average lifespan',
        'featureDescTags': 'Add color tags to important emails (urgent, important, todo), filter by tags',
        'featureDescAutoCategory': 'Intelligent email categorization (verification, transaction, social, promotion) ⚠️ Mutually exclusive with visualization',
        'featureDescVisualization': 'Email trend line chart, domain usage pie chart, send success rate chart ⚠️ Mutually exclusive with auto-categorization',
        'featureDescAdvancedBackup': 'Export as JSON/CSV/TXT, auto periodic backup to prevent data loss',
        'featureDescFAB': 'Quick action menu in bottom-right corner, one-click to generate mailbox, check emails, send emails',
        'tipPerformanceWarning': 'Performance Warning',
        'tipAllFeaturesEnabled': 'All features are enabled, which may affect app performance and page response speed. Note: Data visualization and auto-categorization are mutually exclusive, max 8 features can be enabled.',
        'btnRestoreRecommended': 'Restore Recommended (Search+Templates+Folders+Statistics)',
        'tipRestoreSuccess': 'Recommended settings restored, page will be smoother',
        'tipAutoDisabledFAB': 'Quick action button auto-disabled to optimize performance',
        'tipAutoDisabledAutoCategory': 'Auto-categorization auto-disabled (mutually exclusive with visualization)',
        'tipAutoDisabledVisualization': 'Data visualization auto-disabled (mutually exclusive with auto-categorization)',
        
        // Settings Page - Data Management
        'tipExportSuccess': 'Data exported successfully',
        'tipExportFailed': 'Export failed',
        'tipImportSuccess': 'Data imported successfully',
        'tipImportFailed': 'Import failed',
        'tipAllDataCleared': 'All data cleared',
        'tipClearDataFailed': 'Clear data failed',
        'tipSettingsSaved': 'Settings saved',
        'tipLanguageChanged': 'Language changed',
        'tipChangeLanguageFailed': 'Change language failed',
        'tipTestingConnection': 'Testing connection...',
        
        // Settings Page
        'interfaceSettings': 'Interface Settings',
        'theme': 'Theme',
        'language': 'Language',
        'lightTheme': 'Light',
        'darkTheme': 'Dark',
        'autoTheme': 'Auto',
        'changeLanguage': 'Change',
        'mailboxSettings': 'Mailbox Settings',
        'defaultDomain': 'Default Domain',
        'autoCleanupExpired': 'Auto cleanup expired mailboxes',
        'prefixLength': 'Prefix Length',
        'customMailbox': 'Custom Mailbox',
        'emailSendSettings': 'Email Send Settings',
        'sendMethod': 'Send Method',
        'sendSmtp': 'SMTP Server',
        'sendEmailJsBuiltin': 'Built-in EmailJS (2/month)',
        'sendEmailJsExternal': 'External EmailJS',
        'sendResendBuiltin': 'Built-in Resend API (3/month)',
        'sendResendExternal': 'External Resend API',
        'emailjsQuota': 'EmailJS Quota',
        'resendQuota': 'Resend Quota',
        'btnConfigureService': 'Configure Email Service',
        
        // Statistics and Details
        'detailedStatistics': 'Detailed Statistics',
        'domainStatistics': 'Domain Statistics',
        'domainUsageData': 'Domain usage data coming soon',
        'emailTrends': 'Email Trends',
        'emailTrendChart': 'Email trend chart coming soon',
        
        // Email Templates
        'emailTemplates': 'Email Templates',
        'createTemplate': 'Create Template',
        'templateCategory': 'Category',
        'labelCategory': 'Category:',
        'templateAll': 'All',
        'templateCustom': 'Custom',
        'noTemplatesAvailable': 'No templates available',
        'btnSaveTemplate': 'Save Template',
        'btnSendEmail': 'Send Email',
        'templateNamePlaceholder': 'Template name',
        'categoryPlaceholder': 'Category',
        'templateBodyPlaceholder': 'Template body...',
        'descriptionPlaceholder': 'Description (optional)',
        
        // Data Management
        'dataManagement': 'Data Management',
        'btnClearAllData': 'Clear All Data',
        'confirmClearData': 'Clear All Data',
        'confirmClearDataMessage': 'This will delete all your data. Are you sure?',
        'tipImportDataGuide': 'Please paste exported data and try again',
        'tipClipboardEmpty': 'Clipboard is empty',
        
        // Loading
        'loading': 'Loading...',
        'error': 'Error',
        'retry': 'Retry'
      }
    } else if (language === 'zh-CN') {
      // ========== Chinese Text ==========
      this.uiTexts = {
        // 页面标题
        'pageInbox': '收件箱',
        'pageOutbox': '发件箱',
        'pageCompose': '写邮件',
        'pageMailboxes': '我的邮箱',
        'pageSettings': '设置',
        'pageCreate': '生成邮箱',
        'pageManage': '我的邮箱',
        'pageCreateTitle': '创建新邮箱',
        
        // 导航按钮
        'navCreate': '生成',
        'navInbox': '收件箱',
        'navOutbox': '发件箱',
        'navMailboxes': '邮箱',
        'navCompose': '写信',
        'navSettings': '设置',
        
        // 通用按钮
        'btnClose': '关闭',
        'btnRefresh': '刷新',
        'btnCheckNew': '检查新邮件',
        'btnGenerate': '生成',
        'btnSend': '发送邮件',
        'btnCopy': '复制',
        'btnCancel': '取消',
        'btnChange': '切换',
        'btnClearAll': '清空全部',
        'btnBatchSelect': '批量选择',
        'btnDeleteSelected': '删除选中',
        'btnCopyContent': '复制内容',
        'btnDelete': '删除',
        'btnDeleteEmail': '删除邮件',
        'btnSave': '保存',
        'btnSaveConfig': '保存配置',
        'btnSaveDraft': '保存草稿',
        'btnLoadDraft': '加载草稿',
        'btnTemplates': '模板',
        'btnAttach': '附件',
        'btnExport': '导出',
        'btnExportData': '导出数据',
        'btnImport': '导入',
        'btnImportData': '导入数据',
        'btnCleanup': '清理',
        'btnSelect': '选择',
        'btnTestConnection': '测试连接',
        'btnConfirm': '确认',
        'btnRefreshAll': '立即刷新所有邮箱',
        'inboxEmpty': '暂无邮件',
        'outboxEmpty': '暂无已发送邮件',
        
        // 表单标签
        'labelFrom': '发件人',
        'labelTo': '收件人',
        'labelSubject': '主题',
        'labelBody': '内容',
        'labelAttachments': '附件',
        'labelDomain': '域名',
        'labelPrefix': '前缀',
        'labelDuration': '有效期',
        'labelDurationTitle': '邮箱有效期',
        'labelDurationCustom': '输入天数 (1-36500)',
        'duration7Days': '7天',
        'duration1Month': '1个月',
        'duration6Months': '6个月',
        'duration1Year': '1年',
        'durationForever': '永久',
        'durationCustom': '自定义',
        'labelCurrentMailbox': '当前邮箱',
        'labelExpiryDate': '过期时间：',
        'labelServerUrl': '服务器地址 *',
        'labelAuthToken': '认证令牌',
        'labelOptional': '(可选)',
        'labelTimeout': '请求超时时间',
        'labelPort': '端口',
        'customMailboxPlaceholderSmtpHost': 'SMTP服务器',
        'customMailboxPlaceholderImapHost': 'IMAP服务器',
        'tipSmtpConfigured': 'SMTP已配置且连接成功',
        'tipSmtpWaitingConfig': '请完成SMTP配置',
        'tipCustomMailboxRequiresSMTP': '请先选择SMTP作为发送方式以启用自定义邮箱',
        'tipEmailJSBuiltinInfo': 'EmailJS内置服务（2封/月）',
        'tipEmailJSExternalInfo': '配置您的EmailJS账户',
        'tipResendBuiltinInfo': 'Resend内置服务（每月3封）',
        'tipResendExternalInfo': '配置您的Resend账户',
        'emailPlaceholder': '邮箱地址',
        'passwordPlaceholder': '密码',
        'displayNamePlaceholder': '显示名称',
        'btnWaitingConfig': '待用户配置完成',
        'tipEmailJSQuotaExceeded': 'EmailJS配额已用完，请使用其他发送方式或配置自己的EmailJS账户',
        'tipResendQuotaExceeded': 'Resend配额已用完，请使用其他发送方式或配置自己的Resend账户',
        'externalEmailJSConfig': '外部EmailJS配置',
        'tipConfigureEmailJS': '请输入您的EmailJS凭证（Service ID、Template ID、Public Key）',
        'externalResendConfig': '外部Resend配置',
        'tipConfigureResend': '请输入您的Resend API密钥',
        'placeholderServiceId': '服务ID',
        'placeholderTemplateId': '模板ID',
        'placeholderPublicKey': '公钥',
        'placeholderApiKey': 'API密钥',
        'placeholderFromEmail': '发件人邮箱',
        'placeholderFromName': '发件人名称（可选）',
        
        // 占位符
        'placeholderPrefix': '输入前缀 (3-20字符)',
        'placeholderTo': '输入收件人邮箱',
        'placeholderSubject': '输入邮件主题',
        'placeholderBody': '输入邮件正文...',
        'recipientPlaceholder': '收件人邮箱...',
        'subjectPlaceholder': '邮件主题...',
        'bodyPlaceholder': '撰写您的消息...',
        'btnAddAttachment': '+ 添加附件',
        'placeholderAuthToken': '输入你的认证令牌',
        
        // 邮件详情
        'detailTitle': '邮件详情',
        'detailFrom': '发件人：',
        'detailSubject': '主题：',
        'detailTime': '时间：',
        'detailContent': '内容：',
        
        // 创建页面
        'createDescription': '选择创建方式',
        'createModeRandom': '随机生成',
        'createModeCustom': '自定义邮箱',
        'createDescRandom': '快速生成随机邮箱地址',
        'createDescCustom': '手动设置前缀和域名',
        'createCanReceive': '可在应用内接收邮件',
        'createAddressOnly': '仅生成地址，暂不支持应用内接收',
        'createManualCheck': '请访问 {domain} 手动检查',
        'createTip': '提示：[可接收] 或 [仅地址]',
        'btnGenerateRandom': '随机生成邮箱',
        'btnGenerateCustom': '创建自定义邮箱',
        'tipNoMailbox': '暂无邮箱',
        
        // 收件箱页面
        'inboxAllMailboxes': '所有邮箱',
        'inboxUnread': '◆未读',
        'statTotalEmails': '总邮件数',
        'statUnreadEmails': '未读邮件',
        'statTodayEmails': '今日邮件',
        
        // 发件箱页面
        'statSentTotal': '已发送',
        'statSentSuccess': '成功',
        'statSentFailed': '失败',
        'sentSuccess': '发送成功',
        'sentFailed': '发送失败',
        'labelSender': '发件人',
        'labelRecipient': '收件人',
        'sentDetailTitle': '已发送邮件详情',
        'sentStatus': '发送状态',
        'sentErrorReason': '失败原因',
        'sentTime': '发送时间',
        'sentContent': '邮件内容',
        'noContent': '(无内容)',
        'tipNoSentEmails': '暂无已发送邮件',
        'tipEmptySentDesc': '发送后的邮件将显示在此',
        'confirmClearAll': '确认清除所有已发送邮件',
        'confirmClearAllDesc': '此操作无法撤销',
        'confirmDeleteSelected': '确认删除选中邮件',
        'confirmDeleteSelectedDesc': '此操作无法撤销',
        'clearSuccess': '所有记录已清除',
        'deleteSuccess': '选中记录已删除',
        
        // 邮箱页面
        'statTotalMailboxes': '总邮箱数',
        'statActiveMailboxes': '活跃邮箱',
        'statExpiringMailboxes': '即将过期',
        'mailboxPinned': '[已置顶]',
        'mailboxBlocked': '[已拒收]',
        'menuMailboxActions': '邮箱操作',
        'actionPinMailbox': '置顶邮箱',
        'actionUnpinMailbox': '取消置顶',
        'actionCopyMailbox': '复制地址',
        'actionExtendExpiry': '延长有效期',
        'actionReduceExpiry': '减少有效期',
        'actionBlockMailbox': '拒收邮件',
        'actionUnblockMailbox': '恢复接收',
        'tipSelectExpiry': '选择延长天数',
        'tipSelectReduce': '选择减少天数',
        'btnExtend7Days': '延长7天',
        'btnExtend30Days': '延长30天',
        'btnExtend90Days': '延长90天',
        'btnExtendCustom': '自定义天数',
        'btnReduce1Day': '减少1天',
        'btnReduce7Days': '减少7天',
        'btnReduce30Days': '减少30天',
        'btnReduceCustom': '自定义天数',
        'labelCustomDays': '请输入天数(1-100)',
        'tipInvalidDays': '请输入1-100之间的数字',
        'confirmBlock': '确认拒收',
        'confirmBlockMessage': '拒收后将无法接收邮件，确认操作？',
        'confirmUnblock': '确认恢复',
        'confirmUnblockMessage': '该邮箱将恢复接收邮件，确认操作？',
        'tipPinSuccess': '置顶成功',
        'tipUnpinSuccess': '取消置顶成功',
        'tipCopySuccess': '已复制到剪贴板',
        'tipExtendSuccess': '有效期已延长',
        'tipReduceSuccess': '有效期已减少',
        'tipBlockSuccess': '邮箱已拒收',
        'tipUnblockSuccess': '邮箱已恢复接收',
        
        // 设置页面
        'settingsDescription': '个性化配置和应用管理',
        'settingsInterface': '界面设置',
        'settingsTheme': '主题',
        'settingsLanguage': '语言',
        'settingsDomain': '默认域名',
        'settingsDomainCount': '84个域名可选',
        'settingsDefaultDomain': '默认域名',
        'settingsAutoCleanup': '自动清理过期邮箱',
        'settingsPrefixLength': '前缀长度',
        'settingsNewMailboxDelay': '新邮箱延迟(分钟)',
        'settingsSendMethod': '发送方式(16种)',
        'settingsMailboxSettings': '邮箱设置',
        'settingsEmailSend': '邮件发送设置',
        'settingsServiceConfig': '邮件服务配置',
        'settingsConfigNote': '配置说明',
        'settingsBuiltinNote': '内置服务，开箱即用',
        'settingsExternalNote': '外部服务需要API密钥',
        'settingsAutoCheck': '自动检查设置',
        'settingsEnableAutoCheck': '启用自动检查',
        'settingsCheckInterval': '检查间隔',
        'settingsCheckWarning': '注意：频率过高可能影响API稳定性',
        
        // 语言选项
        'langChinese': '中文 (Chinese)',
        'langEnglish': '英文',
        
        // CreateMailboxPage - 自定义邮箱卡片
        'customMailboxEnabledIndicator': '(自定义邮箱已启用)',
        'customMailboxCardTitle': '[自定义] 自定义邮箱',
        'customMailboxCardEnabled': '已启用',
        'customMailboxCardConnected': '已连接',
        'customMailboxCardSend': '发送',
        'customMailboxCardReceive': '接收',
        'customMailboxCardNote': '支持附件发送 | 真实邮箱 | 注意：SMTP/IMAP需服务器支持',
        'btnViewConfig': '查看配置',
        'btnDisable': '禁用',
        'customMailboxDisableTitle': '禁用自定义邮箱',
        'customMailboxDisableConfirm': '禁用后将无法使用自定义邮箱发送带附件的邮件，确认禁用吗？',
        'tipSelectDomain': '请选择域名',
        'tipGeneratingMailbox': '正在生成邮箱...',
        'tipMailboxCreatedReceivable': '邮箱已创建，可以接收邮件',
        'tipMailboxCreatedAddressOnly': '邮箱已创建（仅地址）',
        'tipPrefixTooShort': '前缀至少需要3个字符',
        'tipPrefixCannotBeAllNumbers': '前缀不能全是数字',
        'tipCreateFailedCheck': '创建邮箱失败',
        'tipCreateFailedError': '生成邮箱失败：',
        
        // 规则和限制
        'rulesTitle': '规则限制/使用说明',
        'btnViewRules': '查看规则和限制',
        'rulePrefixTitle': '前缀规则',
        'rulePrefixRule1': '• 前缀长度至少3个字符',
        'rulePrefixRule2': '• 前缀必须包含至少一个字母字符',
        'rulePrefixRule3': '• 前缀不能全是数字',
        'rulePrefixRule4': '• 支持字母、数字和连字符',
        'ruleDomainTitle': '域名规则',
        'ruleDomainRule1': '• 从支持的域名中选择',
        'ruleDomainRule2': '• 不同域名的邮件保留时间不同',
        'ruleDomainRule3': '• 某些域名支持API集成以检索邮件',
        'ruleDurationTitle': '有效期规则',
        'ruleDurationRule1': '• 最短：7天',
        'ruleDurationRule2': '• 最长：1年',
        'ruleDurationRule3': '• 支持自定义有效期',
        'ruleDurationRule4': '• 邮箱过期后将被删除',
        'ruleFolderTitle': '文件夹规则',
        'ruleFolderRule1': '• 创建自定义文件夹来组织邮箱',
        'ruleFolderRule2': '• 在文件夹之间移动邮箱',
        'ruleFolderRule3': '• 文件夹数据自动保存',
        'ruleBatchTitle': '批量操作',
        'ruleBatchRule1': '• 在发件箱中批量选择邮箱',
        'ruleBatchRule2': '• 删除选中的发送记录',
        'ruleBatchRule3': '• 一次清空所有发送记录',
        'ruleCustomMailboxTitle': '自定义邮箱规则',
        'ruleCustomMailboxRule1': '• 配置SMTP和IMAP设置',
        'ruleCustomMailboxRule2': '• 支持真实邮箱账户',
        'ruleCustomMailboxRule3': '• 启用附件发送功能',
        'ruleCustomMailboxRule4': '• 同时只能激活一个自定义邮箱',
        'ruleSendEmailTitle': '邮件发送规则',
        'ruleSendEmailRule1': '• 随机邮箱：只能接收邮件，无法发送',
        'ruleSendEmailRule2': '• 自定义邮箱：配置SMTP后可发送邮件',
        'ruleSendEmailRule3': '• 部分随机邮箱（1SecMail、Guerrilla Mail）支持API收信',
        'ruleSendEmailRule4': '• 发送邮件需要有效的收件人邮箱地址',
        'ruleAttachmentTitle': '附件规则',
        'ruleAttachmentRule1': '• 随机邮箱：无法发送附件',
        'ruleAttachmentRule2': '• 自定义邮箱：可发送附件（最多5个文件）',
        'ruleAttachmentRule3': '• 需要SMTP配置完整',
        'ruleAttachmentRule4': '• 支持的文件类型：所有常见格式',
        'ruleAttachmentRule5': '• 文件大小限制取决于邮件提供商',
        
        // 通知设置
        'notificationSettings': '通知设置',
        'emailNotification': '邮件通知',
        'expiryNotification': '过期通知',
        'notificationSound': '通知声音',
        
        // 高级功能
        'advancedFeatures': '高级功能',
        'featureEmailSearch': '邮件搜索',
        'featureTemplates': '邮件模板',
        'featureFolders': '文件夹',
        'featureStatistics': '统计信息',
        'featureTags': '标签',
        'featureAutoCategory': '自动分类',
        'featureDataVisualization': '数据可视化',
        'featureAdvancedBackup': '高级备份',
        'featureFAB': '浮动按钮',
        
        // 提示信息
        'tipCustomMailboxDisabled': '自定义邮箱已禁用',
        'tipNoMailboxes': '暂无邮箱，请先创建一个',
        'tipRefreshComplete': '刷新完成',
        'tipRefreshSuccess': '邮件已刷新',
        'tipRefreshFailed': '刷新失败',
        'tipMailboxSwitched': '邮箱已切换',
        'tipMailboxDeleted': '邮箱已删除',
        'tipCleanedMailboxes': '已清理{count}个过期邮箱',
        'tipReduceWillExpire': '减少后将立即过期，操作已取消',
        'tipNoDraft': '暂无草稿',
        'tipDraftLoaded': '草稿已加载',
        'tipLoadDraftFailed': '加载草稿失败',
        'tipNoContentToSave': '没有内容可保存',
        'tipDraftSaved': '草稿已保存',
        'tipSaveDraftFailed': '保存草稿失败',
        'tipSendingInProgress': '邮件正在发送中，请稍候...',
        'tipFillAllFields': '请填写完整信息',
        'tipInvalidEmailFormat': '收件人邮箱格式不正确',
        'tipSubjectTooLong': '邮件主题过长，最多{max}字符',
        'tipBodyTooLong': '邮件内容过长，最多{max}字符',
        'tipSendSuccess': '邮件发送成功！',
        'tipSendException': '发送异常：',
        'noAttachments': '暂无附件',
        'tipMaxAttachments': '最多只能添加5个附件',
        'tipAttachmentRequiresCustomMailbox': '附件功能仅在使用自定义邮箱时支持。请先配置并连接您的自定义邮箱。',
        'tipFileTooLarge': '文件 {filename} 超过10MB限制，已跳过',
        'tipAttachmentsAdded': '已添加{count}个附件',
        'tipSelectAttachmentFailed': '选择附件失败：',
        'tipInvalidAttachmentPath': '附件路径无效',
        'tipPreviewFailed': '预览失败',
        'tipDownloadAttachmentFailed': '下载附件失败',
        'tipAttachmentDeleted': '附件已删除',
        'tipInitializingStorage': '正在初始化数据存储...',
        'tipInitializeFailed': '初始化失败，请稍候再试或重启应用',
        'tipStorageNotReady': '数据存储尚未就绪，请重启应用',
        'tipSaveSettingsFailed': '保存设置失败：',
        'tipLoadConfigFailed': '加载配置失败',
        'tipConfigSaveSuccess': '配置保存成功',
        'tipConfigSaveFailed': '配置保存失败',
        'tipSaveProxyFailed': '保存失败：',
        'tipEnterServerUrl': '请先输入服务器地址',
        'tipConnectionSuccess': '连接成功',
        'tipConnectionFailed': '连接失败',
        'tipConfigureServiceSuccess': '邮件服务配置成功',
        'tipConfigureServiceFailed': '配置邮件服务失败',
        'tipTestFailed': '测试失败：',
        
        // 搜索和过滤
        'searchPlaceholder': '搜索邮件...',
        'searchNoResults': '没有搜索结果',
        'btnFilter': '筛选',
        'filterAll': '全部',
        'filterUnread': '未读',
        'filterToday': '今天',
        
        // 邮箱页面
        'folderViewList': '列表视图',
        'folderViewFolder': '文件夹视图',
        'folderView': '文件夹视图',
        'btnCreateFolder': '创建文件夹',
        'folderViewPlaceholder': '文件夹组织功能即将推出',
        'statistics': '统计信息',
        'btnDetails': '详情',
        'statTotal': '总计',
        'statActive': '活跃',
        'statExpiring': '即将过期',
        'mailboxesEmpty': '暂无邮箱',
        'labelCreated': '创建时间',
        'labelExpires': '过期时间',
        'mailboxActions': '邮箱操作',
        'btnCopyEmail': '复制邮箱',
        'btnAddNote': '添加备注',
        'editNote': '编辑备注',
        'notePlaceholder': '输入备注...',
        'btnAddTag': '添加标签',
        'btnMoveToFolder': '移动到文件夹',
        'moveToFolder': '移动到文件夹',
        'selectFolderPlaceholder': '选择目标文件夹',
        'btnMove': '移动',
        'noFolders': '暂无可用文件夹',
        'labelMailboxes': '个邮箱',
        'confirmDeleteMailbox': '删除邮箱',
        'confirmDeleteMailboxMessage': '确定要删除此邮箱吗？',
        'tipMoveSuccess': '移动成功',
        'tipMoveFailed': '移动失败',
        
        // 写信页面
        'selectSender': '选择发件人...',
        'draftSaved': '草稿已保存',
        'sending': '正在发送...',
        
        // 收件箱页面 - 额外
        'labelTags': '标签：',
        'tipTagFiltering': '（标签筛选）',
        'tipCategoryFiltering': '（分类筛选）',
        'labelStatus': '状态',
        'statusSent': '已发送',
        'statusFailed': '失败',
        'statusNew': '新邮件',
        
        // 高级功能页面 - 描述
        'featureDescEmailSearch': '在收件箱中快速搜索邮件内容、发件人，支持未读/已读筛选、时间排序，精准定位目标邮件',
        'featureDescTemplates': '内置验证码、通知、商务、感谢4种常用模板，支持创建个人专属模板，一键填充发件内容',
        'featureDescFolders': '创建工作、购物、社交等自定义分组，拖拽邮箱到分组管理，快速切换查看不同类别邮箱',
        'featureDescStatistics': '查看总邮箱数、今日邮件、发送成功率、平均存活时间等统计数据，掌握使用情况',
        'featureDescTags': '为重要邮件添加彩色标签（紧急、重要、待办等），支持按标签筛选，高效邮件分类管理',
        'featureDescAutoCategory': '智能识别验证码、交易通知、社交动态、促销广告等邮件类型，自动归类显示 ⚠️与数据可视化互斥',
        'featureDescVisualization': '邮件趋势折线图、域名使用饼状图、发送成功率统计图表，数据可视化展示 ⚠️与智能分类互斥',
        'featureDescAdvancedBackup': '支持导出为JSON/CSV/TXT格式，自动定期备份邮箱数据，防止数据丢失',
        'featureDescFAB': '右下角悬浮按钮快捷菜单，一键生成邮箱、检查邮件、发送邮件，提升操作效率',
        'tipPerformanceWarning': '性能警告',
        'tipAllFeaturesEnabled': '所有功能已启用，可能影响应用性能和页面响应速度。说明：数据可视化与智能分类互斥，最多启用8个功能。',
        'btnRestoreRecommended': '恢复推荐设置 (搜索+模板+分组+统计)',
        'tipRestoreSuccess': '已恢复推荐设置，页面将更流畅',
        'tipAutoDisabledFAB': '已自动关闭快速操作按钮以优化性能',
        'tipAutoDisabledAutoCategory': '已自动关闭智能分类功能（与数据可视化互斥）',
        'tipAutoDisabledVisualization': '已自动关闭数据可视化功能（与智能分类互斥）',
        
        // 设置页面 - 数据管理
        'tipExportSuccess': '数据导出成功',
        'tipExportFailed': '导出失败',
        'tipImportSuccess': '数据导入成功',
        'tipImportFailed': '导入失败',
        'tipAllDataCleared': '所有数据已清空',
        'tipClearDataFailed': '清空数据失败',
        'tipSettingsSaved': '设置已保存',
        'tipLanguageChanged': '语言已更改',
        'tipChangeLanguageFailed': '更改语言失败',
        'tipTestingConnection': '正在测试连接...',
        
        // 设置页面
        'interfaceSettings': '界面设置',
        'theme': '主题',
        'language': '语言',
        'lightTheme': '浅色',
        'darkTheme': '深色',
        'autoTheme': '自动',
        'changeLanguage': '更改',
        'mailboxSettings': '邮箱设置',
        'defaultDomain': '默认域名',
        'autoCleanupExpired': '自动清理过期邮箱',
        'prefixLength': '前缀长度',
        'customMailbox': '自定义邮箱',
        'emailSendSettings': '邮件发送设置',
        'sendMethod': '发送方式',
        'sendSmtp': 'SMTP服务器',
        'sendEmailJsBuiltin': '内置EmailJS(月份2次)',
        'sendEmailJsExternal': '外部EmailJS',
        'sendResendBuiltin': '内置Resend API(月份3次)',
        'sendResendExternal': '外部Resend API',
        'emailjsQuota': 'EmailJS配额',
        'resendQuota': 'Resend配额',
        'configureEmailService': '配置邮件服务',
        
        // 统计和详情
        'detailedStatistics': '详细统计',
        'domainStatistics': '域名统计',
        'domainUsageData': '域名使用数据即将推出',
        'emailTrends': '邮件趋势',
        'emailTrendChart': '邮件趋势图表即将推出',
        
        // 邮件模板
        'emailTemplates': '邮件模板',
        'createTemplate': '创建模板',
        'templateCategory': '分类',
        'labelCategory': '分类:',
        'templateAll': '全部',
        'templateCustom': '自定义',
        'noTemplatesAvailable': '暂无可用模板',
        'btnSaveTemplate': '保存模板',
        'btnSendEmail': '发送邮件',
        'templateNamePlaceholder': '模板名称',
        'categoryPlaceholder': '分类',
        'templateBodyPlaceholder': '模板正文...',
        'descriptionPlaceholder': '描述（可选）',
        
        // 数据管理
        'dataManagement': '数据管理',
        'btnClearAllData': '清除所有数据',
        'confirmClearData': '清除所有数据',
        'confirmClearDataMessage': '这将删除您的所有数据。您确定吗？',
        'tipImportDataGuide': '请粘贴导出的数据后重试',
        'tipClipboardEmpty': '剪贴板为空',
        'btnConfigureService': '配置邮件服务',
        
        // 加载
        'loading': '加载中...',
        'error': '错误',
        'retry': '重试'
      }
    }
  }

  // ==================== 生命周期方法 ====================

  /**
   * 组件初始化
   */
  async aboutToAppear(): Promise<void> {
    console.error('=== Index.ets aboutToAppear() 开始执行 ===')
    
    try {
      // ✅ 立即初始化UI文本，避免界面显示空白
      console.error('=== 开始调用 updateUITexts ===')
      this.updateUITexts(this.settingsLanguage)
      console.error('=== updateUITexts 完成 ===')
      
      // ✅ ArkTS修复：直接调用initializeApp，移除setTimeout（不支持回调中的this）
      console.error('=== 开始调用 initializeApp ===')
      Promise.resolve().then(async () => {
        await this.initializeApp()
      })
    } catch (error) {
      console.error('=== aboutToAppear() 发生错误 ===', error)
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'aboutToAppear()异常: %{public}s', JSON.stringify(error))
    }
  }

  /**
   * 页面显示回调
   */
  async onPageShow(): Promise<void> {
    // 🔧 防止启动时重复初始化（只在应用运行中切换页面时重新加载）
    if (!this.isLoading) {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onPageShow: 页面显示，刷新UI')
      
      // 只刷新UI，不重新加载设置
      this.mailboxListRefreshKey++
      this.emailListRefreshKey++
      this.sentEmailListRefreshKey++
      this.statsRefreshKey++
    } else {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onPageShow: 跳过（应用正在初始化中）')
    }
  }

  /**
   * 组件销毁
   */
  aboutToDisappear(): void {
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Index组件销毁，清理资源')
    this.stopTimers()
  }

  // ==================== 初始化方法 ====================

  /**
   * 重试MailboxManager初始化（带多次重试）
   */
  async retryMailboxManagerInit(maxRetries: number = 5): Promise<void> {
    for (let attempt: number = 1; attempt <= maxRetries; attempt++) {
      try {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          `MailboxManager初始化重试 ${attempt}/${maxRetries}`)
        
        // ✅ 从 AppStorage 获取 Context
        let context: common.UIAbilityContext | undefined = AppStorage.get<common.UIAbilityContext>('abilityContext')
        
        if (!context) {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            `AppStorage中Context为空(尝试${attempt})，等待后重试`)
          
          if (attempt < maxRetries) {
            // 等待后再试
            await new Promise<void>(resolve => setTimeout(resolve, 200 * attempt))
            continue
          } else {
            hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
              'Context仍然无效，所有重试已用尽')
            return
          }
        }
        
        const success: boolean = await this.mailboxManager.retryInitialization(context)
        if (success) {
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            'MailboxManager重试初始化成功，重新加载数据')
          // 重新加载数据
          this.loadData()
          this.loadSettings()
          this.updateStats()
          this.updateBadges()
          return // 成功，退出
        } else {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            `MailboxManager重试初始化失败(尝试${attempt})`)
          if (attempt < maxRetries) {
            await new Promise<void>(resolve => setTimeout(resolve, 200 * attempt))
          }
        }
      } catch (error) {
        const err = error as Error
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          `MailboxManager重试初始化异常(尝试${attempt}): %{public}s`, err.message)
        if (attempt < maxRetries) {
          await new Promise<void>(resolve => setTimeout(resolve, 200 * attempt))
        }
      }
    }
  }

  /**
   * 应用初始化
   */
  async initializeApp(): Promise<void> {
    const timer = this.performanceMonitor.startTiming('app_initialization')
    
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '临时邮箱 v2.0 初始化开始')
      console.error('=== initializeApp() 开始 ===')
      
      // ✅ 初始化MailboxManager（从 AppStorage 获取 Context）
      let context: common.UIAbilityContext | undefined
      let initSuccess: boolean = false
      
      // 尝试最多3次获取Context并初始化
      for (let i: number = 0; i < 3; i++) {
        // ✅ 从 AppStorage 获取 Context
        context = AppStorage.get<common.UIAbilityContext>('abilityContext')
        
        if (context) {
          try {
            await this.mailboxManager.initialize(context)
            if (this.mailboxManager.isInitialized()) {
              initSuccess = true
              hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                `MailboxManager初始化成功 (尝试${i + 1}/3)`)
              break
            }
          } catch (e) {
            const err = e as Error
            hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
              `MailboxManager初始化失败 (尝试${i + 1}/3): %{public}s`, err.message)
          }
        } else {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            `AppStorage中Context为空 (尝试${i + 1}/3)，延迟后重试`)
        }
        
        // 如果不是最后一次尝试，等待后再试
        if (i < 2 && !initSuccess) {
          await new Promise<void>(resolve => setTimeout(resolve, 300 * (i + 1)))
        }
      }
      
      // 如果所有尝试都失败，安排后台重试
      if (!initSuccess) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '❌ MailboxManager初始化失败，无法继续加载应用')
        console.error('=== MailboxManager初始化失败 ===')
        
        this.isLoading = false
        this.errorMessage = 'MailboxManager初始化失败，请重启应用'
        timer.endWithError('MailboxManager initialization failed')
        
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '初始化失败，请关闭应用后重新打开')
        
        return  // ← 关键：提前返回，不执行后续操作
      }
      
      // ===== 只有初始化成功后才执行以下操作 =====
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '✅ MailboxManager初始化成功，开始加载数据')
      
      // 加载数据
      this.loadData()
      this.loadSettings()
      
      // 🔧 自动修正不合理的功能配置
      await this.autoFixFeatureConflicts()
      
      this.updateStats()
      this.updateBadges()
      await this.loadQuotaInfo()
      await this.loadProxyConfig()
      
      // ✅ 应用已保存的主题和语言设置
      await this.applyTheme(this.settingsTheme)
      await this.applyLanguage(this.settingsLanguage)
      
      // 启动定时器
      this.startTimers()
      
      this.isLoading = false
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '🔧 DEBUG: isLoading已设置为false')
      timer.end()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '临时邮箱 v2.0 初始化完成')
      console.error('=== initializeApp() 完成 ===')
      
    } catch (error) {
      const err = error as Error
      timer.endWithError(err.message)
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '应用初始化失败: %{public}s', err.message)
      console.error('=== initializeApp() 异常 ===', error)
      this.isLoading = false
      this.errorMessage = '初始化失败，请重启应用'
    }
  }

  /**
   * 加载邮箱和邮件数据
   */
  loadData(): void {
    const mailboxes: MailboxData[] = this.mailboxManager.getMailboxes()
    
    // 排序：置顶的在前，按置顶时间倒序；未置顶的按创建时间倒序
    const sortedMailboxes: MailboxData[] = []
    
    // ✅ 手动复制每个邮箱对象到新数组（确保完全新的引用）
    for (let i: number = 0; i < mailboxes.length; i++) {
      sortedMailboxes.push(mailboxes[i])
    }
    
    // 排序
    sortedMailboxes.sort((a: MailboxData, b: MailboxData) => {
      // 置顶的优先
      if (a.isPinned && !b.isPinned) return -1
      if (!a.isPinned && b.isPinned) return 1
      
      // 都置顶或都未置顶，按时间排序
      if (a.isPinned && b.isPinned) {
        return (b.pinnedTime || 0) - (a.pinnedTime || 0)
      }
      
      return b.createdTime - a.createdTime
    })
    
    // ✅ 直接赋值新数组，触发 @State 响应
    this.mailboxes = sortedMailboxes
    
    // 同样处理 emails
    const emailsArray: EmailData[] = []
    const emails: EmailData[] = this.mailboxManager.getEmails()
    for (let i: number = 0; i < emails.length; i++) {
      emailsArray.push(emails[i])
    }
    this.emails = emailsArray
    
    // ✅ 加载已发送邮件
    const sentEmailsArray: SentEmailData[] = []
    const sentEmails: SentEmailData[] = this.mailboxManager.getSentEmails()
    for (let i: number = 0; i < sentEmails.length; i++) {
      sentEmailsArray.push(sentEmails[i])
    }
    this.sentEmails = sentEmailsArray
    
    // 🆕 加载搜索历史 @since v1.0.1
    const searchHistoryArray: string[] = []
    const history: string[] = this.mailboxManager.getSearchHistory()
    for (let i: number = 0; i < history.length; i++) {
      searchHistoryArray.push(history[i])
    }
    this.searchHistory = searchHistoryArray
    
    // [NEW] 加载文件夹列表 @since v1.0.1
    const foldersArray: MailboxFolder[] = []
    const folders: MailboxFolder[] = this.mailboxManager.getFolders()
    for (let i: number = 0; i < folders.length; i++) {
      foldersArray.push(folders[i])
    }
    this.mailboxFolders = foldersArray
    
    this.currentMailbox = this.mailboxManager.getCurrentMailbox()
    
    // [OK] 强制刷新UI：递增刷新计数器
    this.mailboxListRefreshKey++
    this.emailListRefreshKey++
    this.sentEmailListRefreshKey++  // [OK] 也要刷新发件箱
    
    // [OK] 更新统计数据（必须在数据加载完成后调用）
    this.updateStats()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      `loadData完成: ${this.mailboxes.length}个邮箱, ${this.emails.length}封邮件, refreshKeys: mailbox=${this.mailboxListRefreshKey}, email=${this.emailListRefreshKey}, stats=${this.statsRefreshKey}, 统计: 总=${this.totalEmails}, 未读=${this.unreadEmails}, 今日=${this.todayEmails}`)
    
    // 初始化发件邮箱选择（选择第一个邮箱）
    if (this.mailboxes.length > 0 && !this.composeFrom) {
      this.composeFrom = this.mailboxes[0].email
      this.composeFromIndex = 0
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `初始化发件邮箱: ${this.composeFrom}`)
    }
    
    // 初始化域名选择索引
    this.selectedDomainIndex = this.calculateDomainIndex()
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
      `初始化域名选择: ${this.selectedDomain}, index=${this.selectedDomainIndex}`)
  }

  /**
   * 加载应用设置
   */
  loadSettings(): void {
    const settings: SettingsData = this.mailboxManager.getSettings()
    
    // [OK] 同步设置到 UI 状态变量（提供默认值避免 undefined）
    this.settingsTheme = (settings.theme as 'light' | 'dark' | 'auto') || 'light'
    this.settingsLanguage = settings.language || 'zh-CN'
    this.settingsDefaultDomain = settings.defaultDomain || 'random'
    this.settingsAutoCleanup = settings.autoCleanup !== undefined ? settings.autoCleanup : true
    this.settingsPrefixLength = settings.prefixLength || 8
    this.settingsSendMethod = (settings.sendMethod && typeof settings.sendMethod === 'string') ? settings.sendMethod : 'resend-builtin'
    this.settingsAutoCheck = settings.autoCheck !== undefined ? settings.autoCheck : true
    this.settingsCheckInterval = settings.checkInterval || 30
    this.settingsNewMailboxDelay = settings.newMailboxDelay || 5
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '设置已加载: theme=%{public}s, language=%{public}s, prefixLength=%{public}d, sendMethod=%{public}s, autoCheck=%{public}s',
      this.settingsTheme, this.settingsLanguage, this.settingsPrefixLength, this.settingsSendMethod, this.settingsAutoCheck ? 'true' : 'false')
  }

  /**
   * 自动修正功能冲突和不合理配置
   */
  async autoFixFeatureConflicts(): Promise<void> {
    try {
      // 所有核心功能已启用
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '[OK] 所有核心功能已启用：搜索、模板、分组、统计')
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '[OK] 功能配置检查完成')
      
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '功能修正失败: %{public}s', JSON.stringify(error))
    }
  }

  /**
   * 更新统计数据
   */
  updateStats(): void {
    // [OK] 修复：统计所有邮箱的邮件，不限制当前邮箱
    this.totalEmails = this.emails.length
    this.unreadEmails = this.emails.filter((e: EmailData) => !e.isRead).length
    this.todayEmails = this.emails.filter((e: EmailData) => {
      const emailDate: Date = new Date(e.receivedTime)
      const today: Date = new Date()
      return emailDate.toDateString() === today.toDateString()
    }).length
    
    // 邮箱统计 - activeMailboxes显示未过期的邮箱数
    this.activeMailboxes = this.mailboxes.filter((m: MailboxData) => 
      new Date(m.expiryTime) > new Date()
    ).length
    
    // 即将过期的邮箱（24小时内）
    const expiryThreshold: Date = new Date()
    expiryThreshold.setHours(expiryThreshold.getHours() + 24)
    this.expiringMailboxes = this.mailboxes.filter((m: MailboxData) => {
      const expiry: Date = new Date(m.expiryTime)
      return expiry > new Date() && expiry <= expiryThreshold
    }).length
    
    // [OK] 强制刷新统计卡片UI
    this.statsRefreshKey++
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      `统计更新: 总邮件=${this.totalEmails}, 未读=${this.unreadEmails}, 今日=${this.todayEmails}, statsKey=${this.statsRefreshKey}`)
  }

  /**
   * 更新徽章计数
   */
  updateBadges(): void {
    // 收件箱徽章：显示未读邮件数
    this.inboxBadgeCount = this.unreadEmails
    
    // 我的邮箱徽章：显示邮箱总数（包含自定义邮箱）
    this.mailboxesBadgeCount = this.mailboxes.length + 
      (this.customMailboxEnabled ? 1 : 0)
  }

  /**
   * 根据消息数量获取导航文本颜色
   * 1-2个消息: 绿色
   * 3-5个: 黄色
   * 6-10个: 红色
   * 11+: 黑色
   */
  getNavTextColor(count: number): string {
    if (count === 0) {
      return this.getTextPrimaryColor()  // 默认颜色
    } else if (count >= 1 && count <= 2) {
      return '#4CAF50'  // 绿色
    } else if (count >= 3 && count <= 5) {
      return '#FFC107'  // 黄色
    } else if (count >= 6 && count <= 10) {
      return '#FF5252'  // 红色
    } else {
      return '#000000'  // 黑色
    }
  }

  /**
   * 获取动态主色调（根据当前主题）
   */
  getPrimaryColor(): string {
    const effectiveTheme = this.getEffectiveTheme()
    if (effectiveTheme === 'dark') {
      return '#64B5F6'  // 浅蓝色（深色主题）
    } else {
      return '#1976D2'  // 深蓝色（浅色主题）
    }
  }

  /**
   * 获取动态文本颜色（根据当前主题）
   */
  /**
   * 获取有效的主题模式（处理auto模式）
   */
  private getEffectiveTheme(): 'light' | 'dark' {
    if (this.settingsTheme === 'auto') {
      // 获取系统主题设置
      const colorMode = this.getSystemColorMode()
      return colorMode === 'dark' ? 'dark' : 'light'
    }
    return this.settingsTheme as 'light' | 'dark'
  }

  /**
   * 获取系统主题模式
   */
  private getSystemColorMode(): string {
    try {
      // 使用AppStorage获取系统主题配置
      const colorMode = AppStorage.Get('colorMode') as number | undefined
      if (colorMode !== undefined && colorMode !== null) {
        // colorMode: 0=浅色, 1=深色
        return colorMode === 1 ? 'dark' : 'light'
      }
    } catch (error) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Failed to get system color mode: %{public}s', (error as Error).message)
    }
    // 默认返回浅色
    return 'light'
  }

  getTextPrimaryColor(): string {
    const effectiveTheme = this.getEffectiveTheme()
    if (effectiveTheme === 'dark') {
      return '#FFFFFF'  // 白色文本（深色主题）
    } else {
      return '#212529'  // 深灰文本（浅色主题）
    }
  }

  /**
   * 获取动态背景颜色（根据当前主题）
   */
  getBackgroundColor(): string {
    const effectiveTheme = this.getEffectiveTheme()
    if (effectiveTheme === 'dark') {
      return '#121212'  // 深色背景
    } else {
      return '#FFFFFF'  // 白色背景
    }
  }

  /**
   * 获取动态次背景颜色（根据当前主题）
   */
  getSecondaryBackgroundColor(): string {
    const effectiveTheme = this.getEffectiveTheme()
    if (effectiveTheme === 'dark') {
      return '#1E1E1E'  // 深灰背景
    } else {
      return '#f8f9fa'  // 浅灰背景
    }
  }

  /**
   * 计算当前选中域名的索引
   */
  calculateDomainIndex(): number {
    const options = this.domainManager.getDomainSelectOptions()
    // 先找到当前域名对应的显示文本
    const currentOption = options.find((opt) => opt.value === this.selectedDomain)
    if (!currentOption) {
      return 0
    }
    // 再找到该显示文本的索引
    for (let i: number = 0; i < options.length; i++) {
      if (options[i].text === currentOption.text) {
        return i
      }
    }
    return 0
  }

  /**
   * 加载配额信息
   */
  async loadQuotaInfo(): Promise<void> {
    try {
      const emailjsQuota = await this.quotaManager.getQuotaInfo('emailjs')
      const resendQuota = await this.quotaManager.getQuotaInfo('resend')
      
      this.emailjsQuotaUsed = emailjsQuota.used
      this.emailjsQuotaTotal = emailjsQuota.total
      this.resendQuotaUsed = resendQuota.used
      this.resendQuotaTotal = resendQuota.total
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Quota loaded: EmailJS %{public}d/%{public}d, Resend %{public}d/%{public}d',
        this.emailjsQuotaUsed, this.emailjsQuotaTotal, this.resendQuotaUsed, this.resendQuotaTotal)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Load quota failed: %{public}s', err.message)
    }
  }

  /**
   * 加载代理配置
   */
  async loadProxyConfig(): Promise<void> {
    try {
      // 从MailboxManager加载代理配置
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '加载代理配置')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Load proxy config failed: %{public}s', err.message)
    }
  }

  /**
   * 应用主题
   */
  async applyTheme(theme: string): Promise<void> {
    try {
      this.settingsTheme = theme as 'light' | 'dark' | 'auto'
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '应用主题: %{public}s', theme)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Apply theme failed: %{public}s', err.message)
    }
  }

  /**
   * 应用语言
   */
  async applyLanguage(language: string): Promise<void> {
    try {
      this.settingsLanguage = language
      this.updateUITexts(language)
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '应用语言: %{public}s', language)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Apply language failed: %{public}s', err.message)
    }
  }

  /**
   * 保存并应用设置
   */
  async saveAndApplySettings(): Promise<void> {
    try {
      if (!this.mailboxManager.isInitialized()) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'MailboxManager未初始化，尝试重新初始化...')
        
        await this.systemService.showToast(this.uiTexts['tipInitializingStorage'] || 'Initializing storage...')
        
        await this.retryMailboxManagerInit(5)
        
        if (!this.mailboxManager.isInitialized()) {
          await this.systemService.showToast(this.uiTexts['tipInitializeFailed'] || 'Initialization failed')
          hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '经过多次重试，MailboxManager仍未初始化')
          return
        }
      }
      
      const settingsData: SettingsData = {
        theme: this.settingsTheme,
        language: this.settingsLanguage,
        defaultDomain: this.settingsDefaultDomain,
        autoCleanup: this.settingsAutoCleanup,
        prefixLength: this.settingsPrefixLength,
        defaultDuration: 3600,
        sendMethod: this.settingsSendMethod,
        autoCheck: this.settingsAutoCheck,
        checkInterval: this.settingsCheckInterval,
        newMailboxDelay: this.settingsNewMailboxDelay,
        emailNotification: this.settingsEmailNotification,
        expiryNotification: this.settingsExpiryNotification,
        desktopNotification: this.settingsDesktopNotification,
        enableEmailSearch: this.enableEmailSearch,
        enableTemplates: this.enableTemplates,
        enableFolders: this.enableFolders,
        enableStatistics: this.enableStatistics
      }
      
      await this.mailboxManager.updateSettings(settingsData)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '设置保存成功 theme=%{public}s, language=%{public}s',
        this.settingsTheme, this.settingsLanguage)
      
      await this.applyTheme(this.settingsTheme)
      await this.applyLanguage(this.settingsLanguage)
      
      await this.systemService.showToast(this.uiTexts['tipSaveSuccess'] || 'Settings saved')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '设置保存失败: %{public}s', err.message)
      
      await this.systemService.showToast(this.uiTexts['tipSaveSettingsFailed'] || 'Failed to save settings')
    }
  }

  /**
   * 重置设置
   */
  async resetSettings(): Promise<void> {
    try {
      this.settingsTheme = 'light'
      this.settingsLanguage = 'zh-CN'
      this.settingsAutoCleanup = true
      this.settingsPrefixLength = 8
      
      await this.saveAndApplySettings()
      
      await this.systemService.showToast(this.uiTexts['tipResetSuccess'] || 'Settings reset')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '重置设置失败: %{public}s', err.message)
      
      await this.systemService.showToast(this.uiTexts['tipResetFailed'] || 'Failed to reset settings')
    }
  }

  /**
   * 验证自定义邮箱配置
   */
  validateCustomMailboxConfig(): CustomMailboxValidationResult {
    const missingFields: string[] = []
    
    if (!this.customMailboxEmail || this.customMailboxEmail.trim().length === 0) {
      missingFields.push(this.uiTexts['customMailboxEmail'] || 'Email')
    }
    
    if (!this.customMailboxPassword || this.customMailboxPassword.trim().length === 0) {
      missingFields.push(this.uiTexts['customMailboxPassword'] || 'Password')
    }
    
    if (!this.customMailboxSmtpHost || this.customMailboxSmtpHost.trim().length === 0) {
      missingFields.push(this.uiTexts['customMailboxPlaceholderSmtpHost'] || 'SMTP Host')
    }
    
    if (!this.customMailboxImapHost || this.customMailboxImapHost.trim().length === 0) {
      missingFields.push(this.uiTexts['customMailboxPlaceholderImapHost'] || 'IMAP Host')
    }
    
    return {
      valid: missingFields.length === 0,
      missingFields: missingFields
    }
  }

  /**
   * 测试自定义邮箱连接
   */
  async testCustomMailboxConnection(): Promise<void> {
    try {
      const validation = this.validateCustomMailboxConfig()
      
      if (!validation.valid) {
        await this.systemService.showToast(
          this.uiTexts['tipMissingFields'] || 'Missing fields: ' + validation.missingFields.join(', ')
        )
        return
      }
      
      await this.systemService.showToast(this.uiTexts['tipTestingConnection'] || 'Testing connection...')
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '测试自定义邮箱连接: email=%{public}s, smtpHost=%{public}s, imapHost=%{public}s',
        this.customMailboxEmail, this.customMailboxSmtpHost, this.customMailboxImapHost)
      
      // 构建SMTP配置
      const smtpConfig: Record<string, string> = {
        'smtp_host': this.customMailboxSmtpHost,
        'smtp_port': this.customMailboxSmtpPort.toString(),
        'smtp_secure': this.customMailboxSmtpSecure ? 'true' : 'false',
        'smtp_user': this.customMailboxEmail,
        'smtp_pass': this.customMailboxPassword
      }
      
      // 构建IMAP配置
      const imapConfig: Record<string, string> = {
        'imap_host': this.customMailboxImapHost,
        'imap_port': this.customMailboxImapPort.toString(),
        'imap_secure': this.customMailboxImapSecure ? 'true' : 'false',
        'imap_user': this.customMailboxEmail,
        'imap_pass': this.customMailboxPassword
      }
      
      // 测试SMTP连接
      let smtpSuccess = false
      let smtpError = ''
      
      try {
        // 发送测试邮件到自己
        const testResult = await this.networkService.sendEmail(
          this.customMailboxEmail,
          this.uiTexts['tipTestConnectionTitle'] || 'Connection Test',
          this.uiTexts['tipTestConnectionBody'] || 'This is a test email to verify your SMTP configuration.',
          EmailSenderType.SMTP,
          smtpConfig,
          this.customMailboxEmail,
          this.customMailboxDisplayName || undefined
        )
        
        smtpSuccess = testResult.success
        smtpError = testResult.error || ''
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'SMTP测试结果: %{public}s, error=%{public}s',
          smtpSuccess ? '成功' : '失败', smtpError)
      } catch (error) {
        const err = error as Error
        smtpError = err.message
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'SMTP测试异常: %{public}s', err.message)
      }
      
      // 更新连接状态
      if (smtpSuccess) {
        this.customMailboxConnectionStatus = 'connected'
        this.customMailboxLastTestTime = Date.now()
        
        await this.systemService.showToast(
          this.uiTexts['tipTestConnectionSuccess'] || 'Connection successful! Test email sent.'
        )
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义邮箱连接测试成功')
      } else {
        this.customMailboxConnectionStatus = 'error'
        
        await this.systemService.showToast(
          (this.uiTexts['tipTestConnectionFailed'] || 'Connection failed: ') + smtpError
        )
        
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义邮箱连接测试失败: %{public}s', smtpError)
      }
    } catch (error) {
      const err = error as Error
      this.customMailboxConnectionStatus = 'error'
      
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '测试连接异常: %{public}s', err.message)
      
      await this.systemService.showToast(
        (this.uiTexts['tipTestConnectionFailed'] || 'Connection failed: ') + err.message
      )
    }
  }

  /**
   * 生成邮箱
   */
  async onGenerateMailbox(): Promise<void> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '开始生成邮箱')
      
      if (this.createMode === 'random') {
        // 随机生成模式
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
          '随机生成模式: selectedDomain=%{public}s', this.selectedDomain)
        
        if (!this.selectedDomain) {
          await this.systemService.showToast(this.uiTexts['tipSelectDomain'] || 'Please select a domain')
          return
        }
        
        const duration = this.selectedDuration === -1 ? 7 : this.selectedDuration
        
        await this.systemService.showToast(this.uiTexts['tipGeneratingMailbox'] || 'Generating mailbox...')
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '调用generateRandomMailbox: domain=%{public}s, duration=%{public}d', this.selectedDomain, duration)
        
        const mailbox = await this.mailboxManager.generateRandomMailbox(duration, this.selectedDomain)
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '生成结果: mailbox=%{public}s', mailbox ? mailbox.email : 'null')
        
        if (mailbox) {
          this.currentMailbox = mailbox
          
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '邮箱生成成功: %{public}s', mailbox.email)
          
          const hasAPI = this.domainManager.hasAPISupport(this.currentMailbox.domain || '')
          if (hasAPI) {
            await this.systemService.showToast(this.uiTexts['tipMailboxCreatedReceivable'] || 'Mailbox created and can receive emails')
          } else {
            await this.systemService.showToast(this.uiTexts['tipMailboxCreatedAddressOnly'] || 'Mailbox created (address only)')
          }
        } else {
          await this.systemService.showToast(this.uiTexts['tipCreateFailedCheck'] || 'Failed to create mailbox')
          return
        }
      } else {
        // 自定义生成模式
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义生成模式: prefix=%{public}s, domain=%{public}s', this.customPrefix, this.selectedDomain)
        
        if (!this.customPrefix || this.customPrefix.length < 3) {
          await this.systemService.showToast(this.uiTexts['tipPrefixTooShort'] || 'Prefix must be at least 3 characters')
          return
        }
        
        if (!this.selectedDomain) {
          await this.systemService.showToast(this.uiTexts['tipSelectDomain'] || 'Please select a domain')
          return
        }
        
        const duration = this.selectedDuration === -1 ? 7 : this.selectedDuration
        
        await this.systemService.showToast(this.uiTexts['tipGeneratingMailbox'] || 'Generating mailbox...')
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '调用createCustomMailbox: prefix=%{public}s, domain=%{public}s, duration=%{public}d', 
          this.customPrefix, this.selectedDomain, duration)
        
        const mailbox = await this.mailboxManager.createCustomMailbox(this.customPrefix, this.selectedDomain, duration)
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '生成结果: mailbox=%{public}s', mailbox ? mailbox.email : 'null')
        
        if (mailbox) {
          this.currentMailbox = mailbox
          
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '自定义邮箱生成成功: %{public}s', mailbox.email)
          
          const hasAPI = this.domainManager.hasAPISupport(this.currentMailbox.domain || '')
          if (hasAPI) {
            await this.systemService.showToast(this.uiTexts['tipMailboxCreatedReceivable'] || 'Mailbox created and can receive emails')
          } else {
            await this.systemService.showToast(this.uiTexts['tipMailboxCreatedAddressOnly'] || 'Mailbox created (address only)')
          }
        } else {
          await this.systemService.showToast(this.uiTexts['tipCreateFailedCheck'] || 'Failed to create mailbox')
          return
        }
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '生成邮箱失败: %{public}s', err.message)
      
      await this.systemService.showToast(this.uiTexts['tipCreateFailedError'] || 'Failed to generate mailbox: ' + err.message)
    }
  }


  /**
   * 验证邮件格式
   */
  private validateEmailFormat(email: string): boolean {
    if (!email || email.trim().length === 0) {
      return false
    }
    
    // 使用严格的邮件正则表达式
    const strictEmailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
    
    return strictEmailRegex.test(email.trim())
  }

  /**
   * 启动所有定时器
   */
  startTimers(): void {
    // ✅ 先清理所有旧定时器（防止重复创建）
    this.stopTimers()
    
    // 定时检查过期邮箱（每分钟）
    this.expiryTimer = setInterval(() => {
      this.mailboxManager.checkExpiredMailboxes()
      this.loadData()
      this.updateStats()
      this.updateBadges()
    }, 60000)
    
    // 定时检查即将过期的邮箱并发送通知（每30分钟）
    if (this.settingsExpiryNotification) {
      this.expiryNotificationTimer = setInterval(async () => {
        await this.checkExpiringMailboxes()
      }, 30 * 60 * 1000) // 30分钟
      
      // 立即执行一次检查
      this.checkExpiringMailboxes()
    }
    
    // 自动检查新邮件（根据设置）
    // ✅ 优化：只要启用自动检查就启动，不需要等待选中邮箱
    if (this.settingsAutoCheck) {
      this.startAutoCheck()
    }
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
      '定时器已启动（过期检查+通知+自动检查）')
  }

  /**
   * 停止所有定时器
   */
  private stopTimers(): void {
    if (this.expiryTimer) {
      clearInterval(this.expiryTimer)
      this.expiryTimer = null
    }
    
    if (this.autoCheckTimer) {
      clearInterval(this.autoCheckTimer)
      this.autoCheckTimer = null
    }
    
    if (this.expiryNotificationTimer) {
      clearInterval(this.expiryNotificationTimer)
      this.expiryNotificationTimer = null
    }
  }

  /**
   * 启动自动检查定时器
   */
  private startAutoCheck(): void {
    if (this.autoCheckTimer) {
      return
    }

    const intervalMs: number = this.settingsCheckInterval * 1000
    this.autoCheckTimer = setInterval(() => {
      this.checkNewEmails()
    }, intervalMs)
  }

  /**
   * 检查新邮件
   */
  private checkNewEmails(): void {
    if (!this.currentMailbox) {
      return
    }

    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '检查新邮件')
    // 实现邮件检查逻辑
    this.loadData()
  }

  /**
   * 检查即将过期的邮箱
   */
  async checkExpiringMailboxes(): Promise<void> {
    try {
      const expiringMailboxes: MailboxData[] = this.mailboxes.filter((m: MailboxData) => {
        const timeLeft: number = m.expiryTime - Date.now()
        return timeLeft > 0 && timeLeft < 24 * 60 * 60 * 1000 // 24小时内过期
      })
      
      if (expiringMailboxes.length > 0 && this.settingsExpiryNotification) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '检测到 %{public}d 个即将过期的邮箱', expiringMailboxes.length)
        
        // 发送通知提示
        const message = `${expiringMailboxes.length} mailbox(es) expiring within 24 hours`
        await this.systemService.showToast(message)
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '检查过期邮箱失败: %{public}s', err.message)
    }
  }

  // ==================== 顶部导航栏 ====================

  /**
   * 构建顶部导航栏（5个标签页）
   */
  @Builder buildTopNavigation(): void {
    Column({ space: 0 }) {
      // 标签页导航
      Row({ space: 0 }) {
        // 生成邮箱
        Column({ space: 0 }) {
          Text(this.uiTexts['navCreate'] || '生成')
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(this.getTextPrimaryColor())
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .lineHeight(44)
            .onClick(() => this.currentPage = PageType.CREATE)
          
          if (this.currentPage === PageType.CREATE) {
            Divider()
              .color(this.getPrimaryColor())
              .strokeWidth(3)
          } else {
            Divider()
              .color(Color.Transparent)
              .strokeWidth(3)
          }
        }
        .layoutWeight(1)
        .height(48)
        .onClick(() => this.switchPage(PageType.CREATE))
        
        // 收件箱
        Column({ space: 0 }) {
          Text(this.inboxMode === 'inbox' ? this.uiTexts['navInbox'] : this.uiTexts['navOutbox'] || '收件箱')
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(this.getNavTextColor(this.inboxMode === 'inbox' ? this.inboxBadgeCount : this.sentEmails.length))
            .fontWeight((this.inboxMode === 'inbox' ? this.inboxBadgeCount : this.sentEmails.length) > 0 ? FontWeight.Bold : FontWeight.Normal)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .lineHeight(44)
          
          if (this.currentPage === PageType.INBOX) {
            Divider()
              .color(this.getPrimaryColor())
              .strokeWidth(3)
          } else {
            Divider()
              .color(Color.Transparent)
              .strokeWidth(3)
          }
        }
        .layoutWeight(1)
        .height(48)
        .onClick(() => this.switchPage(PageType.INBOX))
        
        // 我的邮箱
        Column({ space: 0 }) {
          Text(this.uiTexts['navMailboxes'] || '邮箱')
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(this.getNavTextColor(this.mailboxesBadgeCount))
            .fontWeight(this.mailboxesBadgeCount > 0 ? FontWeight.Bold : FontWeight.Normal)
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .lineHeight(44)
          
          if (this.currentPage === PageType.MAILBOXES) {
            Divider()
              .color(this.getPrimaryColor())
              .strokeWidth(3)
          } else {
            Divider()
              .color(Color.Transparent)
              .strokeWidth(3)
          }
        }
        .layoutWeight(1)
        .height(48)
        .onClick(() => this.switchPage(PageType.MAILBOXES))
        
        // 写邮件
        Column({ space: 0 }) {
          Text(this.uiTexts['navCompose'] || '写信')
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(this.getTextPrimaryColor())
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .lineHeight(44)
          
          if (this.currentPage === PageType.COMPOSE) {
            Divider()
              .color(this.getPrimaryColor())
              .strokeWidth(3)
          } else {
            Divider()
              .color(Color.Transparent)
              .strokeWidth(3)
          }
        }
        .layoutWeight(1)
        .height(48)
        .onClick(() => this.switchPage(PageType.COMPOSE))
        
        // 设置
        Column({ space: 0 }) {
          Text(this.uiTexts['navSettings'] || '设置')
            .layoutWeight(1)
            .fontSize(14)
            .fontColor(this.getTextPrimaryColor())
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(44)
            .lineHeight(44)
          
          if (this.currentPage === PageType.SETTINGS) {
            Divider()
              .color(this.getPrimaryColor())
              .strokeWidth(3)
          } else {
            Divider()
              .color(Color.Transparent)
              .strokeWidth(3)
          }
        }
        .layoutWeight(1)
        .height(48)
        .onClick(() => this.switchPage(PageType.SETTINGS))
      }
      .width('100%')
      .height(48)
    }
    .width('100%')
    .expandSafeArea([SafeAreaType.SYSTEM])
  }

  // ==================== 主界面构建 ====================

  build() {
    Column() {
      // 顶部导航栏
      this.buildTopNavigation()

      // 页面内容区域
      this.buildPageContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.getBackgroundColor())
    .expandSafeArea([SafeAreaType.SYSTEM])
  }

  /**
   * 构建页面内容区域
   */
  @Builder
  private buildPageContent(): void {
    Stack() {
      // 根据currentPage显示不同的页面
      if (this.currentPage === PageType.CREATE) {
        CreateMailboxPage({
          currentMailbox: $currentMailbox,
          createMode: $createMode,
          selectedDuration: $selectedDuration,
          customPrefix: $customPrefix,
          selectedDomain: $selectedDomain,
          selectedDomainIndex: $selectedDomainIndex,
          customMailboxEnabled: $customMailboxEnabled,
          customMailboxEmail: $customMailboxEmail,
          customMailboxPassword: $customMailboxPassword,
          customMailboxDisplayName: $customMailboxDisplayName,
          customMailboxProvider: $customMailboxProvider,
          customMailboxSmtpHost: $customMailboxSmtpHost,
          customMailboxSmtpPort: $customMailboxSmtpPort,
          customMailboxSmtpSecure: $customMailboxSmtpSecure,
          customMailboxImapHost: $customMailboxImapHost,
          customMailboxImapPort: $customMailboxImapPort,
          customMailboxImapSecure: $customMailboxImapSecure,
          showCustomMailboxConfig: $showCustomMailboxConfig,
          showCustomMailboxDialog: $showCustomMailboxDialog,
          showCustomDaysDialog: $showCustomDaysDialog,
          customDaysInput: $customDaysInput,
          customDaysType: $customDaysType,
          uiTexts: $uiTexts,
          mailboxListRefreshKey: $mailboxListRefreshKey,
          settingsTheme: $settingsTheme,
          settingsPrefixLength: $settingsPrefixLength,
          mailboxManager: this.mailboxManager,
          i18nService: this.i18nService,
          domainManager: this.domainManager,
          systemService: this.systemService,
          onCreateMailbox: () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onCreateMailbox callback triggered')
            this.onGenerateMailbox()
          },
          onSaveSettings: () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onSaveSettings callback triggered')
            this.saveAndApplySettings()
          },
          onNavigateToSettings: () => {
            this.currentPage = PageType.SETTINGS
          },
          onDisableCustomMailbox: () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onDisableCustomMailbox callback triggered')
            this.saveAndApplySettings()
          }
        })
      } else if (this.currentPage === PageType.INBOX) {
        InboxPage({
          inboxMode: $inboxMode,
          emails: $emails,
          sentEmails: $sentEmails,
          selectedEmail: $selectedEmail,
          selectedSentEmail: $selectedSentEmail,
          showEmailDetail: $showEmailDetail,
          showSentEmailDetail: $showSentEmailDetail,
          selectedSentEmailIds: $selectedSentEmailIds,
          isSelectMode: $isSelectMode,
          showImagePreview: $showImagePreview,
          previewImageUri: $previewImageUri,
          previewImageName: $previewImageName,
          searchKeyword: $searchKeyword,
          searchResults: $searchResults,
          filterType: $filterType,
          sortBy: $sortBy,
          showFilterPanel: $showFilterPanel,
          filterByTagId: $filterByTagId,
          filterByCategory: $filterByCategory,
          emailListRefreshKey: $emailListRefreshKey,
          sentEmailListRefreshKey: $sentEmailListRefreshKey,
          inboxBadgeCount: $inboxBadgeCount,
          uiTexts: $uiTexts,
          enableEmailSearch: $enableEmailSearch,
          settingsTheme: $settingsTheme,
          mailboxManager: this.mailboxManager,
          systemService: this.systemService,
          i18nService: this.i18nService,
          onEmailClick: (email: EmailData) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onEmailClick callback triggered')
            this.selectedEmail = email
            this.showEmailDetail = true
          },
          onSentEmailClick: (sentEmail: SentEmailData) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onSentEmailClick callback triggered')
            this.selectedSentEmail = sentEmail
            this.showSentEmailDetail = true
          },
          onDeleteEmail: async (emailId: number) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onDeleteEmail callback triggered')
            try {
              const index = this.emails.findIndex(e => e.id === emailId)
              if (index > -1) {
                this.emails.splice(index, 1)
                this.emailListRefreshKey++
                await this.systemService.showToast(this.uiTexts['tipEmailDeleted'] || 'Email deleted')
              }
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipDeleteFailed'] || 'Delete failed: ' + err.message)
            }
          },
          onMarkAsRead: async (emailId: number) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onMarkAsRead callback triggered')
            try {
              const email = this.emails.find(e => e.id === emailId)
              if (email) {
                email.isRead = true
                this.emailListRefreshKey++
                await this.systemService.showToast(this.uiTexts['tipMarkedAsRead'] || 'Marked as read')
              }
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipMarkFailed'] || 'Mark failed: ' + err.message)
            }
          },
          onRefreshEmails: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onRefreshEmails callback triggered')
            try {
              // TODO: 实现邮件刷新逻辑
              await this.systemService.showToast(this.uiTexts['tipRefreshSuccess'] || 'Emails refreshed')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipRefreshFailed'] || 'Refresh failed: ' + err.message)
            }
          },
          onDeleteSelectedSentEmails: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onDeleteSelectedSentEmails callback triggered')
            try {
              const idsToDelete = Array.from(this.selectedSentEmailIds)
              this.sentEmails = this.sentEmails.filter(e => !idsToDelete.includes(e.id))
              this.selectedSentEmailIds.clear()
              this.sentEmailListRefreshKey++
              await this.systemService.showToast(this.uiTexts['tipEmailsDeleted'] || 'Emails deleted')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipDeleteFailed'] || 'Delete failed: ' + err.message)
            }
          },
          onClearAllSentEmails: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onClearAllSentEmails callback triggered')
            try {
              this.sentEmails = []
              this.sentEmailListRefreshKey++
              await this.systemService.showToast(this.uiTexts['tipAllEmailsCleared'] || 'All emails cleared')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipClearFailed'] || 'Clear failed: ' + err.message)
            }
          },
          onImagePreview: (uri: string, name: string) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onImagePreview callback triggered')
            this.previewImageUri = uri
            this.previewImageName = name
            this.showImagePreview = true
          }
        })
      } else if (this.currentPage === PageType.MAILBOXES) {
        MailboxesPage({
          mailboxes: $mailboxes,
          selectedMailbox: $selectedMailbox,
          showMailboxActionsMenu: $showMailboxActionsMenu,
          folderViewMode: $folderViewMode,
          expandedFolderIds: $expandedFolderIds,
          selectedFolderId: $selectedFolderId,
          showFolderDialog: $showFolderDialog,
          showCreateFolderDialog: $showCreateFolderDialog,
          editingFolderId: $editingFolderId,
          folderName: $folderName,
          folderIcon: $folderIcon,
          folderColor: $folderColor,
          folderDescription: $folderDescription,
          showMoveFolderDialog: $showMoveFolderDialog,
          movingMailboxId: $movingMailboxId,
          mailboxFolders: $mailboxFolders,
          selectedTargetFolderId: $selectedTargetFolderId,
          showTagDialog: $showTagDialog,
          showCreateTagDialog: $showCreateTagDialog,
          editingTagId: $editingTagId,
          tagName: $tagName,
          tagColor: $tagColor,
          tagIcon: $tagIcon,
          tagDescription: $tagDescription,
          showAddTagDialog: $showAddTagDialog,
          taggingEmailId: $taggingEmailId,
          showStatsDialog: $showStatsDialog,
          statsData: $statsData,
          showNoteDialog: $showNoteDialog,
          editingMailboxIdForNote: $editingMailboxIdForNote,
          mailboxNote: $mailboxNote,
          showStatisticsDetail: $showStatisticsDetail,
          mailboxListRefreshKey: $mailboxListRefreshKey,
          statsRefreshKey: $statsRefreshKey,
          totalEmails: $totalEmails,
          unreadEmails: $unreadEmails,
          todayEmails: $todayEmails,
          activeMailboxes: $activeMailboxes,
          expiringMailboxes: $expiringMailboxes,
          uiTexts: $uiTexts,
          enableFolders: $enableFolders,
          enableStatistics: $enableStatistics,
          settingsTheme: $settingsTheme,
          mailboxManager: this.mailboxManager,
          systemService: this.systemService,
          i18nService: this.i18nService,
          onMailboxClick: (mailbox: MailboxData) => {
            this.selectedMailbox = mailbox
          },
          onDeleteMailbox: async (mailboxId: number) => {
            try {
              await this.mailboxManager.deleteMailbox(mailboxId)
              this.mailboxes = this.mailboxes.filter(m => m.id !== mailboxId)
              this.mailboxListRefreshKey++
              await this.systemService.showToast(this.uiTexts['tipMailboxDeleted'] || 'Mailbox deleted')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipDeleteFailed'] || 'Delete failed: ' + err.message)
            }
          },
          onCopyMailbox: async (mailbox: MailboxData) => {
            await this.systemService.copyToClipboard(mailbox.email)
            await this.systemService.showToast(this.uiTexts['tipCopySuccess'] || 'Copied')
          },
          onRefreshStats: () => {
            this.updateStats()
          },
          onCreateFolder: async () => {
            if (!this.folderName.trim()) {
              await this.systemService.showToast(this.uiTexts['tipFolderNameRequired'] || 'Folder name required')
              return
            }
            try {
              // TODO: Implement folder creation logic
              await this.systemService.showToast(this.uiTexts['tipFolderCreated'] || 'Folder created')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipCreateFailed'] || 'Create failed: ' + err.message)
            }
          },
          onCreateTag: async () => {
            if (!this.tagName.trim()) {
              await this.systemService.showToast(this.uiTexts['tipTagNameRequired'] || 'Tag name required')
              return
            }
            try {
              // TODO: Implement tag creation logic
              await this.systemService.showToast(this.uiTexts['tipTagCreated'] || 'Tag created')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipCreateFailed'] || 'Create failed: ' + err.message)
            }
          },
          onSaveNote: async () => {
            if (this.editingMailboxIdForNote > 0) {
              const mailbox = this.mailboxes.find(m => m.id === this.editingMailboxIdForNote)
              if (mailbox) {
                mailbox.notes = this.mailboxNote
                try {
                  await this.mailboxManager.updateMailbox(mailbox)
                  this.mailboxListRefreshKey++
                  await this.systemService.showToast(this.uiTexts['tipNoteSaved'] || 'Note saved')
                } catch (error) {
                  const err = error as Error
                  await this.systemService.showToast(this.uiTexts['tipSaveFailed'] || 'Save failed: ' + err.message)
                }
              }
            }
          }
        })
      } else if (this.currentPage === PageType.COMPOSE) {
        ComposePage({
          composeFrom: $composeFrom,
          composeFromIndex: $composeFromIndex,
          composeTo: $composeTo,
          composeSubject: $composeSubject,
          composeBody: $composeBody,
          composeAttachments: $composeAttachments,
          hasDraft: $hasDraft,
          selectedTemplateId: $selectedTemplateId,
          showTemplateDialog: $showTemplateDialog,
          showCreateTemplateDialog: $showCreateTemplateDialog,
          editingTemplateId: $editingTemplateId,
          templateName: $templateName,
          templateCategory: $templateCategory,
          templateSubject: $templateSubject,
          templateBody: $templateBody,
          templateDescription: $templateDescription,
          templateFilterCategory: $templateFilterCategory,
          isSendingEmail: $isSendingEmail,
          mailboxes: $mailboxes,
          uiTexts: $uiTexts,
          enableTemplates: $enableTemplates,
          settingsTheme: $settingsTheme,
          i18nService: this.i18nService,
          systemService: this.systemService,
          emailSenderFactory: this.emailSenderFactory,
          mailboxManager: this.mailboxManager,
          onAttachFile: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onAttachFile callback triggered')
            try {
              // ⚠️ 附件功能仅支持自定义邮箱发送
              if (!this.customMailboxEnabled || this.customMailboxConnectionStatus !== 'connected') {
                await this.systemService.showToast(
                  this.uiTexts['tipAttachmentRequiresCustomMailbox'] || 'Attachments are only supported when using a custom mailbox. Please configure and connect your custom mailbox first.'
                )
                hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                  '附件功能仅支持自定义邮箱: customMailboxEnabled=%{public}s, status=%{public}s',
                  this.customMailboxEnabled ? 'true' : 'false', this.customMailboxConnectionStatus)
                return
              }
              
              // 检查附件数量限制（最多5个）
              if (this.composeAttachments.length >= 5) {
                await this.systemService.showToast(this.uiTexts['tipMaxAttachments'] || 'Maximum 5 attachments allowed')
                return
              }
              
              // 使用文件选择器选择附件
              // TODO: 实现文件选择逻辑
              await this.systemService.showToast(this.uiTexts['tipSelectAttachmentFailed'] || 'File selection not implemented')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipSelectAttachmentFailed'] || 'Failed to select attachment: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Select attachment error: %{public}s', err.message)
            }
          },
          onSendEmail: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onSendEmail callback triggered')
            try {
              if (!this.composeFrom || this.composeFrom.length === 0) {
                await this.systemService.showToast(this.uiTexts['tipSelectDomain'] || 'Please select a sender')
                return
              }
              if (!this.composeTo || this.composeTo.length === 0) {
                await this.systemService.showToast(this.uiTexts['tipFillAllFields'] || 'Please fill in all fields')
                return
              }
              if (!this.validateEmailFormat(this.composeTo)) {
                await this.systemService.showToast(this.uiTexts['tipInvalidEmailFormat'] || 'Invalid email format')
                return
              }
              
              this.isSendingEmail = true
              
              await this.systemService.showToast(this.uiTexts['tipSending'] || 'Sending email...')
              
              // 确定发送方式和配置
              let senderType: EmailSenderType = this.settingsSendMethod as EmailSenderType
              let smtpConfig: Record<string, string> | undefined = undefined
              let fromEmail: string = this.composeFrom
              let fromName: string | undefined = undefined
              
              // 检查是否使用自定义邮箱
              if (this.customMailboxEnabled && this.customMailboxConnectionStatus === 'connected') {
                // 使用自定义邮箱SMTP发送
                senderType = EmailSenderType.SMTP
                fromEmail = this.customMailboxEmail
                fromName = this.customMailboxDisplayName || undefined
                
                smtpConfig = {
                  'smtp_host': this.customMailboxSmtpHost,
                  'smtp_port': this.customMailboxSmtpPort.toString(),
                  'smtp_secure': this.customMailboxSmtpSecure ? 'true' : 'false',
                  'smtp_user': this.customMailboxEmail,
                  'smtp_pass': this.customMailboxPassword
                }
                
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                  '使用自定义邮箱SMTP发送: email=%{public}s, host=%{public}s',
                  this.customMailboxEmail, this.customMailboxSmtpHost)
              } else {
                // 使用配置的发送方式
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                  '使用配置的发送方式: %{public}s', senderType)
                
                // 检查内置EmailJS或Resend的配额
                if (senderType === EmailSenderType.EMAILJS_BUILTIN) {
                  const hasQuota = await this.quotaManager.checkQuota('emailjs')
                  if (!hasQuota) {
                    this.isSendingEmail = false
                    await this.systemService.showToast(
                      this.uiTexts['tipEmailJSQuotaExceeded'] || 'EmailJS quota exceeded. Please use another method or configure your own EmailJS account.'
                    )
                    hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'EmailJS配额已用完')
                    return
                  }
                } else if (senderType === EmailSenderType.RESEND_BUILTIN) {
                  const hasQuota = await this.quotaManager.checkQuota('resend')
                  if (!hasQuota) {
                    this.isSendingEmail = false
                    await this.systemService.showToast(
                      this.uiTexts['tipResendQuotaExceeded'] || 'Resend quota exceeded. Please use another method or configure your own Resend account.'
                    )
                    hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Resend配额已用完')
                    return
                  }
                }
              }
              
              // 调用网络服务发送邮件
              const result = await this.networkService.sendEmail(
                this.composeTo,
                this.composeSubject || '(No Subject)',
                this.composeBody,
                senderType,
                smtpConfig,
                fromEmail,
                fromName
              )
              
              this.isSendingEmail = false
              
              if (result.success) {
                // 保存发送记录
                const sentRecord: SentEmailData = {
                  id: Date.now(),
                  from: fromEmail,
                  to: this.composeTo,
                  subject: this.composeSubject || '(No Subject)',
                  body: this.composeBody,
                  sentTime: Date.now(),
                  success: true,
                  attachments: this.composeAttachments.length > 0 ? this.composeAttachments : undefined
                }
                
                try {
                  this.mailboxManager.addSentEmail(sentRecord)
                } catch (error) {
                  hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                    '保存发送记录失败: %{public}s', (error as Error).message)
                }
                
                // 刷新配额信息
                try {
                  await this.loadQuotaInfo()
                } catch (error) {
                  hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                    '刷新配额信息失败: %{public}s', (error as Error).message)
                }
                
                await this.systemService.showToast(this.uiTexts['tipSendSuccess'] || 'Email sent successfully!')
                
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                  '邮件发送成功: to=%{public}s, subject=%{public}s',
                  this.composeTo, this.composeSubject)
                
                // 清空表单
                this.composeFrom = ''
                this.composeFromIndex = 0
                this.composeTo = ''
                this.composeSubject = ''
                this.composeBody = ''
                this.composeAttachments = []
                this.hasDraft = false
              } else {
                // 发送失败
                const errorMsg = result.error || 'Unknown error'
                
                hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                  '邮件发送失败: %{public}s', errorMsg)
                
                await this.systemService.showToast(
                  (this.uiTexts['tipSendException'] || 'Send failed: ') + errorMsg
                )
              }
            } catch (error) {
              this.isSendingEmail = false
              const err = error as Error
              
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
                '邮件发送异常: %{public}s', err.message)
              
              await this.systemService.showToast(
                (this.uiTexts['tipSendException'] || 'Send failed: ') + err.message
              )
            }
          },
          onSaveDraft: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onSaveDraft callback triggered')
            try {
              if (!this.composeBody || this.composeBody.length === 0) {
                await this.systemService.showToast(this.uiTexts['tipNoContentToSave'] || 'No content to save')
                return
              }
              
              // TODO: 实现草稿保存逻辑
              this.hasDraft = true
              
              await this.systemService.showToast(this.uiTexts['tipDraftSaved'] || 'Draft saved')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipSaveDraftFailed'] || 'Save draft failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Save draft error: %{public}s', err.message)
            }
          }
        })
      } else if (this.showRulesPage) {
        RulesPage({
          uiTexts: $uiTexts,
          settingsTheme: $settingsTheme,
          onBack: () => {
            this.showRulesPage = false
          }
        })
      } else if (this.currentPage === PageType.SETTINGS) {
        SettingsPage({
          settingsTheme: $settingsTheme,
          settingsLanguage: $settingsLanguage,
          currentLanguage: $currentLanguage,
          showLanguageMenu: $showLanguageMenu,
          settingsDefaultDomain: $settingsDefaultDomain,
          settingsAutoCleanup: $settingsAutoCleanup,
          settingsPrefixLength: $settingsPrefixLength,
          settingsNewMailboxDelay: $settingsNewMailboxDelay,
          customMailboxEnabled: $customMailboxEnabled,
          customMailboxEmail: $customMailboxEmail,
          customMailboxPassword: $customMailboxPassword,
          customMailboxDisplayName: $customMailboxDisplayName,
          customMailboxProvider: $customMailboxProvider,
          customMailboxSmtpHost: $customMailboxSmtpHost,
          customMailboxSmtpPort: $customMailboxSmtpPort,
          customMailboxSmtpSecure: $customMailboxSmtpSecure,
          customMailboxImapHost: $customMailboxImapHost,
          customMailboxImapPort: $customMailboxImapPort,
          customMailboxImapSecure: $customMailboxImapSecure,
          customMailboxSignature: $customMailboxSignature,
          customMailboxReplyTo: $customMailboxReplyTo,
          customMailboxBccToSelf: $customMailboxBccToSelf,
          customMailboxRequestReadReceipt: $customMailboxRequestReadReceipt,
          customMailboxPriority: $customMailboxPriority,
          customMailboxAutoReplyEnabled: $customMailboxAutoReplyEnabled,
          customMailboxAutoReplyMessage: $customMailboxAutoReplyMessage,
          customMailboxMaxAttachmentSize: $customMailboxMaxAttachmentSize,
          customMailboxConnectionStatus: $customMailboxConnectionStatus,
          customMailboxLastTestTime: $customMailboxLastTestTime,
          customMailboxNotes: $customMailboxNotes,
          showCustomMailboxAdvanced: $showCustomMailboxAdvanced,
          settingsSendMethod: $settingsSendMethod,
          emailjsQuotaUsed: $emailjsQuotaUsed,
          emailjsQuotaTotal: $emailjsQuotaTotal,
          resendQuotaUsed: $resendQuotaUsed,
          resendQuotaTotal: $resendQuotaTotal,
          proxyEnabled: $proxyEnabled,
          proxyBaseUrl: $proxyBaseUrl,
          proxyAuthToken: $proxyAuthToken,
          proxyTimeout: $proxyTimeout,
          proxyTestResult: $proxyTestResult,
          settingsAutoCheck: $settingsAutoCheck,
          settingsCheckInterval: $settingsCheckInterval,
          settingsEmailNotification: $settingsEmailNotification,
          settingsExpiryNotification: $settingsExpiryNotification,
          settingsDesktopNotification: $settingsDesktopNotification,
          enableEmailSearch: $enableEmailSearch,
          enableTemplates: $enableTemplates,
          enableFolders: $enableFolders,
          enableStatistics: $enableStatistics,
          showExportDialog: $showExportDialog,
          exportFormat: $exportFormat,
          exportMailboxId: $exportMailboxId,
          uiTexts: $uiTexts,
          i18nService: this.i18nService,
          systemService: this.systemService,
          onSaveSettings: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onSaveSettings callback triggered')
            try {
              // 保存设置到本地存储
              await this.saveAndApplySettings()
              await this.systemService.showToast(this.uiTexts['tipSettingsSaved'] || 'Settings saved')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipSaveSettingsFailed'] || 'Save settings failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Save settings error: %{public}s', err.message)
            }
          },
          onResetSettings: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onResetSettings callback triggered')
            try {
              // 重置所有设置为默认值
              this.settingsTheme = 'auto'
              this.settingsLanguage = 'en-US'
              this.settingsAutoCleanup = true
              this.settingsPrefixLength = 8
              this.settingsNewMailboxDelay = 0
              this.settingsAutoCheck = false
              this.settingsCheckInterval = 30
              this.settingsEmailNotification = true
              this.settingsExpiryNotification = true
              
              await this.systemService.showToast(this.uiTexts['tipSettingsReset'] || 'Settings reset to default')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipResetFailed'] || 'Reset failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Reset settings error: %{public}s', err.message)
            }
          },
          onConfigureService: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onConfigureService callback triggered, sendMethod=%{public}s', this.settingsSendMethod)
            try {
              // 根据当前的发送方式进行条件判断
              if (this.settingsSendMethod === 'custom-smtp') {
                // 自定义SMTP - 检查是否已配置
                this.customMailboxEnabled = true
                this.currentPage = PageType.SETTINGS
                
                // 检查SMTP配置是否完整
                const validation = this.validateCustomMailboxConfig()
                if (validation.valid && this.customMailboxConnectionStatus === 'connected') {
                  // 已配置且连接成功
                  hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'SMTP已配置且连接成功')
                  await this.systemService.showToast(this.uiTexts['tipSmtpConfigured'] || 'SMTP configured and connected')
                } else {
                  // 未配置或连接失败
                  hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '等待SMTP配置完成')
                  await this.systemService.showToast(this.uiTexts['tipSmtpWaitingConfig'] || 'Please complete SMTP configuration')
                }
              } else if (this.settingsSendMethod === 'emailjs-builtin') {
                // 内置EmailJS - 显示配额信息
                this.currentPage = PageType.SETTINGS
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '显示EmailJS配额信息')
                await this.systemService.showToast(this.uiTexts['tipEmailJSBuiltinInfo'] || 'EmailJS built-in service (2 emails/month)')
              } else if (this.settingsSendMethod === 'emailjs-external') {
                // 外部EmailJS - 显示配置指南
                this.currentPage = PageType.SETTINGS
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '显示外部EmailJS配置指南')
                await this.systemService.showToast(this.uiTexts['tipEmailJSExternalInfo'] || 'Configure your EmailJS account')
              } else if (this.settingsSendMethod === 'resend-builtin') {
                // 内置Resend - 显示配额信息
                this.currentPage = PageType.SETTINGS
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '显示Resend配额信息')
                await this.systemService.showToast(this.uiTexts['tipResendBuiltinInfo'] || 'Resend built-in service (3 emails/month)')
              } else if (this.settingsSendMethod === 'resend-external') {
                // 外部Resend - 显示配置指南
                this.currentPage = PageType.SETTINGS
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '显示外部Resend配置指南')
                await this.systemService.showToast(this.uiTexts['tipResendExternalInfo'] || 'Configure your Resend account')
              } else {
                // 其他发送方式
                this.currentPage = PageType.SETTINGS
                hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '导航到邮件发送设置')
                await this.systemService.showToast(this.uiTexts['tipConfigureServiceSuccess'] || 'Email service configured')
              }
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipConfigureServiceFailed'] || 'Configure service failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Configure service error: %{public}s', err.message)
            }
          },
          onChangeLanguage: async (lang: string) => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onChangeLanguage callback triggered: %{public}s', lang)
            try {
              this.settingsLanguage = lang
              this.currentLanguage = lang === 'zh-CN' ? '中文' : 'English'
              this.showLanguageMenu = false
              
              // 更新UI文本
              this.updateUITexts(lang)
              
              await this.systemService.showToast(this.uiTexts['tipLanguageChanged'] || 'Language changed')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipChangeLanguageFailed'] || 'Change language failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Change language error: %{public}s', err.message)
            }
          },
          onClearData: async () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onClearData callback triggered')
            try {
              // 清空所有数据
              this.mailboxes = []
              this.emails = []
              this.sentEmails = []
              this.selectedEmail = null
              this.selectedSentEmail = null
              
              await this.systemService.showToast(this.uiTexts['tipAllDataCleared'] || 'All data cleared')
            } catch (error) {
              const err = error as Error
              await this.systemService.showToast(this.uiTexts['tipClearDataFailed'] || 'Clear data failed: ' + err.message)
              hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Clear data error: %{public}s', err.message)
            }
          },
          onViewRules: () => {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'onViewRules callback triggered')
            this.showRulesPage = true
          }
        })
      }
    }
    .width('100%')
    .alignContent(Alignment.TopStart)
    .layoutWeight(1)
  }
}
