/**
 * 性能监控模块
 * 提供性能指标记录、分析和报告功能
 * 
 * @module PerformanceMonitor
 * @since 2.0.0
 */

import { AppConstants } from './Constants'
import hilog from '@ohos.hilog'
import { PerformanceMetrics, OperationStats, PerformanceTimer as IPerformanceTimer } from '../types/PerformanceTypes'

/**
 * 性能监控统计结果接口
 */
interface PerformanceStats {
  /** 总操作次数 */
  totalOperations: number
  /** 平均持续时间 */
  averageDuration: number
  /** 成功率 */
  successRate: number
  /** 最慢的操作列表 */
  slowestOperations: PerformanceMetrics[]
  /** 最近的错误列表 */
  recentErrors: PerformanceMetrics[]
}

/**
 * 性能阈值配置接口
 */
interface PerformanceThresholds {
  /** 网络请求阈值（毫秒） */
  network_request: number
  /** 数据导出阈值（毫秒） */
  data_export: number
  /** 数据导入阈值（毫秒） */
  data_import: number
  /** 文件操作阈值（毫秒） */
  file_operation: number
  /** UI渲染阈值（毫秒） */
  ui_render: number
  /** 数据处理阈值（毫秒） */
  data_processing: number
}

/**
 * 性能报告接口
 */
interface PerformanceReport {
  /** 报告生成时间 */
  generatedAt: string
  /** 统计摘要 */
  summary: PerformanceStats
  /** 详细指标列表 */
  detailedMetrics: PerformanceMetrics[]
}

/**
 * 网络统计接口
 */
interface NetworkStats {
  /** 总请求数 */
  totalRequests: number
  /** 失败率 */
  failureRate: number
  /** 成功率 */
  successRate: number
}

/**
 * 性能监控类（单例）
 * 
 * @class PerformanceMonitor
 * @description 记录和分析应用性能指标
 */
export class PerformanceMonitor {
  private static instance: PerformanceMonitor
  private metrics: PerformanceMetrics[] = []
  private maxMetrics: number = 1000 // 最大保存指标数量
  
  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns PerformanceMonitor实例
   */
  static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor()
    }
    return PerformanceMonitor.instance
  }
  
  /**
   * 开始性能监控
   * @param operation 操作名称
   * @returns 性能计时器实例
   */
  startTiming(operation: string): PerformanceTimer {
    return new PerformanceTimer(operation, this)
  }
  
  /**
   * 记录性能指标
   * @param metric 性能指标
   */
  recordMetric(metric: PerformanceMetrics): void {
    this.metrics.push(metric)
    
    // 保持指标数量在限制范围内
    if (this.metrics.length > this.maxMetrics) {
      this.metrics = this.metrics.slice(-this.maxMetrics)
    }
    
    // 记录到日志
    if (metric.success) {
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `性能监控 - ${metric.operationName || 'unknown'}: ${metric.duration}ms`)
    } else {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `性能警告 - ${metric.operationName || 'unknown'}: ${metric.duration}ms, 错误: ${metric.error || 'unknown'}`)
    }
    
    // 性能警告阈值
    this.checkPerformanceThresholds(metric)
  }
  
  /**
   * 检查性能阈值
   * @param metric 性能指标
   * @private
   */
  private checkPerformanceThresholds(metric: PerformanceMetrics): void {
    const thresholds: PerformanceThresholds = {
      network_request: 5000,      // 网络请求 5秒
      data_export: 3000,          // 数据导出 3秒
      data_import: 3000,          // 数据导入 3秒
      file_operation: 2000,       // 文件操作 2秒
      ui_render: 100,             // UI渲染 100毫秒
      data_processing: 1000       // 数据处理 1秒
    }
    
    const operationName = metric.operationName || 'unknown'
    let threshold = 1000 // 默认阈值
    
    if (operationName === 'network_request') {
      threshold = thresholds.network_request
    } else if (operationName === 'data_export') {
      threshold = thresholds.data_export
    } else if (operationName === 'data_import') {
      threshold = thresholds.data_import
    } else if (operationName === 'file_operation') {
      threshold = thresholds.file_operation
    } else if (operationName === 'ui_render') {
      threshold = thresholds.ui_render
    } else if (operationName === 'data_processing') {
      threshold = thresholds.data_processing
    }
    
    if (metric.duration > threshold) {
      hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `性能超阈值 - ${operationName}: ${metric.duration}ms > ${threshold}ms`)
    }
  }
  
  /**
   * 获取性能统计
   * @returns 性能统计结果
   */
  getPerformanceStats(): PerformanceStats {
    if (this.metrics.length === 0) {
      const emptyStats: PerformanceStats = {
        totalOperations: 0,
        averageDuration: 0,
        successRate: 0,
        slowestOperations: [],
        recentErrors: []
      }
      return emptyStats
    }
    
    const totalOperations = this.metrics.length
    const successfulOperations = this.metrics.filter(m => m.success).length
    const totalDuration = this.metrics.reduce((sum, m) => sum + m.duration, 0)
    const averageDuration = totalDuration / totalOperations
    const successRate = (successfulOperations / totalOperations) * 100
    
    // 最慢的10个操作（避免使用spread操作符）
    const sortedMetrics: PerformanceMetrics[] = []
    for (const metric of this.metrics) {
      sortedMetrics.push(metric)
    }
    sortedMetrics.sort((a, b) => b.duration - a.duration)
    const slowestOperations = sortedMetrics.slice(0, 10)
    
    // 最近的错误（最多10个）
    const errorMetrics = this.metrics.filter(m => !m.success)
    const recentErrors = errorMetrics.slice(-10)
    
    const stats: PerformanceStats = {
      totalOperations: totalOperations,
      averageDuration: averageDuration,
      successRate: successRate,
      slowestOperations: slowestOperations,
      recentErrors: recentErrors
    }
    
    return stats
  }
  
  /**
   * 清理旧指标
   * @param olderThanHours 清理多少小时前的指标
   */
  clearOldMetrics(olderThanHours: number = 24): void {
    const cutoffTime = Date.now() - (olderThanHours * 60 * 60 * 1000)
    this.metrics = this.metrics.filter(m => m.timestamp > cutoffTime)
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
      `已清理${olderThanHours}小时前的性能指标`)
  }
  
  /**
   * 导出性能报告
   * @returns JSON格式的性能报告
   */
  exportPerformanceReport(): string {
    const stats = this.getPerformanceStats()
    const report: PerformanceReport = {
      generatedAt: new Date().toISOString(),
      summary: stats,
      detailedMetrics: this.metrics.slice(-100) // 最近100条记录
    }
    
    return JSON.stringify(report, null, 2)
  }
}

/**
 * 性能计时器类
 * 用于记录单个操作的性能指标
 * 
 * @class PerformanceTimer
 */
export class PerformanceTimer {
  private startTime: number
  private operation: string
  private monitor: PerformanceMonitor
  private metadata: Record<string, string | number | boolean> = {}
  
  /**
   * 构造函数
   * @param operation 操作名称
   * @param monitor 性能监控实例
   */
  constructor(operation: string, monitor: PerformanceMonitor) {
    this.operation = operation
    this.monitor = monitor
    this.startTime = Date.now()
  }
  
  /**
   * 添加元数据
   * @param key 键
   * @param value 值
   * @returns 当前实例（支持链式调用）
   */
  addMetadata(key: string, value: string | number | boolean): PerformanceTimer {
    this.metadata[key] = value
    return this
  }
  
  /**
   * 结束计时并记录成功
   */
  end(): void {
    const duration = Date.now() - this.startTime
    const metric: PerformanceMetrics = {
      timestamp: Date.now(),
      duration: duration,
      success: true,
      operationName: this.operation
    }
    this.monitor.recordMetric(metric)
  }
  
  /**
   * 结束计时并记录错误
   * @param error 错误信息
   */
  endWithError(error: string): void {
    const duration = Date.now() - this.startTime
    const metric: PerformanceMetrics = {
      timestamp: Date.now(),
      duration: duration,
      success: false,
      error: error,
      operationName: this.operation
    }
    this.monitor.recordMetric(metric)
  }
}

/**
 * 性能装饰器（已禁用 - ArkTS限制）
 * 
 * 注意：ArkTS不支持Function.apply/call，装饰器功能无法实现
 * 
 * 替代方案：直接在方法内使用PerformanceTimer
 * 
 * 示例：
 * ```typescript
 * const timer = PerformanceMonitor.getInstance().startTiming('操作名')
 * try {
 *   // 你的代码
 * } finally {
 *   timer.end()
 * }
 * ```
 * 
 * @deprecated 由于ArkTS限制，此装饰器已禁用
 * @param operation 操作名称
 * @returns 空装饰器函数
 */
export const performanceMonitor = (operation: string) => {
  return (target: ESObject, propertyName: string, descriptor: PropertyDescriptor): PropertyDescriptor => {
    // 由于ArkTS不支持Function.apply，装饰器功能已禁用
    // 请直接使用 PerformanceTimer 进行性能监控
    hilog.warn(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      'performanceMonitor装饰器已禁用，请使用PerformanceTimer代替')
    return descriptor
  }
}

/**
 * 内存使用监控类（单例）
 * 
 * @class MemoryMonitor
 */
export class MemoryMonitor {
  private static instance: MemoryMonitor
  
  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns MemoryMonitor实例
   */
  static getInstance(): MemoryMonitor {
    if (!MemoryMonitor.instance) {
      MemoryMonitor.instance = new MemoryMonitor()
    }
    return MemoryMonitor.instance
  }
  
  /**
   * 记录内存使用情况
   * @param context 上下文描述
   */
  logMemoryUsage(context: string): void {
    try {
      // TODO: 集成HarmonyOS内存监控API
      // import process from '@ohos.process'
      // const memInfo = process.getMemoryInfo()
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `内存监控 - ${context}: 功能待实现`)
    } catch (error) {
      const err = error as Error
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        `内存监控失败: ${err.message}`)
    }
  }
  
  /**
   * 检查内存泄漏
   */
  checkMemoryLeaks(): void {
    // 简单的内存泄漏检查逻辑
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '内存泄漏检查: 功能待实现')
  }
}

/**
 * 网络监控类（单例）
 * 
 * @class NetworkMonitor
 */
export class NetworkMonitor {
  private static instance: NetworkMonitor
  private requestCount: number = 0
  private failureCount: number = 0
  
  /**
   * 私有构造函数（单例模式）
   */
  private constructor() {}
  
  /**
   * 获取单例实例
   * @returns NetworkMonitor实例
   */
  static getInstance(): NetworkMonitor {
    if (!NetworkMonitor.instance) {
      NetworkMonitor.instance = new NetworkMonitor()
    }
    return NetworkMonitor.instance
  }
  
  /**
   * 记录网络请求
   * @param success 是否成功
   * @param duration 持续时间（毫秒）
   * @param url 请求URL
   */
  recordRequest(success: boolean, duration: number, url: string): void {
    this.requestCount++
    if (!success) {
      this.failureCount++
    }
    
    const status = success ? '成功' : '失败'
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
      `网络请求 - ${status}: ${url}, 耗时: ${duration}ms`)
    
    // 记录到性能监控
    const monitor = PerformanceMonitor.getInstance()
    const metric: PerformanceMetrics = {
      timestamp: Date.now(),
      duration: duration,
      success: success,
      operationName: 'network_request'
    }
    monitor.recordMetric(metric)
  }
  
  /**
   * 获取网络统计
   * @returns 网络统计信息
   */
  getNetworkStats(): NetworkStats {
    const successRate = this.requestCount > 0 ? 
      ((this.requestCount - this.failureCount) / this.requestCount) * 100 : 0
    const failureRate = 100 - successRate
    
    const stats: NetworkStats = {
      totalRequests: this.requestCount,
      failureRate: failureRate,
      successRate: successRate
    }
    
    return stats
  }
  
  /**
   * 重置统计
   */
  resetStats(): void {
    this.requestCount = 0
    this.failureCount = 0
  }
}
