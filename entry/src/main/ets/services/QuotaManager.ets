/**
 * 配额管理服务
 * 管理内置服务（EmailJS、Resend）的使用配额
 * 
 * @description 
 * 提供配额追踪、自动重置、持久化存储等功能
 * 单例模式确保全局唯一实例
 * 
 * @since 2.0.0
 */

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import { AppConstants } from '../common/Constants'
import hilog from '@ohos.hilog'
import { QuotaLimits } from '../types/QuotaTypes'

/**
 * 服务类型联合类型
 */
type ServiceType = 'emailjs' | 'resend'

/**
 * 计费周期类型
 */
type BillingPeriod = 'month' | 'day'

/**
 * 配额信息接口（用于返回）
 * 与QuotaTypes.QuotaInfo不同，这个包含更多计算字段
 */
export interface QuotaInfo {
  /** 服务名称 */
  service: string
  /** 总配额 */
  total: number
  /** 已使用 */
  used: number
  /** 剩余 */
  remaining: number
  /** 重置日期(时间戳) */
  resetDate: number
  /** 计费周期 */
  period: BillingPeriod
}

/**
 * 单个服务的配额数据
 */
interface ServiceQuotaData {
  /** 已使用次数 */
  used: number
  /** 重置日期（时间戳） */
  resetDate: number
}

/**
 * 配额数据存储格式
 */
interface QuotaData {
  /** EmailJS配额数据 */
  emailjs: ServiceQuotaData
  /** Resend配额数据 */
  resend: ServiceQuotaData
}

/**
 * 单个服务的配额配置
 */
interface ServiceQuotaConfig {
  /** 总配额 */
  total: number
  /** 计费周期 */
  period: BillingPeriod
}

/**
 * 配额配置定义
 */
interface QuotaConfig {
  /** EmailJS配额配置 */
  emailjs: ServiceQuotaConfig
  /** Resend配额配置 */
  resend: ServiceQuotaConfig
}

/**
 * 配额管理器（单例）
 * 
 * @class QuotaManager
 * @description 管理EmailJS和Resend服务的使用配额
 */
export class QuotaManager {
  private static instance: QuotaManager
  
  /**
   * 配额配置
   * EmailJS: 每月2封，Resend: 每月3封
   */
  private readonly quotaConfig: QuotaConfig = {
    emailjs: {
      total: 2,
      period: 'month'
    },
    resend: {
      total: 3,
      period: 'month'
    }
  }

  /**
   * 当前配额数据
   * 初始化时设置默认值
   */
  private quotaData: QuotaData = {
    emailjs: {
      used: 0,
      resetDate: this.getNextResetDate('month')
    },
    resend: {
      used: 0,
      resetDate: this.getNextResetDate('month')
    }
  }

  /** 数据持久化助手 */
  private preferencesHelper: preferences.Preferences | null = null

  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {}

  /**
   * 获取单例实例
   * @returns QuotaManager实例
   */
  static getInstance(): QuotaManager {
    if (!QuotaManager.instance) {
      QuotaManager.instance = new QuotaManager()
    }
    return QuotaManager.instance
  }

  /**
   * 初始化配额管理器
   * @param context 应用上下文
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferencesHelper = await preferences.getPreferences(context, 'quota_data')
      await this.loadQuotaData()
      
      // 检查是否需要重置配额
      await this.checkAndResetQuota()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'QuotaManager初始化成功')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'QuotaManager初始化失败: %{public}s', err.message)
    }
  }

  /**
   * 从持久化存储加载配额数据
   * @private
   */
  private async loadQuotaData(): Promise<void> {
    if (!this.preferencesHelper) return

    try {
      const dataStr = await this.preferencesHelper.get('quota_data', JSON.stringify(this.quotaData))
      this.quotaData = JSON.parse(dataStr.toString()) as QuotaData

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '配额数据加载成功: EmailJS %{public}d/%{public}d, Resend %{public}d/%{public}d',
        this.quotaData.emailjs.used, this.quotaConfig.emailjs.total,
        this.quotaData.resend.used, this.quotaConfig.resend.total)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '加载配额数据失败: %{public}s', err.message)
    }
  }

  /**
   * 保存配额数据到持久化存储
   * @private
   */
  private async saveQuotaData(): Promise<void> {
    if (!this.preferencesHelper) return

    try {
      await this.preferencesHelper.put('quota_data', JSON.stringify(this.quotaData))
      await this.preferencesHelper.flush()
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存配额数据失败: %{public}s', err.message)
    }
  }

  /**
   * 检查并重置过期配额
   * 如果当前时间超过重置日期，自动重置配额
   * @private
   */
  private async checkAndResetQuota(): Promise<void> {
    const now = Date.now()
    let needSave = false

    // 检查EmailJS配额
    if (now >= this.quotaData.emailjs.resetDate) {
      this.quotaData.emailjs.used = 0
      this.quotaData.emailjs.resetDate = this.getNextResetDate('month')
      needSave = true
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'EmailJS配额已重置')
    }

    // 检查Resend配额
    if (now >= this.quotaData.resend.resetDate) {
      this.quotaData.resend.used = 0
      this.quotaData.resend.resetDate = this.getNextResetDate('month')
      needSave = true
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Resend配额已重置')
    }

    if (needSave) {
      await this.saveQuotaData()
    }
  }

  /**
   * 计算下次重置日期
   * @param period 计费周期（月/天）
   * @returns 下次重置日期的时间戳
   * @private
   */
  private getNextResetDate(period: BillingPeriod): number {
    const now = new Date()
    if (period === 'month') {
      // 下个月1号0点
      const nextMonth = new Date(now.getFullYear(), now.getMonth() + 1, 1, 0, 0, 0, 0)
      return nextMonth.getTime()
    } else {
      // 明天0点
      const tomorrow = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1, 0, 0, 0, 0)
      return tomorrow.getTime()
    }
  }

  /**
   * 获取服务的配额数据
   * @param service 服务类型
   * @returns 配额数据
   * @private
   */
  private getServiceQuotaData(service: ServiceType): ServiceQuotaData {
    if (service === 'emailjs') {
      return this.quotaData.emailjs
    } else {
      return this.quotaData.resend
    }
  }

  /**
   * 获取服务的配额配置
   * @param service 服务类型
   * @returns 配额配置
   * @private
   */
  private getServiceQuotaConfig(service: ServiceType): ServiceQuotaConfig {
    if (service === 'emailjs') {
      return this.quotaConfig.emailjs
    } else {
      return this.quotaConfig.resend
    }
  }

  /**
   * 更新服务的配额数据
   * @param service 服务类型
   * @param data 新的配额数据
   * @private
   */
  private setServiceQuotaData(service: ServiceType, data: ServiceQuotaData): void {
    if (service === 'emailjs') {
      this.quotaData.emailjs = data
    } else {
      this.quotaData.resend = data
    }
  }

  /**
   * 检查是否有配额
   * @param service 服务类型
   * @returns 是否有剩余配额
   */
  async checkQuota(service: ServiceType): Promise<boolean> {
    await this.checkAndResetQuota()
    
    const config = this.getServiceQuotaConfig(service)
    const data = this.getServiceQuotaData(service)
    
    return data.used < config.total
  }

  /**
   * 使用配额
   * @param service 服务类型
   * @returns 是否使用成功
   */
  async useQuota(service: ServiceType): Promise<boolean> {
    const hasQuota = await this.checkQuota(service)
    
    if (!hasQuota) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '%{public}s配额已用完', service)
      return false
    }

    const data = this.getServiceQuotaData(service)
    data.used += 1
    this.setServiceQuotaData(service, data)
    
    await this.saveQuotaData()

    const config = this.getServiceQuotaConfig(service)
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '%{public}s配额使用成功: %{public}d/%{public}d',
      service, data.used, config.total)

    return true
  }

  /**
   * 获取配额信息
   * @param service 服务类型
   * @returns 配额信息
   */
  async getQuotaInfo(service: ServiceType): Promise<QuotaInfo> {
    await this.checkAndResetQuota()
    
    const config = this.getServiceQuotaConfig(service)
    const data = this.getServiceQuotaData(service)
    
    const quotaInfo: QuotaInfo = {
      service: service,
      total: config.total,
      used: data.used,
      remaining: config.total - data.used,
      resetDate: data.resetDate,
      period: config.period
    }
    
    return quotaInfo
  }

  /**
   * 获取所有配额信息
   * @returns 所有服务的配额信息
   */
  async getAllQuotaInfo(): Promise<Record<string, QuotaInfo>> {
    const result: Record<string, QuotaInfo> = {}
    result['emailjs'] = await this.getQuotaInfo('emailjs')
    result['resend'] = await this.getQuotaInfo('resend')
    
    return result
  }

  /**
   * 重置配额（测试用）
   * @param service 服务类型（可选，不传则重置所有）
   */
  async resetQuota(service?: ServiceType): Promise<void> {
    if (service) {
      const data = this.getServiceQuotaData(service)
      data.used = 0
      data.resetDate = this.getNextResetDate('month')
      this.setServiceQuotaData(service, data)
    } else {
      this.quotaData.emailjs.used = 0
      this.quotaData.emailjs.resetDate = this.getNextResetDate('month')
      this.quotaData.resend.used = 0
      this.quotaData.resend.resetDate = this.getNextResetDate('month')
    }
    
    await this.saveQuotaData()
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '配额已重置: %{public}s', service || 'all')
  }

  /**
   * 获取配额使用百分比
   * @param service 服务类型
   * @returns 使用百分比（0-100）
   */
  getQuotaPercentage(service: ServiceType): number {
    const config = this.getServiceQuotaConfig(service)
    const data = this.getServiceQuotaData(service)
    return (data.used / config.total) * 100
  }

  /**
   * 获取距离重置的剩余天数
   * @param service 服务类型
   * @returns 剩余天数
   */
  getDaysUntilReset(service: ServiceType): number {
    const data = this.getServiceQuotaData(service)
    const now = Date.now()
    const diff = data.resetDate - now
    return Math.ceil(diff / (24 * 60 * 60 * 1000))
  }
}
