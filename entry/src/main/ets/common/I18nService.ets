/**
 * 国际化服务
 * 提供多语言支持（中文/英文）
 */

import preferences from '@ohos.data.preferences'
import { common } from '@kit.AbilityKit'
import hilog from '@ohos.hilog'
import { AppConstants } from './Constants'

/**
 * 语言文本类
 */
class LanguageTexts {
  // 应用信息
  appName: string = ''
  appDescription: string = ''
  
  // 按钮文本
  btnGenerate: string = ''
  btnRefresh: string = ''
  btnCopy: string = ''
  btnDelete: string = ''
  btnExport: string = ''
  btnImport: string = ''
  btnCleanup: string = ''
  
  // 标题文本
  titleInbox: string = ''
  titleManage: string = ''
  titleGenerate: string = ''
  
  // 提示文本
  tipNoEmails: string = ''
  tipNoMailboxes: string = ''
  tipExpirySoon: string = ''
  tipCopySuccess: string = ''
  tipDeleteSuccess: string = ''
  
  // 状态文本
  statusActive: string = ''
  statusExpired: string = ''
  statusLoading: string = ''
  
  // 错误文本
  errorNetwork: string = ''
  errorGenerate: string = ''
  errorLoad: string = ''
  
  // 数据管理文本
  confirmClearData: string = ''
  confirmClearDataMessage: string = ''
}

// 中文文本
const zhCNTexts: LanguageTexts = {
  appName: '便捷邮箱',
  appDescription: '临时邮箱管理工具',
  
  btnGenerate: '生成邮箱',
  btnRefresh: '刷新',
  btnCopy: '复制',
  btnDelete: '删除',
  btnExport: '导出',
  btnImport: '导入',
  btnCleanup: '清理过期',
  
  titleInbox: '收件箱',
  titleManage: '邮箱管理',
  titleGenerate: '快速生成邮箱',
  
  tipNoEmails: '暂无邮件',
  tipNoMailboxes: '暂无已保存的邮箱',
  tipExpirySoon: '即将过期',
  tipCopySuccess: '已复制到剪贴板',
  tipDeleteSuccess: '删除成功',
  
  statusActive: '活跃',
  statusExpired: '已过期',
  statusLoading: '加载中...',
  
  errorNetwork: '网络请求失败',
  errorGenerate: '生成邮箱失败',
  errorLoad: '加载数据失败',
  
  confirmClearData: '清除所有数据',
  confirmClearDataMessage: '这将删除您的所有数据。您确定吗？'
}

// 英文文本
const enUSTexts: LanguageTexts = {
  appName: 'Temporary Mailbox',
  appDescription: 'Temporary Email Manager',
  
  btnGenerate: 'Generate',
  btnRefresh: 'Refresh',
  btnCopy: 'Copy',
  btnDelete: 'Delete',
  btnExport: 'Export',
  btnImport: 'Import',
  btnCleanup: 'Cleanup',
  
  titleInbox: 'Inbox',
  titleManage: 'Manage',
  titleGenerate: 'Generate Mailbox',
  
  tipNoEmails: 'No emails',
  tipNoMailboxes: 'No saved mailboxes',
  tipExpirySoon: 'Expiring soon',
  tipCopySuccess: 'Copied to clipboard',
  tipDeleteSuccess: 'Deleted successfully',
  
  statusActive: 'Active',
  statusExpired: 'Expired',
  statusLoading: 'Loading...',
  
  errorNetwork: 'Network error',
  errorGenerate: 'Failed to generate',
  errorLoad: 'Failed to load data',
  
  confirmClearData: 'Clear All Data',
  confirmClearDataMessage: 'This will delete all your data. Are you sure?'
}

// 俄文文本
const ruRUTexts: LanguageTexts = {
  appName: 'Временная почта',
  appDescription: 'Менеджер временной почты',
  
  btnGenerate: 'Создать',
  btnRefresh: 'Обновить',
  btnCopy: 'Копировать',
  btnDelete: 'Удалить',
  btnExport: 'Экспорт',
  btnImport: 'Импорт',
  btnCleanup: 'Очистить',
  
  titleInbox: 'Входящие',
  titleManage: 'Управление',
  titleGenerate: 'Создать почтовый ящик',
  
  tipNoEmails: 'Нет писем',
  tipNoMailboxes: 'Нет сохраненных почтовых ящиков',
  tipExpirySoon: 'Скоро истечет',
  tipCopySuccess: 'Скопировано в буфер обмена',
  tipDeleteSuccess: 'Успешно удалено',
  
  statusActive: 'Активный',
  statusExpired: 'Истек',
  statusLoading: 'Загрузка...',
  
  errorNetwork: 'Ошибка сети',
  errorGenerate: 'Не удалось создать',
  errorLoad: 'Не удалось загрузить данные',
  
  confirmClearData: 'Очистить все данные',
  confirmClearDataMessage: 'Это удалит все ваши данные. Вы уверены?'
}

/**
 * 国际化服务类（单例模式）
 */
export class I18nService {
  private static instance: I18nService
  private currentLanguage: string = 'zh-CN'
  private texts: LanguageTexts = zhCNTexts
  private preferencesHelper: preferences.Preferences | null = null

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): I18nService {
    if (!I18nService.instance) {
      I18nService.instance = new I18nService()
    }
    return I18nService.instance
  }

  /**
   * 初始化服务
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferencesHelper = await preferences.getPreferences(context, 'convenient_mailbox_i18n')
      const savedLanguage = await this.preferencesHelper.get('language', 'zh-CN')
      this.setLanguage(savedLanguage.toString())
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        'I18nService初始化成功，语言: %{public}s', this.currentLanguage)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'I18nService初始化失败: %{public}s', err.message)
    }
  }

  /**
   * 设置语言
   * ✅ 修复：添加完整的异常处理
   * ✅ 新增：支持俄语 (ru-RU)
   */
  async setLanguage(language: string): Promise<void> {
    // ✅ 参数验证：如果为空或undefined，使用默认语言
    if (!language) {
      language = 'zh-CN'
    }
    
    this.currentLanguage = language
    
    if (language === 'zh-CN') {
      this.texts = zhCNTexts
    } else if (language === 'en-US') {
      this.texts = enUSTexts
    } else if (language === 'ru-RU') {
      this.texts = ruRUTexts
    } else {
      this.texts = zhCNTexts // 默认中文
    }
    
    // ✅ 保存设置（添加异常处理）
    if (this.preferencesHelper) {
      try {
        await this.preferencesHelper.put('language', language)
        await this.preferencesHelper.flush()
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
          '语言设置已保存: %{public}s', language)
      } catch (error) {
        const err = error as Error
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
          '保存语言设置失败: %{public}s', err.message)
        // 不抛出异常，允许应用继续运行
      }
    }
  }

  /**
   * 获取当前语言
   */
  getCurrentLanguage(): string {
    return this.currentLanguage
  }

  /**
   * 获取文本
   */
  getText(key: string): string {
    // 使用类型安全的方式访问属性
    switch (key) {
      case 'appName': return this.texts.appName
      case 'appDescription': return this.texts.appDescription
      case 'btnGenerate': return this.texts.btnGenerate
      case 'btnRefresh': return this.texts.btnRefresh
      case 'btnCopy': return this.texts.btnCopy
      case 'btnDelete': return this.texts.btnDelete
      case 'btnExport': return this.texts.btnExport
      case 'btnImport': return this.texts.btnImport
      case 'btnCleanup': return this.texts.btnCleanup
      case 'titleInbox': return this.texts.titleInbox
      case 'titleManage': return this.texts.titleManage
      case 'titleGenerate': return this.texts.titleGenerate
      case 'tipNoEmails': return this.texts.tipNoEmails
      case 'tipNoMailboxes': return this.texts.tipNoMailboxes
      case 'tipExpirySoon': return this.texts.tipExpirySoon
      case 'tipCopySuccess': return this.texts.tipCopySuccess
      case 'tipDeleteSuccess': return this.texts.tipDeleteSuccess
      case 'statusActive': return this.texts.statusActive
      case 'statusExpired': return this.texts.statusExpired
      case 'statusLoading': return this.texts.statusLoading
      case 'errorNetwork': return this.texts.errorNetwork
      case 'errorGenerate': return this.texts.errorGenerate
      case 'errorLoad': return this.texts.errorLoad
      case 'confirmClearData': return this.texts.confirmClearData
      case 'confirmClearDataMessage': return this.texts.confirmClearDataMessage
      default: return key
    }
  }

  /**
   * 获取所有文本
   */
  getTexts(): LanguageTexts {
    return this.texts
  }
}
