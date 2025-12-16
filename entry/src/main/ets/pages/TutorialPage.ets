/**
 * 使用教程说明页面
 * 提供软件功能的详细说明和使用指南
 * 
 * @since 2.0.0
 */

import { router } from '@kit.ArkUI'
import { AppConstants } from '../common/Constants'
import hilog from '@ohos.hilog'

@Component
export struct TutorialPage {
  @Link uiTexts: Record<string, string>

  /**
   * 获取文本颜色（根据主题）
   */
  getTextPrimaryColor(): string {
    return '#000000'
  }

  getTextSecondaryColor(): string {
    return '#666666'
  }

  getPrimaryColor(): string {
    return '#007AFF'
  }

  getBackgroundColor(): string {
    return '#FFFFFF'
  }

  getBorderColor(): string {
    return '#E5E5EA'
  }

  /**
   * 构建页面
   */
  build() {
    Column() {
      // 顶部导航栏
      Column() {
        Row() {
          Button({ type: ButtonType.Normal, stateEffect: true }) {
            Text('←')
              .fontSize(24)
              .fontColor(this.getPrimaryColor())
          }
          .width(40)
          .height(40)
          .backgroundColor('transparent')
          .onClick(() => {
            router.back()
          })

          Text(this.uiTexts['tutorialTitle'] || 'Usage Tutorial')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTextPrimaryColor())
            .layoutWeight(1)
            .textAlign(TextAlign.Center)

          Blank()
            .width(40)
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })

        Divider()
          .color(this.getBorderColor())
          .strokeWidth(1)
      }
      .width('100%')
      .backgroundColor(this.getBackgroundColor())

      // 内容区域 - 线性布局，从上到下显示所有说明
      Scroll() {
        Column({ space: 20 }) {
          // 写信功能说明
          this.buildComposeSection()

          // 临时邮箱说明
          this.buildMailboxSection()

          // 附件功能说明
          this.buildAttachmentSection()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 16, bottom: 16 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.On)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 构建写信功能说明
   */
  @Builder buildComposeSection(): void {
    Column({ space: 12 }) {
      // 标题
      Text(this.uiTexts['tutorialComposeTitle'] || 'Write Email Feature')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())

      // 说明文本
      Text(this.uiTexts['tutorialComposeDesc'] || 'You can write and send emails using any of the following methods:')
        .fontSize(14)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .maxLines(10)
        .textOverflow({ overflow: TextOverflow.Clip })

      // 支持的发送方式
      this.buildMethodCard(
        this.uiTexts['sendSmtp'] || 'SMTP Server',
        this.uiTexts['tutorialSmtpDesc'] || 'Use your own SMTP server configuration. Requires email address, password, SMTP host, and port settings.',
        '✅'
      )

      this.buildMethodCard(
        this.uiTexts['sendEmailJsBuiltin'] || 'Built-in EmailJS (2/month)',
        this.uiTexts['tutorialEmailJSBuiltinDesc'] || 'Use the built-in EmailJS service with 2 free emails per month. No configuration needed.',
        '✅'
      )

      this.buildMethodCard(
        this.uiTexts['sendEmailJsExternal'] || 'External EmailJS',
        this.uiTexts['tutorialEmailJSExternalDesc'] || 'Use your own EmailJS account. Requires Service ID, Template ID, and Public Key. Unlimited emails.',
        '✅'
      )

      this.buildMethodCard(
        this.uiTexts['sendResendBuiltin'] || 'Built-in Resend (3/month)',
        this.uiTexts['tutorialResendBuiltinDesc'] || 'Use the built-in Resend API service with 3 free emails per month. No configuration needed.',
        '✅'
      )

      this.buildMethodCard(
        this.uiTexts['sendResendExternal'] || 'External Resend API',
        this.uiTexts['tutorialResendExternalDesc'] || 'Use your own Resend API key. Requires API key configuration. Unlimited emails.',
        '✅'
      )

      // 配额说明
      Text(this.uiTexts['tutorialQuotaNote'] || 'Note: Built-in services have monthly quotas that reset on the 1st of each month.')
        .fontSize(12)
        .fontColor('#FF9500')
        .lineHeight(1.6)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFF3E0')
        .borderRadius(4)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(8)
  }

  /**
   * 构建临时邮箱说明
   */
  @Builder buildMailboxSection(): void {
    Column({ space: 12 }) {
      // 标题
      Text(this.uiTexts['tutorialMailboxTitle'] || 'Temporary Mailbox Features')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())

      // 功能说明
      Text(this.uiTexts['tutorialMailboxDesc'] || 'Temporary mailboxes are randomly generated email addresses with the following features:')
        .fontSize(14)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .maxLines(10)
        .textOverflow({ overflow: TextOverflow.Clip })

      // 功能列表
      this.buildFeatureItem(
        this.uiTexts['tutorialMailboxReceive'] || 'Receive Emails',
        this.uiTexts['tutorialMailboxReceiveDesc'] || 'All temporary mailboxes can receive emails. You can view received emails in the inbox.'
      )

      this.buildFeatureItem(
        this.uiTexts['tutorialMailboxSend'] || 'Send Emails',
        this.uiTexts['tutorialMailboxSendDesc'] || 'All temporary mailboxes can send emails using any configured sending method. Select the mailbox in the compose page.'
      )

      this.buildFeatureItem(
        this.uiTexts['tutorialMailboxExpiry'] || 'Expiration',
        this.uiTexts['tutorialMailboxExpiryDesc'] || 'Each mailbox has an expiration time. After expiration, the mailbox cannot receive new emails. You can set the duration when creating a mailbox (7 days, 1 month, 6 months, 1 year, or custom).'
      )

      this.buildFeatureItem(
        this.uiTexts['tutorialMailboxManage'] || 'Management',
        this.uiTexts['tutorialMailboxManageDesc'] || 'You can view mailbox details, check expiration time, move emails to folders, and delete mailboxes.'
      )

      // 限制说明
      Text(this.uiTexts['tutorialMailboxLimitation'] || 'Limitation: Temporary mailboxes are for temporary use only. After expiration, the mailbox and all its emails will no longer be accessible.')
        .fontSize(12)
        .fontColor('#D32F2F')
        .lineHeight(1.6)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#FFEBEE')
        .borderRadius(4)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(8)
  }

  /**
   * 构建附件功能说明
   */
  @Builder buildAttachmentSection(): void {
    Column({ space: 12 }) {
      // 标题
      Text(this.uiTexts['tutorialAttachmentTitle'] || 'Attachment Features')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.getTextPrimaryColor())

      // 说明文本
      Text(this.uiTexts['tutorialAttachmentDesc'] || 'You can attach files to emails when sending. Here are the attachment rules:')
        .fontSize(14)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .maxLines(10)
        .textOverflow({ overflow: TextOverflow.Clip })

      // 限制信息
      this.buildLimitationItem(
        this.uiTexts['tutorialAttachmentCount'] || 'Maximum Files',
        this.uiTexts['tutorialAttachmentCountDesc'] || 'You can attach up to 5 files per email.'
      )

      this.buildLimitationItem(
        this.uiTexts['tutorialAttachmentSize'] || 'File Size Limit',
        this.uiTexts['tutorialAttachmentSizeDesc'] || 'Each file must not exceed 10MB. Files larger than this limit will be skipped.'
      )

      this.buildLimitationItem(
        this.uiTexts['tutorialAttachmentSupport'] || 'Supported Methods',
        this.uiTexts['tutorialAttachmentSupportDesc'] || 'Attachments are supported with all sending methods: SMTP, EmailJS, and Resend.'
      )

      this.buildLimitationItem(
        this.uiTexts['tutorialAttachmentFormat'] || 'File Types',
        this.uiTexts['tutorialAttachmentFormatDesc'] || 'All file types are supported (documents, images, videos, archives, etc.).'
      )

      // 使用提示
      Text(this.uiTexts['tutorialAttachmentTip'] || 'Tip: Compress large files before attaching to reduce email size and improve delivery speed.')
        .fontSize(12)
        .fontColor('#1976D2')
        .lineHeight(1.6)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .backgroundColor('#E3F2FD')
        .borderRadius(4)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .backgroundColor(this.getBackgroundColor())
    .borderRadius(8)
  }

  /**
   * 构建发送方式卡片
   */
  @Builder buildMethodCard(title: string, description: string, status: string): void {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text(status)
          .fontSize(14)
          .fontColor('#4CAF50')

        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextPrimaryColor())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .width('100%')
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }

  /**
   * 构建功能项
   */
  @Builder buildFeatureItem(title: string, description: string): void {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text('•')
          .fontSize(14)
          .fontColor(this.getPrimaryColor())
          .fontWeight(FontWeight.Bold)

        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextPrimaryColor())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .width('100%')
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }

  /**
   * 构建限制项
   */
  @Builder buildLimitationItem(title: string, description: string): void {
    Column({ space: 4 }) {
      Row({ space: 8 }) {
        Text('-')
          .fontSize(14)
          .fontColor(this.getPrimaryColor())
          .fontWeight(FontWeight.Bold)

        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextPrimaryColor())
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Text(description)
        .fontSize(12)
        .fontColor(this.getTextSecondaryColor())
        .lineHeight(1.6)
        .width('100%')
        .maxLines(5)
        .textOverflow({ overflow: TextOverflow.Clip })
    }
    .width('100%')
    .margin({ top: 8, bottom: 8 })
  }
}
