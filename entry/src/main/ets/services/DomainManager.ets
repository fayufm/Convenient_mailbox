/**
 * 域名管理服务
 * 管理84个邮箱域名及其分类信息
 * 
 * 包含高可靠性、中等可靠性、高级、标准和国际域名
 * 支持API收信的域名包括1SecMail（7个）和Guerrilla Mail（10个）
 * 
 * @module DomainManager
 * @since 2.0.0
 */

import { AppConstants } from '../common/Constants'
import hilog from '@ohos.hilog'
import { DomainInfo, DomainSelectOption } from '../types/DomainTypes'

/**
 * 国际域名数据接口
 * @private
 */
interface IntlDomainData {
  domain: string;
  country: string;
}

/**
 * 域名分类枚举
 */
export enum DomainCategory {
  /** 高可靠性域名 */
  HIGH_RELIABILITY = 'high_reliability',
  /** 中等可靠性域名 */
  MEDIUM_RELIABILITY = 'medium_reliability',
  /** 高级域名 */
  PREMIUM = 'premium',
  /** 标准域名 */
  STANDARD = 'standard',
  /** 国际顶级域名 */
  INTERNATIONAL = 'international'
}

/**
 * 域名管理器（单例）
 * 
 * @class DomainManager
 * @description 管理所有临时邮箱域名，提供分类、查询和选择功能
 */
export class DomainManager {
  private static instance: DomainManager
  private domains: DomainInfo[] = []
  private domainMap: Map<string, DomainInfo> = new Map()

  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {
    this.initializeDomains()
  }

  /**
   * 获取单例实例
   * @returns DomainManager实例
   */
  static getInstance(): DomainManager {
    if (!DomainManager.instance) {
      DomainManager.instance = new DomainManager()
    }
    return DomainManager.instance
  }

  /**
   * 初始化所有域名
   * 创建并分类所有可用域名
   * @private
   */
  private initializeDomains(): void {
    // 高可靠性域名（13个）
    const highReliability: DomainInfo[] = []
    
    const hr1: DomainInfo = { domain: '10minutemail.com', name: '10minutemail.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr2: DomainInfo = { domain: 'temp-mail.org', name: 'temp-mail.org - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr3: DomainInfo = { domain: 'throwaway.email', name: 'throwaway.email - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr4: DomainInfo = { domain: 'maildrop.cc', name: 'maildrop.cc - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr5: DomainInfo = { domain: 'emailnator.com', name: 'emailnator.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr6: DomainInfo = { domain: 'inboxkitten.com', name: 'inboxkitten.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr7: DomainInfo = { domain: 'tempail.com', name: 'tempail.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr8: DomainInfo = { domain: 'minuteinbox.com', name: 'minuteinbox.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr9: DomainInfo = { domain: 'tempinbox.net', name: 'tempinbox.net - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr10: DomainInfo = { domain: 'quickemail.org', name: 'quickemail.org - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr11: DomainInfo = { domain: 'mailtemp.net', name: 'mailtemp.net - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr12: DomainInfo = { domain: 'fastinbox.com', name: 'fastinbox.com - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    const hr13: DomainInfo = { domain: 'tempbox.net', name: 'tempbox.net - 高可靠', apiSupported: false, reliability: 5, region: 'global' }
    
    highReliability.push(hr1, hr2, hr3, hr4, hr5, hr6, hr7, hr8, hr9, hr10, hr11, hr12, hr13)

    // 中等可靠性域名（22个）
    const mediumReliability: DomainInfo[] = []
    
    const mr1: DomainInfo = { domain: 'etempmail.com', name: 'etempmail.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr2: DomainInfo = { domain: 'tempmailo.com', name: 'tempmailo.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr3: DomainInfo = { domain: 'disposablemail.com', name: 'disposablemail.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr4: DomainInfo = { domain: 'trashmail.com', name: 'trashmail.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr5: DomainInfo = { domain: 'incognitomail.org', name: 'incognitomail.org - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr6: DomainInfo = { domain: 'tmail.ws', name: 'tmail.ws - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr7: DomainInfo = { domain: 'mailbox.in.ua', name: 'mailbox.in.ua - 中等可靠', apiSupported: false, reliability: 3, region: 'ua' }
    const mr8: DomainInfo = { domain: 'tempmail.plus', name: 'tempmail.plus - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr9: DomainInfo = { domain: 'mail.tm', name: 'mail.tm - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr10: DomainInfo = { domain: 'emailfake.com', name: 'emailfake.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr11: DomainInfo = { domain: 'tempail.org', name: 'tempail.org - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr12: DomainInfo = { domain: 'inboxes.com', name: 'inboxes.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr13: DomainInfo = { domain: 'mailcatch.com', name: 'mailcatch.com - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr14: DomainInfo = { domain: 'tempmail.ninja', name: 'tempmail.ninja - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr15: DomainInfo = { domain: 'mailbox.org', name: 'mailbox.org - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr16: DomainInfo = { domain: 'tempinbox.info', name: 'tempinbox.info - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr17: DomainInfo = { domain: 'quickmail.pro', name: 'quickmail.pro - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr18: DomainInfo = { domain: 'mailtemp.co', name: 'mailtemp.co - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr19: DomainInfo = { domain: 'tempbox.co', name: 'tempbox.co - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr20: DomainInfo = { domain: 'fastmail.cc', name: 'fastmail.cc - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr21: DomainInfo = { domain: 'inboxtemp.org', name: 'inboxtemp.org - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    const mr22: DomainInfo = { domain: 'mailfast.org', name: 'mailfast.org - 中等可靠', apiSupported: false, reliability: 3, region: 'global' }
    
    mediumReliability.push(mr1, mr2, mr3, mr4, mr5, mr6, mr7, mr8, mr9, mr10, mr11, mr12, mr13, mr14, mr15, mr16, mr17, mr18, mr19, mr20, mr21, mr22)

    // 高级域名（10个）
    const premium: DomainInfo[] = []
    
    const pm1: DomainInfo = { domain: 'duck.com', name: 'duck.com - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm2: DomainInfo = { domain: 'proton.me', name: 'proton.me - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm3: DomainInfo = { domain: 'mail7.io', name: 'mail7.io - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm4: DomainInfo = { domain: 'tempmail.email', name: 'tempmail.email - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm5: DomainInfo = { domain: 'secure-mail.biz', name: 'secure-mail.biz - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm6: DomainInfo = { domain: 'privacy-mail.net', name: 'privacy-mail.net - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm7: DomainInfo = { domain: 'anonymous.to', name: 'anonymous.to - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm8: DomainInfo = { domain: 'hideme.be', name: 'hideme.be - 高级', apiSupported: false, reliability: 4, region: 'be' }
    const pm9: DomainInfo = { domain: 'cryptomail.cc', name: 'cryptomail.cc - 高级', apiSupported: false, reliability: 4, region: 'global' }
    const pm10: DomainInfo = { domain: 'safebox.net', name: 'safebox.net - 高级', apiSupported: false, reliability: 4, region: 'global' }
    
    premium.push(pm1, pm2, pm3, pm4, pm5, pm6, pm7, pm8, pm9, pm10)

    // 标准域名（19个）- 简化处理
    const standard: DomainInfo[] = this.createStandardDomains()

    // 国际域名（20个）- 简化处理
    const international: DomainInfo[] = this.createInternationalDomains()

    // 合并所有域名（避免spread操作符）
    this.domains = this.domains.concat(highReliability)
    this.domains = this.domains.concat(mediumReliability)
    this.domains = this.domains.concat(premium)
    this.domains = this.domains.concat(standard)
    this.domains = this.domains.concat(international)

    // 添加API支持域名
    this.addAPISupportedDomains()

    // 构建域名映射
    this.buildDomainMap()

    const apiSupportedCount = this.domains.filter(d => d.apiSupported).length
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '域名管理器初始化完成，共%{public}d个域名（API支持：%{public}d个）',
      this.domains.length, apiSupportedCount)
  }

  /**
   * 创建标准域名列表
   * @private
   */
  private createStandardDomains(): DomainInfo[] {
    const standardDomains: string[] = [
      'tempmail.org', 'mailinator.com', 'guerrillamail.com', 'yopmail.com',
      'mohmal.com', 'sharklasers.com', 'grr.la', 'pokemail.net',
      'spam4.me', 'bccto.me', 'emailondeck.com', 'fakeinbox.com',
      'getairmail.com', 'getnada.com', 'tempmail.io', 'inboxmail.org',
      'quickinbox.net', 'fasttemp.com', 'mailtemp.org'
    ]

    const result: DomainInfo[] = []
    for (const domainStr of standardDomains) {
      const info: DomainInfo = {
        domain: domainStr,
        name: domainStr,
        apiSupported: false,
        reliability: 3,
        region: 'global'
      }
      result.push(info)
    }
    return result
  }

  /**
   * 创建国际域名列表
   * @private
   */
  private createInternationalDomains(): DomainInfo[] {
    const intlData: IntlDomainData[] = [
      { domain: 'otona.uk', country: '英国' },
      { domain: 'adadad.uk', country: '英国' },
      { domain: 'tempmail.de', country: '德国' },
      { domain: 'mailtemp.fr', country: '法国' },
      { domain: 'quickmail.it', country: '意大利' },
      { domain: 'tempbox.es', country: '西班牙' },
      { domain: 'mailfast.nl', country: '荷兰' },
      { domain: 'inboxtemp.ca', country: '加拿大' },
      { domain: 'fastmail.au', country: '澳大利亚' },
      { domain: 'tempmail.jp', country: '日本' },
      { domain: 'quickemail.br', country: '巴西' },
      { domain: 'mailbox.mx', country: '墨西哥' },
      { domain: 'tempinbox.in', country: '印度' },
      { domain: 'fasttemp.kr', country: '韩国' },
      { domain: 'mailquick.se', country: '瑞典' },
      { domain: 'tempbox.no', country: '挪威' },
      { domain: 'quickmail.dk', country: '丹麦' },
      { domain: 'mailtemp.fi', country: '芬兰' },
      { domain: 'tempfast.pl', country: '波兰' },
      { domain: 'inboxmail.cz', country: '捷克' }
    ]

    const result: DomainInfo[] = []
    for (const item of intlData) {
      const info: DomainInfo = {
        domain: item.domain,
        name: `${item.domain} - ${item.country}`,
        apiSupported: false,
        reliability: 3,
        region: item.country
      }
      result.push(info)
    }
    return result
  }

  /**
   * 添加API支持的域名
   * @private
   */
  private addAPISupportedDomains(): void {
    // 1SecMail的7个域名
    const oneSecMailDomains: string[] = [
      '1secmail.com', '1secmail.org', '1secmail.net',
      'wwjmp.com', 'esiix.com', 'xojxe.com', 'yoggm.com'
    ]

    for (const domain of oneSecMailDomains) {
      const domainInfo: DomainInfo = {
        domain: domain,
        name: `${domain} - 高可靠 [支持收信]`,
        apiSupported: true,
        reliability: 5,
        region: 'global',
        description: '官方1SecMail域名，完整API支持'
      }
      this.domains.push(domainInfo)
    }

    // Guerrilla Mail的10个域名
    const guerrillaMailDomains: string[] = [
      'guerrillamail.com', 'guerrillamail.net', 'guerrillamail.org',
      'guerrillamailblock.com', 'sharklasers.com', 'grr.la',
      'pokemail.net', 'spam4.me', 'guerrillamail.biz', 'guerrillamail.de'
    ]

    // 标记已存在的Guerrilla Mail域名为API支持
    for (const domainInfo of this.domains) {
      if (guerrillaMailDomains.indexOf(domainInfo.domain) >= 0) {
        domainInfo.apiSupported = true
        domainInfo.description = 'Guerrilla Mail API支持，邮件保留1小时'
        if (domainInfo.name.indexOf('[支持收信]') < 0) {
          domainInfo.name = domainInfo.name.replace(' [仅地址]', '') + ' [支持收信]'
        }
      }
    }
  }

  /**
   * 构建域名映射
   * @private
   * @note 统一使用小写域名作为key，避免大小写问题
   */
  private buildDomainMap(): void {
    for (const info of this.domains) {
      // ✅ 优化：统一使用小写域名作为key
      this.domainMap.set(info.domain.toLowerCase(), info)
    }
  }

  /**
   * 获取所有域名
   * @returns 所有域名信息数组
   */
  getAllDomains(): DomainInfo[] {
    return this.domains
  }

  /**
   * 获取有API支持的域名
   * @returns API支持的域名数组
   */
  getAPISupportedDomains(): DomainInfo[] {
    return this.domains.filter(d => d.apiSupported)
  }

  /**
   * 获取域名信息
   * @param domain 域名
   * @returns 域名信息，不存在则返回undefined
   * @note 自动转换为小写查询，不区分大小写
   */
  getDomainInfo(domain: string): DomainInfo | undefined {
    // ✅ 优化：统一转小写查询，不区分大小写
    return this.domainMap.get(domain.toLowerCase())
  }

  /**
   * 检查域名是否支持API
   * @param domain 域名
   * @returns 是否支持API
   * @note 自动转换为小写查询，不区分大小写
   */
  hasAPISupport(domain: string): boolean {
    // ✅ 优化：统一转小写查询，不区分大小写
    const info = this.domainMap.get(domain.toLowerCase())
    return info ? info.apiSupported : false
  }

  /**
   * 获取域名选择选项（用于UI）
   * @returns 域名选择选项数组
   */
  getDomainSelectOptions(): DomainSelectOption[] {
    const options: DomainSelectOption[] = []

    // 添加随机选项
    const randomOption: DomainSelectOption = {
      value: 'random',
      text: '随机域名（优先可收信）'
    }
    options.push(randomOption)

    // 先添加有API支持的域名
    const supported = this.getAPISupportedDomains()
    for (const info of supported) {
      const option: DomainSelectOption = {
        value: info.domain,
        text: info.domain  // ✅ 简化：只显示域名本身
      }
      options.push(option)
    }

    // 再添加其他域名
    const unsupported = this.domains.filter(d => !d.apiSupported)
    for (const info of unsupported) {
      const option: DomainSelectOption = {
        value: info.domain,
        text: info.domain  // ✅ 简化：只显示域名本身
      }
      options.push(option)
    }

    return options
  }

  /**
   * 获取随机域名
   * @param preferAPISupport 是否优先API支持域名
   * @param apiWeight API域名的权重（0-1）
   * @returns 随机域名字符串
   */
  getRandomDomain(preferAPISupport: boolean = true, apiWeight: number = 0.9): string {
    if (preferAPISupport) {
      const supported = this.getAPISupportedDomains()
      if (supported.length > 0) {
        // 按权重概率返回API支持域名
        if (Math.random() < apiWeight) {
          return supported[Math.floor(Math.random() * supported.length)].domain
        }
      }
    }
    
    // 返回所有域名中的随机一个
    return this.domains[Math.floor(Math.random() * this.domains.length)].domain
  }

  /**
   * 获取域名总数
   * @returns 域名总数
   */
  getDomainCount(): number {
    return this.domains.length
  }
}
