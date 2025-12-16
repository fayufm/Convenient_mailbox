/**
 * 数据类型定义
 * 定义应用中使用的所有数据结构
 */

/**
 * 邮箱状态枚举
 */
export enum MailboxStatus {
  ACTIVE = 'ACTIVE',
  EXPIRED = 'EXPIRED',
  DELETED = 'DELETED'
}

/**
 * 邮件类型枚举
 */
export enum EmailType {
  NORMAL = 'NORMAL',
  VERIFICATION = 'VERIFICATION',
  NOTIFICATION = 'NOTIFICATION'
}

/**
 * 邮箱类型枚举
 * @since 2.1.0
 */
export enum MailboxType {
  /** 临时邮箱 */
  TEMPORARY = 'temporary',
  /** 自定义邮箱（通过代理） */
  CUSTOM = 'custom'
}

/**
 * 自定义邮箱配置（用于MailboxData.customConfig）
 * 存储自定义邮箱的IMAP/SMTP配置
 * @since 2.1.0
 */
export interface CustomMailboxConfig {
  /** 密码/授权码（加密存储） */
  password: string
  /** 显示名称（可选） */
  displayName?: string
  
  // IMAP配置（接收）
  /** IMAP服务器地址 */
  imapHost: string
  /** IMAP端口 */
  imapPort: number
  /** 是否使用SSL/TLS */
  imapSecure: boolean
  /** 邮箱文件夹（可选，默认INBOX） */
  imapFolder?: string
  
  // SMTP配置（发送）
  /** SMTP服务器地址 */
  smtpHost: string
  /** SMTP端口 */
  smtpPort: number
  /** 是否使用SSL/TLS */
  smtpSecure: boolean
  
  // 元数据
  /** 最后同步时间（时间戳） */
  lastSyncTime?: number
  /** 是否启用自动同步 */
  syncEnabled?: boolean
  /** 服务商标识（gmail/qq/163/126等） */
  provider?: string
}

/**
 * 自定义邮箱设置（用于SettingsData.customMailbox）
 * 包含完整的自定义邮箱配置信息，用于全局设置
 * @since 2.1.0
 */
export interface CustomMailboxSettings {
  /** 是否启用自定义邮箱 */
  enabled: boolean
  /** 邮箱地址 */
  email: string
  /** 密码/授权码（加密存储） */
  password: string
  /** 显示名称 */
  displayName: string
  
  // SMTP配置（发送）
  /** SMTP服务器地址 */
  smtpHost: string
  /** SMTP端口 */
  smtpPort: number
  /** 是否使用SSL/TLS */
  smtpSecure: boolean
  
  // IMAP配置（接收）
  /** IMAP服务器地址 */
  imapHost: string
  /** IMAP端口 */
  imapPort: number
  /** 是否使用SSL/TLS */
  imapSecure: boolean
  
  // 服务商配置
  /** 服务商类型（gmail/outlook/qq/163/custom） */
  provider?: string
  
  // ✨ 高级功能配置
  /** 邮件签名 */
  signature?: string
  /** 回复地址（不同于发件地址） */
  replyTo?: string
  /** 是否密送给自己（备份） */
  bccToSelf?: boolean
  /** 请求已读回执 */
  requestReadReceipt?: boolean
  /** 邮件优先级 */
  priority?: 'high' | 'normal' | 'low'
  /** 启用自动回复 */
  autoReplyEnabled?: boolean
  /** 自动回复内容 */
  autoReplyMessage?: string
  /** 最大附件大小限制（MB） */
  maxAttachmentSize?: number
  /** 连接状态 */
  connectionStatus?: 'unknown' | 'connected' | 'disconnected' | 'error'
  /** 最后测试连接时间（时间戳） */
  lastTestTime?: number
  /** 配置备注说明 */
  notes?: string
}

/**
 * 邮箱数据接口
 */
export interface MailboxData {
  id: number
  email: string
  prefix: string
  domain: string
  createdTime: number
  expiryTime: number
  status: MailboxStatus
  emailCount: number
  unreadCount: number
  availableTime?: number  // 邮箱可用时间（冷却时间后），时间戳
  isPinned?: boolean      // 是否置顶
  isBlocked?: boolean     // 是否拒收邮件
  pinnedTime?: number     // 置顶时间（用于排序）
  blockedTime?: number    // 拒收时间（用于排序小圆点）
  
  // 🆕 自定义邮箱相关字段 @since 2.1.0
  /** 邮箱类型（临时/自定义） */
  mailboxType?: MailboxType
  /** 是否为自定义邮箱（向后兼容） */
  isCustom?: boolean
  /** 自定义邮箱配置（仅自定义邮箱有值） */
  customConfig?: CustomMailboxConfig
  
  // 🆕 功能增强字段 @since v1.0.1
  /** 所属文件夹ID */
  folderId?: number
  /** 邮箱备注信息 */
  notes?: string
  /** 邮箱标签（标签名称数组） */
  tags?: string[]
}

/**
 * 附件数据接口
 */
export interface AttachmentData {
  id: string              // 附件唯一ID
  filename: string        // 文件名
  size: number           // 文件大小（字节）
  contentType: string    // MIME类型
  url?: string           // 附件URL（用于下载）
  localPath?: string     // 本地路径（用于上传）
}

/**
 * 邮件数据接口
 */
export interface EmailData {
  id: number
  mailboxId: number
  from: string
  subject: string
  date: string
  body: string
  isRead: boolean
  isVerification: boolean
  emailType: EmailType
  receivedTime: number
  attachments?: AttachmentData[]  // 附件列表
  
  // 🆕 功能增强字段 @since v1.0.1
  /** 邮件分类（验证码/交易/社交等） */
  category?: EmailCategory
  /** 邮件标签ID数组 */
  tags?: number[]
}

/**
 * 草稿数据接口
 */
export interface DraftData {
  id: number
  to: string
  subject: string
  body: string
  createdTime: number
  updatedTime: number
  attachments?: AttachmentData[]  // 附件列表
  from?: string  // ✅ 发件邮箱（支持自定义邮箱）
}

/**
 * 已发送邮件数据接口
 */
export interface SentEmailData {
  id: number
  from: string          // 发件人邮箱（临时邮箱）
  to: string            // 收件人邮箱
  subject: string       // 邮件主题
  body: string          // 邮件内容
  sentTime: number      // 发送时间戳
  success: boolean      // 是否发送成功
  errorMessage?: string // 失败时的错误信息
  attachments?: AttachmentData[]  // 附件列表
}

/**
 * 设置数据接口
 */
export interface SettingsData {
  theme: string
  language: string
  defaultDuration: number
  defaultDomain: string
  prefixLength: number
  autoCleanup: boolean
  emailNotification: boolean
  expiryNotification: boolean
  desktopNotification: boolean
  // 新增字段
  sendMethod: string
  autoCheck: boolean
  checkInterval: number
  newMailboxDelay: number
  // ✅ 自定义邮箱设置（完整配置）
  customMailbox?: CustomMailboxSettings
  
  // 🆕 高级功能开关 @since v1.0.1
  /** 启用邮件搜索和过滤功能 */
  enableEmailSearch?: boolean
  /** 启用邮件模板库功能 */
  enableTemplates?: boolean
  /** 启用邮箱分组管理功能 */
  enableFolders?: boolean
  /** 启用使用统计报告功能 */
  enableStatistics?: boolean
  /** 启用邮件标签系统功能 */
  enableTags?: boolean
  /** 启用邮件智能分类功能 */
  enableAutoCategory?: boolean
  /** 启用数据可视化功能 */
  enableDataVisualization?: boolean
  /** 启用高级数据管理功能 */
  enableAdvancedBackup?: boolean
  /** 启用快速操作浮动按钮功能 */
  enableFAB?: boolean
}

/**
 * 网络响应接口
 */
export interface NetworkResponse<T> {
  success: boolean
  data: T | null
  error: string
}

/**
 * 临时邮件接口
 */
export interface TempEmail {
  id: number
  from: string
  subject: string
  date: string
}

/**
 * 临时邮件内容接口
 */
export interface TempEmailContent {
  id: number
  from: string
  subject: string
  date: string
  body: string
  textBody: string
  htmlBody: string
  attachments: string[]
}

/**
 * 自定义邮箱配置验证结果接口
 * @deprecated 旧版接口，已合并到新的CustomMailboxConfig中
 */
export interface CustomMailboxValidationResult {
  valid: boolean                // 配置是否完整有效
  missingFields: string[]       // 缺失或无效的字段列表
}

/**
 * 帮助文档章节接口
 */
export interface HelpSection {
  id: number                    // 章节唯一ID
  title: string                 // 章节标题
  content: string               // 章节内容
  isAdvanced?: boolean          // 是否为高级内容（默认折叠）
  isExpanded?: boolean          // 是否展开（内部状态）
  level?: number                // 层级（1=主标题, 2=副标题）
  icon?: string                 // 图标标识
}

// ==================== 功能增强数据结构 @since v1.0.1 ====================

/**
 * 邮件分类枚举
 * 用于智能分类邮件类型
 * @since v1.0.1
 */
export enum EmailCategory {
  /** 验证码邮件 */
  VERIFICATION = 'verification',
  /** 交易邮件（订单、支付等） */
  TRANSACTION = 'transaction',
  /** 社交邮件（关注、点赞、评论等） */
  SOCIAL = 'social',
  /** 推广邮件（广告、促销等） */
  PROMOTION = 'promotion',
  /** 通知邮件（系统通知、更新等） */
  NOTIFICATION = 'notification',
  /** 其他未分类邮件 */
  OTHER = 'other'
}

/**
 * 邮件模板分类枚举
 * @since v1.0.1
 */
export enum TemplateCategory {
  /** 商务邮件模板 */
  BUSINESS = 'business',
  /** 个人邮件模板 */
  PERSONAL = 'personal',
  /** 验证码回复模板 */
  VERIFICATION = 'verification',
  /** 自定义模板 */
  CUSTOM = 'custom'
}

/**
 * 邮件模板接口
 * 存储预设和自定义的邮件模板，提升写邮件效率
 * @since v1.0.1
 */
export interface EmailTemplate {
  /** 模板唯一ID */
  id: number
  /** 模板名称 */
  name: string
  /** 模板分类 */
  category: TemplateCategory
  /** 邮件主题 */
  subject: string
  /** 邮件内容 */
  body: string
  /** 创建时间（时间戳） */
  createdTime: number
  /** 最后使用时间（时间戳，可选） */
  lastUsedTime?: number
  /** 使用次数统计 */
  useCount: number
  /** 是否收藏（置顶显示） */
  isFavorite: boolean
  /** 模板描述（可选） */
  description?: string
  /** 模板变量（如 [ORDER_ID]，可选） */
  variables?: string[]
}

/**
 * 邮箱文件夹接口
 * 用于分组管理邮箱
 * @since v1.0.1
 */
export interface MailboxFolder {
  /** 文件夹唯一ID */
  id: number
  /** 文件夹名称 */
  name: string
  /** 文件夹图标（Emoji） */
  icon: string
  /** 文件夹颜色（十六进制颜色码） */
  color: string
  /** 文件夹内的邮箱ID数组 */
  mailboxIds: number[]
  /** 创建时间（时间戳） */
  createdTime: number
  /** 排序顺序（数字越小越靠前） */
  sortOrder: number
  /** 文件夹描述（可选） */
  description?: string
}

/**
 * 邮件标签接口
 * 用于标记和分类邮件
 * @since v1.0.1
 */
export interface EmailTag {
  /** 标签唯一ID */
  id: number
  /** 标签名称 */
  name: string
  /** 标签颜色（十六进制颜色码） */
  color: string
  /** 创建时间（时间戳） */
  createdTime: number
  /** 使用次数统计（可选） */
  useCount?: number
  /** 标签图标（Emoji，可选） */
  icon?: string
  /** 标签描述（可选） */
  description?: string
}

/**
 * 邮箱使用统计数据接口
 * 用于生成统计报告
 * @since v1.0.1
 */
/**
 * 域名统计项
 * @since v1.0.1
 */
export interface DomainStatItem {
  domain: string
  count: number
  percentage: number
}

/**
 * 邮件趋势项
 * @since v1.0.1
 */
export interface EmailTrendItem {
  date: string
  count: number
}

/**
 * 标签统计项
 * @since v1.0.1
 */
export interface TagStatItem {
  tagId: number
  tagName: string
  count: number
}

/**
 * 邮箱统计数据接口
 * @since v1.0.1
 */
export interface MailboxStatistics {
  /** 邮箱总数 */
  totalMailboxes: number
  /** 邮件总数 */
  totalEmails: number
  /** 今日收到的邮件数 */
  todayEmails: number
  /** 未读邮件数 */
  unreadCount: number
  /** 活跃邮箱数（未过期） */
  activeMailboxes?: number
  /** 已过期邮箱数 */
  expiredMailboxes?: number
  /** 最常用的域名列表（Top 5） */
  topDomains: DomainStatItem[]
  /** 域名统计（所有域名） */
  domainStats: DomainStatItem[]
  /** 最近7天的邮件趋势 */
  emailTrend: EmailTrendItem[]
  /** 平均邮箱存活时间（天） */
  avgMailboxLifetime: number
  /** 发送成功率（百分比） */
  sendingSuccessRate: number
  /** 各分类邮件数量统计（可选） */
  categoryStats?: Record<EmailCategory, number>
  /** 各标签使用次数统计（可选） */
  tagStats?: TagStatItem[]
}
