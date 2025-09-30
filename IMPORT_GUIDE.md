# 📱 Convenient Mailbox - DevEco Studio 导入指南

## 🎯 完整导入流程

### 第一步：下载和安装 DevEco Studio

1. **访问华为开发者官网**
   - 地址：https://developer.harmonyos.com/cn/develop/deveco-studio
   - 选择适合你操作系统的版本下载

2. **安装 DevEco Studio**
   - 运行安装程序
   - 选择安装路径
   - 等待安装完成

3. **首次启动配置**
   - 启动 DevEco Studio
   - 同意用户协议
   - 选择UI主题
   - 下载并安装 HarmonyOS SDK

### 第二步：导入项目

1. **打开 DevEco Studio**
   - 启动应用
   - 在欢迎界面选择 "Open"

2. **选择项目目录**
   - 浏览到 `Convenient_mailbox` 文件夹
   - 选择整个项目文件夹
   - 点击 "OK"

3. **等待项目同步**
   - DevEco Studio 会自动识别项目结构
   - 等待 Gradle 同步完成
   - 可能需要几分钟时间

### 第三步：配置开发环境

1. **检查 SDK 版本**
   - 打开 `File > Project Structure`
   - 确认 HarmonyOS SDK 版本为 API 9 或更高

2. **配置签名（调试用）**
   - 在 `File > Project Structure > Project > Signing Configs`
   - 使用默认的调试签名配置
   - 或创建自己的签名配置

### 第四步：构建和运行

1. **首次构建**
   - 点击 `Build > Build Hap(s)/App(s) > entry`
   - 等待构建完成

2. **运行方式选择**

   **方案A：使用模拟器**
   - 点击 `Tools > Device Manager`
   - 创建新的 HarmonyOS 模拟器
   - 启动模拟器
   - 点击 `Run > Run 'entry'`

   **方案B：使用真机调试**
   - 连接华为/荣耀手机到电脑
   - 在手机上开启开发者模式和USB调试
   - 在 DevEco Studio 中选择设备
   - 点击 `Run > Run 'entry'`

   **方案C：使用预览器**
   - 打开 `entry/src/main/ets/pages/Index.ets`
   - 点击右侧的 "Previewer" 标签
   - 实时预览UI效果

## 🔧 常见问题解决

### 问题1：SDK 下载失败
**解决方案：**
- 检查网络连接
- 使用华为开发者账号登录
- 尝试手动下载SDK

### 问题2：构建失败
**解决方案：**
```bash
# 清理项目
Build > Clean Project

# 重新构建
Build > Rebuild Project
```

### 问题3：模拟器启动失败
**解决方案：**
- 确保电脑支持虚拟化
- 在BIOS中启用VT-x/AMD-V
- 增加模拟器内存分配

### 问题4：真机连接失败
**解决方案：**
- 安装手机驱动程序
- 确认USB调试已开启
- 尝试更换USB数据线

## 📋 项目结构说明

导入成功后，你会看到以下项目结构：

```
Convenient_mailbox/
├── 📁 AppScope/              # 应用级配置
├── 📁 entry/                 # 主模块
│   ├── 📁 src/main/
│   │   ├── 📁 ets/           # ArkTS源码
│   │   └── 📁 resources/     # 资源文件
│   └── 📄 module.json5       # 模块配置
├── 📄 build-profile.json5    # 构建配置
├── 📄 hvigorfile.ts         # 构建脚本
└── 📄 package.json          # 依赖管理
```

## 🚀 快速验证

导入完成后，按以下步骤验证：

1. **检查项目结构** ✅
   - 确认所有文件都正确导入
   - 没有红色错误标记

2. **构建项目** ✅
   ```
   Build > Build Hap(s)/App(s) > entry
   ```

3. **运行应用** ✅
   - 选择运行目标（模拟器/真机/预览器）
   - 点击运行按钮

4. **测试功能** ✅
   - 点击"生成新邮箱"按钮
   - 选择不同的有效期
   - 查看邮件接收功能

## 📱 应用功能预览

成功运行后，你将看到：

### 主界面功能
- 🎯 **邮箱生成区域** - 显示当前邮箱地址
- ⏰ **时长选择器** - 7天/1月/6月/12月选项
- 🔘 **操作按钮** - 生成/复制/删除功能

### 邮件管理
- 📬 **收件箱** - 显示接收到的邮件
- 📊 **统计信息** - 总邮件数、未读数、剩余时间
- 🔍 **邮件详情** - 发件人、主题、内容预览

### 邮箱管理
- ⚙️ **邮箱列表** - 显示所有创建的邮箱
- 🏷️ **状态标识** - 活跃/即将过期/已过期
- 🛠️ **管理操作** - 续期/删除功能

## 🎨 自定义开发

如果你想修改应用：

1. **修改UI界面**
   - 编辑 `entry/src/main/ets/pages/Index.ets`
   - 使用ArkUI组件和布局

2. **修改业务逻辑**
   - 编辑 `entry/src/main/ets/common/MailboxManager.ets`
   - 添加新的功能方法

3. **修改应用配置**
   - 编辑 `entry/src/main/module.json5`
   - 修改权限、图标等配置

4. **添加新页面**
   - 在 `pages` 目录创建新的 `.ets` 文件
   - 在 `main_pages.json` 中注册新页面

## 📞 获取帮助

如果遇到问题：

1. **查看官方文档**
   - HarmonyOS开发者文档
   - DevEco Studio用户指南

2. **社区支持**
   - 华为开发者论坛
   - HarmonyOS技术交流群

3. **问题反馈**
   - 项目GitHub Issues
   - 开发者邮箱支持

---

🎉 **恭喜！** 现在你已经成功导入了Convenient Mailbox项目，可以开始体验和开发了！
