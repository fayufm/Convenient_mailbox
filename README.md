# Convenient Mailbox - 临时邮箱生成器

## 📧 项目简介

Convenient Mailbox 是一个专为鸿蒙系统开发的临时邮箱生成器应用。用户可以快速生成临时邮箱用于接收验证码、注册网站等场景，有效保护个人隐私。

## ✨ 主要功能

### 🎯 核心功能
- **临时邮箱生成** - 一键生成随机临时邮箱地址
- **自定义有效期** - 支持7天、1月、6月、12月等多种时长
- **邮件接收** - 实时接收和显示邮件内容
- **邮箱管理** - 管理多个临时邮箱，支持续期和删除
- **隐私保护** - 自动清理过期邮箱，保护用户隐私

### 🛠️ 辅助功能
- **一键复制** - 快速复制邮箱地址到剪贴板
- **邮件分类** - 自动识别验证码邮件
- **状态提醒** - 实时显示邮箱剩余时间和状态
- **数据持久化** - 本地保存邮箱和邮件数据

## 🏗️ 技术架构

### 开发语言和框架
- **ArkTS** - 鸿蒙官方开发语言
- **ArkUI** - 声明式UI开发框架
- **HarmonyOS SDK** - 鸿蒙系统开发工具包

### 项目结构
```
Convenient_mailbox/
├── entry/                          # 主模块
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/       # 应用入口
│   │   │   │   └── EntryAbility.ets
│   │   │   ├── pages/              # 页面文件
│   │   │   │   └── Index.ets       # 主页面
│   │   │   └── common/             # 公共模块
│   │   │       ├── DataTypes.ets   # 数据类型定义
│   │   │       └── MailboxManager.ets # 邮箱管理器
│   │   ├── resources/              # 资源文件
│   │   │   └── base/
│   │   │       ├── element/        # 字符串、颜色等资源
│   │   │       └── profile/        # 配置文件
│   │   └── module.json5            # 模块配置
│   └── hvigorfile.ts              # 构建配置
├── AppScope/                       # 应用级配置
│   ├── app.json5                  # 应用配置
│   └── resources/                 # 应用级资源
├── build-profile.json5            # 构建配置
├── hvigorfile.ts                 # 根构建配置
├── package.json                  # 依赖管理
└── README.md                     # 项目文档
```

## 🚀 开发环境搭建

### 1. 安装DevEco Studio
1. 访问华为开发者官网下载 [DevEco Studio](https://developer.harmonyos.com/cn/develop/deveco-studio)
2. 安装并配置HarmonyOS SDK
3. 创建华为开发者账号

### 2. 导入项目
1. 打开DevEco Studio
2. 选择 "Open" 或 "Import Project"
3. 选择项目根目录 `Convenient_mailbox`
4. 等待项目同步完成

### 3. 配置签名
1. 在DevEco Studio中打开 `File > Project Structure`
2. 选择 `Project > Signing Configs`
3. 配置签名证书和Profile文件

## 🔨 构建和运行

### 命令行构建
```bash
# 安装依赖
npm install

# 调试版本构建
npm run debug

# 发布版本构建
npm run release

# 清理构建文件
npm run clean
```

### IDE构建
1. 在DevEco Studio中点击 `Build > Build Hap(s)/App(s)`
2. 选择构建目标和模式
3. 等待构建完成

### 运行和调试
1. **模拟器运行**：点击 `Run > Run 'entry'`
2. **真机调试**：连接华为设备，启用开发者模式
3. **预览器**：使用DevEco Studio内置预览器

## 📱 应用截图

### 主界面
- 邮箱生成区域
- 时长选择器
- 操作按钮组

### 邮件管理
- 收件箱列表
- 邮件详情显示
- 未读邮件标识

### 邮箱管理
- 邮箱列表
- 状态显示
- 续期和删除操作

## 📦 打包发布

### 生成HAP包
1. 在DevEco Studio中选择 `Build > Generate Signed Bundle/APK`
2. 选择 `HAP` 格式
3. 配置签名信息
4. 选择发布模式（Release）
5. 生成 `.hap` 文件

### 上架华为应用市场
1. **注册开发者账号**
   - 访问华为开发者联盟
   - 完成实名认证

2. **创建应用**
   - 填写应用基本信息
   - 上传应用图标和截图
   - 设置应用分类和标签

3. **上传HAP包**
   - 上传构建好的 `.hap` 文件
   - 填写版本更新说明
   - 配置应用权限说明

4. **提交审核**
   - 检查应用信息完整性
   - 提交华为审核
   - 等待审核结果

5. **发布上线**
   - 审核通过后选择发布时间
   - 应用正式上线华为应用市场

## 🔧 开发说明

### 核心组件
- **MailboxManager** - 邮箱生成和管理逻辑
- **DataTypes** - 数据结构定义
- **Index页面** - 主界面UI和交互逻辑

### 数据存储
- 使用鸿蒙本地存储API保存邮箱和邮件数据
- 支持数据持久化和自动清理

### 权限说明
- `ohos.permission.INTERNET` - 网络访问权限
- `ohos.permission.GET_NETWORK_INFO` - 网络状态获取权限

## 🐛 已知问题

1. **邮件接收** - 当前版本使用模拟数据，实际版本需要集成邮件服务API
2. **推送通知** - 需要申请通知权限并集成推送服务
3. **数据同步** - 多设备数据同步功能待开发

## 🔮 未来规划

### v1.1.0
- [ ] 集成真实邮件服务API
- [ ] 添加推送通知功能
- [ ] 支持邮件搜索和过滤

### v1.2.0
- [ ] 多设备数据同步
- [ ] 邮件导出功能
- [ ] 自定义邮箱域名

### v2.0.0
- [ ] 分布式协同功能
- [ ] AI邮件分类
- [ ] 高级隐私保护

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🤝 贡献指南

欢迎提交Issue和Pull Request来帮助改进项目！

## 📞 联系我们

- 项目地址：[GitHub Repository]
- 问题反馈：[Issues]
- 邮箱：support@convenientmailbox.com

---

**注意**：本应用仅用于学习和演示目的，实际使用时请确保遵守相关法律法规和服务条款。
