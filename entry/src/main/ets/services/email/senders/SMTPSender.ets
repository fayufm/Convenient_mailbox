/**
 * SMTP邮件发送器
 * 使用SMTP协议发送邮件
 */

import { IEmailSender, EmailSenderConfig, EmailContent, SendResult, ConfigField, EmailSenderType } from '../IEmailSender'
import { NetworkResponse } from '../../../common/DataTypes'
import { AppConstants } from '../../../common/Constants'
import hilog from '@ohos.hilog'

export class SMTPSender implements IEmailSender {
  private config: EmailSenderConfig = {
    name: 'SMTP服务器',
    type: EmailSenderType.SMTP,
    requiresConfig: true,
    hasBuiltInService: false,
    description: '使用标准SMTP协议发送邮件，支持大多数邮件服务商'
  }

  getConfig(): EmailSenderConfig {
    return this.config
  }

  async send(content: EmailContent, userConfig?: Record<string, string>): Promise<NetworkResponse<SendResult>> {
    try {
      if (!userConfig) {
        return {
          success: false,
          data: null,
          error: '需要SMTP配置信息'
        }
      }

      // 验证配置
      const isValid = await this.validateConfig(userConfig)
      if (!isValid) {
        return {
          success: false,
          data: null,
          error: 'SMTP配置验证失败'
        }
      }

      // 注意：HarmonyOS原生不直接支持SMTP协议
      // 需要通过后端API或使用第三方库
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        'SMTP发送需要后端支持或第三方库')

      return {
        success: false,
        data: null,
        error: 'SMTP发送需要后端API支持，请使用其他发送方式'
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

  async validateConfig(config: Record<string, string>): Promise<boolean> {
    const required = ['host', 'port', 'username', 'password']
    return required.every(key => config[key] && config[key].length > 0)
  }

  async testConnection(config?: Record<string, string>): Promise<boolean> {
    if (!config) return false
    return await this.validateConfig(config)
  }

  getConfigFields(): ConfigField[] {
    return [
      {
        key: 'host',
        label: 'SMTP服务器',
        type: 'text',
        required: true,
        placeholder: 'smtp.gmail.com',
        helpText: '例如：smtp.gmail.com, smtp.qq.com'
      },
      {
        key: 'port',
        label: '端口',
        type: 'number',
        required: true,
        defaultValue: '587',
        helpText: '通常为587(TLS)或465(SSL)'
      },
      {
        key: 'username',
        label: '用户名',
        type: 'text',
        required: true,
        placeholder: 'your@email.com'
      },
      {
        key: 'password',
        label: '密码',
        type: 'password',
        required: true,
        helpText: '某些邮箱需要使用授权码而非密码'
      },
      {
        key: 'from',
        label: '发件人地址',
        type: 'text',
        required: true,
        placeholder: 'your@email.com'
      },
      {
        key: 'from_name',
        label: '发件人名称',
        type: 'text',
        required: false,
        placeholder: '临时邮箱'
      }
    ]
  }
}

