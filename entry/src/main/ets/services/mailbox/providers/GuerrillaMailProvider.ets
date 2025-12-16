/**
 * Guerrilla Mail 服务提供商
 * 支持10个官方域名，免费且无需API密钥
 * 
 * 官方网站：https://www.guerrillamail.com/
 * API文档：https://docs.guerrillamail.com/
 * 
 * 特性：
 * - 免费、开源
 * - 无需注册或API密钥
 * - 邮件保留1小时
 * - 支持自定义邮箱前缀
 * - 支持多个域名选择
 * 
 * @module GuerrillaMailProvider
 * @since 2.0.0
 */

import { IMailboxProvider, MailboxProviderConfig } from '../IMailboxProvider'
import { NetworkResponse, TempEmail, TempEmailContent } from '../../../common/DataTypes'
import { NetworkService } from '../../../common/NetworkService'
import { AppConstants } from '../../../common/Constants'
import hilog from '@ohos.hilog'

/**
 * Guerrilla Mail API响应接口
 */
interface GuerrillaMailResponse {
  /** 邮箱地址 */
  email_addr: string
  /** 邮箱时间戳 */
  email_timestamp: number
  /** 会话令牌 */
  sid_token: string
  /** 别名（可选） */
  alias?: string
}

/**
 * Guerrilla Mail邮件列表响应接口
 */
interface GuerrillaMailListResponse {
  /** 邮件列表 */
  list: GuerrillaMailItem[]
}

/**
 * Guerrilla Mail邮件项接口
 */
interface GuerrillaMailItem {
  /** 邮件ID */
  mail_id: number | string
  /** 发件人 */
  mail_from: string
  /** 邮件主题 */
  mail_subject: string
  /** 邮件摘要 */
  mail_excerpt: string
  /** 邮件时间戳（秒） */
  mail_timestamp: string
  /** 是否已读（0/1） */
  mail_read: number
}

/**
 * Guerrilla Mail邮件详情接口
 */
interface GuerrillaMailDetail {
  /** 邮件ID */
  mail_id: number | string
  /** 发件人 */
  mail_from: string
  /** 邮件主题 */
  mail_subject: string
  /** 邮件正文 */
  mail_body: string
  /** 邮件摘要 */
  mail_excerpt: string
  /** 邮件时间戳（秒） */
  mail_timestamp: string
  /** 是否已读（0/1） */
  mail_read: number
  /** 邮件日期 */
  mail_date: string
  /** 收件人 */
  mail_recipient: string
}

/**
 * Guerrilla Mail服务提供商实现
 * 
 * @class GuerrillaMailProvider
 * @implements IMailboxProvider
 */
export class GuerrillaMailProvider implements IMailboxProvider {
  private networkService: NetworkService = NetworkService.getInstance()
  private sessionToken: string = ''
  private emailAddress: string = ''

  private config: MailboxProviderConfig

  /**
   * 构造函数
   */
  constructor() {
    this.config = {
      name: 'Guerrilla Mail',
      supportedDomains: [
        'guerrillamail.com',
        'guerrillamail.net',
        'guerrillamail.org',
        'guerrillamailblock.com',
        'sharklasers.com',
        'grr.la',
        'pokemail.net',
        'spam4.me',
        'guerrillamail.biz',
        'guerrillamail.de'
      ],
      apiEndpoint: 'https://api.guerrillamail.com/ajax.php',
      requiresAuth: true, // 需要会话token
      maxRetries: 3,
      timeout: 15000
    }
  }

  /**
   * 获取提供商配置
   * @returns 配置信息
   */
  getConfig(): MailboxProviderConfig {
    return this.config
  }

  /**
   * 生成随机邮箱
   * @param domain 指定域名（可选）
   * @returns 邮箱地址
   */
  async generateRandomMailbox(domain?: string): Promise<NetworkResponse<string>> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail: 开始生成随机邮箱，指定域名=%{public}s', domain || '无')

      // 1. 获取新的会话和邮箱地址
      const url = `${this.config.apiEndpoint}?f=get_email_address`
      const response = await this.networkService.get<GuerrillaMailResponse>(url)

      if (!response.success || !response.data) {
        const errorResponse: NetworkResponse<string> = {
          success: false,
          data: null,
          error: '初始化Guerrilla Mail会话失败'
        }
        return errorResponse
      }

      this.emailAddress = response.data.email_addr
      this.sessionToken = response.data.sid_token

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail: 获得初始邮箱=%{public}s, token=%{public}s',
        this.emailAddress, this.sessionToken.substring(0, 8) + '...')

      // 2. 如果指定了域名，设置域名
      if (domain && this.config.supportedDomains.indexOf(domain) >= 0) {
        const setDomainResult = await this.setDomain(domain)
        if (setDomainResult.success && setDomainResult.data) {
          this.emailAddress = setDomainResult.data.email_addr
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            'GuerrillaMail: 设置域名后邮箱=%{public}s', this.emailAddress)
        }
      }

      const successResponse: NetworkResponse<string> = {
        success: true,
        data: this.emailAddress,
        error: ''
      }
      return successResponse
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail生成邮箱失败: %{public}s', err.message)
      const errorResponse: NetworkResponse<string> = {
        success: false,
        data: null,
        error: `Guerrilla Mail生成失败: ${err.message}`
      }
      return errorResponse
    }
  }

  /**
   * 创建自定义邮箱
   * @param prefix 邮箱前缀
   * @param domain 邮箱域名
   * @returns 完整邮箱地址
   */
  async createCustomMailbox(prefix: string, domain: string): Promise<NetworkResponse<string>> {
    try {
      if (this.config.supportedDomains.indexOf(domain) < 0) {
        const errorResponse: NetworkResponse<string> = {
          success: false,
          data: null,
          error: `Guerrilla Mail不支持域名: ${domain}`
        }
        return errorResponse
      }

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail: 创建自定义邮箱 %{public}s@%{public}s', prefix, domain)

      // 1. 获取新会话
      const sessionUrl = `${this.config.apiEndpoint}?f=get_email_address`
      const sessionResp = await this.networkService.get<GuerrillaMailResponse>(sessionUrl)

      if (!sessionResp.success || !sessionResp.data) {
        const errorResponse: NetworkResponse<string> = {
          success: false,
          data: null,
          error: '初始化Guerrilla Mail会话失败'
        }
        return errorResponse
      }

      this.sessionToken = sessionResp.data.sid_token

      // 2. 设置域名（如果不是当前域名）
      const currentDomain = sessionResp.data.email_addr.split('@')[1]
      if (domain !== currentDomain) {
        const setDomainResult = await this.setDomain(domain)
        if (!setDomainResult.success) {
          hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            'GuerrillaMail: 设置域名失败，继续使用默认域名')
        }
      }

      // 3. 设置邮箱前缀
      const setUrl = `${this.config.apiEndpoint}?f=set_email_user&email_user=${encodeURIComponent(prefix)}&sid_token=${this.sessionToken}`
      const setResp = await this.networkService.get<GuerrillaMailResponse>(setUrl)

      if (setResp.success && setResp.data && setResp.data.email_addr) {
        this.emailAddress = setResp.data.email_addr

        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: 成功创建邮箱=%{public}s', this.emailAddress)

        const successResponse: NetworkResponse<string> = {
          success: true,
          data: this.emailAddress,
          error: ''
        }
        return successResponse
      }

      const errorResponse: NetworkResponse<string> = {
        success: false,
        data: null,
        error: '设置邮箱前缀失败'
      }
      return errorResponse
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail创建自定义邮箱失败: %{public}s', err.message)
      const errorResponse: NetworkResponse<string> = {
        success: false,
        data: null,
        error: `创建失败: ${err.message}`
      }
      return errorResponse
    }
  }

  /**
   * 设置域名
   * @param domain 目标域名
   * @returns 设置结果
   * @private
   */
  private async setDomain(domain: string): Promise<NetworkResponse<GuerrillaMailResponse>> {
    try {
      const url = `${this.config.apiEndpoint}?f=set_domain&domain=${encodeURIComponent(domain)}&sid_token=${this.sessionToken}`
      const response = await this.networkService.get<GuerrillaMailResponse>(url)

      if (response.success && response.data) {
        return response
      }

      const errorResponse: NetworkResponse<GuerrillaMailResponse> = {
        success: false,
        data: null,
        error: '设置域名失败'
      }
      return errorResponse
    } catch (error) {
      const err = error as Error
      const errorResponse: NetworkResponse<GuerrillaMailResponse> = {
        success: false,
        data: null,
        error: err.message
      }
      return errorResponse
    }
  }

  /**
   * 检查邮箱可用性
   * @param email 邮箱地址
   * @returns 是否可用
   */
  async checkMailboxAvailability(email: string): Promise<NetworkResponse<boolean>> {
    // Guerrilla Mail允许任意邮箱前缀
    const response: NetworkResponse<boolean> = {
      success: true,
      data: true,
      error: ''
    }
    return response
  }

  /**
   * 获取邮件列表
   * @param email 邮箱地址
   * @returns 邮件列表
   */
  async getEmailList(email: string): Promise<NetworkResponse<TempEmail[]>> {
    try {
      // ✅ 关键修复：如果没有session token，先获取一个新的
      if (!this.sessionToken) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: 没有session token，尝试为邮箱 %{public}s 创建新会话', email)
        
        const parts = email.split('@')
        if (parts.length !== 2) {
          const errorResponse: NetworkResponse<TempEmail[]> = {
            success: false,
            data: null,
            error: '邮箱格式错误'
          }
          return errorResponse
        }
        
        const prefix = parts[0]
        const domain = parts[1]
        
        // 尝试创建自定义邮箱来获取session
        const createResult = await this.createCustomMailbox(prefix, domain)
        if (!createResult.success) {
          hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            'GuerrillaMail: 创建会话失败: %{public}s', createResult.error || '未知错误')
          const errorResponse: NetworkResponse<TempEmail[]> = {
            success: false,
            data: null,
            error: '无法创建会话: ' + (createResult.error || '未知错误')
          }
          return errorResponse
        }
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: 成功创建会话，token=%{public}s', 
          this.sessionToken.substring(0, 8) + '...')
      }

      const url = `${this.config.apiEndpoint}?f=get_email_list&offset=0&sid_token=${this.sessionToken}`
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail: 请求邮件列表，URL=%{public}s', url.replace(this.sessionToken, this.sessionToken.substring(0, 8) + '...'))
      
      const response = await this.networkService.get<GuerrillaMailListResponse>(url)

      if (response.success && response.data) {
        const list = response.data.list || []
        const emails: TempEmail[] = []
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: API返回%{public}d封邮件', list.length)
        
        for (const item of list) {
          // 确保mail_id被正确转换为number类型
          let emailId: number
          if (typeof item.mail_id === 'string') {
            emailId = parseInt(item.mail_id)
          } else {
            emailId = item.mail_id
          }

          const tempEmail: TempEmail = {
            id: emailId,
            from: item.mail_from,
            subject: item.mail_subject || '(无主题)',
            date: new Date(parseInt(item.mail_timestamp) * 1000).toISOString()
          }
          emails.push(tempEmail)
          
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            'GuerrillaMail邮件: ID=%{public}d, From=%{public}s, Subject=%{public}s',
            emailId, item.mail_from, item.mail_subject || '(无主题)')
        }

        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: 成功解析%{public}d封邮件', emails.length)

        const successResponse: NetworkResponse<TempEmail[]> = {
          success: true,
          data: emails,
          error: ''
        }
        return successResponse
      }

      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail: API返回空数据或失败')
      
      const emptyResponse: NetworkResponse<TempEmail[]> = {
        success: true,
        data: [],
        error: ''
      }
      return emptyResponse
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail获取邮件列表失败: %{public}s', err.message)
      const errorResponse: NetworkResponse<TempEmail[]> = {
        success: false,
        data: null,
        error: err.message
      }
      return errorResponse
    }
  }

  /**
   * 获取邮件内容
   * @param email 邮箱地址
   * @param emailId 邮件ID
   * @returns 邮件内容
   */
  async getEmailContent(email: string, emailId: number | string): Promise<NetworkResponse<TempEmailContent>> {
    try {
      if (!this.sessionToken) {
        const errorResponse: NetworkResponse<TempEmailContent> = {
          success: false,
          data: null,
          error: '会话已过期，请重新生成邮箱'
        }
        return errorResponse
      }

      const url = `${this.config.apiEndpoint}?f=fetch_email&email_id=${emailId}&sid_token=${this.sessionToken}`
      const response = await this.networkService.get<GuerrillaMailDetail>(url)

      if (response.success && response.data) {
        // 确保mail_id被正确转换为number类型
        let contentId: number
        if (typeof response.data.mail_id === 'string') {
          contentId = parseInt(response.data.mail_id)
        } else {
          contentId = response.data.mail_id
        }

        const content: TempEmailContent = {
          id: contentId,
          from: response.data.mail_from,
          subject: response.data.mail_subject || '(无主题)',
          date: new Date(parseInt(response.data.mail_timestamp) * 1000).toISOString(),
          body: response.data.mail_body || response.data.mail_excerpt || '',
          textBody: response.data.mail_excerpt || '',
          htmlBody: response.data.mail_body || response.data.mail_excerpt || '',
          attachments: []
        }

        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'GuerrillaMail: 获取邮件内容成功，ID=%{public}s', emailId.toString())

        const successResponse: NetworkResponse<TempEmailContent> = {
          success: true,
          data: content,
          error: ''
        }
        return successResponse
      }

      const errorResponse: NetworkResponse<TempEmailContent> = {
        success: false,
        data: null,
        error: '获取邮件内容失败'
      }
      return errorResponse
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail获取邮件内容失败: %{public}s', err.message)
      const errorResponse: NetworkResponse<TempEmailContent> = {
        success: false,
        data: null,
        error: err.message
      }
      return errorResponse
    }
  }

  /**
   * 删除邮件
   * @param email 邮箱地址
   * @param emailId 邮件ID
   * @returns 删除结果
   */
  async deleteEmail(email: string, emailId: number | string): Promise<NetworkResponse<boolean>> {
    // Guerrilla Mail的邮件会在1小时后自动删除，不支持主动删除
    hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      'GuerrillaMail不支持删除邮件，邮件将在1小时后自动删除')
    
    const errorResponse: NetworkResponse<boolean> = {
      success: false,
      data: false,
      error: 'Guerrilla Mail不支持删除邮件（1小时后自动删除）'
    }
    return errorResponse
  }

  /**
   * 检查服务可用性
   * @returns 服务是否可用
   */
  async isAvailable(): Promise<boolean> {
    try {
      const url = `${this.config.apiEndpoint}?f=get_email_address`
      const response = await this.networkService.get<GuerrillaMailResponse>(url)
      return response.success
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'GuerrillaMail服务检查失败: %{public}s', err.message)
      return false
    }
  }
}
