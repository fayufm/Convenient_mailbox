/**
 * 邮箱管理器
 * 核心业务逻辑：邮箱生成、邮件管理、数据持久化
 */

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { MailboxData, MailboxStatus, MailboxType, CustomMailboxConfig, EmailData, EmailType, EmailCategory, DraftData, SettingsData, TempEmail, SentEmailData, AttachmentData, EmailTemplate, TemplateCategory, MailboxFolder, EmailTag, MailboxStatistics, TagStatItem, DomainStatItem, EmailTrendItem } from './DataTypes'
import { NetworkService } from './NetworkService'
import { I18nService } from './I18nService'
import { SystemService } from './SystemService'
import { AppConstants } from './Constants'
import { MailboxProviderFactory } from '../services/mailbox/MailboxProviderFactory'
import { DomainManager } from '../services/DomainManager'
import { QuotaManager } from '../services/QuotaManager'
import { UserEmailConfigManager } from '../config/UserEmailConfig'
import { SecureStorage } from './SecureStorage'
import { SecureEmailServiceConfig } from '../config/EmailServiceConfig'
import { ProxyResponse, IMAPListRequest, IMAPEmailData } from '../types/ProxyTypes'
import hilog from '@ohos.hilog'

/**
 * 导出数据接口
 */
interface ExportData {
  version: string
  mailboxes: MailboxData[]
  emails: EmailData[]
  drafts: DraftData[]
  sentEmails: SentEmailData[]
  templates: EmailTemplate[]
  folders: MailboxFolder[]
  tags: EmailTag[]
  settings: SettingsData
  exportTime: number
}

/**
 * 邮箱管理器类（单例模式）
 */
export class MailboxManager {
  private static instance: MailboxManager

  // 服务实例
  private networkService: NetworkService = NetworkService.getInstance()
  private i18nService: I18nService = I18nService.getInstance()
  private systemService: SystemService = SystemService.getInstance()
  private providerFactory: MailboxProviderFactory = MailboxProviderFactory.getInstance()
  private domainManager: DomainManager = DomainManager.getInstance()
  private quotaManager: QuotaManager = QuotaManager.getInstance()
  private emailConfigManager: UserEmailConfigManager = UserEmailConfigManager.getInstance()

  // 数据存储
  private mailboxes: MailboxData[] = []
  private emails: EmailData[] = []
  private drafts: DraftData[] = []
  private sentEmails: SentEmailData[] = []  // ✅ 已发送的邮件记录
  private currentMailbox: MailboxData | null = null
  private deletedEmailIds: Set<number> = new Set()  // ✅ 记录已删除的邮件ID
  private deletedSentEmailIds: Set<number> = new Set()  // ✅ 记录已删除的发送记录ID
  
  // 🆕 功能增强数据存储 @since v1.0.1
  private templates: EmailTemplate[] = []  // 邮件模板
  private folders: MailboxFolder[] = []    // 邮箱文件夹
  private tags: EmailTag[] = []            // 邮件标签
  private searchHistory: string[] = []     // 搜索历史记录

  // 设置
  private settings: SettingsData = {
    theme: 'light',
    language: 'zh-CN',
    defaultDuration: AppConstants.DEFAULT_DURATION_DAYS,
    defaultDomain: AppConstants.DEFAULT_DOMAIN,
    prefixLength: AppConstants.DEFAULT_PREFIX_LENGTH,
    autoCleanup: true,
    emailNotification: false,
    expiryNotification: true,
    desktopNotification: false,
    // 新增字段默认值
    sendMethod: 'resend-builtin',
    autoCheck: true,
    checkInterval: 30,
    newMailboxDelay: 5,
    // 🆕 功能增强开关默认值 @since v1.0.1 - 修复遗漏的初始值
    enableEmailSearch: true,
    enableTemplates: true,
    enableFolders: true,
    enableStatistics: true,
    enableTags: false,
    enableAutoCategory: false,
    enableDataVisualization: false,
    enableAdvancedBackup: false,
    enableFAB: false
  }

  // Preferences存储
  private preferencesHelper: preferences.Preferences | null = null

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): MailboxManager {
    if (!MailboxManager.instance) {
      MailboxManager.instance = new MailboxManager()
    }
    return MailboxManager.instance
  }

  // ==================== 初始化 ====================

  /**
   * 初始化管理器
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      // 初始化数据存储
      this.preferencesHelper = await preferences.getPreferences(context, 'convenient_mailbox')

      // ✅ 初始化安全存储
      const secureStorage = SecureStorage.getInstance()
      await secureStorage.initialize(context)

      // ✅ 初始化并迁移API密钥
      await SecureEmailServiceConfig.initialize()

      // 初始化国际化服务
      await this.i18nService.initialize(context)

      // 初始化配额管理器
      await this.quotaManager.initialize(context)

      // 初始化邮件配置管理器
      await this.emailConfigManager.initialize(context)

      // 加载保存的数据
      await this.loadData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'MailboxManager初始化成功，邮箱数: %{public}d', this.mailboxes.length)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'MailboxManager初始化失败: %{public}s', err.message)
      // 不抛出错误，允许应用继续运行
    }
  }

  /**
   * 检查是否已初始化
   */
  isInitialized(): boolean {
    return this.preferencesHelper !== null
  }

  /**
   * 重试初始化（仅初始化preferences和加载数据）
   */
  async retryInitialization(context: common.UIAbilityContext): Promise<boolean> {
    if (this.preferencesHelper) {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'MailboxManager已初始化，无需重试')
      return true
    }

    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '重试MailboxManager初始化...')
      
      // 只重试preferences和数据加载
      this.preferencesHelper = await preferences.getPreferences(context, 'convenient_mailbox')
      await this.loadData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'MailboxManager重试初始化成功')
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'MailboxManager重试初始化失败: %{public}s', err.message)
      return false
    }
  }

  // ==================== 数据持久化 ====================

  /**
   * 加载数据
   */
  private async loadData(): Promise<void> {
    if (!this.preferencesHelper) {
      return
    }

    try {
      const mailboxesStr = await this.preferencesHelper.get('mailboxes', '[]')
      const emailsStr = await this.preferencesHelper.get('emails', '[]')
      const draftsStr = await this.preferencesHelper.get('drafts', '[]')
      const sentEmailsStr = await this.preferencesHelper.get('sentEmails', '[]')  // ✅ 加载已发送邮件
      const settingsStr = await this.preferencesHelper.get('settings', '{}')
      const deletedEmailIdsStr = await this.preferencesHelper.get('deletedEmailIds', '[]')  // ✅ 加载已删除邮件ID
      const deletedSentEmailIdsStr = await this.preferencesHelper.get('deletedSentEmailIds', '[]')  // ✅ 加载已删除发送记录ID
      
      // 🆕 加载功能增强数据 @since v1.0.1
      const templatesStr = await this.preferencesHelper.get('templates', '[]')
      const foldersStr = await this.preferencesHelper.get('folders', '[]')
      const tagsStr = await this.preferencesHelper.get('tags', '[]')
      const searchHistoryStr = await this.preferencesHelper.get('searchHistory', '[]')

      this.mailboxes = JSON.parse(mailboxesStr.toString()) as MailboxData[]
      this.emails = JSON.parse(emailsStr.toString()) as EmailData[]
      this.drafts = JSON.parse(draftsStr.toString()) as DraftData[]
      this.sentEmails = JSON.parse(sentEmailsStr.toString()) as SentEmailData[]  // ✅ 解析已发送邮件
      
      // ✅ 恢复已删除邮件ID的Set
      const deletedIdsArray = JSON.parse(deletedEmailIdsStr.toString()) as number[]
      this.deletedEmailIds = new Set(deletedIdsArray)
      
      // ✅ 恢复已删除发送记录ID的Set
      const deletedSentIdsArray = JSON.parse(deletedSentEmailIdsStr.toString()) as number[]
      this.deletedSentEmailIds = new Set(deletedSentIdsArray)
      
      // 🆕 解析功能增强数据 @since v1.0.1
      this.templates = JSON.parse(templatesStr.toString()) as EmailTemplate[]
      this.folders = JSON.parse(foldersStr.toString()) as MailboxFolder[]
      this.tags = JSON.parse(tagsStr.toString()) as EmailTag[]
      this.searchHistory = JSON.parse(searchHistoryStr.toString()) as string[]
      
      // 🆕 数据迁移：将已保存的emoji替换为纯文本
      this.migrateEmojiToPlainText()
      
      // 🆕 初始化默认数据（如果为空）
      if (this.templates.length === 0) {
        this.initializeDefaultTemplates()
      }
      if (this.folders.length === 0) {
        this.initializeDefaultFolders()
      }
      if (this.tags.length === 0) {
        this.initializeDefaultTags()
      }
      
      const loadedSettings: ESObject = JSON.parse(settingsStr.toString())
      if (loadedSettings && typeof loadedSettings === 'object') {
        // ✅ 手动合并加载的设置与默认值，确保新增字段有默认值（ArkTS不支持对象展开）
        if (loadedSettings.theme !== undefined) { this.settings.theme = loadedSettings.theme as string }
        if (loadedSettings.language !== undefined) { this.settings.language = loadedSettings.language as string }
        if (loadedSettings.defaultDuration !== undefined) { this.settings.defaultDuration = loadedSettings.defaultDuration as number }
        if (loadedSettings.defaultDomain !== undefined) { this.settings.defaultDomain = loadedSettings.defaultDomain as string }
        if (loadedSettings.prefixLength !== undefined) { this.settings.prefixLength = loadedSettings.prefixLength as number }
        if (loadedSettings.autoCleanup !== undefined) { this.settings.autoCleanup = loadedSettings.autoCleanup as boolean }
        if (loadedSettings.emailNotification !== undefined) { this.settings.emailNotification = loadedSettings.emailNotification as boolean }
        if (loadedSettings.expiryNotification !== undefined) { this.settings.expiryNotification = loadedSettings.expiryNotification as boolean }
        if (loadedSettings.desktopNotification !== undefined) { this.settings.desktopNotification = loadedSettings.desktopNotification as boolean }
        if (loadedSettings.sendMethod !== undefined) { this.settings.sendMethod = loadedSettings.sendMethod as string }
        if (loadedSettings.autoCheck !== undefined) { this.settings.autoCheck = loadedSettings.autoCheck as boolean }
        if (loadedSettings.checkInterval !== undefined) { this.settings.checkInterval = loadedSettings.checkInterval as number }
        if (loadedSettings.newMailboxDelay !== undefined) { this.settings.newMailboxDelay = loadedSettings.newMailboxDelay as number }
        
        // 🆕 加载功能增强开关 @since v1.0.1 - 修复缺失的字段加载
        if (loadedSettings.enableEmailSearch !== undefined) { this.settings.enableEmailSearch = loadedSettings.enableEmailSearch as boolean }
        if (loadedSettings.enableTemplates !== undefined) { this.settings.enableTemplates = loadedSettings.enableTemplates as boolean }
        if (loadedSettings.enableFolders !== undefined) { this.settings.enableFolders = loadedSettings.enableFolders as boolean }
        if (loadedSettings.enableStatistics !== undefined) { this.settings.enableStatistics = loadedSettings.enableStatistics as boolean }
        if (loadedSettings.enableTags !== undefined) { this.settings.enableTags = loadedSettings.enableTags as boolean }
        if (loadedSettings.enableAutoCategory !== undefined) { this.settings.enableAutoCategory = loadedSettings.enableAutoCategory as boolean }
        if (loadedSettings.enableDataVisualization !== undefined) { this.settings.enableDataVisualization = loadedSettings.enableDataVisualization as boolean }
        if (loadedSettings.enableAdvancedBackup !== undefined) { this.settings.enableAdvancedBackup = loadedSettings.enableAdvancedBackup as boolean }
        if (loadedSettings.enableFAB !== undefined) { this.settings.enableFAB = loadedSettings.enableFAB as boolean }
      }

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据加载成功: 邮箱%{public}d, 邮件%{public}d, 已发送%{public}d, 模板%{public}d, 文件夹%{public}d, 标签%{public}d',
        this.mailboxes.length, this.emails.length, this.sentEmails.length, this.templates.length, this.folders.length, this.tags.length)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '加载数据失败: %{public}s', err.message)
    }
  }

  /**
   * 保存数据
   */
  private async saveData(): Promise<void> {
    if (!this.preferencesHelper) {
      const errorMsg = '数据存储未初始化，无法保存数据。请稍后重试。'
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, errorMsg)
      throw new Error(errorMsg)
    }

    try {
      await this.preferencesHelper.put('mailboxes', JSON.stringify(this.mailboxes))
      await this.preferencesHelper.put('emails', JSON.stringify(this.emails))
      await this.preferencesHelper.put('drafts', JSON.stringify(this.drafts))
      await this.preferencesHelper.put('sentEmails', JSON.stringify(this.sentEmails))  // ✅ 保存已发送邮件
      await this.preferencesHelper.put('settings', JSON.stringify(this.settings))
      // ✅ 保存已删除邮件ID（Set转数组）
      const deletedIdsArray = Array.from(this.deletedEmailIds)
      await this.preferencesHelper.put('deletedEmailIds', JSON.stringify(deletedIdsArray))
      // ✅ 保存已删除发送记录ID（Set转数组）
      const deletedSentIdsArray = Array.from(this.deletedSentEmailIds)
      await this.preferencesHelper.put('deletedSentEmailIds', JSON.stringify(deletedSentIdsArray))
      
      // 🆕 保存功能增强数据 @since v1.0.1
      await this.preferencesHelper.put('templates', JSON.stringify(this.templates))
      await this.preferencesHelper.put('folders', JSON.stringify(this.folders))
      await this.preferencesHelper.put('tags', JSON.stringify(this.tags))
      await this.preferencesHelper.put('searchHistory', JSON.stringify(this.searchHistory))
      
      await this.preferencesHelper.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '数据保存成功 (模板: %{public}d, 文件夹: %{public}d, 标签: %{public}d)', 
        this.templates.length, this.folders.length, this.tags.length)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存数据失败: %{public}s', err.message)
      throw new Error(`数据保存失败: ${err.message}`)
    }
  }

  // ==================== 邮箱管理 ====================

  /**
   * 生成随机邮箱
   */
  async generateRandomMailbox(duration?: number, specifiedDomain?: string): Promise<MailboxData> {
    const prefix = this.generateRandomPrefix(this.settings.prefixLength)
    
    // 使用指定域名或随机选择
    let domain: string
    if (specifiedDomain && specifiedDomain !== 'random') {
      domain = specifiedDomain
    } else {
      domain = this.domainManager.getRandomDomain(true) // 优先选择有API支持的域名
    }

    // 使用提供商生成邮箱
    const provider = this.providerFactory.getProviderByDomain(domain)
    const result = await provider.generateRandomMailbox(domain)
    
    let email: string
    if (result.success && result.data) {
      email = result.data
      // 更新前缀和域名（如果API返回的与预期不同）
      const parts = email.split('@')
      if (parts.length === 2) {
        domain = parts[1]
      }
    } else {
      // 如果API失败，直接生成邮箱地址
      email = `${prefix}@${domain}`
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '提供商生成失败，使用本地生成: %{public}s', email)
    }

    const now = Date.now()
    const expiryDays = duration || this.settings.defaultDuration
    const expiryTime = now + (expiryDays * 24 * 60 * 60 * 1000)
    
    // 计算邮箱可用时间（冷却时间）
    const delayMinutes = this.settings.newMailboxDelay || 5
    const availableTime = now + (delayMinutes * 60 * 1000)

    const mailbox: MailboxData = {
      id: now + Math.random() * 1000,
      email: email,
      prefix: email.split('@')[0],
      domain: domain,
      createdTime: now,
      expiryTime: expiryTime,
      availableTime: availableTime,
      status: MailboxStatus.ACTIVE,
      emailCount: 0,
      unreadCount: 0
    }

    this.mailboxes.push(mailbox)
    this.currentMailbox = mailbox
    
    // 如果启用了自动清理，执行清理过期邮箱
    if (this.settings.autoCleanup) {
      const cleanedCount = this.cleanupExpiredMailboxes()
      if (cleanedCount > 0) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自动清理过期邮箱: %{public}d个', cleanedCount)
      }
    }
    
    await this.saveData()

    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '生成邮箱: %{public}s (域名支持API: %{public}s)', 
      email, this.domainManager.hasAPISupport(domain) ? '是' : '否')

    return mailbox
  }

  /**
   * 创建自定义邮箱
   */
  async createCustomMailbox(prefix: string, domain: string, duration?: number): Promise<MailboxData | null> {
    try {
      // 使用提供商创建邮箱
      const provider = this.providerFactory.getProviderByDomain(domain)
      const result = await provider.createCustomMailbox(prefix, domain)
      
      if (!result.success || !result.data) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '创建自定义邮箱失败: %{public}s', result.error || '未知错误')
        return null
      }

      const email = result.data
      const now = Date.now()
      const expiryDays = duration || this.settings.defaultDuration
      const expiryTime = now + (expiryDays * 24 * 60 * 60 * 1000)
      
      // 计算邮箱可用时间（冷却时间）
      const delayMinutes = this.settings.newMailboxDelay || 5
      const availableTime = now + (delayMinutes * 60 * 1000)

      const mailbox: MailboxData = {
        id: now + Math.random() * 1000,
        email: email,
        prefix: prefix,
        domain: domain,
        createdTime: now,
        expiryTime: expiryTime,
        availableTime: availableTime,
        status: MailboxStatus.ACTIVE,
        emailCount: 0,
        unreadCount: 0
      }

      this.mailboxes.push(mailbox)
      this.currentMailbox = mailbox
      await this.saveData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '创建自定义邮箱: %{public}s', email)

      return mailbox
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '创建自定义邮箱异常: %{public}s', err.message)
      return null
    }
  }

  /**
   * 生成随机前缀
   */
  private generateRandomPrefix(length: number): string {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let result = ''
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  /**
   * 删除邮箱
   */
  deleteMailbox(mailboxId: number): void {
    const index = this.mailboxes.findIndex(m => m.id === mailboxId)
    if (index !== -1) {
      this.mailboxes.splice(index, 1)

      // 删除相关邮件
      this.emails = this.emails.filter(e => e.mailboxId !== mailboxId)

      // 如果删除的是当前邮箱，清空当前邮箱
      if (this.currentMailbox && this.currentMailbox.id === mailboxId) {
        this.currentMailbox = null
      }

      this.saveData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '删除邮箱: %{public}d', mailboxId)
    }
  }

  /**
   * 更新邮箱
   */
  async updateMailbox(mailbox: MailboxData): Promise<void> {
    const index = this.mailboxes.findIndex(m => m.id === mailbox.id)
    if (index !== -1) {
      this.mailboxes[index] = mailbox

      // 如果更新的是当前邮箱，同步更新
      if (this.currentMailbox && this.currentMailbox.id === mailbox.id) {
        this.currentMailbox = mailbox
      }

      await this.saveData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '更新邮箱: %{public}d', mailbox.id)
    }
  }

  /**
   * 设置当前邮箱
   */
  setCurrentMailbox(mailbox: MailboxData): void {
    this.currentMailbox = mailbox
  }

  /**
   * 延长邮箱有效期
   */
  extendMailbox(mailbox: MailboxData, additionalDays: number): void {
    mailbox.expiryTime += additionalDays * 24 * 60 * 60 * 1000
    this.saveData()
  }

  // ==================== 邮件管理 ====================

  /**
   * 检查新邮件（支持临时邮箱和自定义邮箱）
   * @since 2.1.0 新增自定义邮箱支持
   */
  async checkNewEmails(mailboxId: number): Promise<void> {
    const mailbox = this.mailboxes.find(m => m.id === mailboxId)
    if (!mailbox) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '未找到邮箱ID=%{public}d', mailboxId)
      return
    }

    // 🆕 判断邮箱类型并使用对应的接收方法
    if (this.isCustomMailbox(mailbox)) {
      // 自定义邮箱：通过代理IMAP接收
      await this.checkCustomMailboxEmails(mailbox)
    } else {
      // 临时邮箱：通过API接收
      await this.checkTempMailboxEmails(mailbox)
    }
  }

  /**
   * 🆕 判断是否为自定义邮箱
   * @private
   * @since 2.1.0
   */
  private isCustomMailbox(mailbox: MailboxData): boolean {
    return mailbox.isCustom === true || mailbox.mailboxType === MailboxType.CUSTOM
  }

  /**
   * 🆕 验证自定义邮箱配置是否完整
   * @private
   * @since 2.1.0
   */
  private validateCustomMailboxConfig(mailbox: MailboxData): boolean {
    if (!this.isCustomMailbox(mailbox)) {
      return false
    }
    
    if (!mailbox.customConfig) {
      return false
    }
    
    const config = mailbox.customConfig
    return !!(
      config.password &&
      config.imapHost &&
      config.imapPort > 0 &&
      config.imapPort <= 65535
    )
  }

  /**
   * 🆕 检查自定义邮箱邮件（通过代理IMAP）
   * @private
   * @since 2.1.0
   */
  private async checkCustomMailboxEmails(mailbox: MailboxData): Promise<void> {
    try {
      // 验证配置
      if (!this.validateCustomMailboxConfig(mailbox)) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义邮箱配置不完整: %{public}s', mailbox.email)
        return
      }
      
      // 获取代理配置
      const proxyConfig = await this.emailConfigManager.getProxyConfig()
      if (!proxyConfig.enabled || !proxyConfig.baseUrl) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义邮箱需要配置后端代理服务器')
        return
      }
      
      const config = mailbox.customConfig!
      const url = `${proxyConfig.baseUrl}/email/receive/imap/list`
      
      // 构建请求
      const requestData: IMAPListRequest = {
        email: mailbox.email,
        password: config.password,
        imapHost: config.imapHost,
        imapPort: config.imapPort,
        secure: config.imapSecure,
        limit: 50,
        folder: config.imapFolder || 'INBOX'
      }
      
      // 构建请求头
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      }
      if (proxyConfig.authToken) {
        headers['Authorization'] = `Bearer ${proxyConfig.authToken}`
      }
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '正在通过代理获取自定义邮箱邮件: %{public}s', mailbox.email)
      
      // 调用代理API
      const response = await this.networkService.post<ProxyResponse<IMAPEmailData[]>>(
        url,
        requestData,
        headers
      )
      
      if (response.success && response.data && response.data.success && response.data.data) {
        const imapEmails = response.data.data
        let newCount = 0
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '从代理获取到%{public}d封邮件', imapEmails.length)
        
        // 处理邮件
        for (const imapEmail of imapEmails) {
          // 生成本地ID（使用IMAP ID的hash）
          const localId = this.hashEmailId(imapEmail.id)
          
          // 检查是否已存在或已删除
          const exists = this.emails.some(e =>
            e.id === localId && e.mailboxId === mailbox.id
          )
          const isDeleted = this.deletedEmailIds.has(localId)
          
          if (!exists && !isDeleted) {
            const email: EmailData = {
              id: localId,
              mailboxId: mailbox.id,
              from: imapEmail.from,
              subject: imapEmail.subject,
              date: imapEmail.date,
              body: imapEmail.preview || '',
              isRead: false,
              isVerification: this.detectVerificationEmail(
                imapEmail.subject,
                imapEmail.preview || ''
              ),
              emailType: EmailType.NORMAL,
              receivedTime: Date.now(),
              attachments: imapEmail.attachments?.map(att => {
                const attachment: AttachmentData = {
                  id: att.filename,
                  filename: att.filename,
                  size: att.size,
                  contentType: att.contentType
                }
                return attachment
              })
            }
            
            this.emails.push(email)
            newCount++
            
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
              '新邮件: ID=%{public}d, From=%{public}s, Subject=%{public}s',
              email.id, email.from, email.subject)
          }
        }
        
        // 更新邮箱统计
        mailbox.emailCount = this.emails.filter(e =>
          e.mailboxId === mailbox.id
        ).length
        mailbox.unreadCount = this.emails.filter(e =>
          e.mailboxId === mailbox.id && !e.isRead
        ).length
        
        // 更新最后同步时间
        if (mailbox.customConfig) {
          mailbox.customConfig.lastSyncTime = Date.now()
        }
        
        if (newCount > 0) {
          this.saveData()
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '自定义邮箱收到%{public}d封新邮件，已保存', newCount)
        } else {
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '自定义邮箱没有新邮件')
        }
      } else {
        const errorMsg = response.data?.error || response.error || '未知错误'
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '检查自定义邮箱失败: %{public}s', errorMsg)
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '检查自定义邮箱异常: %{public}s', err.message)
    }
  }

  /**
   * ✅ 检查临时邮箱邮件（现有逻辑，重命名）
   * @private
   * @since 2.1.0 从checkNewEmails重构而来
   */
  private async checkTempMailboxEmails(mailbox: MailboxData): Promise<void> {
    try {
      // 原有的checkNewEmails逻辑
      const domain = mailbox.email.split('@')[1]
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '检查新邮件: email=%{public}s, domain=%{public}s', mailbox.email, domain)
      
      const provider = this.providerFactory.getProviderByDomain(domain)
      const providerName = provider.getConfig().name
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '使用提供商: %{public}s 检查邮件', providerName)
      
      // 使用provider的getEmailList方法，而不是NetworkService.checkEmails
      const response = await provider.getEmailList(mailbox.email)

      if (response.success && response.data) {
        const tempEmails = response.data
        let newCount = 0

        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '✅ 从API获取到%{public}d封邮件', tempEmails.length)

        for (let i = 0; i < tempEmails.length; i++) {
          const tempEmail = tempEmails[i]
          // ✅ 检查是否已存在或已被删除
          const exists = this.emails.some(e => e.id === tempEmail.id && e.mailboxId === mailbox.id)
          const isDeleted = this.deletedEmailIds.has(tempEmail.id)

          if (!exists && !isDeleted) {
            const email: EmailData = {
              id: tempEmail.id,
              mailboxId: mailbox.id,
              from: tempEmail.from,
              subject: tempEmail.subject,
              date: tempEmail.date,
              body: '',
              isRead: false,
              isVerification: false,
              emailType: EmailType.NORMAL,
              receivedTime: Date.now()
            }

            this.emails.push(email)
            newCount++
            
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
              '📬 新邮件: ID=%{public}d, From=%{public}s, Subject=%{public}s',
              email.id, email.from, email.subject)
          }
        }

        // 更新邮箱统计
        mailbox.emailCount = this.emails.filter(e => e.mailboxId === mailbox.id).length
        mailbox.unreadCount = this.emails.filter(e => e.mailboxId === mailbox.id && !e.isRead).length

        if (newCount > 0) {
          this.saveData()
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '✅ 收到%{public}d封新邮件，已保存', newCount)
        } else {
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '📭 没有新邮件')
        }
      } else {
        // ⚠️ 邮箱检查失败（通常是临时邮箱服务问题，如1SecMail的403错误）
        const errorMsg = response.error || '未知错误'
        
        // 特殊处理1SecMail的403错误
        if (errorMsg.includes('HTTP 403') || errorMsg.includes('403 Forbidden')) {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '⚠️ 临时邮箱服务暂时不可用（HTTP 403）: %{public}s\n' +
            '这是第三方服务器问题，不影响邮件发送功能。', mailbox.email)
        } else {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '⚠️ 检查邮件失败: %{public}s, 错误: %{public}s',
            mailbox.email, errorMsg)
        }
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '检查邮件失败: %{public}s', err.message)
    }
  }

  /**
   * 删除邮件
   */
  deleteEmail(emailId: number): void {
    const index = this.emails.findIndex(e => e.id === emailId)
    if (index !== -1) {
      const email = this.emails[index]
      this.emails.splice(index, 1)

      // 更新邮箱统计
      const mailbox = this.mailboxes.find(m => m.id === email.mailboxId)
      if (mailbox) {
        mailbox.emailCount--
        if (!email.isRead) {
          mailbox.unreadCount--
        }
      }

      // ✅ 记录已删除的邮件ID，防止刷新时重新出现
      if (!this.deletedEmailIds) {
        this.deletedEmailIds = new Set<number>()
      }
      this.deletedEmailIds.add(emailId)

      this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮件已删除: ID=%{public}d', emailId)
    }
  }
  
  /**
   * 添加已发送邮件
   */
  addSentEmail(sentEmail: SentEmailData): void {
    this.sentEmails.push(sentEmail)
    this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '已保存发送记录: ID=%{public}d, to=%{public}s', sentEmail.id, sentEmail.to)
  }
  
  /**
   * 删除已发送邮件
   */
  deleteSentEmail(sentEmailId: number): void {
    const index = this.sentEmails.findIndex(e => e.id === sentEmailId)
    if (index !== -1) {
      this.sentEmails.splice(index, 1)
      
      // ✅ 记录已删除的发送记录ID，防止重新出现
      if (!this.deletedSentEmailIds) {
        this.deletedSentEmailIds = new Set<number>()
      }
      this.deletedSentEmailIds.add(sentEmailId)
      
      this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '发送记录已删除: ID=%{public}d', sentEmailId)
    }
  }
  
  /**
   * 批量删除已发送邮件
   */
  deleteSentEmails(sentEmailIds: number[]): void {
    for (let i = 0; i < sentEmailIds.length; i++) {
      const emailId = sentEmailIds[i]
      const index = this.sentEmails.findIndex(e => e.id === emailId)
      if (index !== -1) {
        this.sentEmails.splice(index, 1)
        
        // ✅ 记录已删除的发送记录ID
        if (!this.deletedSentEmailIds) {
          this.deletedSentEmailIds = new Set<number>()
        }
        this.deletedSentEmailIds.add(emailId)
      }
    }
    
    this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '批量删除发送记录: %{public}d条', sentEmailIds.length)
  }
  
  /**
   * 清空所有已发送邮件
   */
  clearAllSentEmails(): void {
    // 记录所有已删除的发送记录ID
    for (let i = 0; i < this.sentEmails.length; i++) {
      if (!this.deletedSentEmailIds) {
        this.deletedSentEmailIds = new Set<number>()
      }
      this.deletedSentEmailIds.add(this.sentEmails[i].id)
    }
    
    this.sentEmails = []
    this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '已清空所有发送记录')
  }

  /**
   * 标记邮件为已读
   */
  markEmailAsRead(emailId: number): void {
    const email = this.emails.find(e => e.id === emailId)
    if (email && !email.isRead) {
      email.isRead = true

      // 更新邮箱统计
      const mailbox = this.mailboxes.find(m => m.id === email.mailboxId)
      if (mailbox) {
        mailbox.unreadCount--
      }

      this.saveData()
    }
  }

  // ==================== 过期管理 ====================

  /**
   * 检查过期邮箱
   */
  checkExpiredMailboxes(): void {
    const now = Date.now()
    let hasExpired = false

    for (let i = 0; i < this.mailboxes.length; i++) {
      const mailbox = this.mailboxes[i]
      if (mailbox.expiryTime < now && mailbox.status === MailboxStatus.ACTIVE) {
        mailbox.status = MailboxStatus.EXPIRED
        hasExpired = true
      }
    }

    if (hasExpired) {
      this.saveData()
    }
  }

  /**
   * 清理过期邮箱
   */
  cleanupExpiredMailboxes(): number {
    const now = Date.now()
    const expiredIds: number[] = []

    // 找出过期的邮箱ID
    for (let i = 0; i < this.mailboxes.length; i++) {
      if (this.mailboxes[i].expiryTime < now) {
        expiredIds.push(this.mailboxes[i].id)
      }
    }

    // 删除过期邮箱
    for (let i = 0; i < expiredIds.length; i++) {
      this.deleteMailbox(expiredIds[i])
    }

    return expiredIds.length
  }

  /**
   * 格式化剩余时间
   */
  formatRemainingTime(expiryDate: Date): string {
    const now = Date.now()
    const diff = expiryDate.getTime() - now

    if (diff <= 0) {
      return '已过期'
    }

    const days = Math.floor(diff / (24 * 60 * 60 * 1000))
    const hours = Math.floor((diff % (24 * 60 * 60 * 1000)) / (60 * 60 * 1000))
    const minutes = Math.floor((diff % (60 * 60 * 1000)) / (60 * 1000))

    if (days > 0) {
      return `${days}天`
    } else if (hours > 0) {
      return `${hours}小时`
    } else {
      return `${minutes}分钟`
    }
  }

  // ==================== 数据导入导出 ====================

  /**
   * 导出数据
   */
  exportData(): string {
    const data: ExportData = {
      version: '2.0.0',
      mailboxes: this.mailboxes,
      emails: this.emails,
      drafts: this.drafts,
      sentEmails: this.sentEmails,
      templates: this.templates,
      folders: this.folders,
      tags: this.tags,
      settings: this.settings,
      exportTime: Date.now()
    }
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '导出数据: 邮箱%{public}d, 邮件%{public}d, 已发送%{public}d, 模板%{public}d, 文件夹%{public}d, 标签%{public}d',
      this.mailboxes.length, this.emails.length, this.sentEmails.length, 
      this.templates.length, this.folders.length, this.tags.length)
    
    return JSON.stringify(data, null, 2)
  }

  /**
   * 导入数据
   */
  importData(dataStr: string): boolean {
    try {
      const data: ESObject = JSON.parse(dataStr)

      // 版本检查
      if (data.version && typeof data.version === 'string') {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '导入数据版本: %{public}s', data.version)
      }

      // 导入邮箱数据
      if (data.mailboxes && Array.isArray(data.mailboxes)) {
        this.mailboxes = data.mailboxes as MailboxData[]
      }
      
      // 导入邮件数据
      if (data.emails && Array.isArray(data.emails)) {
        this.emails = data.emails as EmailData[]
      }
      
      // 导入草稿数据
      if (data.drafts && Array.isArray(data.drafts)) {
        this.drafts = data.drafts as DraftData[]
      }
      
      // 导入已发送邮件数据
      if (data.sentEmails && Array.isArray(data.sentEmails)) {
        this.sentEmails = data.sentEmails as SentEmailData[]
      }
      
      // 导入模板数据
      if (data.templates && Array.isArray(data.templates)) {
        this.templates = data.templates as EmailTemplate[]
      }
      
      // 导入文件夹数据
      if (data.folders && Array.isArray(data.folders)) {
        this.folders = data.folders as MailboxFolder[]
      }
      
      // 导入标签数据
      if (data.tags && Array.isArray(data.tags)) {
        this.tags = data.tags as EmailTag[]
      }
      
      // 导入设置数据
      if (data.settings && typeof data.settings === 'object') {
        const loadedSettings: ESObject = data.settings
        if (loadedSettings.theme !== undefined) { this.settings.theme = loadedSettings.theme as string }
        if (loadedSettings.language !== undefined) { this.settings.language = loadedSettings.language as string }
        if (loadedSettings.defaultDuration !== undefined) { this.settings.defaultDuration = loadedSettings.defaultDuration as number }
        if (loadedSettings.defaultDomain !== undefined) { this.settings.defaultDomain = loadedSettings.defaultDomain as string }
        if (loadedSettings.prefixLength !== undefined) { this.settings.prefixLength = loadedSettings.prefixLength as number }
        if (loadedSettings.autoCleanup !== undefined) { this.settings.autoCleanup = loadedSettings.autoCleanup as boolean }
        if (loadedSettings.emailNotification !== undefined) { this.settings.emailNotification = loadedSettings.emailNotification as boolean }
        if (loadedSettings.expiryNotification !== undefined) { this.settings.expiryNotification = loadedSettings.expiryNotification as boolean }
        if (loadedSettings.sendMethod !== undefined) { this.settings.sendMethod = loadedSettings.sendMethod as string }
        if (loadedSettings.autoCheck !== undefined) { this.settings.autoCheck = loadedSettings.autoCheck as boolean }
        if (loadedSettings.checkInterval !== undefined) { this.settings.checkInterval = loadedSettings.checkInterval as number }
        if (loadedSettings.newMailboxDelay !== undefined) { this.settings.newMailboxDelay = loadedSettings.newMailboxDelay as number }
      }

      this.saveData()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据导入成功: 邮箱%{public}d, 邮件%{public}d, 已发送%{public}d, 模板%{public}d, 文件夹%{public}d, 标签%{public}d',
        this.mailboxes.length, this.emails.length, this.sentEmails.length,
        this.templates.length, this.folders.length, this.tags.length)
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据导入失败: %{public}s', err.message)
      return false
    }
  }

  // ==================== 🆕 自定义邮箱管理 ====================

  /**
   * 🆕 添加自定义邮箱
   * @since 2.1.0
   */
  async addCustomMailbox(mailboxData: MailboxData): Promise<boolean> {
    try {
      // ✅ 优化：使用更严格的邮箱地址格式验证
      // - 用户名部分：字母、数字、点、下划线、百分号、加号、减号
      // - @符号
      // - 域名部分：字母、数字、点、减号
      // - 顶级域名：至少2个字母
      const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/
      if (!emailRegex.test(mailboxData.email)) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '无效的邮箱地址格式: %{public}s', mailboxData.email)
        return false
      }
      
      // 检查邮箱是否已存在
      const exists = this.mailboxes.some(m => m.email === mailboxData.email)
      if (exists) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '邮箱已存在: %{public}s', mailboxData.email)
        return false
      }
      
      // 验证自定义配置
      if (!mailboxData.customConfig) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '自定义邮箱缺少配置')
        return false
      }
      
      // 🔒 加密密码
      if (mailboxData.customConfig.password) {
        mailboxData.customConfig.password = this.encryptPassword(mailboxData.customConfig.password)
      }
      
      // 设置邮箱类型
      mailboxData.mailboxType = MailboxType.CUSTOM
      mailboxData.isCustom = true
      
      // 添加到列表
      this.mailboxes.push(mailboxData)
      this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '自定义邮箱已添加: %{public}s (ID=%{public}d)', mailboxData.email, mailboxData.id)
      
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '添加自定义邮箱失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 🆕 更新自定义邮箱配置
   * @since 2.1.0
   */
  async updateCustomMailbox(mailboxId: number, config: CustomMailboxConfig): Promise<boolean> {
    try {
      const mailbox = this.mailboxes.find(m => m.id === mailboxId)
      if (!mailbox || !this.isCustomMailbox(mailbox)) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '未找到自定义邮箱ID=%{public}d', mailboxId)
        return false
      }
      
      // 🔒 加密密码
      if (config.password) {
        config.password = this.encryptPassword(config.password)
      }
      
      mailbox.customConfig = config
      this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '自定义邮箱配置已更新: ID=%{public}d', mailboxId)
      
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '更新自定义邮箱失败: %{public}s', err.message)
      return false
    }
  }

  // ==================== 🆕 辅助方法 ====================

  /**
   * 🆕 将IMAP邮件ID（字符串）转换为本地数字ID
   * 使用简单的hash算法
   * @private
   * @since 2.1.0
   */
  private hashEmailId(imapId: string): number {
    let hash = 0
    for (let i = 0; i < imapId.length; i++) {
      const char = imapId.charCodeAt(i)
      hash = ((hash << 5) - hash) + char
      hash = hash & hash // Convert to 32bit integer
    }
    return Math.abs(hash)
  }

  /**
   * 🆕 检测是否为验证码邮件
   * @private
   * @since 2.1.0
   */
  private detectVerificationEmail(subject: string, body: string): boolean {
    const keywords = [
      '验证码', '验证', 'verification', 'code', 'verify',
      'OTP', '动态密码', '一次性密码', 'confirmation',
      '确认码', 'security code', '安全码'
    ]
    
    const text = (subject + ' ' + body).toLowerCase()
    return keywords.some(keyword => text.includes(keyword.toLowerCase()))
  }

  /**
   * 🆕 加密密码（简单的XOR+Base64）
   * @private
   * @since 2.1.0
   */
  private encryptPassword(password: string): string {
    const key = 'CustomMailboxKey2025'
    let encrypted = ''
    
    for (let i = 0; i < password.length; i++) {
      const charCode = password.charCodeAt(i) ^ key.charCodeAt(i % key.length)
      encrypted += String.fromCharCode(charCode)
    }
    
    // Base64编码
    const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    let result = ''
    
    for (let i = 0; i < encrypted.length; i += 3) {
      const byte1 = encrypted.charCodeAt(i)
      const byte2 = i + 1 < encrypted.length ? encrypted.charCodeAt(i + 1) : 0
      const byte3 = i + 2 < encrypted.length ? encrypted.charCodeAt(i + 2) : 0
      
      const encoded1 = byte1 >> 2
      const encoded2 = ((byte1 & 3) << 4) | (byte2 >> 4)
      const encoded3 = ((byte2 & 15) << 2) | (byte3 >> 6)
      const encoded4 = byte3 & 63
      
      result += base64Chars.charAt(encoded1)
      result += base64Chars.charAt(encoded2)
      result += i + 1 < encrypted.length ? base64Chars.charAt(encoded3) : '='
      result += i + 2 < encrypted.length ? base64Chars.charAt(encoded4) : '='
    }
    
    return result
  }

  /**
   * 🆕 解密密码
   * @private
   * @since 2.1.0
   */
  private decryptPassword(encrypted: string): string {
    // Base64解码
    const base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    let decoded = ''
    
    for (let i = 0; i < encrypted.length; i += 4) {
      const encoded1 = base64Chars.indexOf(encrypted.charAt(i))
      const encoded2 = base64Chars.indexOf(encrypted.charAt(i + 1))
      const encoded3 = encrypted.charAt(i + 2) !== '=' ? base64Chars.indexOf(encrypted.charAt(i + 2)) : 0
      const encoded4 = encrypted.charAt(i + 3) !== '=' ? base64Chars.indexOf(encrypted.charAt(i + 3)) : 0
      
      const byte1 = (encoded1 << 2) | (encoded2 >> 4)
      const byte2 = ((encoded2 & 15) << 4) | (encoded3 >> 2)
      const byte3 = ((encoded3 & 3) << 6) | encoded4
      
      decoded += String.fromCharCode(byte1)
      if (encrypted.charAt(i + 2) !== '=') {
        decoded += String.fromCharCode(byte2)
      }
      if (encrypted.charAt(i + 3) !== '=') {
        decoded += String.fromCharCode(byte3)
      }
    }
    
    // XOR解密
    const key = 'CustomMailboxKey2025'
    let decrypted = ''
    
    for (let i = 0; i < decoded.length; i++) {
      const charCode = decoded.charCodeAt(i) ^ key.charCodeAt(i % key.length)
      decrypted += String.fromCharCode(charCode)
    }
    
    return decrypted
  }

  // ==================== Getters ====================

  getMailboxes(): MailboxData[] {
    // 如果启用了自动清理，先执行清理过期邮箱
    if (this.settings.autoCleanup) {
      const cleanedCount = this.cleanupExpiredMailboxes()
      if (cleanedCount > 0) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '获取邮箱列表时自动清理过期邮箱: %{public}d个', cleanedCount)
      }
    }
    
    // ✅ 返回数组副本，确保每次调用都返回新的数组引用
    // 这样 @State 才能检测到变化并触发UI更新
    const result: MailboxData[] = []
    for (let i = 0; i < this.mailboxes.length; i++) {
      result.push(this.mailboxes[i])
    }
    return result
  }

  getEmails(): EmailData[] {
    // ✅ 返回数组副本
    const result: EmailData[] = []
    for (let i = 0; i < this.emails.length; i++) {
      result.push(this.emails[i])
    }
    return result
  }

  getSentEmails(): SentEmailData[] {
    // ✅ 返回数组副本
    const result: SentEmailData[] = []
    for (let i = 0; i < this.sentEmails.length; i++) {
      result.push(this.sentEmails[i])
    }
    return result
  }

  getCurrentMailbox(): MailboxData | null {
    return this.currentMailbox
  }

  getSettings(): SettingsData {
    return this.settings
  }

  /**
   * 更新并保存设置
   */
  async updateSettings(settings: Partial<SettingsData>): Promise<void> {
    // 更新设置对象
    if (settings.theme !== undefined) {
      this.settings.theme = settings.theme
    }
    if (settings.language !== undefined) {
      this.settings.language = settings.language
    }
    if (settings.defaultDuration !== undefined) {
      this.settings.defaultDuration = settings.defaultDuration
    }
    if (settings.defaultDomain !== undefined) {
      this.settings.defaultDomain = settings.defaultDomain
    }
    if (settings.prefixLength !== undefined) {
      this.settings.prefixLength = settings.prefixLength
    }
    if (settings.autoCleanup !== undefined) {
      this.settings.autoCleanup = settings.autoCleanup
    }
    if (settings.emailNotification !== undefined) {
      this.settings.emailNotification = settings.emailNotification
    }
    if (settings.expiryNotification !== undefined) {
      this.settings.expiryNotification = settings.expiryNotification
    }
    if (settings.desktopNotification !== undefined) {
      this.settings.desktopNotification = settings.desktopNotification
    }
    // 新增字段
    if (settings.sendMethod !== undefined) {
      this.settings.sendMethod = settings.sendMethod
    }
    if (settings.autoCheck !== undefined) {
      this.settings.autoCheck = settings.autoCheck
    }
    if (settings.checkInterval !== undefined) {
      this.settings.checkInterval = settings.checkInterval
    }
    if (settings.newMailboxDelay !== undefined) {
      this.settings.newMailboxDelay = settings.newMailboxDelay
    }
    // ✅ 自定义邮箱配置
    if (settings.customMailbox !== undefined) {
      this.settings.customMailbox = settings.customMailbox
    }
    
    // 🆕 功能增强开关 @since v1.0.1 - 修复缺失的字段更新
    if (settings.enableEmailSearch !== undefined) {
      this.settings.enableEmailSearch = settings.enableEmailSearch
    }
    if (settings.enableTemplates !== undefined) {
      this.settings.enableTemplates = settings.enableTemplates
    }
    if (settings.enableFolders !== undefined) {
      this.settings.enableFolders = settings.enableFolders
    }
    if (settings.enableStatistics !== undefined) {
      this.settings.enableStatistics = settings.enableStatistics
    }
    if (settings.enableTags !== undefined) {
      this.settings.enableTags = settings.enableTags
    }
    if (settings.enableAutoCategory !== undefined) {
      this.settings.enableAutoCategory = settings.enableAutoCategory
    }
    if (settings.enableDataVisualization !== undefined) {
      this.settings.enableDataVisualization = settings.enableDataVisualization
    }
    if (settings.enableAdvancedBackup !== undefined) {
      this.settings.enableAdvancedBackup = settings.enableAdvancedBackup
    }
    if (settings.enableFAB !== undefined) {
      this.settings.enableFAB = settings.enableFAB
    }
    
    // 持久化保存
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '设置已更新并保存')
  }
  
  getDrafts(): DraftData[] {
    // ✅ 返回数组副本
    const result: DraftData[] = []
    for (let i = 0; i < this.drafts.length; i++) {
      result.push(this.drafts[i])
    }
    return result
  }
  
  /**
   * 保存草稿
   */
  saveDraft(draft: DraftData): void {
    // 检查是否已存在相同ID的草稿，如果存在则更新
    const existingIndex = this.drafts.findIndex(d => d.id === draft.id)
    if (existingIndex >= 0) {
      this.drafts[existingIndex] = draft
    } else {
      this.drafts.push(draft)
    }
    
    // 限制草稿数量，最多保留10个
    if (this.drafts.length > 10) {
      this.drafts = this.drafts.slice(-10)
    }
    
    this.saveData()
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '草稿已保存，当前草稿数: %{public}d', this.drafts.length)
  }
  
  /**
   * 删除草稿
   */
  deleteDraft(draftId: number): void {
    const index = this.drafts.findIndex(d => d.id === draftId)
    if (index >= 0) {
      this.drafts.splice(index, 1)
      this.saveData()
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '草稿已删除，ID: %{public}d', draftId)
    }
  }
  
  /**
   * 清空所有数据
   */
  async clearAllData(): Promise<void> {
    try {
      // 清空内存数据
      this.mailboxes = []
      this.emails = []
      this.drafts = []
      this.currentMailbox = null
      
      // 恢复默认设置
      this.settings = {
        theme: 'light',
        language: 'zh-CN',
        defaultDuration: AppConstants.DEFAULT_DURATION_DAYS,
        defaultDomain: AppConstants.DEFAULT_DOMAIN,
        prefixLength: AppConstants.DEFAULT_PREFIX_LENGTH,
        autoCleanup: true,
        emailNotification: false,
        expiryNotification: true,
        desktopNotification: false,
        // 新增字段默认值
        sendMethod: 'resend-builtin',
        autoCheck: true,
        checkInterval: 30,
        newMailboxDelay: 5
      }
      
      // 清空持久化数据
      if (this.preferencesHelper) {
        await this.preferencesHelper.put('mailboxes', '[]')
        await this.preferencesHelper.put('emails', '[]')
        await this.preferencesHelper.put('drafts', '[]')
        await this.preferencesHelper.put('settings', JSON.stringify(this.settings))
        await this.preferencesHelper.flush()
      }
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '所有数据已清空')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '清空数据失败: %{public}s', err.message)
      throw new Error(`清空数据失败: ${err.message}`)
    }
  }
  
  /**
   * 获取Provider工厂（供UI层使用）
   */
  getProviderFactory() {
    return this.providerFactory
  }

  // ==================== 功能增强方法 @since v1.0.1 ====================

  /**
   * 初始化默认模板
   * @private
   * @since v1.0.1
   */
  private initializeDefaultTemplates(): void {
    this.templates = [
      {
        id: 1,
        name: '验证码回复',
        category: TemplateCategory.VERIFICATION,
        subject: '验证码已收到',
        body: '您好，\n\n我已收到验证码并完成验证。\n\n谢谢！',
        createdTime: Date.now(),
        useCount: 0,
        isFavorite: true,
        description: '快速回复验证码相关邮件'
      },
      {
        id: 2,
        name: '账号注册确认',
        category: TemplateCategory.BUSINESS,
        subject: '注册确认',
        body: '您好，\n\n我已完成账号注册，请查收相关信息。\n\n此致',
        createdTime: Date.now(),
        useCount: 0,
        isFavorite: false,
        description: '确认账号注册'
      },
      {
        id: 3,
        name: '订单咨询',
        category: TemplateCategory.BUSINESS,
        subject: '关于订单的咨询',
        body: '您好，\n\n我想咨询关于订单号 [ORDER_ID] 的相关信息。\n\n期待您的回复。',
        createdTime: Date.now(),
        useCount: 0,
        isFavorite: false,
        description: '订单相关咨询',
        variables: ['ORDER_ID']
      },
      {
        id: 4,
        name: '自动回复',
        category: TemplateCategory.PERSONAL,
        subject: '自动回复',
        body: '您好，\n\n这是一封自动回复邮件。我已收到您的来信，会尽快回复。\n\n谢谢！',
        createdTime: Date.now(),
        useCount: 0,
        isFavorite: false,
        description: '设置自动回复'
      }
    ]
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '已初始化%{public}d个默认模板', this.templates.length)
  }

  /**
   * 数据迁移：将已保存的emoji替换为纯文本
   * @private
   * @since v1.0.1
   */
  private migrateEmojiToPlainText(): void {
    try {
      // 迁移文件夹中的emoji
      for (let i = 0; i < this.folders.length; i++) {
        const folder = this.folders[i]
        if (folder.icon) {
          // 替换emoji为纯文本
          if (folder.icon === '💼') {
            folder.icon = '[Work]'
          } else if (folder.icon === '🛒') {
            folder.icon = '[Shopping]'
          } else if (folder.icon === '👥') {
            folder.icon = '[Social]'
          } else if (folder.icon === '🧪') {
            folder.icon = '[Test]'
          } else if (folder.icon === '📁') {
            folder.icon = '[Folder]'
          }
        }
      }
      
      // 迁移标签中的emoji
      for (let i = 0; i < this.tags.length; i++) {
        const tag = this.tags[i]
        if (tag.icon) {
          // 替换emoji为纯文本
          if (tag.icon === '⭐') {
            tag.icon = '[Star]'
          } else if (tag.icon === '📋') {
            tag.icon = '[Todo]'
          } else if (tag.icon === '✅') {
            tag.icon = '[Done]'
          } else if (tag.icon === '📖') {
            tag.icon = '[Read]'
          } else if (tag.icon === '🏷️') {
            tag.icon = '[Tag]'
          }
        }
      }
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据迁移完成：已将emoji替换为纯文本')
    } catch (error) {
      const err = error as Error
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据迁移失败: %{public}s', err.message)
    }
  }

  /**
   * 初始化默认文件夹
   * @private
   * @since v1.0.1
   */
  private initializeDefaultFolders(): void {
    this.folders = [
      {
        id: 1,
        name: '工作',
        icon: '[Work]',
        color: '#2196F3',
        mailboxIds: [],
        createdTime: Date.now(),
        sortOrder: 1,
        description: '工作相关邮箱'
      },
      {
        id: 2,
        name: '购物',
        icon: '[Shopping]',
        color: '#FF9800',
        mailboxIds: [],
        createdTime: Date.now(),
        sortOrder: 2,
        description: '在线购物邮箱'
      },
      {
        id: 3,
        name: '社交',
        icon: '[Social]',
        color: '#9C27B0',
        mailboxIds: [],
        createdTime: Date.now(),
        sortOrder: 3,
        description: '社交平台邮箱'
      },
      {
        id: 4,
        name: '测试',
        icon: '[Test]',
        color: '#4CAF50',
        mailboxIds: [],
        createdTime: Date.now(),
        sortOrder: 4,
        description: '测试用途邮箱'
      }
    ]
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '已初始化%{public}d个默认文件夹', this.folders.length)
  }

  /**
   * 初始化默认标签
   * @private
   * @since v1.0.1
   */
  private initializeDefaultTags(): void {
    this.tags = [
      {
        id: 1,
        name: '重要',
        color: '#F44336',
        icon: '⭐',
        createdTime: Date.now(),
        useCount: 0,
        description: '重要邮件'
      },
      {
        id: 2,
        name: '待办',
        color: '#FF9800',
        icon: '📋',
        createdTime: Date.now(),
        useCount: 0,
        description: '需要处理的邮件'
      },
      {
        id: 3,
        name: '已完成',
        color: '#4CAF50',
        icon: '✅',
        createdTime: Date.now(),
        useCount: 0,
        description: '已处理完成的邮件'
      },
      {
        id: 4,
        name: '稍后阅读',
        color: '#2196F3',
        icon: '📖',
        createdTime: Date.now(),
        useCount: 0,
        description: '稍后阅读的邮件'
      },
      {
        id: 5,
        name: '归档',
        color: '#9E9E9E',
        icon: '📦',
        createdTime: Date.now(),
        useCount: 0,
        description: '归档保存的邮件'
      }
    ]
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '已初始化%{public}d个默认标签', this.tags.length)
  }

  // ==================== 模板管理 @since v1.0.1 ====================

  /**
   * 获取所有模板
   * @returns 模板数组副本
   * @since v1.0.1
   */
  getTemplates(): EmailTemplate[] {
    const result: EmailTemplate[] = []
    for (let i = 0; i < this.templates.length; i++) {
      result.push(this.templates[i])
    }
    return result
  }

  /**
   * 根据ID获取模板
   * @param id 模板ID
   * @returns 模板对象或null
   * @since v1.0.1
   */
  getTemplateById(id: number): EmailTemplate | null {
    const template = this.templates.find(t => t.id === id)
    return template || null
  }

  /**
   * 根据分类获取模板
   * @param category 模板分类
   * @returns 该分类的模板数组
   * @since v1.0.1
   */
  getTemplatesByCategory(category: TemplateCategory): EmailTemplate[] {
    const result: EmailTemplate[] = []
    for (let i = 0; i < this.templates.length; i++) {
      if (this.templates[i].category === category) {
        result.push(this.templates[i])
      }
    }
    return result
  }

  /**
   * 添加新模板
   * @param template 模板对象
   * @since v1.0.1
   */
  async addTemplate(template: EmailTemplate): Promise<void> {
    this.templates.push(template)
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '模板已添加: %{public}s (ID: %{public}d)', template.name, template.id)
  }

  /**
   * 更新模板
   * @param id 模板ID
   * @param template 更新后的模板对象
   * @since v1.0.1
   */
  async updateTemplate(id: number, template: EmailTemplate): Promise<void> {
    const index = this.templates.findIndex(t => t.id === id)
    if (index !== -1) {
      this.templates[index] = template
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板已更新: %{public}s (ID: %{public}d)', template.name, template.id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板不存在: ID %{public}d', id)
    }
  }

  /**
   * 删除模板
   * @param id 模板ID
   * @since v1.0.1
   */
  async deleteTemplate(id: number): Promise<void> {
    const index = this.templates.findIndex(t => t.id === id)
    if (index !== -1) {
      const template = this.templates[index]
      this.templates.splice(index, 1)
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板已删除: %{public}s (ID: %{public}d)', template.name, id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板不存在: ID %{public}d', id)
    }
  }

  /**
   * 使用模板（增加使用次数）
   * @param id 模板ID
   * @since v1.0.1
   */
  async useTemplate(id: number): Promise<void> {
    const template = this.templates.find(t => t.id === id)
    if (template) {
      template.useCount++
      template.lastUsedTime = Date.now()
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板已使用: %{public}s (使用次数: %{public}d)', template.name, template.useCount)
    }
  }

  /**
   * 切换模板收藏状态
   * @param id 模板ID
   * @since v1.0.1
   */
  async toggleTemplateFavorite(id: number): Promise<void> {
    const template = this.templates.find(t => t.id === id)
    if (template) {
      template.isFavorite = !template.isFavorite
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '模板收藏状态已切换: %{public}s (收藏: %{public}s)', 
        template.name, template.isFavorite.toString())
    }
  }

  /**
   * 生成新的模板ID
   * @private
   * @returns 新的模板ID
   * @since v1.0.1
   */
  private generateTemplateId(): number {
    if (this.templates.length === 0) {
      return 1
    }
    const maxId = Math.max(...this.templates.map(t => t.id))
    return maxId + 1
  }

  // ==================== 文件夹管理 @since v1.0.1 ====================

  /**
   * 获取所有文件夹
   * @returns 文件夹数组副本
   * @since v1.0.1
   */
  getFolders(): MailboxFolder[] {
    const result: MailboxFolder[] = []
    for (let i = 0; i < this.folders.length; i++) {
      result.push(this.folders[i])
    }
    return result
  }

  /**
   * 根据ID获取文件夹
   * @param id 文件夹ID
   * @returns 文件夹对象或null
   * @since v1.0.1
   */
  getFolderById(id: number): MailboxFolder | null {
    const folder = this.folders.find(f => f.id === id)
    return folder || null
  }

  /**
   * 添加新文件夹
   * @param folder 文件夹对象
   * @since v1.0.1
   */
  async addFolder(folder: MailboxFolder): Promise<void> {
    this.folders.push(folder)
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '文件夹已添加: %{public}s%{public}s (ID: %{public}d)', 
      folder.icon, folder.name, folder.id)
  }

  /**
   * 更新文件夹
   * @param id 文件夹ID
   * @param folder 更新后的文件夹对象
   * @since v1.0.1
   */
  async updateFolder(id: number, folder: MailboxFolder): Promise<void> {
    const index = this.folders.findIndex(f => f.id === id)
    if (index !== -1) {
      // 创建深拷贝以确保数据完整性
      const folderCopy: MailboxFolder = {
        id: folder.id,
        name: folder.name,
        icon: folder.icon,
        color: folder.color,
        mailboxIds: folder.mailboxIds ? [...folder.mailboxIds] : [],
        createdTime: folder.createdTime,
        sortOrder: folder.sortOrder,
        description: folder.description
      }
      
      this.folders[index] = folderCopy
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '文件夹已更新: %{public}s%{public}s (ID: %{public}d)', 
        folder.icon, folder.name, folder.id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '文件夹不存在: ID %{public}d', id)
    }
  }

  /**
   * 删除文件夹
   * @param id 文件夹ID
   * @since v1.0.1
   */
  async deleteFolder(id: number): Promise<void> {
    const index = this.folders.findIndex(f => f.id === id)
    if (index !== -1) {
      const folder = this.folders[index]
      
      // 将文件夹内的所有邮箱移出文件夹
      folder.mailboxIds.forEach(mailboxId => {
        const mailbox = this.mailboxes.find(m => m.id === mailboxId)
        if (mailbox) {
          mailbox.folderId = undefined
        }
      })
      
      this.folders.splice(index, 1)
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '文件夹已删除: %{public}s%{public}s (ID: %{public}d)', 
        folder.icon, folder.name, id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '文件夹不存在: ID %{public}d', id)
    }
  }

  /**
   * 将邮箱移动到文件夹
   * @param mailboxId 邮箱ID
   * @param folderId 文件夹ID（0表示移出所有文件夹）
   * @since v1.0.1
   */
  async moveMailboxToFolder(mailboxId: number, folderId: number): Promise<void> {
    const mailbox = this.mailboxes.find(m => m.id === mailboxId)
    if (!mailbox) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮箱不存在: ID %{public}d', mailboxId)
      return
    }
    
    // 从旧文件夹移除
    if (mailbox.folderId) {
      const oldFolder = this.folders.find(f => f.id === mailbox.folderId)
      if (oldFolder) {
        const idx = oldFolder.mailboxIds.indexOf(mailboxId)
        if (idx !== -1) {
          oldFolder.mailboxIds.splice(idx, 1)
        }
      }
    }
    
    // 添加到新文件夹
    if (folderId > 0) {
      const newFolder = this.folders.find(f => f.id === folderId)
      if (newFolder) {
        if (!newFolder.mailboxIds.includes(mailboxId)) {
          newFolder.mailboxIds.push(mailboxId)
        }
        mailbox.folderId = folderId
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '邮箱已移动: %{public}s → %{public}s%{public}s', 
          mailbox.email, newFolder.icon, newFolder.name)
      } else {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '文件夹不存在: ID %{public}d', folderId)
        mailbox.folderId = undefined
      }
    } else {
      mailbox.folderId = undefined
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮箱已移出文件夹: %{public}s', mailbox.email)
    }
    
    await this.saveData()
  }

  /**
   * 获取文件夹内的邮箱
   * @param folderId 文件夹ID
   * @returns 邮箱数组
   * @since v1.0.1
   */
  getMailboxesInFolder(folderId: number): MailboxData[] {
    const folder = this.folders.find(f => f.id === folderId)
    if (!folder) {
      return []
    }
    
    const result: MailboxData[] = []
    folder.mailboxIds.forEach(mailboxId => {
      const mailbox = this.mailboxes.find(m => m.id === mailboxId)
      if (mailbox) {
        result.push(mailbox)
      }
    })
    
    return result
  }

  /**
   * 生成新的文件夹ID
   * @private
   * @returns 新的文件夹ID
   * @since v1.0.1
   */
  private generateFolderId(): number {
    if (this.folders.length === 0) {
      return 1
    }
    const maxId = Math.max(...this.folders.map(f => f.id))
    return maxId + 1
  }

  // ==================== 标签管理 @since v1.0.1 ====================

  /**
   * 获取所有标签
   * @returns 标签数组副本
   * @since v1.0.1
   */
  getTags(): EmailTag[] {
    const result: EmailTag[] = []
    for (let i = 0; i < this.tags.length; i++) {
      result.push(this.tags[i])
    }
    return result
  }

  /**
   * 根据ID获取标签
   * @param id 标签ID
   * @returns 标签对象或null
   * @since v1.0.1
   */
  getTagById(id: number): EmailTag | null {
    const tag = this.tags.find(t => t.id === id)
    return tag || null
  }

  /**
   * 添加新标签
   * @param tag 标签对象
   * @since v1.0.1
   */
  async addTag(tag: EmailTag): Promise<void> {
    this.tags.push(tag)
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '标签已添加: %{public}s (ID: %{public}d)', tag.name, tag.id)
  }

  /**
   * 更新标签
   * @param id 标签ID
   * @param tag 更新后的标签对象
   * @since v1.0.1
   */
  async updateTag(id: number, tag: EmailTag): Promise<void> {
    const index = this.tags.findIndex(t => t.id === id)
    if (index !== -1) {
      this.tags[index] = tag
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '标签已更新: %{public}s (ID: %{public}d)', tag.name, tag.id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '标签不存在: ID %{public}d', id)
    }
  }

  /**
   * 删除标签
   * @param id 标签ID
   * @since v1.0.1
   */
  async deleteTag(id: number): Promise<void> {
    // 从所有邮件中移除该标签
    this.emails.forEach(email => {
      if (email.tags) {
        const idx = email.tags.indexOf(id)
        if (idx !== -1) {
          email.tags.splice(idx, 1)
        }
      }
    })
    
    const index = this.tags.findIndex(t => t.id === id)
    if (index !== -1) {
      const tag = this.tags[index]
      this.tags.splice(index, 1)
      await this.saveData()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '标签已删除: %{public}s (ID: %{public}d)', tag.name, id)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '标签不存在: ID %{public}d', id)
    }
  }

  /**
   * 切换邮件标签
   * @param emailId 邮件ID
   * @param tagId 标签ID
   * @since v1.0.1
   */
  async toggleEmailTag(emailId: number, tagId: number): Promise<void> {
    const email = this.emails.find(e => e.id === emailId)
    if (!email) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮件不存在: ID %{public}d', emailId)
      return
    }
    
    if (!email.tags) {
      email.tags = []
    }
    
    const idx = email.tags.indexOf(tagId)
    const tag = this.tags.find(t => t.id === tagId)
    
    if (idx !== -1) {
      // 移除标签
      email.tags.splice(idx, 1)
      
      if (tag && tag.useCount) {
        tag.useCount--
      }
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮件标签已移除: 邮件 %{public}d, 标签 %{public}s', emailId, tag?.name || '')
    } else {
      // 添加标签
      email.tags.push(tagId)
      
      if (tag) {
        tag.useCount = (tag.useCount || 0) + 1
      }
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮件标签已添加: 邮件 %{public}d, 标签 %{public}s', emailId, tag?.name || '')
    }
    
    await this.saveData()
  }

  /**
   * 为邮件添加多个标签
   * @param emailId 邮件ID
   * @param tagIds 标签ID数组
   * @since v1.0.1
   */
  async addEmailTags(emailId: number, tagIds: number[]): Promise<void> {
    const email = this.emails.find(e => e.id === emailId)
    if (!email) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '邮件不存在: ID %{public}d', emailId)
      return
    }
    
    if (!email.tags) {
      email.tags = []
    }
    
    tagIds.forEach(tagId => {
      if (!email.tags) {
        email.tags = []
      }
      if (!email.tags.includes(tagId)) {
        email.tags.push(tagId)
        
        const tag = this.tags.find(t => t.id === tagId)
        if (tag) {
          tag.useCount = (tag.useCount || 0) + 1
        }
      }
    })
    
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '邮件标签已批量添加: 邮件 %{public}d, %{public}d个标签', emailId, tagIds.length)
  }

  /**
   * 获取带有特定标签的邮件
   * @param tagId 标签ID
   * @returns 邮件数组
   * @since v1.0.1
   */
  getEmailsByTag(tagId: number): EmailData[] {
    const result: EmailData[] = []
    this.emails.forEach(email => {
      if (email.tags && email.tags.includes(tagId)) {
        result.push(email)
      }
    })
    return result
  }

  /**
   * 生成新的标签ID
   * @private
   * @returns 新的标签ID
   * @since v1.0.1
   */
  private generateTagId(): number {
    if (this.tags.length === 0) {
      return 1
    }
    const maxId = Math.max(...this.tags.map(t => t.id))
    return maxId + 1
  }

  // ==================== 搜索历史管理 @since v1.0.1 ====================

  /**
   * 获取搜索历史
   * @returns 搜索历史数组
   * @since v1.0.1
   */
  getSearchHistory(): string[] {
    const result: string[] = []
    for (let i = 0; i < this.searchHistory.length; i++) {
      result.push(this.searchHistory[i])
    }
    return result
  }

  /**
   * 添加搜索历史
   * @param keyword 搜索关键词
   * @since v1.0.1
   */
  async addSearchHistory(keyword: string): Promise<void> {
    if (!keyword.trim()) {
      return
    }
    
    // 移除重复项
    const idx = this.searchHistory.indexOf(keyword)
    if (idx !== -1) {
      this.searchHistory.splice(idx, 1)
    }
    
    // 添加到开头
    this.searchHistory.unshift(keyword)
    
    // 限制历史记录数量为20条
    if (this.searchHistory.length > 20) {
      this.searchHistory = this.searchHistory.slice(0, 20)
    }
    
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '搜索历史已添加: %{public}s', keyword)
  }

  /**
   * 清空搜索历史
   * @since v1.0.1
   */
  async clearSearchHistory(): Promise<void> {
    this.searchHistory = []
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '搜索历史已清空')
  }

  // ==================== 邮件分类 @since v1.0.1 ====================

  /**
   * 自动分类邮件
   * @param email 邮件对象
   * @returns 邮件分类
   * @since v1.0.1
   */
  categorizeEmail(email: EmailData): EmailCategory {
    const text = (email.subject + ' ' + email.body).toLowerCase()
    
    // 验证码关键词（中/英/俄）
    const verificationKeywords = [
      'verification', 'verify', 'code', 'otp', '验证码', '验证', '确认码',
      'confirm', 'activation', '激活', 'security code', '动态密码', 
      'проверка', 'код', 'подтверждение'
    ]
    
    // 交易关键词（中/英/俄）
    const transactionKeywords = [
      'order', 'payment', 'receipt', 'invoice', 'transaction',
      '订单', '支付', '收据', '发票', '交易', 'purchase', 'refund',
      'оплата', 'заказ', 'счет', 'покупка'
    ]
    
    // 社交关键词（中/英/俄）
    const socialKeywords = [
      'friend request', 'follow', 'like', 'comment', 'share',
      '好友请求', '关注', '点赞', '评论', '分享', 'mentioned you',
      'подписка', 'друзья', 'лайк', 'комментарий'
    ]
    
    // 推广关键词（中/英/俄）
    const promotionKeywords = [
      'discount', 'sale', 'offer', 'deal', 'promotion', '优惠', '折扣',
      '促销', '特价', 'limited time', 'buy now', '立即购买',
      'скидка', 'акция', 'распродажа'
    ]
    
    // 通知关键词（中/英/俄）
    const notificationKeywords = [
      'notification', 'reminder', 'alert', 'update', 'notice',
      '通知', '提醒', '更新', '公告', 'newsletter', '订阅',
      'уведомление', 'напоминание', 'обновление'
    ]
    
    // 按优先级匹配（验证码优先级最高）
    if (verificationKeywords.some(kw => text.includes(kw))) {
      return EmailCategory.VERIFICATION
    }
    if (transactionKeywords.some(kw => text.includes(kw))) {
      return EmailCategory.TRANSACTION
    }
    if (socialKeywords.some(kw => text.includes(kw))) {
      return EmailCategory.SOCIAL
    }
    if (promotionKeywords.some(kw => text.includes(kw))) {
      return EmailCategory.PROMOTION
    }
    if (notificationKeywords.some(kw => text.includes(kw))) {
      return EmailCategory.NOTIFICATION
    }
    
    return EmailCategory.OTHER
  }

  /**
   * 为所有邮件重新分类
   * @since v1.0.1
   */
  async recategorizeAllEmails(): Promise<void> {
    let count = 0
    this.emails.forEach(email => {
      email.category = this.categorizeEmail(email)
      count++
    })
    
    await this.saveData()
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '已为%{public}d封邮件重新分类', count)
  }

  /**
   * 根据分类获取邮件
   * @param category 邮件分类
   * @returns 该分类的邮件数组
   * @since v1.0.1
   */
  getEmailsByCategory(category: EmailCategory): EmailData[] {
    const result: EmailData[] = []
    this.emails.forEach(email => {
      if (email.category === category) {
        result.push(email)
      }
    })
    return result
  }

  // ==================== 统计计算 @since v1.0.1 ====================

  /**
   * 计算邮箱和邮件统计数据
   * @returns 统计数据对象
   * @since v1.0.1
   */
  calculateStatistics(): MailboxStatistics {
    const now = Date.now()
    const sevenDaysAgo = now - 7 * 24 * 60 * 60 * 1000
    
    // 今日邮件数
    const todayStart = new Date().setHours(0, 0, 0, 0)
    const todayEmails = this.emails.filter(e => e.receivedTime >= todayStart).length
    
    // 未读邮件数
    const unreadCount = this.emails.filter(e => !e.isRead).length
    
    // 活跃和过期邮箱数
    let activeMailboxes = 0
    let expiredMailboxes = 0
    this.mailboxes.forEach(m => {
      if (m.expiryTime >= now) {
        activeMailboxes++
      } else {
        expiredMailboxes++
      }
    })
    
    // 域名统计（包含百分比）
    const domainCount: Record<string, number> = {}
    this.mailboxes.forEach(m => {
      domainCount[m.domain] = (domainCount[m.domain] || 0) + 1
    })
    const totalMailboxCount = this.mailboxes.length || 1
    const domainStats = Object.entries(domainCount)
      .sort((entryA, entryB) => {
        const countA = entryA[1] as number
        const countB = entryB[1] as number
        return countB - countA
      })
      .map((entry) => {
        const count = entry[1] as number
        const item: DomainStatItem = {
          domain: entry[0],
          count: count,
          percentage: Math.round((count / totalMailboxCount) * 100)
        }
        return item
      })
    
    // 最常用域名（Top 5）
    const topDomains = domainStats.slice(0, 5)
    
    // 最近7天邮件趋势
    const dateCount: Record<string, number> = {}
    this.emails.forEach(e => {
      if (e.receivedTime >= sevenDaysAgo) {
        const date = new Date(e.receivedTime).toLocaleDateString()
        dateCount[date] = (dateCount[date] || 0) + 1
      }
    })
    const emailTrend = Object.entries(dateCount)
      .map((entry) => {
        const item: EmailTrendItem = {
          date: entry[0],
          count: entry[1] as number
        }
        return item
      })
      .sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime())
    
    // 平均邮箱生存时间（天）
    let totalLifetime = 0
    let expiredCount = 0
    this.mailboxes.forEach(m => {
      if (m.expiryTime < now && m.status === MailboxStatus.EXPIRED) {
        const lifetime = (m.expiryTime - m.createdTime) / (24 * 60 * 60 * 1000)
        totalLifetime += lifetime
        expiredCount++
      }
    })
    const avgMailboxLifetime = expiredCount > 0 ? Math.round(totalLifetime / expiredCount) : 0
    
    // 发送成功率
    const successCount = this.sentEmails.filter(e => e.success).length
    const sendingSuccessRate = this.sentEmails.length > 0
      ? Math.round((successCount / this.sentEmails.length) * 100)
      : 0
    
    // 各分类邮件数量统计（可选）
    const categoryStats: Record<EmailCategory, number> = {
      [EmailCategory.VERIFICATION]: 0,
      [EmailCategory.TRANSACTION]: 0,
      [EmailCategory.SOCIAL]: 0,
      [EmailCategory.PROMOTION]: 0,
      [EmailCategory.NOTIFICATION]: 0,
      [EmailCategory.OTHER]: 0
    }
    this.emails.forEach(e => {
      if (e.category) {
        categoryStats[e.category]++
      }
    })
    
    // 各标签使用次数统计（可选）
    const tagStats: TagStatItem[] = []
    this.tags.forEach(tag => {
      if (tag.useCount && tag.useCount > 0) {
        const statItem: TagStatItem = {
          tagId: tag.id,
          tagName: tag.name,
          count: tag.useCount
        }
        tagStats.push(statItem)
      }
    })
    tagStats.sort((a, b) => b.count - a.count)
    
    const statistics: MailboxStatistics = {
      totalMailboxes: this.mailboxes.length,
      totalEmails: this.emails.length,
      todayEmails,
      unreadCount,
      activeMailboxes,
      expiredMailboxes,
      topDomains,
      domainStats,
      emailTrend,
      avgMailboxLifetime,
      sendingSuccessRate,
      categoryStats,
      tagStats
    }
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '统计数据已计算: 邮箱%{public}d, 邮件%{public}d, 今日%{public}d',
      statistics.totalMailboxes, statistics.totalEmails, statistics.todayEmails)
    
    return statistics
  }
}
