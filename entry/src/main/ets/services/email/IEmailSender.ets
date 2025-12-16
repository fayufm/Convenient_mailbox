/**
 * 邮件发送服务接口
 * 定义不同邮件发送方式的统一接口
 * 
 * @module IEmailSender
 * @since 2.0.0
 */

import { NetworkResponse } from '../../common/DataTypes'

/**
 * 邮件发送配置接口
 * 描述邮件发送方式的基本信息
 */
export interface EmailSenderConfig {
  /** 发送方式名称 */
  name: string
  /** 发送方式类型 */
  type: EmailSenderType
  /** 是否需要用户配置 */
  requiresConfig: boolean
  /** 是否有内置服务 */
  hasBuiltInService: boolean
  /** 最大附件大小(MB) */
  maxAttachmentSize?: number
  /** 描述 */
  description: string
}

/**
 * 邮件内容接口
 * 定义邮件的完整信息
 * 
 * TODO: 考虑将此接口移至DataTypes.ets以保持架构一致性
 */
export interface EmailContent {
  /** 发件人地址 */
  from?: string
  /** 发件人名称 */
  fromName?: string
  /** 收件人地址 */
  to: string
  /** 邮件主题 */
  subject: string
  /** 正文（纯文本） */
  body: string
  /** HTML正文 */
  html?: string
  /** 抄送地址列表 */
  cc?: string[]
  /** 密送地址列表 */
  bcc?: string[]
  /** 附件列表 */
  attachments?: EmailAttachment[]
}

/**
 * 邮件附件接口
 * 
 * TODO: 考虑将此接口移至DataTypes.ets以保持架构一致性
 */
export interface EmailAttachment {
  /** 文件名 */
  filename: string
  /** 内容(base64编码) */
  content: string
  /** MIME内容类型 */
  contentType: string
}

/**
 * 发送结果接口
 * 描述邮件发送操作的结果
 */
export interface SendResult {
  /** 是否发送成功 */
  success: boolean
  /** 消息ID（由邮件服务商返回） */
  messageId?: string
  /** 错误信息（发送失败时） */
  error?: string
  /** 是否使用了内置服务配额 */
  quotaUsed?: boolean
}

/**
 * 配置字段选项接口
 * 用于select类型的配置字段
 */
export interface ConfigFieldOption {
  /** 选项值 */
  value: string
  /** 选项显示标签 */
  label: string
}

/**
 * 配置字段定义接口
 * 定义用户需要配置的字段信息
 */
export interface ConfigField {
  /** 字段key（用于数据存储） */
  key: string
  /** 显示标签（用于UI展示） */
  label: string
  /** 字段类型 */
  type: 'text' | 'password' | 'number' | 'select'
  /** 是否必填 */
  required: boolean
  /** 占位符文本 */
  placeholder?: string
  /** 默认值 */
  defaultValue?: string
  /** 选项列表（仅用于select类型） */
  options?: ConfigFieldOption[]
  /** 帮助文本（显示在字段下方） */
  helpText?: string
}

/**
 * 邮件发送器接口
 * 所有邮件发送实现必须遵循此接口
 * 
 * @interface IEmailSender
 */
export interface IEmailSender {
  /**
   * 获取发送器配置信息
   * @returns 配置信息对象
   */
  getConfig(): EmailSenderConfig

  /**
   * 发送邮件
   * @param content 邮件内容
   * @param userConfig 用户自定义配置（可选）
   * @returns 发送结果的网络响应
   */
  send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>>

  /**
   * 验证用户配置是否有效
   * @param config 配置对象
   * @returns 是否有效
   */
  validateConfig(config: Record<string, string>): Promise<boolean>

  /**
   * 测试与邮件服务的连接
   * @param config 配置对象（可选，使用默认配置如未提供）
   * @returns 连接是否成功
   */
  testConnection(config?: Record<string, string>): Promise<boolean>

  /**
   * 获取配置字段定义列表
   * 用于UI动态生成配置表单
   * @returns 配置字段数组
   */
  getConfigFields(): ConfigField[]
}

/**
 * 邮件发送方式类型枚举
 * 定义系统支持的所有邮件发送方式
 * 
 * @enum EmailSenderType
 */
export enum EmailSenderType {
  /** SMTP协议 */
  SMTP = 'smtp',
  /** EmailJS（外部配置） */
  EMAILJS_EXTERNAL = 'emailjs-external',
  /** EmailJS（内置服务，不推荐） */
  EMAILJS_BUILTIN = 'emailjs-builtin',
  /** EmailJS（后端代理，推荐） */
  EMAILJS_PROXY = 'emailjs-proxy',
  /** SendGrid API */
  SENDGRID = 'sendgrid',
  /** Mailgun API */
  MAILGUN = 'mailgun',
  /** Postmark API */
  POSTMARK = 'postmark',
  /** Resend（外部配置） */
  RESEND_EXTERNAL = 'resend-external',
  /** Resend（内置服务，不推荐） */
  RESEND_BUILTIN = 'resend-builtin',
  /** Resend（后端代理，推荐） */
  RESEND_PROXY = 'resend-proxy',
  /** Brevo (前身Sendinblue) */
  BREVO = 'brevo',
  /** MailerSend API */
  MAILERSEND = 'mailersend',
  /** Elastic Email API */
  ELASTIC_EMAIL = 'elastic-email',
  /** SparkPost API */
  SPARKPOST = 'sparkpost',
  /** Mailjet API */
  MAILJET = 'mailjet',
  /** Amazon SES */
  AMAZON_SES = 'amazon-ses',
  /** Formspree表单服务 */
  FORMSPREE = 'formspree',
  /** Netlify Forms */
  NETLIFY_FORMS = 'netlify-forms'
}
