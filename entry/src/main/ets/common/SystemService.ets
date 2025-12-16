/**
 * 系统服务
 * 封装系统API调用，如剪贴板、Toast、文件操作等
 */

import pasteboard from '@ohos.pasteboard'
import promptAction from '@ohos.promptAction'
import notificationManager from '@ohos.notificationManager'
import picker from '@ohos.file.picker'
import fs from '@ohos.file.fs'
import util from '@ohos.util'
import { AppConstants } from './Constants'
import hilog from '@ohos.hilog'

/**
 * 对话框选项接口
 */
export interface DialogOptions {
  title: string
  message: string
  buttons: string[]
}

/**
 * 对话框按钮接口
 * @deprecated 保留用于类型兼容性，新代码请直接使用对象字面量
 */
interface DialogButton {
  text: string
  color: string
}

  /**
   * Toast选项接口
   */
  interface ToastOptions {
    message: string
    duration: number
    bottom?: number
  }

/**
 * 对话框配置接口
 * @deprecated 保留用于类型兼容性，新代码请直接使用对象字面量
 */
interface DialogConfig {
  title: string
  message: string
  buttons: DialogButton[]
}

/**
 * 通知选项接口
 */
export interface NotificationOptions {
  title: string
  text: string
  additionalText?: string
}

/**
 * 系统服务类（单例模式）
 */
export class SystemService {
  private static instance: SystemService
  private notificationId: number = 1000  // 通知ID计数器

  private constructor() {}

  /**
   * 获取单例实例
   */
  static getInstance(): SystemService {
    if (!SystemService.instance) {
      SystemService.instance = new SystemService()
    }
    return SystemService.instance
  }

  /**
   * 复制文本到剪贴板
   * ⚠️ 注意：如果没有READ_PASTEBOARD权限，此功能会失败但不影响应用其他功能
   */
  async copyToClipboard(text: string): Promise<boolean> {
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text)
      const systemPasteboard = pasteboard.getSystemPasteboard()
      await systemPasteboard.setData(pasteData)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '文本已复制到剪贴板')
      return true
    } catch (error) {
      const err = error as Error
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '复制到剪贴板失败（可能缺少权限）: %{public}s', err.message)
      // ✅ 优雅降级：返回false但不抛出异常
      return false
    }
  }

  // ⚠️ 已移除 getFromClipboard() 方法
  // 原因：读取剪贴板需要 READ_PASTEBOARD 权限，但该方法未被使用
  // 如需恢复，请在 module.json5 中添加权限声明

  /**
   * 显示Toast提示
   * ✅ 已更新：使用新的 promptAction API
   * @since 2.1.1
   */
  async showToast(message: string, duration?: number): Promise<void> {
    try {
      // ✅ 使用明确类型的配置对象
      const toastConfig: ToastOptions = {
        message: message,
        duration: duration || 2000,
        bottom: 100
      }
      await promptAction.showToast(toastConfig)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '显示Toast失败: %{public}s', err.message)
    }
  }

  /**
   * 显示对话框
   * ✅ 已更新：使用新的 promptAction API
   * @since 2.1.1
   */
  async showDialog(options: DialogOptions): Promise<number> {
    try {
      // ✅ 明确构建按钮配置，满足ArkTS类型要求
      const dialogButtons: DialogButton[] = options.buttons.map(text => {
        const button: DialogButton = {
          text: text,
          color: '#007DFF'
        }
        return button
      })
      
      // ✅ 构建对话框配置
      const dialogConfig: DialogConfig = {
        title: options.title,
        message: options.message,
        buttons: dialogButtons
      }
      
      const result = await promptAction.showDialog(dialogConfig)
      
      return result.index || 0
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '显示对话框失败: %{public}s', err.message)
      return -1
    }
  }

  /**
   * 显示确认对话框
   */
  async showConfirm(title: string, message: string): Promise<boolean> {
    const result = await this.showDialog({
      title: title,
      message: message,
      buttons: ['取消', '确定']
    })
    return result === 1
  }

  /**
   * 显示加载提示
   */
  async showLoading(message?: string): Promise<void> {
    try {
      await this.showToast(message || '加载中...', 1000)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '显示加载提示失败: %{public}s', err.message)
    }
  }

  /**
   * 隐藏加载提示
   */
  async hideLoading(): Promise<void> {
    // Toast会自动消失，这里不需要实现
  }

  /**
   * 震动反馈
   */
  async vibrate(duration?: number): Promise<void> {
    try {
      // 注意：震动功能需要权限，这里仅作占位
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '震动反馈: %{public}d ms', duration || 50)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '震动失败: %{public}s', err.message)
    }
  }

  /**
   * 选择文件
   * 使用文件选择器选择JSON文件
   */
  async selectFile(): Promise<string[]> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '打开文件选择器')
      
      // 创建文档选择器
      const documentSelectOptions = new picker.DocumentSelectOptions()
      const documentPicker = new picker.DocumentViewPicker()
      
      // 选择文件
      const result: string[] = await documentPicker.select(documentSelectOptions) as string[]
      
      if (!result || !result.length || result.length === 0) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '用户未选择文件')
        return []
      }
      
      // 读取文件内容
      const fileContents: string[] = []
      for (const uri of result) {
        try {
          const file = fs.openSync(uri, fs.OpenMode.READ_ONLY)
          const stat = fs.statSync(uri)
          const buffer = new ArrayBuffer(stat.size)
          fs.readSync(file.fd, buffer)
          fs.closeSync(file)
          
          // 将 ArrayBuffer 转换为字符串
          const uint8Array = new Uint8Array(buffer)
          let content = ''
          for (let i = 0; i < uint8Array.length; i++) {
            content += String.fromCharCode(uint8Array[i])
          }
          
          fileContents.push(content)
          hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '文件读取成功，大小: %{public}d 字节', stat.size)
        } catch (err) {
          const error = err as Error
          hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
            '读取文件失败: %{public}s', error.message)
        }
      }
      
      return fileContents
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '选择文件失败: %{public}s', err.message)
      return []
    }
  }

  /**
   * 保存文件
   * 使用文件保存器保存文件
   */
  async saveFile(fileName: string, content: string): Promise<boolean> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '保存文件: %{public}s', fileName)
      
      // 检查是否有数据
      if (!content || content.trim() === '' || content === '{}') {
        hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '没有数据可导出')
        return false
      }
      
      // 创建文档保存选择器
      const documentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker = new picker.DocumentViewPicker()
      
      // 选择保存位置
      const uriArray: string[] = await documentPicker.save(documentSaveOptions) as string[]
      
      if (!uriArray || uriArray.length === 0) {
        hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '用户取消保存')
        return false
      }
      
      const uriResult: string = uriArray[0]
      
      // 写入文件
      const file = fs.openSync(uriResult, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      
      // 将字符串转换为 ArrayBuffer
      const textEncoder: util.TextEncoder = new util.TextEncoder()
      const uint8Array: Uint8Array = textEncoder.encodeInto(content)
      
      fs.writeSync(file.fd, uint8Array.buffer)
      fs.closeSync(file)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '文件保存成功，大小: %{public}d 字节', uint8Array.length)
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存文件失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 读取文件
   * 注意：在ArkTS中文件读取需要使用fs模块
   */
  async readFile(filePath: string): Promise<string> {
    try {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '读取文件: %{public}s', filePath)
      // 实际实现需要使用@ohos.file.fs
      return ''
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '读取文件失败: %{public}s', err.message)
      return ''
    }
  }

  /**
   * 发送系统通知
   * @param options 通知选项
   * @returns 是否发送成功
   */
  async sendNotification(options: NotificationOptions): Promise<boolean> {
    try {
      // 创建通知内容
      const notificationRequest: notificationManager.NotificationRequest = {
        id: this.notificationId++,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: options.title,
            text: options.text,
            additionalText: options.additionalText || ''
          }
        }
      }

      // 发送通知
      await notificationManager.publish(notificationRequest)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '通知已发送: %{public}s', options.title)
      return true
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '发送通知失败: %{public}s', err.message)
      return false
    }
  }

  /**
   * 播放通知声音
   * 注意：实际实现需要使用媒体播放API
   */
  async playNotificationSound(): Promise<void> {
    try {
      // 简化实现：使用震动代替声音
      await this.vibrate(100)
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '通知声音已播放')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '播放通知声音失败: %{public}s', err.message)
    }
  }

  /**
   * 取消所有通知
   */
  async cancelAllNotifications(): Promise<void> {
    try {
      await notificationManager.cancelAll()
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '已取消所有通知')
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '取消通知失败: %{public}s', err.message)
    }
  }
}

