/**
 * 邮件发送器相关类型定义
 * 用于邮件发送器的配置和管理
 * 
 * @module SenderTypes
 * @since 2.0.0
 */

/**
 * 发送器选项接口
 * 用于UI选择器的选项定义
 */
export interface SenderOption {
  /** 选项值（发送器类型标识） */
  value: string
  /** 显示文本 */
  label: string
}

/**
 * 发送器配置字段接口
 * 描述发送器需要的配置字段
 */
export interface SenderConfigField {
  /** 字段名称 */
  name: string
  /** 显示标签 */
  label: string
  /** 字段类型 */
  type: 'text' | 'password' | 'email' | 'number'
  /** 是否必填 */
  required: boolean
  /** 占位符文本 */
  placeholder?: string
  /** 默认值 */
  defaultValue?: string
  /** 帮助文本 */
  helpText?: string
}

/**
 * 发送器元数据接口
 * 描述发送器的基本信息
 */
export interface SenderMetadata {
  /** 发送器ID */
  id: string
  /** 显示名称 */
  name: string
  /** 描述 */
  description: string
  /** 是否需要API密钥 */
  requiresApiKey: boolean
  /** 是否支持HTML */
  supportsHtml: boolean
  /** 是否支持附件 */
  supportsAttachments: boolean
  /** 每日免费配额（-1表示无限制） */
  freeQuota: number
  /** 官方网站 */
  website?: string
}

/**
 * 发送器统计信息接口
 * 追踪发送器的使用统计
 */
export interface SenderStats {
  /** 发送器类型 */
  senderType: string
  /** 总发送次数 */
  totalSent: number
  /** 成功次数 */
  successCount: number
  /** 失败次数 */
  failureCount: number
  /** 成功率（0-100） */
  successRate: number
  /** 平均响应时间（毫秒） */
  averageResponseTime: number
  /** 最后使用时间 */
  lastUsed: string
}

/**
 * 邮件内容接口
 * 描述邮件的完整内容
 */
export interface EmailContentData {
  /** 收件人 */
  to: string
  /** 主题 */
  subject: string
  /** 纯文本内容 */
  text?: string
  /** HTML内容 */
  html?: string
  /** 发件人 */
  from?: string
  /** 发件人名称 */
  fromName?: string
  /** 抄送 */
  cc?: string[]
  /** 密送 */
  bcc?: string[]
  /** 回复地址 */
  replyTo?: string
  /** 附件列表 */
  attachments?: EmailAttachmentData[]
}

/**
 * 邮件附件接口
 * 描述邮件附件的信息
 */
export interface EmailAttachmentData {
  /** 文件名 */
  filename: string
  /** 内容类型 */
  contentType: string
  /** 内容（Base64编码） */
  content: string
  /** 文件大小（字节） */
  size?: number
}

/**
 * 批量发送配置接口
 * 用于批量发送邮件的配置
 */
export interface BulkSendConfig {
  /** 收件人列表 */
  recipients: string[]
  /** 邮件内容模板 */
  template: EmailContentData
  /** 是否并发发送 */
  concurrent: boolean
  /** 并发数量 */
  concurrency?: number
  /** 发送间隔（毫秒） */
  interval?: number
}

