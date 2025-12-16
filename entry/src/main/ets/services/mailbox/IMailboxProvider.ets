/**
 * 邮箱服务提供商接口
 * 定义临时邮箱服务的统一接口
 */

import { NetworkResponse, TempEmail, TempEmailContent } from '../../common/DataTypes'

/**
 * 邮箱提供商配置
 */
export interface MailboxProviderConfig {
  name: string                    // 提供商名称
  supportedDomains: string[]      // 支持的域名列表
  apiEndpoint: string            // API端点
  requiresAuth: boolean          // 是否需要认证
  maxRetries: number             // 最大重试次数
  timeout: number                // 请求超时时间(ms)
}

/**
 * 邮箱提供商接口
 */
export interface IMailboxProvider {
  /**
   * 获取提供商配置
   */
  getConfig(): MailboxProviderConfig

  /**
   * 生成随机邮箱
   * @param domain 指定域名（可选）
   */
  generateRandomMailbox(domain?: string): Promise<NetworkResponse<string>>

  /**
   * 创建自定义邮箱
   * @param prefix 邮箱前缀
   * @param domain 邮箱域名
   */
  createCustomMailbox(prefix: string, domain: string): Promise<NetworkResponse<string>>

  /**
   * 检查邮箱是否可用
   * @param email 邮箱地址
   */
  checkMailboxAvailability(email: string): Promise<NetworkResponse<boolean>>

  /**
   * 获取邮件列表
   * @param email 邮箱地址
   */
  getEmailList(email: string): Promise<NetworkResponse<TempEmail[]>>

  /**
   * 获取邮件详情
   * @param email 邮箱地址
   * @param emailId 邮件ID
   */
  getEmailContent(email: string, emailId: number | string): Promise<NetworkResponse<TempEmailContent>>

  /**
   * 删除邮件
   * @param email 邮箱地址
   * @param emailId 邮件ID
   */
  deleteEmail(email: string, emailId: number | string): Promise<NetworkResponse<boolean>>

  /**
   * 检查提供商是否可用
   */
  isAvailable(): Promise<boolean>
}

/**
 * 邮箱提供商类型
 */
export enum MailboxProviderType {
  ONE_SEC_MAIL = '1secmail',        // 1SecMail (官方稳定)
  TEMP_MAIL = 'temp-mail',          // Temp-Mail.org
  GUERRILLA_MAIL = 'guerrilla',     // Guerrilla Mail
  MAILDROP = 'maildrop',            // MailDrop
  MAILINATOR = 'mailinator',        // Mailinator
  FALLBACK = 'fallback'             // 备用方案（直接返回邮箱地址，不验证）
}

