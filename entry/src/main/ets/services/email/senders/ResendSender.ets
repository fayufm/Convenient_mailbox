/**
 * Resend邮件发送器
 * 支持外置和内置两种模式
 * 
 * Resend是一个现代化的邮件API服务
 * 提供简洁的API和高送达率
 * 
 * @module ResendSender
 * @since 2.0.0
 */

import { IEmailSender, EmailSenderConfig, EmailContent, SendResult, ConfigField, EmailSenderType } from '../IEmailSender'
import { NetworkResponse } from '../../../common/DataTypes'
import { NetworkService } from '../../../common/NetworkService'
import { QuotaManager } from '../../QuotaManager'
import { AppConstants } from '../../../common/Constants'
import { SecureEmailServiceConfig, validateResendConfig } from '../../../config/EmailServiceConfig'
import hilog from '@ohos.hilog'

/**
 * Resend发送请求数据接口
 */
interface ResendSendRequest {
  /** 发件人地址 */
  from: string
  /** 收件人地址列表 */
  to: string[]
  /** 邮件主题 */
  subject: string
  /** 邮件正文（纯文本） */
  text: string
  /** 邮件正文（HTML） */
  html: string
}

/**
 * Resend API响应数据接口
 */
interface ResendApiResponseData {
  /** 邮件ID */
  id?: string
}

/**
 * Resend发送结果接口
 */
interface ResendSendResult {
  /** 是否成功 */
  success: boolean
  /** 消息ID */
  messageId: string
  /** 是否使用了配额 */
  quotaUsed: boolean
}

/**
 * 外置Resend发送器
 * 使用用户自己的Resend API密钥
 * 
 * @class ResendExternalSender
 * @implements {IEmailSender}
 */
export class ResendExternalSender implements IEmailSender {
  private networkService = NetworkService.getInstance()

  private config: EmailSenderConfig = {
    name: '外置Resend API',
    type: EmailSenderType.RESEND_EXTERNAL,
    requiresConfig: true,
    hasBuiltInService: false,
    description: '使用自己的Resend API密钥，无配额限制'
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
      if (!userConfig || !userConfig['api_key']) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '缺少Resend API密钥'
        }
        return errorResponse
      }

      const url = 'https://api.resend.com/emails'
      
      // 验证必要字段
      if (!content.to || content.to.trim() === '') {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'Resend外置: 收件人地址为空')
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '收件人地址不能为空'
        }
        return errorResponse
      }
      
      const postData: ResendSendRequest = {
        from: userConfig['from_email'] || 'onboarding@resend.dev',
        to: [content.to],
        subject: content.subject,
        text: content.body,
        html: content.html || content.body.replace(/\n/g, '<br>')
      }

      // ✅ 日志脱敏：隐藏敏感信息保护隐私
      const maskedTo = content.to.replace(/(.{2}).*(@.*)/, '$1***$2')
      const maskedSubject = content.subject.length > 10 
        ? content.subject.substring(0, 10) + '...' 
        : '[已隐藏]'
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Resend外置发送: to=%{public}s, from=%{public}s, subject=%{public}s',
        maskedTo, postData.from, maskedSubject)

      const headers: Record<string, string> = {
        'Authorization': `Bearer ${userConfig['api_key']}`,
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br'
      }

      const response = await this.networkService.post<ResendApiResponseData>(
        url,
        postData,
        headers
      )

      if (response.success && response.data) {
        const sendResult: SendResult = {
          success: true,
          messageId: response.data.id || 'resend-' + Date.now(),
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
          error: response.error || 'Resend发送失败'
        }
        return errorResponse
      }
    } catch (error) {
      const err = error as Error
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
    return !!(config['api_key'] && config['api_key'].startsWith('re_'))
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
        key: 'api_key',
        label: 'API Key',
        type: 'password',
        required: true,
        placeholder: 're_xxxxxxxxxxxx',
        helpText: '在Resend控制台获取API密钥'
      },
      {
        key: 'from_email',
        label: '发件人地址',
        type: 'text',
        required: false,
        defaultValue: 'onboarding@resend.dev',
        helpText: '需要在Resend验证的域名'
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
 * 内置Resend发送器
 * 使用应用内置的Resend API配置
 * 
 * @class ResendBuiltinSender
 * @implements {IEmailSender}
 */
export class ResendBuiltinSender implements IEmailSender {
  private networkService = NetworkService.getInstance()
  private quotaManager = QuotaManager.getInstance()

  private config: EmailSenderConfig = {
    name: '内置Resend API',
    type: EmailSenderType.RESEND_BUILTIN,
    requiresConfig: false,
    hasBuiltInService: true,
    description: '使用内置Resend服务，每月3封免费配额'
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
      const builtInConfig = await SecureEmailServiceConfig.getResendConfig()
      if (!builtInConfig) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: 'Resend内置服务配置读取失败'
        }
        return errorResponse
      }

      // 检查配额
      const hasQuota = await this.quotaManager.checkQuota('resend')
      if (!hasQuota) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: 'Resend配额已用完，请使用其他发送方式或配置自己的Resend API'
        }
        return errorResponse
      }

      // 验证必要字段
      if (!content.to || content.to.trim() === '') {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'Resend内置: 收件人地址为空')
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '收件人地址不能为空'
        }
        return errorResponse
      }

      const url = 'https://api.resend.com/emails'
      
      const postData: ResendSendRequest = {
        from: builtInConfig.from_email,
        to: [content.to],
        subject: content.subject,
        text: content.body,
        html: content.html || content.body.replace(/\n/g, '<br>')
      }

      // ✅ 日志脱敏：隐藏敏感信息保护隐私
      const maskedTo = content.to.replace(/(.{2}).*(@.*)/, '$1***$2')
      const maskedSubject = content.subject.length > 10 
        ? content.subject.substring(0, 10) + '...' 
        : '[已隐藏]'
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Resend内置发送: to=%{public}s, from=%{public}s, subject=%{public}s',
        maskedTo, postData.from, maskedSubject)

      const headers: Record<string, string> = {
        'Authorization': `Bearer ${builtInConfig.api_key}`,
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'application/json',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br'
      }

      const response = await this.networkService.post<ResendApiResponseData>(
        url,
        postData,
        headers
      )

      if (response.success && response.data) {
        // 使用配额
        await this.quotaManager.useQuota('resend')

        const sendResult: SendResult = {
          success: true,
          messageId: response.data.id || 'resend-builtin-' + Date.now(),
          quotaUsed: true
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
          error: response.error || 'Resend发送失败'
        }
        return errorResponse
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Resend内置服务发送失败: %{public}s', err.message)
      
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
    return true
  }

  /**
   * 获取配置字段定义
   * @returns 配置字段数组（内置服务无需配置）
   */
  getConfigFields(): ConfigField[] {
    const fields: ConfigField[] = []
    return fields
  }
}
