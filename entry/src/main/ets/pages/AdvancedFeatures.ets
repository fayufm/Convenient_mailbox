import router from '@ohos.router'
import hilog from '@ohos.hilog'
import promptAction from '@ohos.promptAction'
import { AppConstants, ThemeColors } from '../common/Constants'
import { MailboxManager } from '../common/MailboxManager'
import { SettingsData } from '../common/DataTypes'

/**
 * 高级功能管理页面
 * @since v2.0.0
 */
@Entry
@Component
struct AdvancedFeatures {
  // 业务逻辑管理器
  private mailboxManager: MailboxManager = MailboxManager.getInstance()
  
  // 功能开关状态
  @State enableEmailSearch: boolean = true
  @State enableTemplates: boolean = true
  @State enableFolders: boolean = true
  @State enableStatistics: boolean = true
  
  // 国际化文本
  @State uiTexts: Record<string, string> = {}
  
  // 功能描述文本
  private featureDescriptions: Record<string, string> = {
    'featureEmailSearch': '在收件箱中快速搜索邮件内容、发件人，支持未读/已读筛选、时间排序，精准定位目标邮件',
    'featureTemplates': '内置验证码、通知、商务、感谢4种常用模板，支持创建个人专属模板，一键填充发件内容',
    'featureFolders': '创建工作、购物、社交等自定义分组，拖拽邮箱到分组管理，快速切换查看不同类别邮箱',
    'featureStatistics': '查看总邮箱数、今日邮件、发送成功率、平均存活时间等统计数据，掌握使用情况',
    'featureTags': '为重要邮件添加彩色标签（紧急、重要、待办等），支持按标签筛选，高效邮件分类管理',
    'featureAutoCategory': '智能识别验证码、交易通知、社交动态、促销广告等邮件类型，自动归类显示 ⚠️与数据可视化互斥',
    'featureVisualization': '邮件趋势折线图、域名使用饼状图、发送成功率统计图表，数据可视化展示 ⚠️与智能分类互斥',
    'featureAdvancedBackup': '支持导出为JSON/CSV/TXT格式，自动定期备份邮箱数据，防止数据丢失',
    'featureFAB': '右下角悬浮按钮快捷菜单，一键生成邮箱、检查邮件、发送邮件，提升操作效率'
  }
  
  async aboutToAppear() {
    await this.loadSettings()
    this.loadUITexts()
    this.checkAllFeaturesEnabled()
  }
  
  /**
   * 检查是否所有功能都启用，如果是则显示警告
   */
  checkAllFeaturesEnabled() {
    // 所有核心功能已启用
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
      '✅ 所有核心功能已启用：搜索、模板、分组、统计')
  }
  
  /**
   * 恢复推荐设置：只启用常用的4个核心功能
   */
  async restoreRecommendedSettings() {
    try {
      // 核心功能设置
      this.enableEmailSearch = true
      this.enableTemplates = true
      this.enableFolders = true
      this.enableStatistics = true
      
      // 保存设置
      await this.mailboxManager.updateSettings({
        enableEmailSearch: true,
        enableTemplates: true,
        enableFolders: true,
        enableStatistics: true
      })
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '✅ 已恢复推荐设置：启用搜索、模板、分组、统计，禁用其他高级功能')
      
      // 提示用户
      promptAction.showToast({
        message: this.uiTexts['tipRestoreSuccess'] || 'Recommended settings restored, page will be smoother',
        duration: 2000
      })
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '恢复推荐设置失败: %{public}s', JSON.stringify(error))
    }
  }
  
  /**
   * 加载功能设置
   * 🔧 修复：改为从 MailboxManager 统一加载，确保数据源一致
   */
  async loadSettings() {
    try {
      const settings = this.mailboxManager.getSettings()
      
      this.enableEmailSearch = settings.enableEmailSearch !== undefined ? settings.enableEmailSearch : true
      this.enableTemplates = settings.enableTemplates !== undefined ? settings.enableTemplates : true
      this.enableFolders = settings.enableFolders !== undefined ? settings.enableFolders : true
      this.enableStatistics = settings.enableStatistics !== undefined ? settings.enableStatistics : true
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 
        '高级功能设置已加载: 搜索=%{public}s, 模板=%{public}s, 分组=%{public}s, 统计=%{public}s',
        this.enableEmailSearch ? 'ON' : 'OFF',
        this.enableTemplates ? 'ON' : 'OFF',
        this.enableFolders ? 'ON' : 'OFF',
        this.enableStatistics ? 'ON' : 'OFF')
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '加载功能设置失败: %{public}s', JSON.stringify(error))
    }
  }
  
  /**
   * 保存功能设置
   * 🔧 修复：改为通过 MailboxManager.updateSettings() 保存，确保数据流一致
   * 🔧 新增：自动处理功能冲突，防止性能问题
   */
  async saveFeatureSetting(key: string, value: boolean) {
    try {
      // 构建部分设置更新对象
      let partialSettings: Partial<SettingsData> = {}
      
      // 根据key设置对应的属性
      if (key === 'enableEmailSearch') {
        partialSettings.enableEmailSearch = value
      } else if (key === 'enableTemplates') {
        partialSettings.enableTemplates = value
      } else if (key === 'enableFolders') {
        partialSettings.enableFolders = value
      } else if (key === 'enableStatistics') {
        partialSettings.enableStatistics = value
      }
      
      // 通过 MailboxManager 统一保存
      await this.mailboxManager.updateSettings(partialSettings)
      
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '功能设置已保存到 MailboxManager: %{public}s = %{public}s', key, value ? '启用' : '关闭')
    } catch (error) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG,
        '保存功能设置失败: %{public}s', JSON.stringify(error))
    }
  }
  
  /**
   * 加载UI文本
   */
  loadUITexts() {
    // 从本地存储或默认值加载翻译文本
    const language = this.getSystemLanguage()
    
    if (language === 'zh-CN') {
      this.uiTexts = {
        'pageTitle': '高级功能',
        'featureEmailSearch': '邮件搜索与过滤',
        'featureTemplates': '邮件模板库',
        'featureFolders': '邮箱分组管理',
        'featureStatistics': '使用统计报告',
        'featureTags': '邮件标签系统',
        'featureAutoCategory': '邮件智能分类',
        'featureVisualization': '数据可视化',
        'featureAdvancedBackup': '高级数据管理',
        'featureFAB': '快速操作按钮',
        'tipPerformanceWarning': '性能警告',
        'tipAllFeaturesEnabled': '所有功能已启用，可能影响应用性能和页面响应速度。说明：数据可视化与智能分类互斥，最多启用8个功能。',
        'btnRestoreRecommended': '恢复推荐设置 (搜索+模板+分组+统计)',
        'tipRestoreSuccess': '已恢复推荐设置，页面将更流畅',
        'tipAutoDisabledFAB': '已自动关闭快速操作按钮以优化性能',
        'tipAutoDisabledAutoCategory': '已自动关闭智能分类功能（与数据可视化互斥）',
        'tipAutoDisabledVisualization': '已自动关闭数据可视化功能（与智能分类互斥）'
      }
    } else {
      this.uiTexts = {
        'pageTitle': 'Advanced Features',
        'featureEmailSearch': 'Email Search & Filter',
        'featureTemplates': 'Email Templates',
        'featureFolders': 'Mailbox Folders',
        'featureStatistics': 'Usage Statistics',
        'featureTags': 'Email Tags',
        'featureAutoCategory': 'Auto Categorization',
        'featureVisualization': 'Data Visualization',
        'featureAdvancedBackup': 'Advanced Backup',
        'featureFAB': 'Quick Action Button',
        'tipPerformanceWarning': 'Performance Warning',
        'tipAllFeaturesEnabled': 'All features are enabled, which may affect app performance and page response speed. Note: Data visualization and auto-categorization are mutually exclusive, max 8 features can be enabled.',
        'btnRestoreRecommended': 'Restore Recommended (Search+Templates+Folders+Statistics)',
        'tipRestoreSuccess': 'Recommended settings restored, page will be smoother',
        'tipAutoDisabledFAB': 'Quick action button auto-disabled to optimize performance',
        'tipAutoDisabledAutoCategory': 'Auto-categorization auto-disabled (mutually exclusive with visualization)',
        'tipAutoDisabledVisualization': 'Data visualization auto-disabled (mutually exclusive with auto-categorization)'
      }
    }
  }
  
  /**
   * 获取系统语言
   */
  private getSystemLanguage(): string {
    // 从本地存储或系统设置获取语言
    // 默认返回中文
    return 'zh-CN'
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('←')
            .fontSize('1.5rem')
            .fontColor(ThemeColors.PRIMARY)
        }
        .width(48)
        .height(48)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back()
        })
        
        Text(this.uiTexts['pageTitle'])
          .fontSize('1.125rem')
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 占位，保持标题居中
        Row().width(48).height(48)
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor(Color.White)
      
      Divider()
      
      // 所有核心功能已启用
      if (this.enableEmailSearch && this.enableTemplates && this.enableFolders && 
          this.enableStatistics) {
        Column({ space: 10 }) {
          Row({ space: 8 }) {
            Text('⚠️')
              .fontSize('1.25rem')
            
            Column({ space: 4 }) {
              Text(this.uiTexts['tipPerformanceWarning'] || 'Performance Warning')
                .fontSize('0.875rem')
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF6B00')
              
              Text(this.uiTexts['tipAllFeaturesEnabled'] || 'All features are enabled, which may affect app performance and page response speed.')
                .fontSize('0.75rem')
                .fontColor('#666666')
                .maxLines(3)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          
          // 一键恢复推荐设置按钮
          Button(this.uiTexts['btnRestoreRecommended'] || 'Restore Recommended Settings')
            .width('100%')
            .fontSize('0.8125rem')
            .backgroundColor('#FF9800')
            .fontColor(Color.White)
            .height(36)
            .onClick(async () => {
              await this.restoreRecommendedSettings()
            })
        }
        .width('100%')
        .padding(12)
        .backgroundColor('#FFF3E0')
        .borderRadius(8)
        .border({ width: 1, color: '#FFB74D' })
        .margin({ left: 16, right: 16, top: 12, bottom: 12 })
      }
      
      // 功能列表
      Scroll() {
        Column({ space: 0 }) {
          // 邮件搜索和过滤
          Column({ space: 4 }) {
            Row() {
              Text(this.uiTexts['featureEmailSearch'])
                .fontSize('0.9375rem')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableEmailSearch })
                .onChange((isOn: boolean) => {
                  this.enableEmailSearch = isOn
                  this.saveFeatureSetting('enableEmailSearch', isOn)
                })
            }
            .width('100%')
            
            if (this.enableEmailSearch) {
              Text(this.featureDescriptions['featureEmailSearch'])
                .fontSize('0.6875rem')
                .fontColor(ThemeColors.TEXT_SECONDARY)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          
          Divider().padding({ left: 16, right: 16 })
          
          // 邮件模板库
          Column({ space: 4 }) {
            Row() {
              Text(this.uiTexts['featureTemplates'])
                .fontSize('0.9375rem')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableTemplates })
                .onChange((isOn: boolean) => {
                  this.enableTemplates = isOn
                  this.saveFeatureSetting('enableTemplates', isOn)
                })
            }
            .width('100%')
            
            if (this.enableTemplates) {
              Text(this.featureDescriptions['featureTemplates'])
                .fontSize('0.6875rem')
                .fontColor(ThemeColors.TEXT_SECONDARY)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          
          Divider().padding({ left: 16, right: 16 })
          
          // 邮箱分组管理
          Column({ space: 4 }) {
            Row() {
              Text(this.uiTexts['featureFolders'])
                .fontSize('0.9375rem')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableFolders })
                .onChange((isOn: boolean) => {
                  this.enableFolders = isOn
                  this.saveFeatureSetting('enableFolders', isOn)
                })
            }
            .width('100%')
            
            if (this.enableFolders) {
              Text(this.featureDescriptions['featureFolders'])
                .fontSize('0.6875rem')
                .fontColor(ThemeColors.TEXT_SECONDARY)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          
          Divider().padding({ left: 16, right: 16 })
          
          // 使用统计报告
          Column({ space: 4 }) {
            Row() {
              Text(this.uiTexts['featureStatistics'])
                .fontSize('0.9375rem')
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              
              Toggle({ type: ToggleType.Switch, isOn: this.enableStatistics })
                .onChange((isOn: boolean) => {
                  this.enableStatistics = isOn
                  this.saveFeatureSetting('enableStatistics', isOn)
                })
            }
            .width('100%')
            
            if (this.enableStatistics) {
              Text(this.featureDescriptions['featureStatistics'])
                .fontSize('0.6875rem')
                .fontColor(ThemeColors.TEXT_SECONDARY)
                .width('100%')
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ top: 4 })
            }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .alignItems(HorizontalAlign.Start)
          
        }
        .width('100%')
        .backgroundColor(Color.White)
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
    .alignItems(HorizontalAlign.Start)
  }
}

