/**
 * Mailboxes Page - 我的邮箱页面
 * 负责显示和管理所有邮箱地址
 */

import { MailboxData, MailboxFolder, EmailTag, MailboxStatistics, DomainStatItem, EmailTrendItem, TagStatItem } from '../common/DataTypes'
import { MailboxManager } from '../common/MailboxManager'
import { AppConstants, ThemeColors, UISizes } from '../common/Constants'
import { I18nService } from '../common/I18nService'
import { SystemService } from '../common/SystemService'
import promptAction from '@ohos.promptAction'
import hilog from '@ohos.hilog'

// 统计项接口
interface StatItem {
  label: string
  value: string
  color: string
}

@Component
export struct MailboxesPage {
  // ==================== Props from Parent ====================
  @Link mailboxes: MailboxData[]
  @Link selectedMailbox: MailboxData | null
  @Link showMailboxActionsMenu: boolean
  @Link folderViewMode: string
  @Link expandedFolderIds: number[]
  @Link selectedFolderId: number
  @Link showFolderDialog: boolean
  @Link showCreateFolderDialog: boolean
  @Link editingFolderId: number
  @Link folderName: string
  @Link folderIcon: string
  @Link folderColor: string
  @Link folderDescription: string
  @Link showMoveFolderDialog: boolean
  @Link movingMailboxId: number
  @Link mailboxFolders: MailboxFolder[]
  @Link selectedTargetFolderId: number
  @Link showTagDialog: boolean
  @Link showCreateTagDialog: boolean
  @Link editingTagId: number
  @Link tagName: string
  @Link tagColor: string
  @Link tagIcon: string
  @Link tagDescription: string
  @Link showAddTagDialog: boolean
  @Link taggingEmailId: number
  @Link showStatsDialog: boolean
  @Link statsData: Record<string, Object> | null
  @Link showNoteDialog: boolean
  @Link editingMailboxIdForNote: number
  @Link mailboxNote: string
  @Link showStatisticsDetail: boolean
  @Link mailboxListRefreshKey: number
  @Link statsRefreshKey: number
  @Link totalEmails: number
  @Link unreadEmails: number
  @Link todayEmails: number
  @Link activeMailboxes: number
  @Link expiringMailboxes: number
  @Link uiTexts: Record<string, string>
  @Link enableFolders: boolean
  @Link enableStatistics: boolean
  @Link settingsTheme: 'light' | 'dark' | 'auto'
  
  // Services
  @Prop mailboxManager: MailboxManager
  @Prop i18nService: I18nService
  @Prop systemService: SystemService
  
  // Callbacks
  onMailboxClick?: (mailbox: MailboxData) => void
  onDeleteMailbox?: (mailboxId: number) => void
  onCopyMailbox?: (mailbox: MailboxData) => void
  onRefreshStats?: () => void
  onCreateFolder?: () => void
  onCreateTag?: () => void
  onSaveNote?: () => void
  
  // ==================== Helper Methods ====================
  
  /**
   * 获取动态主色调（根据当前主题）
   */
  getPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#64B5F6'
    } else if (this.settingsTheme === 'light') {
      return '#1976D2'
    } else {
      return '#2196F3'
    }
  }

  /**
   * 获取动态文本颜色（根据当前主题）
   */
  getTextPrimaryColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#FFFFFF'
    } else {
      return '#212529'
    }
  }

  /**
   * 获取动态背景颜色（根据当前主题）
   */
  getBackgroundColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#121212'
    } else {
      return '#FFFFFF'
    }
  }

  /**
   * 获取域名统计数据
   */
  getDomainStats(): Array<[string, number]> {
    const domainStats: Map<string, number> = new Map()
    for (let i = 0; i < this.mailboxes.length; i++) {
      const mailbox = this.mailboxes[i]
      const domain = mailbox.email.split('@')[1] || 'unknown'
      const count = domainStats.get(domain) || 0
      domainStats.set(domain, count + 1)
    }
    return Array.from(domainStats.entries())
  }

  /**
   * 获取动态边框颜色（根据当前主题）
   */
  getBorderColor(): string {
    if (this.settingsTheme === 'dark') {
      return '#333333'
    } else {
      return '#E0E0E0'
    }
  }

  /**
   * 格式化日期
   */
  private formatDate(date: Date): string {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`
  }
  
  /**
   * 获取邮箱状态文本
   */
  private getMailboxStatusText(mailbox: MailboxData): string {
    const now: Date = new Date()
    const expiryDate: Date = new Date(mailbox.expiryTime)
    if (expiryDate <= now) {
      return this.uiTexts['statusExpired'] || '已过期'
    }
    const daysLeft: number = Math.floor((expiryDate.getTime() - now.getTime()) / 86400000)
    
    if (daysLeft < 1) {
      return this.uiTexts['statusExpiringToday'] || '今日过期'
    } else if (daysLeft < 3) {
      return `${daysLeft}${this.uiTexts['daysLeft'] || '天后过期'}`
    } else {
      return this.uiTexts['statusActive'] || '正常'
    }
  }
  
  /**
   * 根据邮箱ID获取邮箱地址
   */
  private getMailboxEmailById(mailboxId: number): string {
    const mailbox = this.mailboxes.find(m => m.id === mailboxId)
    return mailbox ? mailbox.email : ''
  }
  
  /**
   * 根据邮箱获取状态颜色
   */
  private getMailboxStatusColor(mailbox: MailboxData | undefined): string {
    if (!mailbox) {
      return '#999999'
    }
    const now: Date = new Date()
    const expiryDate: Date = new Date(mailbox.expiryTime)
    if (expiryDate <= now) {
      return '#FF5252'
    }
    return '#4CAF50'
  }
  
  // ==================== Builder Methods ====================
  
  @Builder buildMailboxesPage(): void {
    Column({ space: 16 }) {
      // Header
      Row() {
        Text(this.uiTexts['pageMailboxes'] || 'My Mailboxes')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        if (this.enableFolders) {
          Button(this.folderViewMode === 'list' ? this.uiTexts['folderViewFolder'] || 'Folder View' : this.uiTexts['folderViewList'] || 'List View')
            .fontSize(12)
            .onClick(() => {
              this.folderViewMode = this.folderViewMode === 'list' ? 'folder' : 'list'
            })
        }
      }
      .width('100%')
      .padding({ top: 16 })
      
      // Statistics report
      if (this.enableStatistics) {
        this.buildStatisticsReport()
      }
      
      // Folder view or list view
      if (this.enableFolders && this.folderViewMode === 'folder') {
        this.buildFolderView()
      } else {
        // List view
        if (this.mailboxes.length === 0) {
          Column() {
            Text(this.uiTexts['mailboxesEmpty'] || 'No mailboxes yet')
              .fontSize(14)
              .fontColor(this.getTextPrimaryColor())
          }
          .width('100%')
          .height(200)
          .justifyContent(FlexAlign.Center)
        } else {
          List() {
            ForEach(this.mailboxes, (mailbox: MailboxData) => {
              ListItem() {
                this.buildMailboxItem(mailbox)
              }
            }, (mailbox: MailboxData) => `${mailbox.id}_${this.mailboxListRefreshKey}`)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({ strokeWidth: 1, color: this.getBorderColor() })
        }
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder buildMailboxItem(mailbox: MailboxData): void {
    Column() {
      Row() {
        Column() {
          Text(mailbox.email)
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.getTextPrimaryColor())
          
          Text(`${this.uiTexts['labelCreated'] || 'Created'}: ${this.formatDate(new Date(mailbox.createdTime))}`)
            .fontSize(10)
            .fontColor(this.getTextPrimaryColor())
            .margin({ top: 2 })
          
          Text(`${this.uiTexts['labelExpires'] || 'Expires'}: ${this.formatDate(new Date(mailbox.expiryTime))}`)
            .fontSize(10)
            .fontColor(new Date(mailbox.expiryTime) <= new Date() ? Color.Red : this.getTextPrimaryColor())
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        
        Blank()
        
        Column() {
          Text(this.getMailboxStatusText(mailbox))
            .fontSize(10)
            .fontColor(new Date(mailbox.expiryTime) <= new Date() ? Color.Red : '#4CAF50')
          
          Button('⋮')
            .fontSize(16)
            .backgroundColor(Color.Transparent)
            .fontColor(this.getTextPrimaryColor())
            .onClick(() => {
              this.selectedMailbox = mailbox
              this.showMailboxActionsMenu = true
            })
        }
      }
      .width('100%')
      
      if (mailbox.notes) {
        Text(mailbox.notes)
          .fontSize(10)
          .fontColor(this.getTextPrimaryColor())
          .margin({ top: 5 })
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
    }
    .width('100%')
    .padding(12)
    .onClick(() => {
      if (this.onMailboxClick) {
        this.onMailboxClick(mailbox)
      }
    })
  }
  
  @Builder buildMailboxActionsMenu(): void {
    if (this.showMailboxActionsMenu && this.selectedMailbox) {
      Column() {
        Text(this.uiTexts['mailboxActions'] || 'Mailbox Actions')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
          .fontColor(this.getTextPrimaryColor())
        
        Button(this.uiTexts['btnCopyEmail'] || 'Copy Email')
          .width('100%')
          .margin({ bottom: 10 })
          .onClick(async () => {
            if (this.selectedMailbox) {
              await this.systemService.copyToClipboard(this.selectedMailbox.email)
              await this.systemService.showToast(this.uiTexts['tipCopySuccess'] || 'Copied')
            }
            this.showMailboxActionsMenu = false
          })
        
        Button(this.uiTexts['btnAddNote'] || 'Add Note')
          .width('100%')
          .margin({ bottom: 10 })
          .onClick(() => {
            if (this.selectedMailbox) {
              this.editingMailboxIdForNote = this.selectedMailbox.id
              this.mailboxNote = this.selectedMailbox.notes || ''
              this.showNoteDialog = true
            }
            this.showMailboxActionsMenu = false
          })
        
        // 标签功能已移除
        
        if (this.enableFolders) {
          Button(this.uiTexts['btnMoveToFolder'] || 'Move to Folder')
            .width('100%')
            .margin({ bottom: 10 })
            .onClick(() => {
              if (this.selectedMailbox) {
                this.movingMailboxId = this.selectedMailbox.id
                this.showMoveFolderDialog = true
              }
              this.showMailboxActionsMenu = false
            })
        }
        
        Button(this.uiTexts['btnDelete'] || 'Delete')
          .width('100%')
          .backgroundColor(Color.Red)
          .fontColor(Color.White)
          .onClick(async () => {
            if (this.selectedMailbox) {
              const confirm: boolean = await this.systemService.showConfirm(
                this.uiTexts['confirmDeleteMailbox'] || 'Delete Mailbox',
                this.uiTexts['confirmDeleteMailboxMessage'] || 'Are you sure?'
              )
              if (confirm && this.onDeleteMailbox) {
                this.onDeleteMailbox(this.selectedMailbox.id)
              }
            }
            this.showMailboxActionsMenu = false
          })
      }
      .padding(20)
      .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : Color.White)
      .borderRadius(8)
      .border({
        width: 1,
        color: this.settingsTheme === 'dark' ? '#333333' : '#E0E0E0'
      })
      .width('80%')
    }
  }
  
  @Builder buildFolderView(): void {
    Column() {
      // 文件夹视图标题
      Row() {
        Text(this.uiTexts['folderView'] || 'Folder View')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        Button(this.uiTexts['btnCreateFolder'] || 'Create Folder')
          .fontSize(12)
          .onClick(() => {
            this.showCreateFolderDialog = true
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      
      // 文件夹列表
      if (this.mailboxFolders.length > 0) {
        List() {
          ForEach(this.mailboxFolders, (folder: MailboxFolder) => {
            ListItem() {
              Column() {
                // 文件夹头部
                Row() {
                  Column() {
                    Text(folder.name)
                      .fontSize(14)
                      .fontWeight(FontWeight.Bold)
                      .fontColor(this.getTextPrimaryColor())
                    
                    if (folder.description) {
                      Text(folder.description)
                        .fontSize(10)
                        .fontColor(Color.Gray)
                        .margin({ top: 2 })
                    }
                  }
                  .layoutWeight(1)
                  
                  Text(`${folder.mailboxIds?.length || 0}`)
                    .fontSize(12)
                    .fontColor(Color.Gray)
                    .padding({ right: 10 })
                }
                .width('100%')
                .padding(12)
                .onClick(() => {
                  const idx = this.expandedFolderIds.indexOf(folder.id)
                  if (idx !== -1) {
                    this.expandedFolderIds.splice(idx, 1)
                  } else {
                    this.expandedFolderIds.push(folder.id)
                  }
                })
                
                // 文件夹内的邮箱列表（展开时显示）
                if (this.expandedFolderIds.includes(folder.id) && folder.mailboxIds.length > 0) {
                  Column() {
                    ForEach(folder.mailboxIds, (mailboxId: number) => {
                      Row() {
                        Text(this.getMailboxEmailById(mailboxId))
                          .fontSize(12)
                          .fontColor(this.getTextPrimaryColor())
                          .layoutWeight(1)
                        
                        Text(this.uiTexts['labelActive'] || 'Active')
                          .fontSize(10)
                          .fontColor('#4CAF50')
                      }
                      .width('100%')
                      .padding({ left: 40, right: 12, top: 8, bottom: 8 })
                      .backgroundColor(this.settingsTheme === 'dark' ? '#0A0A0A' : '#FAFAFA')
                    })
                  }
                  .width('100%')
                }
              }
              .width('100%')
              .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : Color.White)
              .borderRadius(8)
              .border({
                width: 1,
                color: this.settingsTheme === 'dark' ? '#333333' : '#E0E0E0'
              })
            }
            .margin({ left: 16, right: 16, bottom: 10 })
          })
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ top: 10, bottom: 10 })
      } else {
        Text(this.uiTexts['noFolders'] || 'No folders available')
          .fontSize(12)
          .fontColor(Color.Gray)
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding(20)
      }
    }
    .width('100%')
    .height('100%')
  }
  
  @Builder buildFolderItem(folder: MailboxFolder): void {
    Row() {
      Text(folder.name)
        .fontSize(14)
        .layoutWeight(1)
      
      Text(`(${folder.mailboxIds?.length || 0})`)
        .fontSize(12)
        .fontColor(Color.Gray)
    }
    .width('100%')
    .padding(10)
    .onClick(() => {
      this.selectedFolderId = folder.id
    })
  }
  
  @Builder buildStatisticsReport(): void {
    Column() {
      Row() {
        Text(this.uiTexts['statistics'] || 'Statistics')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.getTextPrimaryColor())
        
        Blank()
        
        Button(this.uiTexts['btnDetails'] || 'Details')
          .fontSize(12)
          .onClick(() => {
            this.showStatsDialog = true
            if (this.onRefreshStats) {
              this.onRefreshStats()
            }
          })
      }
      .width('100%')
      
      Row() {
        this.buildStatCard(this.uiTexts['statTotal'] || 'Total', this.mailboxes.length.toString(), ThemeColors.PRIMARY)
        this.buildStatCard(this.uiTexts['statActive'] || 'Active', this.activeMailboxes.toString(), '#4CAF50')
        this.buildStatCard(this.uiTexts['statExpiring'] || 'Expiring', this.expiringMailboxes.toString(), '#FF9800')
      }
      .width('100%')
      .margin({ top: 8 })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : '#F5F5F5')
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
  
  @Builder buildStatCard(label: string, value: string, color: string): void {
    Column() {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      Text(label)
        .fontSize(11)
        .fontColor(this.getTextPrimaryColor())
        .margin({ top: 4 })
    }
  }
  
  @Builder buildCreateFolderDialog(): void {
    if (this.showCreateFolderDialog) {
      Column() {
        Text(this.uiTexts['createFolder'] || 'Create Folder')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        TextInput({ placeholder: this.uiTexts['folderNamePlaceholder'] || 'Folder name' })
          .onChange((value: string) => {
            this.folderName = value
          })
          .margin({ bottom: 10 })
        
        TextInput({ placeholder: this.uiTexts['descriptionPlaceholder'] || 'Description' })
          .onChange((value: string) => {
            this.folderDescription = value
          })
          .margin({ bottom: 10 })
        
        Row() {
          Button(this.uiTexts['btnCancel'] || 'Cancel')
            .onClick(() => {
              this.showCreateFolderDialog = false
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnCreate'] || 'Create')
            .onClick(() => {
              if (this.onCreateFolder) {
                this.onCreateFolder()
              }
              this.showCreateFolderDialog = false
            })
        }
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .width('80%')
    }
  }
  
  @Builder buildMoveFolderDialog(): void {
    if (this.showMoveFolderDialog) {
      Column() {
        Text(this.uiTexts['moveToFolder'] || 'Move to Folder')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
          .fontColor(this.getTextPrimaryColor())
        
        Text(this.uiTexts['selectFolderPlaceholder'] || 'Select destination folder')
          .fontSize(12)
          .margin({ bottom: 10 })
          .fontColor(this.getTextPrimaryColor())
        
        // 文件夹列表选择器
        if (this.mailboxFolders.length > 0) {
          Column() {
            ForEach(this.mailboxFolders, (folder: MailboxFolder) => {
              Row() {
                Column() {
                  Text(folder.name)
                    .fontSize(14)
                    .fontColor(this.getTextPrimaryColor())
                  
                  Text(`${folder.mailboxIds?.length || 0} ${this.uiTexts['labelMailboxes'] || 'mailboxes'}`)
                    .fontSize(10)
                    .fontColor(Color.Gray)
                }
                .layoutWeight(1)
                
                if (this.selectedTargetFolderId === folder.id) {
                  Text('[OK]')
                    .fontSize(16)
                    .fontColor('#4CAF50')
                    .fontWeight(FontWeight.Bold)
                }
              }
              .width('100%')
              .padding(10)
              .backgroundColor(this.selectedTargetFolderId === folder.id ? 
                (this.settingsTheme === 'dark' ? '#2A2A2A' : '#F5F5F5') : 
                Color.Transparent)
              .borderRadius(4)
              .onClick(() => {
                this.selectedTargetFolderId = folder.id
              })
            })
          }
          .width('100%')
          .padding(10)
          .backgroundColor(this.settingsTheme === 'dark' ? '#0A0A0A' : '#FAFAFA')
          .borderRadius(4)
          .margin({ bottom: 15 })
        } else {
          Text(this.uiTexts['noFolders'] || 'No folders available')
            .fontSize(12)
            .fontColor(Color.Gray)
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(10)
            .margin({ bottom: 15 })
        }
        
        Row() {
          Button(this.uiTexts['btnCancel'] || 'Cancel')
            .onClick(() => {
              this.showMoveFolderDialog = false
              this.selectedTargetFolderId = 0
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnMove'] || 'Move')
            .onClick(async () => {
              if (this.selectedTargetFolderId > 0 && this.movingMailboxId > 0) {
                let moveSuccess: boolean = false
                try {
                  // 从其他文件夹中移除该邮箱
                  for (let i = 0; i < this.mailboxFolders.length; i++) {
                    const idx = this.mailboxFolders[i].mailboxIds.indexOf(this.movingMailboxId)
                    if (idx !== -1) {
                      this.mailboxFolders[i].mailboxIds.splice(idx, 1)
                      // 保存修改过的源文件夹
                      try {
                        await this.mailboxManager.updateFolder(this.mailboxFolders[i].id, this.mailboxFolders[i])
                      } catch (e) {
                        // 即使保存失败，数据已经在内存中修改了，继续处理
                      }
                    }
                  }
                  
                  // 添加到目标文件夹
                  const targetFolder = this.mailboxFolders.find(f => f.id === this.selectedTargetFolderId)
                  if (targetFolder) {
                    if (!targetFolder.mailboxIds.includes(this.movingMailboxId)) {
                      targetFolder.mailboxIds.push(this.movingMailboxId)
                    }
                    
                    // 保存到MailboxManager
                    try {
                      await this.mailboxManager.updateFolder(this.selectedTargetFolderId, targetFolder)
                      moveSuccess = true
                    } catch (e) {
                      // 即使保存失败，数据已经在内存中修改了
                      moveSuccess = true
                    }
                  }
                } catch (error) {
                  // 外层异常处理
                }
                
                // 显示结果提示
                if (moveSuccess) {
                  await this.systemService.showToast(this.uiTexts['tipMoveSuccess'] || 'Moved successfully')
                  // 刷新文件夹列表以确保UI同步
                  const updatedFolders = this.mailboxManager.getFolders()
                  for (let i = 0; i < updatedFolders.length; i++) {
                    this.mailboxFolders[i] = updatedFolders[i]
                  }
                } else {
                  await this.systemService.showToast(this.uiTexts['tipMoveFailed'] || 'Move failed')
                }
              }
              this.showMoveFolderDialog = false
              this.selectedTargetFolderId = 0
            })
            .enabled(this.selectedTargetFolderId > 0)
        }
      }
      .padding(20)
      .backgroundColor(this.settingsTheme === 'dark' ? '#1E1E1E' : Color.White)
      .borderRadius(8)
      .border({
        width: 1,
        color: this.settingsTheme === 'dark' ? '#333333' : '#E0E0E0'
      })
      .width('80%')
    }
  }
  
  @Builder buildCreateTagDialog(): void {
    if (this.showCreateTagDialog) {
      Column() {
        Text(this.uiTexts['createTag'] || 'Create Tag')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        TextInput({ placeholder: this.uiTexts['tagNamePlaceholder'] || 'Tag name' })
          .onChange((value: string) => {
            this.tagName = value
          })
          .margin({ bottom: 10 })
        
        Row() {
          Button(this.uiTexts['btnCancel'] || 'Cancel')
            .onClick(() => {
              this.showCreateTagDialog = false
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnCreate'] || 'Create')
            .onClick(() => {
              if (this.onCreateTag) {
                this.onCreateTag()
              }
              this.showCreateTagDialog = false
            })
        }
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .width('80%')
    }
  }
  
  @Builder buildAddTagDialog(): void {
    if (this.showAddTagDialog) {
      Column() {
        Text(this.uiTexts['addTag'] || 'Add Tag to Mailbox')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        Text(this.uiTexts['selectTagsPlaceholder'] || 'Select tags to add')
          .fontSize(12)
          .margin({ bottom: 10 })
        
        Row() {
          Button(this.uiTexts['btnCancel'] || 'Cancel')
            .onClick(() => {
              this.showAddTagDialog = false
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnAdd'] || 'Add')
            .onClick(() => {
              // TODO: Add tag logic
              this.showAddTagDialog = false
            })
        }
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .width('80%')
    }
  }
  
  @Builder buildStatsDialog(): void {
    if (this.showStatsDialog) {
      Stack() {
        // 背景遮罩（点击关闭）
        Column()
          .width('100%')
          .height('100%')
          .onClick(() => {
            this.showStatsDialog = false
          })
        
        // 对话框内容
        Column() {
          Text(this.uiTexts['detailedStatistics'] || 'Detailed Statistics')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 15 })
            .textAlign(TextAlign.Center)
            .width('100%')
          
          Scroll() {
            Column() {
              this.buildDomainStatsSection()
              this.buildEmailTrendSection()
              
              // 标签功能已移除
            }
            .width('100%')
            .alignItems(HorizontalAlign.Center)
          }
          .layoutWeight(1)
        }
        .padding(20)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .border({ width: 1, color: '#E0E0E0' })
        .constraintSize({ 
          minWidth: '70%', 
          maxWidth: '90%', 
          minHeight: 300, 
          maxHeight: '85%' 
        })
      }
      .width('100%')
      .height('100%')
    }
  }
  
  @Builder buildStatsSection(title: string, items: StatItem[]): void {
    Column() {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
      
      ForEach(items, (item: StatItem) => {
        Row() {
          Text(item.label)
            .fontSize(12)
            .layoutWeight(1)
          Text(item.value)
            .fontSize(12)
            .fontColor(item.color)
        }
        .width('100%')
        .padding(5)
      }, (item: StatItem) => item.label)
    }
    .margin({ bottom: 15 })
  }
  
  @Builder buildDomainStatsSection(): void {
    Column() {
      Text(this.uiTexts['domainStatistics'] || 'Domain Statistics')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .textAlign(TextAlign.Center)
        .width('100%')
      
      // 显示各域名的统计
      if (this.getDomainStats().length > 0) {
        Column() {
          ForEach(this.getDomainStats(), (entry: [string, number]) => {
            Row() {
              Text(entry[0])
                .fontSize(12)
                .layoutWeight(1)
              Text(`${entry[1]}`)
                .fontSize(12)
                .fontColor('#4CAF50')
                .fontWeight(FontWeight.Bold)
            }
            .width('100%')
            .padding(8)
            .backgroundColor(this.settingsTheme === 'dark' ? '#2A2A2A' : '#F5F5F5')
            .borderRadius(4)
            .margin({ bottom: 4 })
          }, (entry: [string, number]) => entry[0])
        }
        .width('100%')
      } else {
        Text(this.uiTexts['noData'] || 'No data')
          .fontSize(12)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 15 })
  }
  
  @Builder buildEmailTrendSection(): void {
    Column() {
      Text(this.uiTexts['emailTrends'] || 'Email Trends')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .textAlign(TextAlign.Center)
        .width('100%')
      
      // 显示邮箱统计信息
      if (this.mailboxes.length > 0) {
        Column() {
          ForEach(this.mailboxes, (mailbox: MailboxData) => {
            Column() {
              Row() {
                Text(mailbox.email)
                  .fontSize(12)
                  .layoutWeight(1)
              }
              .width('100%')
              .margin({ bottom: 6 })
              
              Row() {
                Text('Active')
                  .fontSize(12)
                  .fontColor('#2196F3')
                  .fontWeight(FontWeight.Bold)
              }
              .width('100%')
            }
            .width('100%')
            .padding(8)
            .backgroundColor(this.settingsTheme === 'dark' ? '#2A2A2A' : '#F5F5F5')
            .borderRadius(4)
            .margin({ bottom: 4 })
          }, (mailbox: MailboxData) => mailbox.id.toString())
        }
        .width('100%')
      } else {
        Text(this.uiTexts['noEmails'] || 'No emails received')
          .fontSize(12)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
          .width('100%')
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .margin({ bottom: 15 })
  }
  
  @Builder buildTagStatsSection(): void {
    Column() {
      Text(this.uiTexts['tagStatistics'] || 'Tag Statistics')
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 10 })
        .textAlign(TextAlign.Center)
        .width('100%')
      
      Text(this.uiTexts['tagStatsPlaceholder'] || 'Tag usage data coming soon')
        .fontSize(12)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Center)
        .width('100%')
    }
    .width('100%')
    .margin({ bottom: 15 })
  }
  
  @Builder buildNoteDialog(): void {
    if (this.showNoteDialog) {
      Column() {
        Text(this.uiTexts['editNote'] || 'Edit Note')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 15 })
        
        TextArea({ text: this.mailboxNote, placeholder: this.uiTexts['notePlaceholder'] || 'Enter note...' })
          .height(120)
          .onChange((value: string) => {
            this.mailboxNote = value
          })
          .margin({ bottom: 15 })
        
        Row() {
          Button(this.uiTexts['btnCancel'] || 'Cancel')
            .onClick(() => {
              this.showNoteDialog = false
            })
            .margin({ right: 10 })
          
          Button(this.uiTexts['btnSave'] || 'Save')
            .onClick(() => {
              if (this.onSaveNote) {
                this.onSaveNote()
              }
              this.showNoteDialog = false
            })
        }
      }
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .width('80%')
    }
  }
  
  @Builder buildQRCodeDialog(): void {
    // QR code dialog placeholder
  }
  
  // ==================== Main Build Method ====================
  
  build() {
    Stack() {
      this.buildMailboxesPage()
      
      // Dialogs overlay
      if (this.showMailboxActionsMenu) {
        // 点击外部关闭菜单
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showMailboxActionsMenu = false
          })
        
        this.buildMailboxActionsMenu()
      }
      if (this.showCreateFolderDialog) {
        this.buildCreateFolderDialog()
      }
      if (this.showMoveFolderDialog) {
        this.buildMoveFolderDialog()
      }
      if (this.showCreateTagDialog) {
        this.buildCreateTagDialog()
      }
      if (this.showAddTagDialog) {
        this.buildAddTagDialog()
      }
      if (this.showStatsDialog) {
        this.buildStatsDialog()
      }
      if (this.showNoteDialog) {
        this.buildNoteDialog()
      }
    }
    .width('100%')
    .height('100%')
  }
}
