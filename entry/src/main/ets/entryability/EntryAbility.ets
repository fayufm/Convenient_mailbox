import { AbilityConstant, Configuration, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppConstants } from '../common/Constants';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    
    // ✅ 将 Context 保存到 AppStorage，供页面使用
    AppStorage.setOrCreate('abilityContext', this.context);
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Context saved to AppStorage');
    
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, '%{public}s', 'Ability onBackground');
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    // 系统配置变化（如深色模式切换）
    hilog.info(AppConstants.LOG_DOMAIN, AppConstants.LOG_TAG, 'Configuration updated: colorMode=%{public}d', 
      newConfig.colorMode !== undefined ? newConfig.colorMode : -1);
    
    // 通知应用更新主题（如果设置为"跟随系统"）
    // 注意：实际主题应用由应用内部的设置控制
    // 这里只记录系统配置变化，具体是否应用取决于用户设置
  }
}