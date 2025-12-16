/**
 * 性能监控相关类型定义
 * 用于追踪和分析应用性能
 * 
 * @module PerformanceTypes
 * @since 2.0.0
 */

/**
 * 性能指标接口
 * 记录单次操作的性能数据
 */
export interface PerformanceMetrics {
  /** 操作持续时间（毫秒） */
  duration: number
  /** 是否成功 */
  success: boolean
  /** 错误信息（如果失败） */
  error?: string
  /** 时间戳 */
  timestamp: number
  /** 操作名称 */
  operationName?: string
  /** 内存使用（字节，可选） */
  memoryUsage?: number
}

/**
 * 操作统计信息接口
 * 汇总某个操作的统计数据
 */
export interface OperationStats {
  /** 总调用次数 */
  totalCalls: number
  /** 成功次数 */
  successCount: number
  /** 失败次数 */
  failureCount: number
  /** 平均持续时间（毫秒） */
  averageDuration: number
  /** 最小持续时间（毫秒） */
  minDuration?: number
  /** 最大持续时间（毫秒） */
  maxDuration?: number
  /** 最后调用时间 */
  lastCallTime?: number
}

/**
 * 性能计时器接口
 * 用于计时单个操作
 */
export interface PerformanceTimer {
  /** 计时器ID */
  id: string
  /** 开始时间戳 */
  startTime: number
  /** 结束时间戳（可选） */
  endTime?: number
  /** 是否已结束 */
  completed: boolean
}

/**
 * 性能报告接口
 * 生成性能分析报告
 */
export interface PerformanceReport {
  /** 报告生成时间 */
  generatedAt: string
  /** 监控时间段（毫秒） */
  timeWindow: number
  /** 操作统计列表 */
  operations: OperationStatsWithName[]
  /** 总调用次数 */
  totalOperations: number
  /** 平均响应时间 */
  averageResponseTime: number
  /** 成功率（0-100） */
  overallSuccessRate: number
}

/**
 * 带名称的操作统计接口
 * 在OperationStats基础上添加操作名称
 */
export interface OperationStatsWithName extends OperationStats {
  /** 操作名称 */
  operationName: string
}

/**
 * 性能阈值配置接口
 * 定义性能警告和错误的阈值
 */
export interface PerformanceThresholds {
  /** 警告阈值（毫秒） */
  warningThreshold: number
  /** 错误阈值（毫秒） */
  errorThreshold: number
  /** 内存警告阈值（MB） */
  memoryWarningThreshold?: number
  /** 失败率警告阈值（0-100） */
  failureRateWarning?: number
}

/**
 * 性能监控配置接口
 * 配置性能监控行为
 */
export interface PerformanceMonitorConfig {
  /** 是否启用监控 */
  enabled: boolean
  /** 是否记录详细日志 */
  verbose: boolean
  /** 采样率（0-100，100表示全部记录） */
  samplingRate: number
  /** 阈值配置 */
  thresholds: PerformanceThresholds
  /** 最大记录数 */
  maxRecords?: number
}

