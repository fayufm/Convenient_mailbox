/**
 * 用户邮件服务配置管理器
 * 
 * 安全设计：
 * 1. 用户可选择使用自己的后端代理服务器
 * 2. API密钥不存储在应用中，由用户的后端服务器管理
 * 3. 支持禁用内置服务，仅使用自定义后端
 * 4. 支持配置导入导出功能
 * 
 * @module UserEmailConfig
 * @since 2.0.0
 */

import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { AppConstants } from '../common/Constants'
import hilog from '@ohos.hilog'
import { ProxyServerConfig, ProxyTestResult } from '../types/ProxyTypes'
import { NetworkService, RequestConfig } from '../common/NetworkService'
import { NetworkResponse } from '../common/DataTypes'
import { http } from '@kit.NetworkKit'

/**
 * 邮件服务类型枚举
 */
export enum EmailServiceType {
  /** EmailJS服务 */
  EMAILJS = 'emailjs',
  /** Resend服务 */
  RESEND = 'resend',
  /** SendGrid服务 */
  SENDGRID = 'sendgrid',
  /** Mailgun服务 */
  MAILGUN = 'mailgun'
}

/**
 * 配置验证结果接口
 */
interface ConfigValidationResult {
  /** 是否有效 */
  valid: boolean
  /** 错误信息（如果无效） */
  error?: string
}

/**
 * 配置导出数据接口
 */
interface ConfigExportData {
  /** 配置版本 */
  version: string
  /** 导出时间戳 */
  timestamp: string
  /** 代理配置（脱敏后） */
  proxy: ProxyConfigForExport
  /** 是否启用内置服务 */
  builtInEnabled: boolean
}

/**
 * 导出用的代理配置接口（脱敏）
 */
interface ProxyConfigForExport {
  /** 是否启用 */
  enabled: boolean
  /** 服务器地址 */
  baseUrl: string
  /** 认证令牌（已脱敏） */
  authToken?: string
  /** 超时时间 */
  timeout: number
}

/**
 * 配置导入数据接口
 */
interface ConfigImportData {
  /** 配置版本 */
  version?: string
  /** 代理配置 */
  proxy?: Partial<ProxyServerConfig>
  /** 是否启用内置服务 */
  builtInEnabled?: boolean
}

/**
 * 用户邮件配置管理器（单例）
 * 
 * @class UserEmailConfigManager
 * @description 管理用户的邮件服务配置，包括后端代理和内置服务设置
 */
export class UserEmailConfigManager {
  private static instance: UserEmailConfigManager
  private preferencesInstance: preferences.Preferences | null = null

  /** 配置键：代理是否启用 */
  private readonly KEY_PROXY_ENABLED = 'proxy_enabled'
  /** 配置键：代理服务器URL */
  private readonly KEY_PROXY_URL = 'proxy_base_url'
  /** 配置键：代理认证令牌 */
  private readonly KEY_PROXY_TOKEN = 'proxy_auth_token'
  /** 配置键：代理超时时间 */
  private readonly KEY_PROXY_TIMEOUT = 'proxy_timeout'
  /** 配置键：内置服务是否启用 */
  private readonly KEY_BUILT_IN_ENABLED = 'built_in_services_enabled'

  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {}

  /**
   * 获取单例实例
   * @returns UserEmailConfigManager实例
   */
  static getInstance(): UserEmailConfigManager {
    if (!UserEmailConfigManager.instance) {
      UserEmailConfigManager.instance = new UserEmailConfigManager()
    }
    return UserEmailConfigManager.instance
  }

  /**
   * 初始化配置管理器
   * @param context 应用上下文
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      const options: preferences.Options = { name: 'user_email_config' }
      this.preferencesInstance = await preferences.getPreferences(context, options)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '用户邮件配置管理器初始化成功')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '初始化用户邮件配置失败: %{public}s', err.message)
    }
  }

  /**
   * 获取后端代理配置
   * @returns 代理配置对象
   */
  async getProxyConfig(): Promise<ProxyServerConfig> {
    if (!this.preferencesInstance) {
      return this.getDefaultProxyConfig()
    }

    try {
      const enabled = await this.preferencesInstance.get(this.KEY_PROXY_ENABLED, false) as boolean
      const baseUrl = await this.preferencesInstance.get(this.KEY_PROXY_URL, '') as string
      const authToken = await this.preferencesInstance.get(this.KEY_PROXY_TOKEN, '') as string
      const timeout = await this.preferencesInstance.get(this.KEY_PROXY_TIMEOUT, 15000) as number

      const config: ProxyServerConfig = {
        enabled: enabled,
        baseUrl: baseUrl,
        authToken: authToken || '',
        timeout: timeout
      }

      return config
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '读取代理配置失败: %{public}s', err.message)
      return this.getDefaultProxyConfig()
    }
  }

  /**
   * 保存后端代理配置
   * @param config 代理配置对象
   * @returns 是否保存成功
   */
  async saveProxyConfig(config: ProxyServerConfig): Promise<boolean> {
    if (!this.preferencesInstance) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '配置实例未初始化')
      return false
    }

    try {
      await this.preferencesInstance.put(this.KEY_PROXY_ENABLED, config.enabled)
      await this.preferencesInstance.put(this.KEY_PROXY_URL, config.baseUrl)
      await this.preferencesInstance.put(this.KEY_PROXY_TOKEN, config.authToken || '')
      await this.preferencesInstance.put(this.KEY_PROXY_TIMEOUT, config.timeout)
      await this.preferencesInstance.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存代理配置成功，enabled=%{public}s, url=%{public}s',
        config.enabled.toString(), config.baseUrl)

      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存代理配置失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 检查是否启用后端代理
   * @returns 是否启用
   */
  async isProxyEnabled(): Promise<boolean> {
    const config = await this.getProxyConfig()
    return config.enabled && config.baseUrl.length > 0
  }

  /**
   * 检查是否启用内置服务（不使用代理）
   * @returns 是否启用内置服务
   */
  async isBuiltInServicesEnabled(): Promise<boolean> {
    if (!this.preferencesInstance) {
      return false // 默认禁用内置服务（更安全）
    }

    try {
      return await this.preferencesInstance.get(this.KEY_BUILT_IN_ENABLED, false) as boolean
    } catch (error) {
      return false
    }
  }

  /**
   * 设置内置服务启用状态
   * @param enabled 是否启用
   * @returns 是否设置成功
   */
  async setBuiltInServicesEnabled(enabled: boolean): Promise<boolean> {
    if (!this.preferencesInstance) {
      return false
    }

    try {
      await this.preferencesInstance.put(this.KEY_BUILT_IN_ENABLED, enabled)
      await this.preferencesInstance.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '内置服务状态已更新: %{public}s', enabled.toString())

      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '更新内置服务状态失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 保存外部EmailJS配置
   * @param config 外部EmailJS配置
   * @returns 是否保存成功
   */
  async saveExternalEmailJSConfig(config: Record<string, string>): Promise<boolean> {
    if (!this.preferencesInstance) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '配置实例未初始化')
      return false
    }

    try {
      await this.preferencesInstance.put('external_emailjs_config', JSON.stringify(config))
      await this.preferencesInstance.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '外部EmailJS配置已保存')

      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存外部EmailJS配置失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 保存外部Resend配置
   * @param config 外部Resend配置
   * @returns 是否保存成功
   */
  async saveExternalResendConfig(config: Record<string, string>): Promise<boolean> {
    if (!this.preferencesInstance) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '配置实例未初始化')
      return false
    }

    try {
      await this.preferencesInstance.put('external_resend_config', JSON.stringify(config))
      await this.preferencesInstance.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '外部Resend配置已保存')

      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存外部Resend配置失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 验证后端代理配置
   * @param config 待验证的配置
   * @returns 验证结果
   */
  async validateProxyConfig(config: ProxyServerConfig): Promise<ConfigValidationResult> {
    // 检查URL格式
    if (!config.baseUrl || config.baseUrl.trim().length === 0) {
      const result: ConfigValidationResult = {
        valid: false,
        error: '服务器地址不能为空'
      }
      return result
    }

    // 简单的URL格式验证
    if (!config.baseUrl.startsWith('http://') && !config.baseUrl.startsWith('https://')) {
      const result: ConfigValidationResult = {
        valid: false,
        error: '服务器地址必须以http://或https://开头'
      }
      return result
    }

    // 检查超时时间
    if (config.timeout < 1000 || config.timeout > 60000) {
      const result: ConfigValidationResult = {
        valid: false,
        error: '超时时间应在1-60秒之间'
      }
      return result
    }

    const result: ConfigValidationResult = {
      valid: true
    }
    return result
  }

  /**
   * 测试后端代理连接
   * @param config 代理配置
   * @returns 测试结果
   */
  async testProxyConnection(config: ProxyServerConfig): Promise<ProxyTestResult> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '测试代理连接: %{public}s', config.baseUrl)

      // 验证URL格式
      if (!config.baseUrl || config.baseUrl.trim() === '') {
        return {
          success: false,
          message: '代理服务器地址不能为空'
        }
      }

      const urlPattern = /^https?:\/\/.+/i
      if (!urlPattern.test(config.baseUrl)) {
        return {
          success: false,
          message: '代理服务器地址格式无效，必须以http://或https://开头'
        }
      }

      // 获取NetworkService实例
      const networkService: NetworkService = NetworkService.getInstance()

      // 构建健康检查URL
      const healthCheckUrl: string = config.baseUrl.endsWith('/') 
        ? `${config.baseUrl}health` 
        : `${config.baseUrl}/health`

      // 记录开始时间
      const startTime: number = Date.now()

      // 构建请求头
      const headers: Record<string, string> = {}
      if (config.authToken) {
        headers['Authorization'] = `Bearer ${config.authToken}`
      }

      // 构建请求配置
      const requestConfig: RequestConfig = {
        url: healthCheckUrl,
        method: http.RequestMethod.GET,
        header: headers,
        connectTimeout: config.timeout || 15000
      }
      
      // 发送健康检查请求
      const response: NetworkResponse<Record<string, ESObject>> = await networkService.request(requestConfig)

      // 计算延迟
      const latency: number = Date.now() - startTime

      if (response.success) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '代理连接测试成功，延迟: %{public}d ms', latency)
        
        // 尝试解析服务器信息
        let serverVersion: string | undefined
        let supportedServices: string[] | undefined
        
        if (response.data && typeof response.data === 'object') {
          const data = response.data as Record<string, ESObject>
          serverVersion = data['version'] as string | undefined
          supportedServices = data['services'] as string[] | undefined
        }

        return {
          success: true,
          message: '连接测试成功',
          latency,
          serverVersion,
          supportedServices
        }
      } else {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '代理连接测试失败: %{public}s', response.error || '未知错误')
        
        return {
          success: false,
          message: response.error || '连接失败',
          latency
        }
      }
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '代理连接测试异常: %{public}s', err.message)
      
      return {
        success: false,
        message: `连接测试失败: ${err.message}`
      }
    }
  }

  /**
   * 重置所有配置
   * @returns 是否重置成功
   */
  async resetAllConfig(): Promise<boolean> {
    if (!this.preferencesInstance) {
      return false
    }

    try {
      await this.preferencesInstance.clear()
      await this.preferencesInstance.flush()

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '配置已重置')
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '重置配置失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 获取默认代理配置
   * @returns 默认配置对象
   * @private
   */
  private getDefaultProxyConfig(): ProxyServerConfig {
    const defaultConfig: ProxyServerConfig = {
      enabled: false,
      baseUrl: '',
      authToken: '',
      timeout: 15000
    }
    return defaultConfig
  }

  /**
   * 导出配置（用于备份）
   * @returns JSON格式的配置字符串
   */
  async exportConfig(): Promise<string> {
    const proxyConfig = await this.getProxyConfig()
    const builtInEnabled = await this.isBuiltInServicesEnabled()

    // 创建脱敏的代理配置
    const safeProxyConfig: ProxyConfigForExport = {
      enabled: proxyConfig.enabled,
      baseUrl: proxyConfig.baseUrl,
      authToken: proxyConfig.authToken ? '***' : undefined,
      timeout: proxyConfig.timeout
    }

    const exportData: ConfigExportData = {
      version: '1.0',
      timestamp: new Date().toISOString(),
      proxy: safeProxyConfig,
      builtInEnabled: builtInEnabled
    }

    return JSON.stringify(exportData, null, 2)
  }

  /**
   * 导入配置（从备份恢复）
   * @param configJson JSON格式的配置字符串
   * @returns 是否导入成功
   */
  async importConfig(configJson: string): Promise<boolean> {
    try {
      const data: ConfigImportData = JSON.parse(configJson) as ConfigImportData

      if (data.proxy) {
        const proxyConfig: ProxyServerConfig = {
          enabled: data.proxy.enabled || false,
          baseUrl: data.proxy.baseUrl || '',
          authToken: data.proxy.authToken || '',
          timeout: data.proxy.timeout || 15000
        }
        await this.saveProxyConfig(proxyConfig)
      }

      if (typeof data.builtInEnabled === 'boolean') {
        await this.setBuiltInServicesEnabled(data.builtInEnabled)
      }

      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '配置导入成功')
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '配置导入失败: %{public}s', err.message)
      return false
    }
  }
}

/**
 * 后端代理API响应格式
 * @deprecated 请使用 types/ProxyTypes 中的 ProxyResponse
 */
export interface ProxyApiResponse<T = Record<string, ESObject>> {
  /** 是否成功 */
  success: boolean
  /** 响应数据 */
  data?: T
  /** 错误信息 */
  error?: string
  /** 消息 */
  message?: string
}

// 重新导出ProxyServerConfig供其他模块使用
export type { ProxyServerConfig }
