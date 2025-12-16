/**
 * 应用常量配置
 * 集中管理所有常量、主题颜色、UI尺寸等配置
 */

/**
 * 应用基础常量
 */
export class AppConstants {
  // ==================== 应用信息 ====================
  static readonly APP_NAME = '临时邮箱'
  static readonly APP_VERSION = '1.0.0'
  static readonly APP_DESCRIPTION = '临时邮箱管理工具'
  
  // ==================== 时间常量（毫秒） ====================
  static readonly SECOND_MS = 1000
  static readonly MINUTE_MS = 60 * 1000
  static readonly HOUR_MS = 60 * 60 * 1000
  static readonly DAY_MS = 24 * 60 * 60 * 1000
  static readonly WEEK_MS = 7 * 24 * 60 * 60 * 1000
  
  // ==================== 邮箱配置 ====================
  static readonly DEFAULT_DURATION_DAYS = 7              // 默认有效期：7天
  static readonly MAX_DURATION_DAYS = 3650               // 最大有效期：10年
  static readonly MIN_DURATION_DAYS = 1                  // 最小有效期：1天
  static readonly DEFAULT_PREFIX_LENGTH = 8              // 默认前缀长度：8位
  static readonly MIN_PREFIX_LENGTH = 3                  // 最小前缀长度：3位
  static readonly MAX_PREFIX_LENGTH = 20                 // 最大前缀长度：20位
  static readonly DEFAULT_DOMAIN = '1secmail.com'        // 默认域名
  
  // ==================== UI配置 ====================
  static readonly REFRESH_INTERVAL_MS = 60 * 1000       // 刷新间隔：60秒
  static readonly TOAST_DURATION_MS = 2000              // Toast显示时长：2秒
  static readonly ANIMATION_DURATION_MS = 300           // 动画时长：300ms
  static readonly DEBOUNCE_DELAY_MS = 500               // 防抖延迟：500ms
  
  // ==================== 网络配置 ====================
  static readonly REQUEST_TIMEOUT_MS = 10 * 1000        // 请求超时：10秒
  static readonly NETWORK_TIMEOUT = 10 * 1000           // 网络超时：10秒
  static readonly RETRY_COUNT = 3                       // 重试次数：3次
  static readonly RETRY_DELAY_MS = 1000                 // 重试延迟：1秒
  
  // ==================== API端点 ====================
  static readonly API_BASE_URL = 'https://www.1secmail.com/api/v1/'
  static readonly EMAILJS_API_URL = 'https://api.emailjs.com/api/v1.0/email/send'
  
  // ==================== 存储键名 ====================
  static readonly STORAGE_KEY_APP_DATA = 'appData'
  static readonly STORAGE_KEY_SETTINGS = 'settings'
  static readonly STORAGE_KEY_MAILBOXES = 'mailboxes'
  static readonly STORAGE_KEY_EMAILS = 'emails'
  static readonly STORAGE_KEY_DRAFTS = 'drafts'
  static readonly STORAGE_KEY_CURRENT_MAILBOX = 'currentMailboxId'
  
  // ==================== 日志配置 ====================
  static readonly LOG_TAG = 'TempMailbox'  // 临时邮箱
  static readonly LOG_DOMAIN = 0x00CB  // Convenient Mailbox - 避免与系统日志(0x0000)冲突
}

/**
 * 主题颜色系统
 */
export class ThemeColors {
  // ==================== 主色调 ====================
  static readonly PRIMARY = '#2196F3'                    // 主色：蓝色
  static readonly PRIMARY_LIGHT = '#64B5F6'              // 浅主色
  static readonly PRIMARY_DARK = '#1976D2'               // 深主色
  
  // ==================== 辅助色 ====================
  static readonly SECONDARY = '#6c757d'                  // 次要色：灰色
  static readonly ACCENT = '#FF4081'                     // 强调色：粉红
  
  // ==================== 状态色 ====================
  static readonly SUCCESS = '#28a745'                    // 成功：绿色
  static readonly WARNING = '#ffc107'                    // 警告：黄色
  static readonly DANGER = '#dc3545'                     // 危险：红色
  static readonly INFO = '#17a2b8'                       // 信息：青色
  
  // ==================== 中性色 ====================
  static readonly WHITE = '#FFFFFF'                      // 纯白
  static readonly BLACK = '#000000'                      // 纯黑
  static readonly GRAY_50 = '#f8f9fa'                    // 最浅灰
  static readonly GRAY_100 = '#e9ecef'                   // 浅灰
  static readonly GRAY_200 = '#dee2e6'                   // 浅中灰
  static readonly GRAY_300 = '#ced4da'                   // 中灰
  static readonly GRAY_400 = '#adb5bd'                   // 中深灰
  static readonly GRAY_500 = '#6c757d'                   // 深中灰
  static readonly GRAY_600 = '#495057'                   // 深灰
  static readonly GRAY_700 = '#343a40'                   // 很深灰
  static readonly GRAY_800 = '#212529'                   // 极深灰
  
  // ==================== 文本色 ====================
  static readonly TEXT_PRIMARY = '#212529'               // 主要文本：深灰
  static readonly TEXT_SECONDARY = '#6c757d'             // 次要文本：中灰
  static readonly TEXT_DISABLED = '#adb5bd'              // 禁用文本：浅灰
  static readonly TEXT_WHITE = '#FFFFFF'                 // 白色文本
  static readonly TEXT_MUTED = '#868e96'                 // 弱化文本
  
  // ==================== 背景色 ====================
  static readonly BACKGROUND_PRIMARY = '#FFFFFF'         // 主背景：白色
  static readonly BACKGROUND_SECONDARY = '#f8f9fa'       // 次背景：浅灰
  static readonly BACKGROUND_CARD = '#FFFFFF'            // 卡片背景
  static readonly BACKGROUND_OVERLAY = 'rgba(0,0,0,0.5)' // 遮罩背景
  
  // ==================== 渐变色 ====================
  static readonly GRADIENT_START = '#667eea'             // 渐变起始色：蓝紫
  static readonly GRADIENT_END = '#764ba2'               // 渐变结束色：紫色
  static readonly GRADIENT_ANGLE = 135                   // 渐变角度：135度
  
  // ==================== 边框色 ====================
  static readonly BORDER_LIGHT = '#e9ecef'               // 浅边框
  static readonly BORDER_MEDIUM = '#dee2e6'              // 中等边框
  static readonly BORDER_DARK = '#ced4da'                // 深边框
  
  // ==================== 阴影色 ====================
  static readonly SHADOW_LIGHT = 'rgba(0, 0, 0, 0.1)'   // 浅阴影
  static readonly SHADOW_MEDIUM = 'rgba(0, 0, 0, 0.15)' // 中阴影
  static readonly SHADOW_DARK = 'rgba(0, 0, 0, 0.25)'   // 深阴影
  
  // ==================== 邮箱状态色 ====================
  static readonly STATUS_ACTIVE = '#28a745'              // 活跃状态：绿色
  static readonly STATUS_EXPIRING = '#ffc107'            // 即将过期：黄色
  static readonly STATUS_EXPIRED = '#dc3545'             // 已过期：红色
}

/**
 * UI尺寸规范
 */
export class UISizes {
  // ==================== 字体大小 ====================
  static readonly FONT_SIZE_TINY = 10                    // 极小字体
  static readonly FONT_SIZE_SMALL = 12                   // 小字体
  static readonly FONT_SIZE_MEDIUM = 14                  // 中等字体
  static readonly FONT_SIZE_LARGE = 16                   // 大字体
  static readonly FONT_SIZE_TITLE = 18                   // 标题字体
  static readonly FONT_SIZE_HEADER = 28                  // 页头字体
  static readonly FONT_SIZE_DISPLAY = 32                 // 显示字体
  
  // ==================== 间距 ====================
  static readonly SPACING_XS = 4                         // 极小间距
  static readonly SPACING_SM = 8                         // 小间距
  static readonly SPACING_MD = 12                        // 中等间距
  static readonly SPACING_LG = 16                        // 大间距
  static readonly SPACING_XL = 20                        // 超大间距
  static readonly SPACING_XXL = 24                       // 极大间距
  static readonly SPACING_HUGE = 32                      // 巨大间距
  
  // ==================== 圆角 ====================
  static readonly BORDER_RADIUS_NONE = 0                 // 无圆角
  static readonly BORDER_RADIUS_SM = 4                   // 小圆角
  static readonly BORDER_RADIUS_MD = 8                   // 中圆角
  static readonly BORDER_RADIUS_LG = 12                  // 大圆角
  static readonly BORDER_RADIUS_XL = 16                  // 超大圆角
  static readonly BORDER_RADIUS_FULL = 9999              // 完全圆角
  
  // ==================== 边框宽度 ====================
  static readonly BORDER_WIDTH_THIN = 1                  // 细边框
  static readonly BORDER_WIDTH_MEDIUM = 2                // 中等边框
  static readonly BORDER_WIDTH_THICK = 3                 // 粗边框
  
  // ==================== 图标尺寸 ====================
  static readonly ICON_SIZE_SMALL = 16                   // 小图标
  static readonly ICON_SIZE_MEDIUM = 24                  // 中等图标
  static readonly ICON_SIZE_LARGE = 32                   // 大图标
  static readonly ICON_SIZE_XLARGE = 48                  // 超大图标
  
  // ==================== 按钮尺寸 ====================
  static readonly BUTTON_HEIGHT_SMALL = 32              // 小按钮高度
  static readonly BUTTON_HEIGHT_MEDIUM = 40             // 中等按钮高度
  static readonly BUTTON_HEIGHT_LARGE = 48              // 大按钮高度
  
  // ==================== 卡片尺寸 ====================
  static readonly CARD_PADDING = 16                      // 卡片内边距
  static readonly CARD_MARGIN = 12                       // 卡片外边距
  
  // ==================== 阴影 ====================
  static readonly SHADOW_ELEVATION_1 = 2                 // 阴影高度1
  static readonly SHADOW_ELEVATION_2 = 4                 // 阴影高度2
  static readonly SHADOW_ELEVATION_3 = 8                 // 阴影高度3
}

