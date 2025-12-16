/**
 * 域名管理相关类型定义
 * 用于管理临时邮箱域名
 * 
 * @module DomainTypes
 * @since 2.0.0
 */

/**
 * 域名信息接口
 * 描述单个临时邮箱域名的详细信息
 */
export interface DomainInfo {
  /** 域名 */
  domain: string
  /** 显示名称 */
  name: string
  /** 是否支持API接收邮件 */
  apiSupported: boolean
  /** 可靠性等级（1-5星） */
  reliability: number
  /** 地区 */
  region: string
  /** 描述 */
  description?: string
  /** 官方网站 */
  website?: string
}

/**
 * 域名选择选项接口
 * 用于UI选择器的域名选项
 */
export interface DomainSelectOption {
  /** 选项值（域名） */
  value: string
  /** 显示文本 (HarmonyOS SelectOption uses 'text' not 'label') */
  text: string
}

/**
 * 域名分类接口
 * 按类别组织域名
 */
export interface DomainCategory {
  /** 分类名称 */
  categoryName: string
  /** 分类描述 */
  description: string
  /** 该分类下的域名列表 */
  domains: string[]
}

/**
 * 域名统计信息接口
 * 域名使用统计
 */
export interface DomainStats {
  /** 总域名数 */
  totalDomains: number
  /** 支持API的域名数 */
  apiSupportedCount: number
  /** 备用域名数 */
  backupDomainCount: number
  /** 按地区统计 */
  byRegion: Record<string, number>
  /** 按可靠性统计 */
  byReliability: Record<number, number>
}

/**
 * 域名可用性检查结果接口
 * 检查域名是否可用
 */
export interface DomainAvailability {
  /** 域名 */
  domain: string
  /** 是否可用 */
  available: boolean
  /** 响应时间（毫秒） */
  responseTime?: number
  /** 检查时间 */
  checkedAt: string
  /** 错误信息（如果不可用） */
  error?: string
}

/**
 * 域名过滤条件接口
 * 用于筛选域名
 */
export interface DomainFilter {
  /** 是否只显示支持API的域名 */
  apiSupportedOnly?: boolean
  /** 地区筛选 */
  region?: string
  /** 最低可靠性等级 */
  minReliability?: number
  /** 搜索关键词 */
  searchKeyword?: string
}

