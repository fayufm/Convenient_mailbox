/**
 * 邮件服务配置相关类型定义
 * 用于配置和管理各种邮件发送服务
 * 
 * @module EmailServiceTypes
 * @since 2.0.0
 */

import { QuotaLimits } from './QuotaTypes'

/**
 * EmailJS服务配置接口
 * EmailJS API所需的配置参数
 */
export interface EmailJSConfig {
  /** 服务ID */
  serviceId: string
  /** 模板ID */
  templateId: string
  /** 公钥 */
  publicKey: string
}

/**
 * Resend服务配置接口
 * Resend API所需的配置参数
 */
export interface ResendConfig {
  /** API密钥 */
  apiKey: string
  /** 发件人邮箱地址 */
  fromEmail: string
  /** 发件人名称 */
  fromName: string
}

/**
 * EmailJS服务定义接口
 * 完整的EmailJS服务配置，包括启用状态和配额
 */
export interface EmailJSServiceDefinition {
  /** 是否启用 */
  enabled: boolean
  /** 服务配置 */
  config: EmailJSConfig
  /** 配额限制 */
  quota: QuotaLimits
}

/**
 * Resend服务定义接口
 * 完整的Resend服务配置，包括启用状态和配额
 */
export interface ResendServiceDefinition {
  /** 是否启用 */
  enabled: boolean
  /** 服务配置 */
  config: ResendConfig
  /** 配额限制 */
  quota: QuotaLimits
}

/**
 * 邮件服务完整定义接口
 * 包含所有内置邮件服务的配置
 */
export interface EmailServiceDefinition {
  /** EmailJS服务 */
  emailjs: EmailJSServiceDefinition
  /** Resend服务 */
  resend: ResendServiceDefinition
}

/**
 * 邮件发送请求参数接口
 * 用于构建邮件发送请求
 */
export interface EmailSendParams {
  /** 收件人 */
  to: string
  /** 主题 */
  subject: string
  /** 邮件正文（纯文本） */
  text?: string
  /** 邮件正文（HTML） */
  html?: string
  /** 发件人邮箱 */
  from?: string
  /** 发件人名称 */
  fromName?: string
  /** 回复地址 */
  replyTo?: string
}

/**
 * 邮件发送响应接口
 * API返回的发送结果
 */
export interface EmailSendResponse {
  /** 是否成功 */
  success: boolean
  /** 邮件ID（如果成功） */
  messageId?: string
  /** 错误信息（如果失败） */
  error?: string
}

