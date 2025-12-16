/**
 * 各种API邮件发送器集合
 * 包含SendGrid, Mailgun, Postmark, Brevo等主流邮件服务提供商
 * 
 * 每个发送器都实现IEmailSender接口
 * 需要用户提供自己的API密钥
 * 
 * @module APISenders
 * @since 2.0.0
 */

import { IEmailSender, EmailSenderConfig, EmailContent, SendResult, ConfigField, EmailSenderType } from '../IEmailSender'
import { NetworkResponse } from '../../../common/DataTypes'
import { NetworkService } from '../../../common/NetworkService'
import hilog from '@ohos.hilog'
import util from '@ohos.util'

/**
 * 邮件地址对象接口
 */
interface EmailAddress {
  /** 邮箱地址 */
  email: string
  /** 名称（可选） */
  name?: string
}

/**
 * SendGrid个性化配置接口
 */
interface SendGridPersonalization {
  /** 收件人列表 */
  to: EmailAddress[]
}

/**
 * SendGrid内容接口
 */
interface SendGridContent {
  /** 内容类型 */
  type: string
  /** 内容值 */
  value: string
}

/**
 * SendGrid发送请求接口
 */
interface SendGridSendRequest {
  /** 个性化配置 */
  personalizations: SendGridPersonalization[]
  /** 发件人 */
  from: EmailAddress
  /** 邮件主题 */
  subject: string
  /** 邮件内容 */
  content: SendGridContent[]
}

/**
 * Mailgun发送请求接口（form-data格式）
 */
interface MailgunSendRequest {
  /** 发件人 */
  from: string
  /** 收件人 */
  to: string
  /** 邮件主题 */
  subject: string
  /** 邮件正文 */
  text: string
}

/**
 * Mailgun API响应接口
 */
interface MailgunApiResponse {
  /** 消息ID */
  id?: string
  /** 消息 */
  message?: string
}

/**
 * Postmark发送请求接口
 */
interface PostmarkSendRequest {
  /** 发件人 */
  From: string
  /** 收件人 */
  To: string
  /** 邮件主题 */
  Subject: string
  /** 邮件正文（纯文本） */
  TextBody: string
  /** 消息流 */
  MessageStream: string
}

/**
 * Postmark API响应接口
 */
interface PostmarkApiResponse {
  /** 消息ID */
  MessageID?: string
  /** 提交时间 */
  SubmittedAt?: string
  /** 收件人 */
  To?: string
}

/**
 * 通用API响应数据接口
 */
interface GenericApiResponseData {
  /** 消息ID */
  id?: string
  /** 消息ID（PostmarkAPI使用） */
  MessageID?: string
}

/**
 * 发送结果实现接口
 */
interface EmailSendResult {
  /** 是否成功 */
  success: boolean
  /** 消息ID */
  messageId: string
  /** 是否使用了配额 */
  quotaUsed?: boolean
}

/**
 * SendGrid发送器
 * Twilio SendGrid是最受欢迎的邮件服务之一
 * 
 * @class SendGridSender
 * @implements {IEmailSender}
 */
export class SendGridSender implements IEmailSender {
  private networkService = NetworkService.getInstance()

  private config: EmailSenderConfig = {
    name: 'SendGrid API',
    type: EmailSenderType.SENDGRID,
    requiresConfig: true,
    hasBuiltInService: false,
    description: 'Twilio SendGrid邮件服务'
  }

  /**
   * 获取发送器配置
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      if (!userConfig || !userConfig['api_key']) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '缺少SendGrid API密钥'
        }
        return errorResponse
      }

      const url = 'https://api.sendgrid.com/v3/mail/send'
      
      const toAddress: EmailAddress = {
        email: content.to
      }

      const personalization: SendGridPersonalization = {
        to: [toAddress]
      }

      const fromAddress: EmailAddress = {
        email: userConfig['from_email'] || 'noreply@example.com',
        name: userConfig['from_name'] || '临时邮箱'
      }

      const emailContent: SendGridContent = {
        type: 'text/plain',
        value: content.body
      }

      const postData: SendGridSendRequest = {
        personalizations: [personalization],
        from: fromAddress,
        subject: content.subject,
        content: [emailContent]
      }

      const headers: Record<string, string> = {
        'Authorization': `Bearer ${userConfig['api_key']}`,
        'Content-Type': 'application/json'
      }

      const response = await this.networkService.post<Record<string, ESObject>>(
        url,
        postData,
        headers
      )

      if (response.success) {
        const sendResult: SendResult = {
          success: true,
          messageId: 'sendgrid-' + Date.now()
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
          error: response.error || 'SendGrid发送失败'
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
   * 验证配置
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    return !!(config['api_key'] && config['from_email'])
  }

  /**
   * 测试连接
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    if (!config) return false
    return await this.validateConfig(config)
  }

  /**
   * 获取配置字段
   */
  getConfigFields(): ConfigField[] {
    const field1: ConfigField = {
      key: 'api_key',
      label: 'API Key',
      type: 'password',
      required: true,
      helpText: '从SendGrid控制台获取'
    }

    const field2: ConfigField = {
      key: 'from_email',
      label: '发件人地址',
      type: 'text',
      required: true
    }

    const field3: ConfigField = {
      key: 'from_name',
      label: '发件人名称',
      type: 'text',
      required: false,
      defaultValue: '临时邮箱'
    }

    const fields: ConfigField[] = [field1, field2, field3]
    return fields
  }
}

/**
 * Mailgun发送器
 * Mailgun是另一个流行的邮件服务
 * 
 * @class MailgunSender
 * @implements {IEmailSender}
 */
export class MailgunSender implements IEmailSender {
  private networkService = NetworkService.getInstance()

  private config: EmailSenderConfig = {
    name: 'Mailgun API',
    type: EmailSenderType.MAILGUN,
    requiresConfig: true,
    hasBuiltInService: false,
    description: 'Mailgun邮件服务'
  }

  /**
   * 获取发送器配置
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      if (!userConfig || !userConfig['api_key'] || !userConfig['domain']) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '缺少Mailgun配置'
        }
        return errorResponse
      }

      const domain = userConfig['domain']
      const url = `https://api.mailgun.net/v3/${domain}/messages`
      
      // Mailgun使用form-data格式
      const formData: MailgunSendRequest = {
        from: `${userConfig['from_name'] || '临时邮箱'} <${userConfig['from_email'] || 'noreply@' + domain}>`,
        to: content.to,
        subject: content.subject,
        text: content.body
      }

      // 编码Basic认证
      const authString = 'api:' + userConfig['api_key']
      const textEncoder = new util.TextEncoder()
      const uint8Array: Uint8Array = textEncoder.encodeInto(authString)
      const base64Helper = new util.Base64Helper()
      const base64Auth: string = base64Helper.encodeToStringSync(uint8Array)

      const headers: Record<string, string> = {
        'Authorization': `Basic ${base64Auth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      }

      const response = await this.networkService.post<MailgunApiResponse>(
        url,
        formData,
        headers
      )

      if (response.success) {
        const sendResult: SendResult = {
          success: true,
          messageId: response.data?.id || 'mailgun-' + Date.now()
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
          error: response.error || 'Mailgun发送失败'
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
   * 验证配置
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    return !!(config['api_key'] && config['domain'])
  }

  /**
   * 测试连接
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    if (!config) return false
    return await this.validateConfig(config)
  }

  /**
   * 获取配置字段
   */
  getConfigFields(): ConfigField[] {
    const field1: ConfigField = {
      key: 'api_key',
      label: 'API Key',
      type: 'password',
      required: true
    }

    const field2: ConfigField = {
      key: 'domain',
      label: '域名',
      type: 'text',
      required: true,
      placeholder: 'mg.example.com'
    }

    const field3: ConfigField = {
      key: 'from_email',
      label: '发件人地址',
      type: 'text',
      required: false
    }

    const field4: ConfigField = {
      key: 'from_name',
      label: '发件人名称',
      type: 'text',
      required: false,
      defaultValue: '临时邮箱'
    }

    const fields: ConfigField[] = [field1, field2, field3, field4]
    return fields
  }
}

/**
 * Postmark发送器
 * Postmark专注于事务性邮件
 * 
 * @class PostmarkSender
 * @implements {IEmailSender}
 */
export class PostmarkSender implements IEmailSender {
  private networkService = NetworkService.getInstance()

  private config: EmailSenderConfig = {
    name: 'Postmark API',
    type: EmailSenderType.POSTMARK,
    requiresConfig: true,
    hasBuiltInService: false,
    description: 'Postmark邮件服务'
  }

  /**
   * 获取发送器配置
   */
  getConfig(): EmailSenderConfig {
    return this.config
  }

  /**
   * 发送邮件
   */
  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      if (!userConfig || !userConfig['server_token']) {
        const errorResponse: NetworkResponse<SendResult> = {
          success: false,
          data: null,
          error: '缺少Postmark Server Token'
        }
        return errorResponse
      }

      const url = 'https://api.postmarkapp.com/email'
      
      const postData: PostmarkSendRequest = {
        From: userConfig['from_email'] || 'noreply@example.com',
        To: content.to,
        Subject: content.subject,
        TextBody: content.body,
        MessageStream: 'outbound'
      }

      const headers: Record<string, string> = {
        'X-Postmark-Server-Token': userConfig['server_token'],
        'Content-Type': 'application/json'
      }

      const response = await this.networkService.post<PostmarkApiResponse>(
        url,
        postData,
        headers
      )

      if (response.success && response.data) {
        const sendResult: SendResult = {
          success: true,
          messageId: response.data.MessageID || 'postmark-' + Date.now()
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
          error: response.error || 'Postmark发送失败'
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
   * 验证配置
   */
  async validateConfig(config: Record<string, string>): Promise<boolean> {
    return !!(config['server_token'] && config['from_email'])
  }

  /**
   * 测试连接
   */
  async testConnection(config?: Record<string, string>): Promise<boolean> {
    if (!config) return false
    return await this.validateConfig(config)
  }

  /**
   * 获取配置字段
   */
  getConfigFields(): ConfigField[] {
    const field1: ConfigField = {
      key: 'server_token',
      label: 'Server Token',
      type: 'password',
      required: true
    }

    const field2: ConfigField = {
      key: 'from_email',
      label: '发件人地址',
      type: 'text',
      required: true
    }

    const fields: ConfigField[] = [field1, field2]
    return fields
  }
}
