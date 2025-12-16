/**
 * 网络服务
 * 封装HTTP请求和第三方API调用
 */

import http from '@ohos.net.http'
import { NetworkResponse, TempEmail, TempEmailContent } from './DataTypes'
import { AppConstants } from './Constants'
import { EmailSenderFactory } from '../services/email/EmailSenderFactory'
import { EmailContent, EmailSenderType } from '../services/email/IEmailSender'
import hilog from '@ohos.hilog'

/**
 * 请求配置接口
 */
export interface RequestConfig {
  url: string
  method: http.RequestMethod
  header?: Object
  extraData?: string | Object
  expectDataType?: http.HttpDataType
  connectTimeout?: number
  readTimeout?: number
}

/**
 * HTTP请求选项
 */
interface HttpRequestOptions {
  method: http.RequestMethod
  header: Object
  extraData?: string | Object
  expectDataType: http.HttpDataType
  connectTimeout: number
  readTimeout: number
}

/**
 * EmailJS模板参数
 */
interface EmailJSTemplateParams {
  to_email: string
  subject: string
  message: string
}

/**
 * EmailJS请求数据
 */
interface EmailJSRequestData {
  service_id: string
  template_id: string
  user_id: string
  template_params: EmailJSTemplateParams
}

/**
 * EmailJS请求头
 */
interface EmailJSHeaders {
  'Content-Type': string
}

/**
 * 网络服务类（单例模式）
 */
export class NetworkService {
  private static instance: NetworkService
  private senderFactory: EmailSenderFactory | null = null

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): NetworkService {
    if (!NetworkService.instance) {
      NetworkService.instance = new NetworkService()
    }
    return NetworkService.instance
  }

  /**
   * 获取EmailSenderFactory实例（延迟初始化）
   */
  private getSenderFactory(): EmailSenderFactory {
    if (!this.senderFactory) {
      this.senderFactory = EmailSenderFactory.getInstance()
    }
    return this.senderFactory
  }

  /**
   * 通用HTTP请求方法
   * 
   * ✅ 修复说明（2025-10-06）：
   * 1. extraData序列化：Object类型必须JSON.stringify，否则API收到 [object Object]
   * 2. header合并：确保Content-Type等默认header始终存在
   * 3. JSON解析保护：添加try-catch防止格式错误导致崩溃
   */
  async request<T>(config: RequestConfig): Promise<NetworkResponse<T>> {
    const httpRequest = http.createHttp()
    
    try {
      // ✅ 修复1：合并header，确保默认header始终存在
      // ArkTS 不支持 Object.assign，改用手动合并
      const mergedHeaders: Record<string, string> = {
        'Content-Type': 'application/json'
      }
      // 手动合并用户提供的 header
      const userHeaders = config.header as Record<string, string>
      if (userHeaders) {
        const keys = Object.keys(userHeaders)
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i]
          mergedHeaders[key] = userHeaders[key]
        }
      }
      
      const options: HttpRequestOptions = {
        method: config.method,
        header: mergedHeaders,
        // ✅ 修复2：序列化extraData - 核心修复！
        // Object类型必须转换为JSON字符串，否则HTTP请求体格式错误
        extraData: (config.extraData && typeof config.extraData !== 'string') 
          ? JSON.stringify(config.extraData) 
          : config.extraData,
        expectDataType: config.expectDataType || http.HttpDataType.STRING,
        connectTimeout: config.connectTimeout || AppConstants.NETWORK_TIMEOUT,
        readTimeout: config.readTimeout || AppConstants.NETWORK_TIMEOUT
      }
      
      const response = await httpRequest.request(config.url, options)

      if (response.responseCode === 200) {
        let data: T | null = null
        if (typeof response.result === 'string') {
          const resultStr = response.result.trim()
          
          // ✅ 修复：EmailJS成功响应为纯文本"OK"，特殊处理
          if (resultStr === 'OK' || resultStr === 'ok') {
            hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
              'API返回纯文本成功响应: %{public}s', resultStr)
            // 对于EmailJS的"OK"响应，返回成功但data为null
            return {
              success: true,
              data: null,
              error: ''
            }
          }
          
          // ✅ 尝试JSON解析
          try {
            data = JSON.parse(resultStr) as T
          } catch (parseError) {
            const err = parseError as Error
            hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
              'JSON解析失败: %{public}s, 原始响应: %{public}s', 
              err.message, resultStr.substring(0, 200))
            return {
              success: false,
              data: null,
              error: 'API返回格式错误：' + err.message
            }
          }
        } else {
          data = response.result as T
        }
        
        return {
          success: true,
          data: data,
          error: ''
        }
      } else {
        // ✅ 详细记录非200响应，包含完整的响应信息供排查
        const resultStr = typeof response.result === 'string' 
          ? response.result 
          : JSON.stringify(response.result)
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
          'HTTP请求失败: code=%{public}d, url=%{public}s, response=%{public}s', 
          response.responseCode, config.url, resultStr.substring(0, 300))
        
        return {
          success: false,
          data: null,
          error: `HTTP ${response.responseCode}: ${response.result}`
        }
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '网络请求失败: %{public}s', err.message)
      return {
        success: false,
        data: null,
        error: err.message
      }
    } finally {
      httpRequest.destroy()
    }
  }

  /**
   * GET请求
   */
  async get<T>(url: string, headers?: Object): Promise<NetworkResponse<T>> {
    return this.request<T>({
      url: url,
      method: http.RequestMethod.GET,
      header: headers
    })
  }

  /**
   * POST请求
   */
  async post<T>(url: string, data?: Object, headers?: Object): Promise<NetworkResponse<T>> {
    return this.request<T>({
      url: url,
      method: http.RequestMethod.POST,
      header: headers,
      extraData: data
    })
  }

  /**
   * 生成临时邮箱
   * 使用1SecMail API
   */
  async generateTempEmail(): Promise<NetworkResponse<string>> {
    try {
      const url = `${AppConstants.API_BASE_URL}/genRandomMailbox?count=1`
      const response = await this.get<string[]>(url)
      
      if (response.success && response.data && response.data.length > 0) {
        return {
          success: true,
          data: response.data[0],
          error: ''
        }
      } else {
        return {
          success: false,
          data: null,
          error: '生成邮箱失败'
        }
      }
    } catch (error) {
      const err = error as Error
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  /**
   * 检查邮件
   */
  async checkEmails(email: string): Promise<NetworkResponse<TempEmail[]>> {
    try {
      const parts = email.split('@')
      if (parts.length !== 2) {
        return {
          success: false,
          data: null,
          error: '邮箱格式错误'
        }
      }
      
      const login = parts[0]
      const domain = parts[1]
      const url = `${AppConstants.API_BASE_URL}/getMessages?login=${login}&domain=${domain}`
      
      return await this.get<TempEmail[]>(url)
    } catch (error) {
      const err = error as Error
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  /**
   * 读取邮件详情
   */
  async readEmail(emailId: number, email: string): Promise<NetworkResponse<TempEmailContent>> {
    try {
      const parts = email.split('@')
      if (parts.length !== 2) {
        return {
          success: false,
          data: null,
          error: '邮箱格式错误'
        }
      }
      
      const login = parts[0]
      const domain = parts[1]
      const url = `${AppConstants.API_BASE_URL}/readMessage?login=${login}&domain=${domain}&id=${emailId}`
      
      return await this.get<TempEmailContent>(url)
    } catch (error) {
      const err = error as Error
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  /**
   * 发送邮件（使用指定的发送方式）
   */
  async sendEmail(
    to: string,
    subject: string,
    body: string,
    senderType?: EmailSenderType,
    userConfig?: Record<string, string>,
    from?: string,
    fromName?: string
  ): Promise<NetworkResponse<string>> {
    try {
      // 默认使用内置EmailJS
      const type = senderType || EmailSenderType.EMAILJS_BUILTIN
      
      // ✅ 日志脱敏：隐藏收件人地址
      const maskedTo = to.replace(/(.{2}).*(@.*)/, '$1***$2')
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'NetworkService.sendEmail: 开始发送邮件, senderType=%{public}s, to=%{public}s',
        type, maskedTo)
      
      const sender = this.getSenderFactory().getSender(type)
      
      if (!sender) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'NetworkService.sendEmail: 未找到发送器, type=%{public}s', type)
        return {
          success: false,
          data: null,
          error: '未找到指定的发送方式: ' + type
        }
      }

      const emailContent: EmailContent = {
        from: from,
        fromName: fromName,
        to: to,
        subject: subject,
        body: body
      }

      // ✅ 日志脱敏：隐藏收件人地址（复用之前的 maskedTo）
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'NetworkService.sendEmail: 调用发送器发送, from=%{public}s, to=%{public}s',
        from || 'undefined', maskedTo)

      const result = await sender.send(emailContent, userConfig)
      
      if (result.success && result.data) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'NetworkService.sendEmail: 发送成功, messageId=%{public}s',
          result.data.messageId || 'none')
        return {
          success: true,
          data: result.data.messageId || 'sent',
          error: ''
        }
      } else {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'NetworkService.sendEmail: 发送失败, error=%{public}s',
          result.error || '未知错误')
        return {
          success: false,
          data: null,
          error: result.error || '发送失败'
        }
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '发送邮件异常: %{public}s', err.message)
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  /**
   * 获取邮件发送器工厂（供其他模块使用）
   */
  getEmailSenderFactory(): EmailSenderFactory {
    return this.getSenderFactory()
  }
}
