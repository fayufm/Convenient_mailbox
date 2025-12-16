/**
 * 安全存储管理器
 * 使用简单的Base64混淆 + 本地存储保护API密钥
 * 
 * 注意：这是一个基础安全方案，提供基本的混淆保护
 * 更高级的保护需要使用后端代理服务
 * 
 * @module SecureStorage
 * @since 2.0.1
 */

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import hilog from '@ohos.hilog'
import { AppConstants } from './Constants'
import util from '@ohos.util'

/**
 * 安全存储管理器类（单例模式）
 */
export class SecureStorage {
  private static instance: SecureStorage
  private preferencesHelper: preferences.Preferences | null = null
  private isInitialized: boolean = false
  
  // 混淆密钥（注意：这只是基础混淆，不是真正的加密）
  private readonly OBFUSCATION_KEY = 'ConvenientMailbox2025'

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): SecureStorage {
    if (!SecureStorage.instance) {
      SecureStorage.instance = new SecureStorage()
    }
    return SecureStorage.instance
  }

  /**
   * 初始化安全存储
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      return
    }

    try {
      // 使用独立的preferences存储密钥
      this.preferencesHelper = await preferences.getPreferences(context, 'secure_keys')
      this.isInitialized = true
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'SecureStorage初始化成功')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'SecureStorage初始化失败: %{public}s', err.message)
      // ArkTS不支持throw任意类型，改为抛出Error实例
      const initError: Error = new Error('SecureStorage初始化失败: ' + err.message)
      throw initError
    }
  }

  /**
   * 简单的XOR加密混淆
   * 注意：这不是真正的加密，只是增加反编译难度
   */
  private obfuscate(data: string): string {
    try {
      const textEncoder = new util.TextEncoder()
      const dataBytes = textEncoder.encodeInto(data)
      const keyBytes = textEncoder.encodeInto(this.OBFUSCATION_KEY)
      
      const result = new Uint8Array(dataBytes.length)
      for (let i = 0; i < dataBytes.length; i++) {
        result[i] = dataBytes[i] ^ keyBytes[i % keyBytes.length]
      }
      
      // 转换为Base64
      const base64 = new util.Base64Helper()
      return base64.encodeToStringSync(result)
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据混淆失败: %{public}s', (error as Error).message)
      return data  // 失败时返回原始数据
    }
  }

  /**
   * 解混淆
   */
  private deobfuscate(encoded: string): string {
    try {
      const base64 = new util.Base64Helper()
      const obfuscatedBytes = base64.decodeSync(encoded)
      
      const textEncoder = new util.TextEncoder()
      const keyBytes = textEncoder.encodeInto(this.OBFUSCATION_KEY)
      
      const result = new Uint8Array(obfuscatedBytes.length)
      for (let i = 0; i < obfuscatedBytes.length; i++) {
        result[i] = obfuscatedBytes[i] ^ keyBytes[i % keyBytes.length]
      }
      
      const textDecoder = util.TextDecoder.create('utf-8')
      // 使用decodeToString（废弃警告可以忽略，仍可正常使用）
      return textDecoder.decodeToString(result)
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '数据解混淆失败: %{public}s', (error as Error).message)
      return encoded  // 失败时返回原始数据
    }
  }

  /**
   * 存储API密钥（混淆后存储）
   */
  async storeApiKey(key: string, value: string): Promise<boolean> {
    if (!this.preferencesHelper) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'SecureStorage未初始化')
      return false
    }

    try {
      const obfuscated = this.obfuscate(value)
      await this.preferencesHelper.put(key, obfuscated)
      await this.preferencesHelper.flush()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'API密钥已安全存储: %{public}s', key)
      return true
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '存储API密钥失败: %{public}s', (error as Error).message)
      return false
    }
  }

  /**
   * 读取API密钥（自动解混淆）
   */
  async getApiKey(key: string): Promise<string | null> {
    if (!this.preferencesHelper) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'SecureStorage未初始化')
      return null
    }

    try {
      const obfuscated = await this.preferencesHelper.get(key, '')
      if (!obfuscated || obfuscated.toString() === '') {
        return null
      }
      
      const deobfuscated = this.deobfuscate(obfuscated.toString())
      return deobfuscated
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '读取API密钥失败: %{public}s', (error as Error).message)
      return null
    }
  }

  /**
   * 删除API密钥
   */
  async deleteApiKey(key: string): Promise<boolean> {
    if (!this.preferencesHelper) {
      return false
    }

    try {
      await this.preferencesHelper.delete(key)
      await this.preferencesHelper.flush()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'API密钥已删除: %{public}s', key)
      return true
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '删除API密钥失败: %{public}s', (error as Error).message)
      return false
    }
  }

  /**
   * 检查密钥是否存在
   */
  async hasApiKey(key: string): Promise<boolean> {
    if (!this.preferencesHelper) {
      return false
    }

    try {
      const value = await this.preferencesHelper.get(key, '')
      return value !== ''
    } catch (error) {
      return false
    }
  }

  /**
   * 批量存储密钥
   */
  async storeMultipleKeys(keys: Record<string, string>): Promise<boolean> {
    if (!this.preferencesHelper) {
      return false
    }

    try {
      const keyNames = Object.keys(keys)
      for (let i = 0; i < keyNames.length; i++) {
        const keyName = keyNames[i]
        const obfuscated = this.obfuscate(keys[keyName])
        await this.preferencesHelper.put(keyName, obfuscated)
      }
      await this.preferencesHelper.flush()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '批量存储%{public}d个API密钥成功', keyNames.length)
      return true
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '批量存储API密钥失败: %{public}s', (error as Error).message)
      return false
    }
  }
}

