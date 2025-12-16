/**
 * 配额管理相关类型定义
 * 用于追踪和管理邮件服务的使用配额
 * 
 * @module QuotaTypes
 * @since 2.0.0
 */

/**
 * 配额信息接口
 * 描述单个服务的配额使用情况
 */
export interface QuotaInfo {
  /** 已使用次数 */
  used: number
  /** 配额限制 */
  limit: number
  /** 配额重置日期（ISO 8601格式） */
  resetDate: string
}

/**
 * 服务配额集合接口
 * 包含所有邮件服务的配额信息
 */
export interface ServiceQuota {
  /** EmailJS服务配额 */
  emailjs: QuotaInfo
  /** Resend服务配额 */
  resend: QuotaInfo
}

/**
 * 配额限制定义接口
 * 定义服务的配额上限
 */
export interface QuotaLimits {
  /** 每日配额限制 */
  readonly daily: number
  /** 每月配额限制 */
  readonly monthly: number
}

/**
 * 配额重置日期接口
 * 用于计算配额重置时间
 */
export interface QuotaResetDates {
  /** EmailJS重置日期 */
  emailjs: string
  /** Resend重置日期 */
  resend: string
}

/**
 * 配额统计信息接口
 * 用于显示配额使用统计
 */
export interface QuotaStats {
  /** 服务名称 */
  serviceName: string
  /** 已使用数量 */
  used: number
  /** 总配额 */
  total: number
  /** 使用百分比 (0-100) */
  percentage: number
  /** 剩余配额 */
  remaining: number
}

