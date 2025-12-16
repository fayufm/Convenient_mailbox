/**
 * 备用邮箱提供商
 * 用于没有公开API的域名，仅生成邮箱地址，不提供邮件接收功能
 */

import { IMailboxProvider, MailboxProviderConfig } from '../IMailboxProvider'
import { NetworkResponse, TempEmail, TempEmailContent } from '../../../common/DataTypes'
import { AppConstants } from '../../../common/Constants'
import hilog from '@ohos.hilog'

export class FallbackProvider implements IMailboxProvider {
  private config: MailboxProviderConfig = {
    name: 'Fallback Provider',
    supportedDomains: [
      // 所有84个域名
      // 高可靠性域名（13个）
      '10minutemail.com', 'temp-mail.org', 'throwaway.email', 'maildrop.cc',
      'emailnator.com', 'inboxkitten.com', 'tempail.com', 'minuteinbox.com',
      'tempinbox.net', 'quickemail.org', 'mailtemp.net', 'fastinbox.com', 'tempbox.net',
      // 中等可靠性域名（22个）
      'etempmail.com', 'tempmailo.com', 'disposablemail.com', 'trashmail.com',
      'incognitomail.org', 'tmail.ws', 'mailbox.in.ua', 'tempmail.plus',
      'mail.tm', 'emailfake.com', 'tempail.org', 'inboxes.com', 'mailcatch.com',
      'tempmail.ninja', 'mailbox.org', 'tempinbox.info', 'quickmail.pro',
      'mailtemp.co', 'tempbox.co', 'fastmail.cc', 'inboxtemp.org', 'mailfast.org',
      // 高级域名（10个）
      'duck.com', 'proton.me', 'mail7.io', 'tempmail.email',
      'secure-mail.biz', 'privacy-mail.net', 'anonymous.to', 'hideme.be',
      'cryptomail.cc', 'safebox.net',
      // 一般域名（19个）
      'tempmail.org', 'mailinator.com', 'guerrillamail.com', 'yopmail.com',
      'mohmal.com', 'sharklasers.com', 'grr.la', 'pokemail.net',
      'spam4.me', 'bccto.me', 'emailondeck.com', 'fakeinbox.com',
      'getairmail.com', 'getnada.com', 'tempmail.io', 'inboxmail.org',
      'quickinbox.net', 'fasttemp.com', 'mailtemp.org',
      // 国际顶级域名（20个）
      'otona.uk', 'adadad.uk', 'tempmail.de', 'mailtemp.fr',
      'quickmail.it', 'tempbox.es', 'mailfast.nl', 'inboxtemp.ca',
      'fastmail.au', 'tempmail.jp', 'quickemail.br', 'mailbox.mx',
      'tempinbox.in', 'fasttemp.kr', 'mailquick.se', 'tempbox.no',
      'quickmail.dk', 'mailtemp.fi', 'tempfast.pl', 'inboxmail.cz'
    ],
    apiEndpoint: '',
    requiresAuth: false,
    maxRetries: 1,
    timeout: 5000
  }

  getConfig(): MailboxProviderConfig {
    return this.config
  }

  /**
   * 生成随机前缀
   */
  private generateRandomPrefix(length: number = 10): string {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    let result = ''
    for (let i = 0; i < length; i++) {
      result += chars.charAt(Math.floor(Math.random() * chars.length))
    }
    return result
  }

  async generateRandomMailbox(domain?: string): Promise<NetworkResponse<string>> {
    try {
      const selectedDomain = domain || this.config.supportedDomains[
        Math.floor(Math.random() * this.config.supportedDomains.length)
      ]
      
      const prefix = this.generateRandomPrefix(10)
      const email = `${prefix}@${selectedDomain}`

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Fallback生成邮箱: %{public}s (注意：无法接收邮件)', email)

      return {
        success: true,
        data: email,
        error: ''
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

  async createCustomMailbox(prefix: string, domain: string): Promise<NetworkResponse<string>> {
    try {
      if (!this.config.supportedDomains.includes(domain)) {
        return {
          success: false,
          data: null,
          error: `域名 ${domain} 不在支持列表中`
        }
      }

      const email = `${prefix}@${domain}`

      // 验证邮箱格式
      if (!/^[a-z0-9._-]+@[a-z0-9.-]+\.[a-z]{2,}$/i.test(email)) {
        return {
          success: false,
          data: null,
          error: '邮箱格式不正确'
        }
      }

      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'Fallback创建邮箱: %{public}s (注意：无法接收邮件)', email)

      return {
        success: true,
        data: email,
        error: ''
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

  async checkMailboxAvailability(email: string): Promise<NetworkResponse<boolean>> {
    // 备用提供商无法验证可用性
    return {
      success: true,
      data: true,
      error: ''
    }
  }

  async getEmailList(email: string): Promise<NetworkResponse<TempEmail[]>> {
    // 备用提供商无法获取邮件
    hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      'Fallback提供商无法接收邮件: %{public}s', email)
    return {
      success: false,
      data: null,
      error: '该域名暂不支持邮件接收，仅可用于注册'
    }
  }

  async getEmailContent(email: string, emailId: number | string): Promise<NetworkResponse<TempEmailContent>> {
    return {
      success: false,
      data: null,
      error: '该域名暂不支持邮件接收'
    }
  }

  async deleteEmail(email: string, emailId: number | string): Promise<NetworkResponse<boolean>> {
    return {
      success: false,
      data: false,
      error: '该域名暂不支持删除邮件'
    }
  }

  async isAvailable(): Promise<boolean> {
    return true // 备用提供商始终可用
  }
}

