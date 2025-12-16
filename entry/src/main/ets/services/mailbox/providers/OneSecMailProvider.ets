/**
 * 1SecMail 服务提供商
 * 官方稳定的临时邮箱服务
 */

import { IMailboxProvider, MailboxProviderConfig } from '../IMailboxProvider'
import { NetworkResponse, TempEmail, TempEmailContent } from '../../../common/DataTypes'
import { NetworkService } from '../../../common/NetworkService'
import { AppConstants } from '../../../common/Constants'
import hilog from '@ohos.hilog'

export class OneSecMailProvider implements IMailboxProvider {
  private networkService: NetworkService = NetworkService.getInstance()

  private config: MailboxProviderConfig = {
    name: '1SecMail',
    supportedDomains: [
      '1secmail.com',
      '1secmail.org',
      '1secmail.net',
      'wwjmp.com',
      'esiix.com',
      'xojxe.com',
      'yoggm.com'
    ],
    apiEndpoint: 'https://www.1secmail.com/api/v1/',
    requiresAuth: false,
    maxRetries: 3,
    timeout: 10000
  }

  getConfig(): MailboxProviderConfig {
    return this.config
  }

  async generateRandomMailbox(domain?: string): Promise<NetworkResponse<string>> {
    try {
      const url = `${this.config.apiEndpoint}?action=genRandomMailbox&count=1`
      const response = await this.networkService.get<string[]>(url)

      if (response.success && response.data && response.data.length > 0) {
        let email = response.data[0]
        
        // 如果指定了域名，替换为指定域名（如果在支持列表中）
        if (domain && this.config.supportedDomains.includes(domain)) {
          const prefix = email.split('@')[0]
          email = `${prefix}@${domain}`
        }

        return {
          success: true,
          data: email,
          error: ''
        }
      }

      return {
        success: false,
        data: null,
        error: '生成邮箱失败'
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '1SecMail生成邮箱失败: %{public}s', err.message)
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  async createCustomMailbox(prefix: string, domain: string): Promise<NetworkResponse<string>> {
    try {
      // 1SecMail不需要预先创建，直接返回邮箱地址
      if (!this.config.supportedDomains.includes(domain)) {
        return {
          success: false,
          data: null,
          error: `域名 ${domain} 不被 1SecMail 支持`
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
    // 1SecMail不需要检查可用性，所有符合格式的邮箱都可用
    const domain = email.split('@')[1]
    if (this.config.supportedDomains.includes(domain)) {
      return {
        success: true,
        data: true,
        error: ''
      }
    }
    return {
      success: false,
      data: false,
      error: '不支持的域名'
    }
  }

  async getEmailList(email: string): Promise<NetworkResponse<TempEmail[]>> {
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
      const url = `${this.config.apiEndpoint}?action=getMessages&login=${login}&domain=${domain}`

      return await this.networkService.get<TempEmail[]>(url)
    } catch (error) {
      const err = error as Error
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  async getEmailContent(email: string, emailId: number | string): Promise<NetworkResponse<TempEmailContent>> {
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
      const url = `${this.config.apiEndpoint}?action=readMessage&login=${login}&domain=${domain}&id=${emailId}`

      return await this.networkService.get<TempEmailContent>(url)
    } catch (error) {
      const err = error as Error
      return {
        success: false,
        data: null,
        error: err.message
      }
    }
  }

  async deleteEmail(email: string, emailId: number | string): Promise<NetworkResponse<boolean>> {
    // 1SecMail API不支持删除邮件
    return {
      success: false,
      data: false,
      error: '1SecMail不支持删除邮件'
    }
  }

  async isAvailable(): Promise<boolean> {
    try {
      const url = `${this.config.apiEndpoint}?action=getDomainList`
      const response = await this.networkService.get<string[]>(url)
      return response.success
    } catch (error) {
      return false
    }
  }
}

