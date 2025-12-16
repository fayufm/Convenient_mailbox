/**
 * 类型定义统一导出
 * 集中管理所有自定义类型
 * 
 * @module types
 * @since 2.0.0
 */

// 配额管理类型
export {
  QuotaInfo,
  ServiceQuota,
  QuotaLimits,
  QuotaResetDates,
  QuotaStats
} from './QuotaTypes'

// 邮件服务类型
export {
  EmailJSConfig,
  ResendConfig,
  EmailJSServiceDefinition,
  ResendServiceDefinition,
  EmailServiceDefinition,
  EmailSendParams,
  EmailSendResponse
} from './EmailServiceTypes'

// 代理类型
export {
  ProxyServerConfig,
  ProxyTestResult,
  ProxyRequestHeaders,
  ProxyRequestBody,
  ProxyResponse,
  ProxyHealthCheck,
  // 🆕 IMAP相关类型 @since 2.1.0
  IMAPMailboxConfig,
  IMAPListRequest,
  IMAPReadRequest,
  IMAPEmailData,
  IMAPAttachment
} from './ProxyTypes'

// 发送器类型
export {
  SenderOption,
  SenderConfigField,
  SenderMetadata,
  SenderStats,
  EmailContentData,
  EmailAttachmentData,
  BulkSendConfig
} from './SenderTypes'

// 性能监控类型
export {
  PerformanceMetrics,
  OperationStats,
  PerformanceTimer,
  PerformanceReport,
  OperationStatsWithName,
  PerformanceThresholds,
  PerformanceMonitorConfig
} from './PerformanceTypes'

// 域名管理类型
export {
  DomainInfo,
  DomainSelectOption,
  DomainCategory,
  DomainStats,
  DomainAvailability,
  DomainFilter
} from './DomainTypes'

