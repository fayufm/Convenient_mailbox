/**
 * 邮件发送器工厂
 * 管理和创建所有邮件发送器实例
 * 
 * 使用单例模式确保全局只有一个工厂实例
 * 提供统一的接口获取不同类型的邮件发送器
 * 
 * @module EmailSenderFactory
 * @since 2.0.0
 */

import { IEmailSender, EmailSenderType } from './IEmailSender'
import { SMTPSender } from './senders/SMTPSender'
import { EmailJSExternalSender, EmailJSBuiltinSender, EmailJSProxySender } from './senders/EmailJSSender'
import { ResendExternalSender, ResendBuiltinSender } from './senders/ResendSender'
import {
  SendGridSender,
  MailgunSender,
  PostmarkSender
} from './senders/APISenders'
import { AppConstants } from '../../common/Constants'
import hilog from '@ohos.hilog'
import { SenderOption } from '../../types/SenderTypes'

/**
 * 邮件发送器工厂（单例）
 * 
 * @class EmailSenderFactory
 * @description 管理所有邮件发送器实例，提供统一的获取接口
 */
export class EmailSenderFactory {
  private static instance: EmailSenderFactory
  
  /** 发送器实例缓存 */
  private senders: Map<EmailSenderType, IEmailSender> = new Map()

  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {
    this.initializeSenders()
  }

  /**
   * 获取工厂单例实例
   * @returns 工厂实例
   */
  static getInstance(): EmailSenderFactory {
    if (!EmailSenderFactory.instance) {
      EmailSenderFactory.instance = new EmailSenderFactory()
    }
    return EmailSenderFactory.instance
  }

  /**
   * 初始化所有发送器
   * 创建并缓存所有可用的邮件发送器实例
   * @private
   */
  private initializeSenders(): void {
    // SMTP
    this.senders.set(EmailSenderType.SMTP, new SMTPSender())
    
    // EmailJS（3种模式）
    this.senders.set(EmailSenderType.EMAILJS_EXTERNAL, new EmailJSExternalSender())
    this.senders.set(EmailSenderType.EMAILJS_BUILTIN, new EmailJSBuiltinSender())
    this.senders.set(EmailSenderType.EMAILJS_PROXY, new EmailJSProxySender()) // ✅ 推荐使用
    
    // Resend（2种模式）
    this.senders.set(EmailSenderType.RESEND_EXTERNAL, new ResendExternalSender())
    this.senders.set(EmailSenderType.RESEND_BUILTIN, new ResendBuiltinSender())
    
    // 其他API服务
    this.senders.set(EmailSenderType.SENDGRID, new SendGridSender())
    this.senders.set(EmailSenderType.MAILGUN, new MailgunSender())
    this.senders.set(EmailSenderType.POSTMARK, new PostmarkSender())
    
    // TODO: 以下发送器待实现
    // this.senders.set(EmailSenderType.BREVO, new BrevoSender())
    // this.senders.set(EmailSenderType.MAILERSEND, new MailerSendSender())
    // this.senders.set(EmailSenderType.ELASTIC_EMAIL, new ElasticEmailSender())
    // this.senders.set(EmailSenderType.SPARKPOST, new SparkPostSender())
    // this.senders.set(EmailSenderType.MAILJET, new MailjetSender())
    // this.senders.set(EmailSenderType.AMAZON_SES, new AmazonSESSender())
    // this.senders.set(EmailSenderType.FORMSPREE, new FormspreeSender())
    // this.senders.set(EmailSenderType.NETLIFY_FORMS, new NetlifyFormsSender())

    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '邮件发送器工厂初始化完成，共%{public}d种发送方式', this.senders.size)
  }

  /**
   * 根据类型获取发送器
   * @param type 发送器类型
   * @returns 发送器实例，如果不存在则返回null
   */
  getSender(type: EmailSenderType): IEmailSender | null {
    return this.senders.get(type) || null
  }

  /**
   * 获取默认发送器（内置EmailJS）
   * @returns 默认发送器实例
   */
  getDefaultSender(): IEmailSender {
    const defaultSender = this.senders.get(EmailSenderType.EMAILJS_BUILTIN)
    if (!defaultSender) {
      throw new Error('默认发送器未初始化')
    }
    return defaultSender
  }

  /**
   * 获取所有发送器
   * @returns 所有发送器实例数组
   */
  getAllSenders(): IEmailSender[] {
    return Array.from(this.senders.values())
  }

  /**
   * 获取所有发送器类型
   * @returns 所有发送器类型数组
   */
  getAllSenderTypes(): EmailSenderType[] {
    return Array.from(this.senders.keys())
  }

  /**
   * 获取内置服务发送器
   * @returns 有内置服务的发送器数组
   */
  getBuiltinSenders(): IEmailSender[] {
    return this.getAllSenders().filter(sender => sender.getConfig().hasBuiltInService)
  }

  /**
   * 获取发送器选择选项（用于UI）
   * @returns 发送器选项数组
   */
  getSenderSelectOptions(): SenderOption[] {
    const option1: SenderOption = {
      value: 'smtp',
      label: 'SMTP服务器'
    }

    const option2: SenderOption = {
      value: 'emailjs-proxy',
      label: 'EmailJS（后端代理-推荐）'
    }

    const option3: SenderOption = {
      value: 'emailjs-external',
      label: 'EmailJS（自己配置）'
    }

    const option4: SenderOption = {
      value: 'emailjs-builtin',
      label: 'EmailJS（内置-不安全）'
    }

    const option5: SenderOption = {
      value: 'sendgrid',
      label: 'SendGrid API'
    }

    const option6: SenderOption = {
      value: 'mailgun',
      label: 'Mailgun API'
    }

    const option7: SenderOption = {
      value: 'postmark',
      label: 'Postmark API'
    }

    const option8: SenderOption = {
      value: 'resend-external',
      label: 'Resend（自己配置）'
    }

    const option9: SenderOption = {
      value: 'resend-builtin',
      label: 'Resend（内置-不安全）'
    }

    const options: SenderOption[] = [
      option1,
      option2,
      option3,
      option4,
      option5,
      option6,
      option7,
      option8,
      option9
    ]

    return options
  }

  /**
   * 检查发送器是否需要配置
   * @param type 发送器类型
   * @returns 是否需要配置
   */
  requiresConfiguration(type: EmailSenderType): boolean {
    const sender = this.getSender(type)
    return sender ? sender.getConfig().requiresConfig : false
  }

  /**
   * 检查发送器是否有内置服务
   * @param type 发送器类型
   * @returns 是否有内置服务
   */
  hasBuiltInService(type: EmailSenderType): boolean {
    const sender = this.getSender(type)
    return sender ? sender.getConfig().hasBuiltInService : false
  }

  /**
   * 获取发送器数量
   * @returns 发送器数量
   */
  getSenderCount(): number {
    return this.senders.size
  }

  /**
   * 检查发送器类型是否存在
   * @param type 发送器类型
   * @returns 是否存在
   */
  hasSender(type: EmailSenderType): boolean {
    return this.senders.has(type)
  }
}
