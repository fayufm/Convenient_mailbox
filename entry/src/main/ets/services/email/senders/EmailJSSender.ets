/**
 * EmailJS邮件发送器
 * 支持三种模式：外置用户配置、通过后端代理、内置服务（不推荐）
 * 
 * ⚠️ 安全提示：
 * - 推荐使用后端代理模式，API密钥存储在您的服务器上
 * - 内置服务已禁用（API密钥会被反编译）
 * - 外置模式适合高级用户自己管理密钥
 * 
 * @module EmailJSSender
 * @since 2.0.0
 */

import { IEmailSender, EmailSenderConfig, EmailContent, SendResult, ConfigField, EmailSenderType } from '../IEmailSender'
import { NetworkResponse } from '../../../common/DataTypes'
import { NetworkService } from '../../../common/NetworkService'
import { QuotaManager } from '../../QuotaManager'
import { UserEmailConfigManager, ProxyApiResponse } from '../../../config/UserEmailConfig'
import { AppConstants } from '../../../common/Constants'
import { SecureEmailServiceConfig, validateEmailJSConfig } from '../../../config/EmailServiceConfig'
import hilog from '@ohos.hilog'

/**
 * EmailJS模板参数接口
 */
interface EmailJSTemplateParams {
  /** 收件人邮箱 */
  to_email: string
  /** 收件人名称 */
  to_name: string
  /** 发件人名称 */
  from_name: string
  /** 邮件主题 */
  subject: string
  /** 邮件内容 */
  message: string
}

/**
 * EmailJS发送请求数据接口
 */
interface EmailJSSendRequest {
  /** 服务ID */
  service_id: string
  /** 模板ID */
  template_id: string
  /** 用户ID（Public Key） */
  user_id: string
  /** 模板参数 */
  template_params: EmailJSTemplateParams
}

/**
 * 代理服务器邮件发送请求接口
 */
interface ProxyEmailSendRequest {
  /** 收件人 */
  to: string
  /** 发件人 */
  from?: string
  /** 发件人名称 */
  fromName?: string
  /** 邮件主题 */
  subject: string
  /** 邮件正文（纯文本） */
  body: string
  /** 邮件正文（HTML） */
  html?: string
}

/**
 * 代理API响应中的数据接口
 */
interface ProxyResponseData {
  /** 消息ID */
  messageId?: string
}

/**
 * SendResult实现接口
 */
interface EmailJSSendResult {
  /** 是否成功 */
  success: boolean
  /** 消息ID */
  messageId: string
  /** 是否使用了配额 */
  quotaUsed: boolean
}

/**
 * 外置EmailJS发送器
 * 使用用户自己的EmailJS账户配置
 * 
 * @class EmailJSExternalSender
 * @implements {IEmailSender}
 */
export class EmailJSExternalSender implements IEmailSender {
  private networkService = NetworkService.getInstance()

  private config: EmailSenderConfig = {
    name: '外置EmailJS服务',
    type: EmailSenderType.EMAILJS_EXTERNAL,
    requiresConfig: true,
    hasBuiltInService: false,
    description: '使用自己的EmailJS账户，无配额限制'
  }

  /**
   * 获取发送器配置
   * @returns 发送器配置对象
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   * @param content 邮件内容
   * @param userConfig 用户配置
   * @returns 发送结果
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      if (!userConfig || !userConfig['service_id'] || !userConfig['template_id'] || !userConfig['public_key']) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '缺少EmailJS配置信息'
        }
        return errorResponse
      }

      const url = 'https://api.emailjs.com/api/v1.0/email/send'
      
      // ✅ 优化：将临时邮箱地址显示在发件人名称中
      const displayFromName = content.from 
        ? content.from  // 优先使用临时邮箱地址
        : (content.fromName || userConfig['from_name'] || '临时邮箱')
      
      const templateParams: EmailJSTemplateParams = {
        to_email: content.to,
        to_name: content.to.split('@')[0],
        from_name: displayFromName,
        subject: content.subject,
        message: content.body
      }

      const postData: EmailJSSendRequest = {
        service_id: userConfig['service_id'],
        template_id: userConfig['template_id'],
        user_id: userConfig['public_key'],
        template_params: templateParams
      }

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Origin': 'https://convenient-mailbox.app',
        'Referer': 'https://convenient-mailbox.app/'
      }

      const response = await this.networkService.post<Record<string, string>>(
        url,
        postData,
        headers
      )

      if (response.success) {
        const sendResult: SendResult = {
          success: true,
          messageId: 'emailjs-' + Date.now(),
          quotaUsed: false
        }

        const successResponse: NetworkResponse<SendResult> = {
          success: true,
          data: sendResult,
          error: ''
        }
        return successResponse
      } else {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: response.error || 'EmailJS发送失败'
        }
        return errorResponse
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'EmailJS发送失败: %{public}s', err.message)
      
      const errorResponse: NetworkResponse<SendResult> = {
        success: false,
        data: null,
        error: err.message
      }
      return errorResponse
    }
  }

  /**
   * 验证用户配置
   * @param config 用户配置
   * @returns 是否有效
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    return !!(config['service_id'] && config['template_id'] && config['public_key'])
  }

  /**
   * 测试连接
   * @param config 用户配置
   * @returns 是否连接成功
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    if (!config) return false
    return await this.validateConfig(config)
  }

  /**
   * 获取配置字段定义
   * @returns 配置字段数组
   */
  getConfigFields(): ConfigField[] {
    const fields: ConfigField[] = [
      {
        key: 'service_id',
        label: 'Service ID',
        type: 'text',
        required: true,
        placeholder: 'service_xxxxxxx',
        helpText: '在EmailJS控制台获取'
      },
      {
        key: 'template_id',
        label: 'Template ID',
        type: 'text',
        required: true,
        placeholder: 'template_xxxxxxx',
        helpText: '邮件模板ID'
      },
      {
        key: 'public_key',
        label: 'Public Key',
        type: 'text',
        required: true,
        placeholder: 'your_public_key',
        helpText: 'EmailJS公钥'
      },
      {
        key: 'from_name',
        label: '发件人名称',
        type: 'text',
        required: false,
        defaultValue: '临时邮箱'
      }
    ]
    return fields
  }
}

/**
 * 内置EmailJS发送器
 * 使用应用内置的EmailJS配置（不推荐用于生产环境）
 * 
 * @class EmailJSBuiltinSender
 * @implements {IEmailSender}
 */
export class EmailJSBuiltinSender implements IEmailSender {
  private networkService = NetworkService.getInstance()
  private quotaManager = QuotaManager.getInstance()

  private config: EmailSenderConfig = {
    name: '内置EmailJS服务',
    type: EmailSenderType.EMAILJS_BUILTIN,
    requiresConfig: false,
    hasBuiltInService: true,
    description: '使用内置EmailJS服务，每月2封免费配额'
  }

  /**
   * 获取发送器配置
   * @returns 发送器配置对象
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   * @param content 邮件内容
   * @param userConfig 用户配置（内置服务不需要）
   * @returns 发送结果
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      // ✅ 从安全存储读取配置
      const builtInConfig = await SecureEmailServiceConfig.getEmailJSConfig()
      if (!builtInConfig) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: 'EmailJS内置服务配置读取失败'
        }
        return errorResponse
      }

      // 检查配额
      const hasQuota = await this.quotaManager.checkQuota('emailjs')
      if (!hasQuota) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: 'EmailJS配额已用完，请使用其他发送方式或配置自己的EmailJS账户'
        }
        return errorResponse
      }

      const url = 'https://api.emailjs.com/api/v1.0/email/send'
      
      // ✅ 优化：将临时邮箱地址显示在发件人名称中，让收件人知道是谁发的
      const displayFromName = content.from 
        ? content.from  // 使用临时邮箱地址作为发件人名称
        : (content.fromName || builtInConfig.from_name)
      
      const templateParams: EmailJSTemplateParams = {
        to_email: content.to,
        to_name: content.to.split('@')[0],
        from_name: displayFromName,
        subject: content.subject,
        message: content.body
      }

      const postData: EmailJSSendRequest = {
        service_id: builtInConfig.service_id,
        template_id: builtInConfig.template_id,
        user_id: builtInConfig.public_key,
        template_params: templateParams
      }

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Origin': 'https://convenient-mailbox.app',
        'Referer': 'https://convenient-mailbox.app/'
      }

      const response = await this.networkService.post<Record<string, string>>(
        url,
        postData,
        headers
      )

      if (response.success) {
        // 使用配额
        await this.quotaManager.useQuota('emailjs')
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'EmailJS内置发送成功')

        const sendResult: SendResult = {
          success: true,
          messageId: 'emailjs-builtin-' + Date.now(),
          quotaUsed: true
        }

        const successResponse: NetworkResponse<SendResult> = {
          success: true,
          data: sendResult,
          error: ''
        }
        return successResponse
      } else {
        // ✅ 详细记录失败原因，帮助排查问题
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'EmailJS内置发送失败: %{public}s', response.error || '未知错误')
        
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: response.error || 'EmailJS发送失败'
        }
        return errorResponse
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'EmailJS内置服务发送失败: %{public}s', err.message)
      
      const errorResponse: NetworkResponse<SendResult> = {
        success: false,
        data: null,
        error: err.message
      }
      return errorResponse
    }
  }

  /**
   * 验证用户配置
   * @param config 用户配置
   * @returns 是否有效（内置服务总是有效）
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    return true // 内置服务不需要用户配置
  }

  /**
   * 测试连接
   * @param config 用户配置
   * @returns 是否连接成功
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    return validateEmailJSConfig() // 检查配置是否有效
  }

  /**
   * 获取配置字段定义
   * @returns 配置字段数组（内置服务无需配置）
   */
  getConfigFields(): ConfigField[] {
    const fields: ConfigField[] = []
    return fields // 内置服务无需配置
  }
}

/**
 * 通过后端代理发送EmailJS（推荐）
 * API密钥安全存储在用户自己的后端服务器
 * 
 * @class EmailJSProxySender
 * @implements {IEmailSender}
 */
export class EmailJSProxySender implements IEmailSender {
  private networkService = NetworkService.getInstance()
  private configManager = UserEmailConfigManager.getInstance()
  private quotaManager = QuotaManager.getInstance()

  private config: EmailSenderConfig = {
    name: 'EmailJS（后端代理）',
    type: EmailSenderType.EMAILJS_PROXY,
    requiresConfig: true,
    hasBuiltInService: false,
    description: '通过您的后端服务器发送，API密钥安全存储（推荐）'
  }

  /**
   * 获取发送器配置
   * @returns 发送器配置对象
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   * @param content 邮件内容
   * @param userConfig 用户配置（代理不需要）
   * @returns 发送结果
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      // 获取后端代理配置
      const proxyConfig = await this.configManager.getProxyConfig()

      if (!proxyConfig.enabled || !proxyConfig.baseUrl) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '请先在设置中配置后端代理服务器'
        }
        return errorResponse
      }

      // 构建请求URL
      const url = `${proxyConfig.baseUrl}/email/send/emailjs`

      // 构建请求数据
      const postData: ProxyEmailSendRequest = {
        to: content.to,
        from: content.from,
        fromName: content.fromName || '临时邮箱',
        subject: content.subject,
        body: content.body,
        html: content.html
      }

      // 构建请求头
      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
      }

      // 如果有认证令牌，添加到请求头
      if (proxyConfig.authToken) {
        headers['Authorization'] = `Bearer ${proxyConfig.authToken}`
      }

      // 发送请求
      const response = await this.networkService.post<ProxyApiResponse<ProxyResponseData>>(
        url,
        postData,
        headers
      )

      if (response.success && response.data && response.data.success) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'EmailJS代理发送成功')

        const sendResult: SendResult = {
          success: true,
          messageId: response.data.data?.messageId || 'proxy-emailjs-' + Date.now(),
          quotaUsed: false
        }

        const successResponse: NetworkResponse<SendResult> = {
          success: true,
          data: sendResult,
          error: ''
        }
        return successResponse
      } else {
        const errorMsg = response.data?.error || response.error || '后端代理发送失败'
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'EmailJS代理发送失败: %{public}s', errorMsg)

        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: errorMsg
        }
        return errorResponse
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'EmailJS代理发送异常: %{public}s', err.message)
      
      const errorResponse: NetworkResponse<SendResult> = {
        success: false,
        data: null,
        error: `代理服务器错误: ${err.message}`
      }
      return errorResponse
    }
  }

  /**
   * 验证用户配置
   * @param config 用户配置
   * @returns 是否有效
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    const proxyConfig = await this.configManager.getProxyConfig()
    return proxyConfig.enabled && proxyConfig.baseUrl.length > 0
  }

  /**
   * 测试连接
   * @param config 用户配置
   * @returns 是否连接成功
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    try {
      const proxyConfig = await this.configManager.getProxyConfig()
      
      if (!proxyConfig.enabled || !proxyConfig.baseUrl) {
        return false
      }

      // 测试代理服务器连接
      const url = `${proxyConfig.baseUrl}/health`
      const headers: Record<string, string> = {}

      if (proxyConfig.authToken) {
        headers['Authorization'] = `Bearer ${proxyConfig.authToken}`
      }

      const response = await this.networkService.get<Record<string, ESObject>>(url, headers)
      return response.success
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '测试代理连接失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 获取配置字段定义
   * @returns 配置字段数组
   */
  getConfigFields(): ConfigField[] {
    const fields: ConfigField[] = [
      {
        key: 'info',
        label: '配置说明',
        type: 'text',
        required: false,
        helpText: '请在【设置】>【邮件服务配置】>【后端代理配置】中配置您的后端服务器地址'
      }
    ]
    return fields
  }
}
