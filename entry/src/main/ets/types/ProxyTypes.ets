/**
 * 后端代理相关类型定义
 * 用于配置和管理用户自定义的后端代理服务器
 * 
 * @module ProxyTypes
 * @since 2.0.0
 */

/**
 * 代理服务器配置接口
 * 用户配置的后端代理服务器信息
 */
export interface ProxyServerConfig {
  /** 是否启用代理 */
  enabled: boolean
  /** 代理服务器基础URL */
  baseUrl: string
  /** 认证令牌 */
  authToken: string
  /** 请求超时时间（毫秒） */
  timeout: number
}

/**
 * 代理连接测试结果接口
 * 测试代理服务器连接状态的结果
 */
export interface ProxyTestResult {
  /** 测试是否成功 */
  success: boolean
  /** 结果消息 */
  message: string
  /** 响应延迟（毫秒，可选） */
  latency?: number
  /** 服务器版本信息（可选） */
  serverVersion?: string
  /** 支持的服务列表（可选） */
  supportedServices?: string[]
}

/**
 * 代理请求头接口
 * 发送到代理服务器的请求头
 */
export interface ProxyRequestHeaders {
  /** 认证令牌 */
  'Authorization': string
  /** 内容类型 */
  'Content-Type': string
  /** 用户代理（可选） */
  'User-Agent'?: string
}

/**
 * 代理请求体接口
 * 发送到代理服务器的请求体
 */
export interface ProxyRequestBody {
  /** 目标服务类型（如'emailjs', 'resend'） */
  service: string
  /** 操作类型（如'send', 'verify'） */
  action: string
  /** 请求数据 */
  data: Record<string, ESObject>
}

/**
 * 代理响应接口
 * 代理服务器返回的响应
 */
export interface ProxyResponse<T = Record<string, Object>> {
  /** 是否成功 */
  success: boolean
  /** 响应数据 */
  data?: T
  /** 错误信息 */
  error?: string
  /** 时间戳 */
  timestamp?: number
}

/**
 * 代理服务器健康检查接口
 * 用于检查代理服务器的健康状态
 */
export interface ProxyHealthCheck {
  /** 服务器状态 */
  status: 'healthy' | 'degraded' | 'down'
  /** 响应时间（毫秒） */
  responseTime: number
  /** 最后检查时间 */
  lastChecked: string
  /** 服务可用性 */
  services: Record<string, boolean>
}

/**
 * IMAP邮箱配置接口
 * 用于配置自定义邮箱的IMAP接收设置
 * 
 * @since 2.1.0
 */
export interface IMAPMailboxConfig {
  /** 邮箱地址 */
  email: string
  /** 密码/授权码（加密存储） */
  password: string
  /** IMAP服务器地址 */
  imapHost: string
  /** IMAP端口（通常993） */
  imapPort: number
  /** 是否使用SSL/TLS */
  imapSecure: boolean
  /** 显示名称（可选） */
  displayName?: string
}

/**
 * IMAP邮件列表请求接口
 * 发送到代理服务器的IMAP列表请求
 * 
 * @since 2.1.0
 */
export interface IMAPListRequest {
  /** 邮箱地址 */
  email: string
  /** 密码/授权码 */
  password: string
  /** IMAP服务器地址 */
  imapHost: string
  /** IMAP端口 */
  imapPort: number
  /** 是否使用SSL/TLS */
  secure: boolean
  /** 获取最新N封邮件（可选，默认50） */
  limit?: number
  /** 邮箱文件夹（可选，默认INBOX） */
  folder?: string
}

/**
 * IMAP邮件详情请求接口
 * 发送到代理服务器的IMAP读取请求
 * 
 * @since 2.1.0
 */
export interface IMAPReadRequest {
  /** 邮箱地址 */
  email: string
  /** 密码/授权码 */
  password: string
  /** IMAP服务器地址 */
  imapHost: string
  /** IMAP端口 */
  imapPort: number
  /** 是否使用SSL/TLS */
  secure: boolean
  /** 邮件唯一ID */
  emailId: string
  /** 邮箱文件夹（可选，默认INBOX） */
  folder?: string
}

/**
 * IMAP邮件数据接口
 * 代理服务器返回的邮件数据
 * 
 * @since 2.1.0
 */
export interface IMAPEmailData {
  /** 邮件唯一ID（IMAP UID） */
  id: string
  /** 发件人 */
  from: string
  /** 主题 */
  subject: string
  /** 日期 */
  date: string
  /** 预览文本（可选） */
  preview?: string
  /** 完整文本内容（可选，详情时返回） */
  body?: string
  /** HTML内容（可选，详情时返回） */
  html?: string
  /** 附件列表（可选） */
  attachments?: IMAPAttachment[]
}

/**
 * IMAP附件接口
 * 邮件附件信息
 * 
 * @since 2.1.0
 */
export interface IMAPAttachment {
  /** 文件名 */
  filename: string
  /** MIME类型 */
  contentType: string
  /** 文件大小（字节） */
  size: number
  /** 附件内容（Base64编码，可选） */
  content?: string
}

