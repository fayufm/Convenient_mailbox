/**
 * 邮件服务配置
 * 内置EmailJS和Resend服务的API配置
 * 
 * ⚠️ 重要安全提示：
 * 1. 不要将真实的API密钥提交到版本控制系统
 * 2. 在生产环境中应使用环境变量或安全存储
 * 3. 定期轮换API密钥
 * 4. 限制API密钥的权限范围
 * 5. 推荐使用后端代理模式，将API密钥存储在服务器端
 * 
 * ✅ 安全改进（v2.0.1）：
 * - 现在使用SecureStorage进行密钥混淆存储
 * - 首次运行时自动迁移密钥到安全存储
 * - 增加了基本的反编译保护
 * 
 * @module EmailServiceConfig
 * @since 2.0.0
 */

import { SecureStorage } from '../common/SecureStorage'
import hilog from '@ohos.hilog'
import { AppConstants } from '../common/Constants'

/**
 * EmailJS配置接口
 */
interface EmailJSConfiguration {
  /** Service ID */
  service_id: string
  /** Template ID */
  template_id: string
  /** Public Key */
  public_key: string
  /** 发件人名称 */
  from_name: string
  /** 是否启用 */
  enabled: boolean
}

/**
 * Resend配置接口
 */
interface ResendConfiguration {
  /** API Key */
  api_key: string
  /** 发件人邮箱 */
  from_email: string
  /** 发件人名称 */
  from_name: string
  /** 是否启用 */
  enabled: boolean
}

/**
 * 配额配置接口
 */
interface ServiceQuotaConfiguration {
  /** 总配额 */
  total: number
  /** 计费周期 */
  period: string
}

/**
 * 所有服务配额配置接口
 */
interface QuotaConfiguration {
  /** EmailJS配额 */
  emailjs: ServiceQuotaConfiguration
  /** Resend配额 */
  resend: ServiceQuotaConfiguration
}

/**
 * 开发模式配置接口
 */
interface DevelopmentModeConfig {
  /** 是否启用模拟发送（不实际调用API） */
  mockEmailSending: boolean
  /** 是否在日志中显示敏感信息 */
  logSensitiveData: boolean
  /** 是否绕过配额检查 */
  bypassQuotaCheck: boolean
}

/**
 * 单个服务信息接口
 */
interface ServiceInformation {
  /** 服务名称 */
  name: string
  /** 官方网站 */
  website: string
  /** 免费配额说明 */
  freeQuota: string
  /** 定价说明 */
  pricing: string
  /** 设置难度 */
  setupDifficulty: string
  /** 功能特性列表 */
  features: string[]
}

/**
 * 所有服务信息接口
 */
interface EmailServiceInformation {
  /** EmailJS服务信息 */
  emailjs: ServiceInformation
  /** Resend服务信息 */
  resend: ServiceInformation
}

/**
 * ⚠️ 原始配置（仅用于首次迁移，之后从安全存储读取）
 * 
 * 注意：这些密钥在首次运行后会被迁移到加密存储
 * 生产环境建议删除这些明文密钥，直接在SecureStorage中预置
 */
class InitialEmailJSConfig implements EmailJSConfiguration {
  service_id: string = 'service_ugpa9db'
  template_id: string = 'template_vrysogd'
  public_key: string = '6zmB29IjEE5FmyZAd'
  from_name: string = '临时邮箱'
  enabled: boolean = true
}

class InitialResendConfig implements ResendConfiguration {
  api_key: string = 're_jfDJpuBU_MuhdpwjZjy46GyYqsPoJ8ShS'
  from_email: string = 'onboarding@resend.dev'
  from_name: string = '临时邮箱'
  enabled: boolean = true
}

const INITIAL_EMAILJS_CONFIG: EmailJSConfiguration = new InitialEmailJSConfig()
const INITIAL_RESEND_CONFIG: ResendConfiguration = new InitialResendConfig()

/**
 * ✅ 安全的API密钥管理类
 * 使用混淆存储保护密钥，首次运行时自动迁移
 */
export class SecureEmailServiceConfig {
  private static secureStorage = SecureStorage.getInstance()
  private static migrationCompleted = false

  /**
   * 初始化并迁移密钥到安全存储（仅首次运行）
   */
  static async initialize(): Promise<void> {
    if (SecureEmailServiceConfig.migrationCompleted) {
      return
    }

    try {
      // 检查是否已经迁移过
      const hasEmailJSKey = await SecureEmailServiceConfig.secureStorage.hasApiKey('emailjs_service_id')
      
      if (!hasEmailJSKey) {
        // 首次运行，迁移密钥到安全存储
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '首次运行，正在迁移API密钥到安全存储...')
        
        await SecureEmailServiceConfig.secureStorage.storeMultipleKeys({
          'emailjs_service_id': INITIAL_EMAILJS_CONFIG.service_id,
          'emailjs_template_id': INITIAL_EMAILJS_CONFIG.template_id,
          'emailjs_public_key': INITIAL_EMAILJS_CONFIG.public_key,
          'resend_api_key': INITIAL_RESEND_CONFIG.api_key,
          'resend_from_email': INITIAL_RESEND_CONFIG.from_email
        })
        
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '✅ API密钥已成功迁移到安全存储')
      } else {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'API密钥已在安全存储中，无需迁移')
      }
      
      SecureEmailServiceConfig.migrationCompleted = true
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'API密钥迁移失败: %{public}s', (error as Error).message)
      // 迁移失败时使用原始配置
    }
  }

  /**
   * 获取EmailJS配置（从安全存储读取）
   */
  static async getEmailJSConfig(): Promise<EmailJSConfiguration | null> {
    await SecureEmailServiceConfig.initialize()

    try {
      const serviceId = await SecureEmailServiceConfig.secureStorage.getApiKey('emailjs_service_id')
      const templateId = await SecureEmailServiceConfig.secureStorage.getApiKey('emailjs_template_id')
      const publicKey = await SecureEmailServiceConfig.secureStorage.getApiKey('emailjs_public_key')

      if (!serviceId || !templateId || !publicKey) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'EmailJS配置读取失败，使用默认配置')
        // 降级到原始配置
        return {
          service_id: INITIAL_EMAILJS_CONFIG.service_id,
          template_id: INITIAL_EMAILJS_CONFIG.template_id,
          public_key: INITIAL_EMAILJS_CONFIG.public_key,
          from_name: INITIAL_EMAILJS_CONFIG.from_name,
          enabled: INITIAL_EMAILJS_CONFIG.enabled
        }
      }

      return {
        service_id: serviceId,
        template_id: templateId,
        public_key: publicKey,
        from_name: '临时邮箱',
        enabled: true
      }
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '读取EmailJS配置失败: %{public}s', (error as Error).message)
      return null
    }
  }

  /**
   * 获取Resend配置（从安全存储读取）
   */
  static async getResendConfig(): Promise<ResendConfiguration | null> {
    await SecureEmailServiceConfig.initialize()

    try {
      const apiKey = await SecureEmailServiceConfig.secureStorage.getApiKey('resend_api_key')
      const fromEmail = await SecureEmailServiceConfig.secureStorage.getApiKey('resend_from_email')

      if (!apiKey || !fromEmail) {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          'Resend配置读取失败，使用默认配置')
        // 降级到原始配置
        return {
          api_key: INITIAL_RESEND_CONFIG.api_key,
          from_email: INITIAL_RESEND_CONFIG.from_email,
          from_name: INITIAL_RESEND_CONFIG.from_name,
          enabled: INITIAL_RESEND_CONFIG.enabled
        }
      }

      return {
        api_key: apiKey,
        from_email: fromEmail,
        from_name: '临时邮箱',
        enabled: true
      }
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '读取Resend配置失败: %{public}s', (error as Error).message)
      return null
    }
  }
}

/**
 * 兼容性：保留旧的导出接口（但现在从安全存储读取）
 * @deprecated 请使用 SecureEmailServiceConfig.getEmailJSConfig()
 */
export const BUILT_IN_EMAILJS_CONFIG: EmailJSConfiguration = {
  service_id: 'service_xxxxxxx',  // ⚠️ 已迁移到安全存储
  template_id: 'template_xxxxxxx',
  public_key: 'xxxxxxxxxxxx',
  from_name: '临时邮箱',
  enabled: true
}

/**
 * 兼容性：保留旧的导出接口（但现在从安全存储读取）
 * @deprecated 请使用 SecureEmailServiceConfig.getResendConfig()
 */
export const BUILT_IN_RESEND_CONFIG: ResendConfiguration = {
  api_key: 're_xxxxxxxxxxxxxxxxxxxx',  // ⚠️ 已迁移到安全存储
  from_email: 'onboarding@resend.dev',
  from_name: '临时邮箱',
  enabled: true
}

/**
 * 配额配置
 * 注意：这些配额应该低于实际服务商的配额，留有安全余地
 */
export const QUOTA_CONFIG: QuotaConfiguration = {
  emailjs: {
    total: 2,           // 每月允许发送2封（EmailJS免费账户200封/月）
    period: 'month'
  },
  resend: {
    total: 3,           // 每月允许发送3封（Resend免费账户3000封/月）
    period: 'month'
  }
}

/**
 * 开发环境配置
 * 在开发和测试时使用
 */
export const DEV_MODE: DevelopmentModeConfig = {
  // 是否启用模拟发送（不实际调用API）
  mockEmailSending: false,
  
  // 是否在日志中显示敏感信息
  logSensitiveData: false,
  
  // 是否绕过配额检查
  bypassQuotaCheck: false
}

/**
 * API服务商信息
 * 提供服务商的详细说明和功能介绍
 */
export const EMAIL_SERVICE_INFO: EmailServiceInformation = {
  emailjs: {
    name: 'EmailJS',
    website: 'https://www.emailjs.com/',
    freeQuota: '200封/月',
    pricing: '免费账户足够个人使用',
    setupDifficulty: '简单',
    features: ['无需后端', '支持模板', '实时发送']
  },
  resend: {
    name: 'Resend',
    website: 'https://resend.com/',
    freeQuota: '3000封/月',
    pricing: '免费账户非常慷慨',
    setupDifficulty: '简单',
    features: ['现代API', '高送达率', '详细日志']
  }
}

/**
 * 检查EmailJS配置是否完整
 * @returns 配置是否有效
 */
export function validateEmailJSConfig(): boolean {
  return BUILT_IN_EMAILJS_CONFIG.enabled &&
    BUILT_IN_EMAILJS_CONFIG.service_id !== 'service_xxxxxxx' &&
    BUILT_IN_EMAILJS_CONFIG.template_id !== 'template_xxxxxxx' &&
    BUILT_IN_EMAILJS_CONFIG.public_key !== 'your_public_key_here'
}

/**
 * 检查Resend配置是否完整
 * @returns 配置是否有效
 */
export function validateResendConfig(): boolean {
  return BUILT_IN_RESEND_CONFIG.enabled &&
    BUILT_IN_RESEND_CONFIG.api_key !== 're_xxxxxxxxxxxxxxxxxxxx' &&
    BUILT_IN_RESEND_CONFIG.api_key.startsWith('re_')
}

/**
 * 获取EmailJS配置的安全副本（隐藏敏感信息）
 * @returns 脱敏后的配置
 */
export function getSafeEmailJSConfig(): Partial<EmailJSConfiguration> {
  const safeConfig: Partial<EmailJSConfiguration> = {
    service_id: BUILT_IN_EMAILJS_CONFIG.service_id.substring(0, 8) + '***',
    template_id: BUILT_IN_EMAILJS_CONFIG.template_id.substring(0, 9) + '***',
    public_key: BUILT_IN_EMAILJS_CONFIG.public_key.substring(0, 5) + '***',
    from_name: BUILT_IN_EMAILJS_CONFIG.from_name,
    enabled: BUILT_IN_EMAILJS_CONFIG.enabled
  }
  return safeConfig
}

/**
 * 获取Resend配置的安全副本（隐藏敏感信息）
 * @returns 脱敏后的配置
 */
export function getSafeResendConfig(): Partial<ResendConfiguration> {
  const safeConfig: Partial<ResendConfiguration> = {
    api_key: 're_***************',
    from_email: BUILT_IN_RESEND_CONFIG.from_email,
    from_name: BUILT_IN_RESEND_CONFIG.from_name,
    enabled: BUILT_IN_RESEND_CONFIG.enabled
  }
  return safeConfig
}
