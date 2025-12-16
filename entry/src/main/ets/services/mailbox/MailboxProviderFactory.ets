/**
 * 邮箱提供商工厂
 * 根据域名智能选择合适的提供商
 */

import { IMailboxProvider, MailboxProviderType } from './IMailboxProvider'
import { OneSecMailProvider } from './providers/OneSecMailProvider'
import { GuerrillaMailProvider } from './providers/GuerrillaMailProvider'
import { FallbackProvider } from './providers/FallbackProvider'
import { AppConstants } from '../../common/Constants'
import hilog from '@ohos.hilog'

/**
 * 邮箱提供商工厂类（单例）
 */
export class MailboxProviderFactory {
  private static instance: MailboxProviderFactory
  
  // 提供商实例缓存
  private providers: Map<MailboxProviderType, IMailboxProvider> = new Map()
  
  // 域名到提供商的映射
  private domainProviderMap: Map<string, MailboxProviderType> = new Map()

  private constructor() {
    this.initializeProviders()
    this.buildDomainMapping()
  }

  static getInstance(): MailboxProviderFactory {
    if (!MailboxProviderFactory.instance) {
      MailboxProviderFactory.instance = new MailboxProviderFactory()
    }
    return MailboxProviderFactory.instance
  }

  /**
   * 初始化所有提供商
   */
  private initializeProviders(): void {
    this.providers.set(MailboxProviderType.ONE_SEC_MAIL, new OneSecMailProvider())
    this.providers.set(MailboxProviderType.GUERRILLA_MAIL, new GuerrillaMailProvider())
    this.providers.set(MailboxProviderType.FALLBACK, new FallbackProvider())
  }

  /**
   * 构建域名到提供商的映射
   */
  private buildDomainMapping(): void {
    // 1SecMail支持的域名
    const oneSecMailDomains = [
      '1secmail.com', '1secmail.org', '1secmail.net',
      'wwjmp.com', 'esiix.com', 'xojxe.com', 'yoggm.com'
    ]

    oneSecMailDomains.forEach(domain => {
      this.domainProviderMap.set(domain, MailboxProviderType.ONE_SEC_MAIL)
    })

    // Guerrilla Mail支持的域名
    const guerrillaMailDomains = [
      'guerrillamail.com', 'guerrillamail.net', 'guerrillamail.org',
      'guerrillamailblock.com', 'sharklasers.com', 'grr.la',
      'pokemail.net', 'spam4.me', 'guerrillamail.biz', 'guerrillamail.de'
    ]

    guerrillaMailDomains.forEach(domain => {
      this.domainProviderMap.set(domain, MailboxProviderType.GUERRILLA_MAIL)
    })

    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '邮箱提供商映射初始化完成，1SecMail=%{public}d个域名，GuerrillaMail=%{public}d个域名',
      oneSecMailDomains.length, guerrillaMailDomains.length)
  }

  /**
   * 根据域名获取提供商
   */
  getProviderByDomain(domain: string): IMailboxProvider {
    const providerType = this.domainProviderMap.get(domain) || MailboxProviderType.FALLBACK
    const provider = this.providers.get(providerType)

    if (!provider) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '未找到域名 %{public}s 的提供商，使用Fallback', domain)
      return this.providers.get(MailboxProviderType.FALLBACK)!
    }

    return provider
  }

  /**
   * 根据类型获取提供商
   */
  getProviderByType(type: MailboxProviderType): IMailboxProvider | null {
    return this.providers.get(type) || null
  }

  /**
   * 获取默认提供商（1SecMail）
   */
  getDefaultProvider(): IMailboxProvider {
    return this.providers.get(MailboxProviderType.ONE_SEC_MAIL)!
  }

  /**
   * 获取所有可用提供商
   */
  getAllProviders(): IMailboxProvider[] {
    return Array.from(this.providers.values())
  }

  /**
   * 检查域名是否有真实API支持
   */
  hasTrueAPISupport(domain: string): boolean {
    const providerType = this.domainProviderMap.get(domain)
    return providerType !== undefined && providerType !== MailboxProviderType.FALLBACK
  }

  /**
   * 获取所有有真实API支持的域名
   */
  getDomainsWithAPISupport(): string[] {
    const domains: string[] = []
    this.domainProviderMap.forEach((providerType, domain) => {
      if (providerType !== MailboxProviderType.FALLBACK) {
        domains.push(domain)
      }
    })
    return domains
  }
}

