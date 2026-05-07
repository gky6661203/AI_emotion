import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State userNickname: string = '同学';
  @State recentEmotion: string = 'neutral';
  @State greeting: string = this.getGreeting();

  getGreeting(): string {
    let hour = new Date().getHours();
    if (hour < 6) return '夜深了';
    if (hour < 9) return '早上好';
    if (hour < 12) return '上午好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    if (hour < 22) return '晚上好';
    return '夜深了';
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.HomeTab()
      }
      .tabBar(this.TabBarItem('首页', $r('sys.media.ohos_ic_home'), 0))

      TabContent() {
        this.ChatTab()
      }
      .tabBar(this.TabBarItem('聊天', $r('sys.media.ohos_ic_chat'), 1))

      TabContent() {
        this.TreeHoleTab()
      }
      .tabBar(this.TabBarItem('树洞', $r('sys.media.ohos_ic_mail'), 2))

      TabContent() {
        this.VoiceTab()
      }
      .tabBar(this.TabBarItem('语音', $r('sys.media.ohos_ic_voice'), 3))

      TabContent() {
        this.SettingsTab()
      }
      .tabBar(this.TabBarItem('设置', $r('sys.media.ohos_ic_settings'), 4))
    }
    .barHeight(65)
    .barBackgroundColor('#FFFFFF')
    .onChange((index) => {
      this.currentTab = index;
    })
  }

  @Builder
  TabBarItem(title: string, icon: Resource, index: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.currentTab === index ? '#4A90D9' : '#999999')
      Text(title)
        .fontSize(10)
        .fontColor(this.currentTab === index ? '#4A90D9' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  HomeTab() {
    Column() {
      // Header
      Row() {
        Column() {
          Text('校园树洞')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text(this.greeting)
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 20, top: 15 })

        Blank()

        // Avatar placeholder
        Circle()
          .width(44)
          .height(44)
          .fill('#E8F4FD')
          .margin({ right: 20 })
          .stroke('#4A90D9')
          .strokeWidth(2)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      // Welcome Card
      Column() {
        Row() {
          Column() {
            Text(`${this.greeting}，${this.userNickname}`)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            Text('今天感觉怎么样？')
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.85)')
              .margin({ top: 6 })
          }

          Blank()

          Text('🌟')
            .fontSize(36)
        }
        .width('100%')
        .padding(20)
      }
      .width('93%')
      .height(120)
      .backgroundColor('#4A90D9')
      .borderRadius(16)
      .shadow({
        radius: 12,
        color: 'rgba(74,144,217,0.25)',
        offsetX: 0,
        offsetY: 4
      })
      .margin({ top: 15 })

      // Quick Entry Section
      Column() {
        Text('快捷入口')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 25, bottom: 15 })

        Column() {
          Row() {
            this.QuickEntry('AI 聊天', '💬', '#4A90D9', () => router.pushUrl({ url: 'pages/Chat' }))
            this.QuickEntry('私密树洞', '📮', '#4CAF50', () => router.pushUrl({ url: 'pages/TreeHole' }))
            this.QuickEntry('语音记录', '🎤', '#FF6B6B', () => router.pushUrl({ url: 'pages/VoiceRecord' }))
            this.QuickEntry('情绪报告', '📊', '#FF9500', () => router.pushUrl({ url: 'pages/EmotionReport' }))
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceEvenly)
        }
        .width('93%')
      }

      Blank()

      // Bottom tip
      Text('陪伴而不诊断，引导而不治疗')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }

  @Builder
  QuickEntry(title: string, emoji: string, color: string, callback: () => void) {
    Column() {
      Column() {
        Text(emoji)
          .fontSize(26)
      }
      .width(56)
      .height(56)
      .backgroundColor(color)
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .shadow({
        radius: 8,
        color: color + '40',
        offsetX: 0,
        offsetY: 3
      })

      Text(title)
        .fontSize(12)
        .fontColor('#666666')
        .margin({ top: 8 })
    }
    .width(70)
    .alignItems(HorizontalAlign.Center)
    .onClick(callback)
  }

  @Builder
  ChatTab() {
    Column() {
      Stack({ alignContent: Alignment.Top }) {
        Column() {
          Text('AI 陪伴')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ top: 15, bottom: 20 })
        }
        .width('100%')
      }
      .width('100%')

      Column() {
        Column() {
          Text('💬')
            .fontSize(70)
            .margin({ top: 60 })
          Text('随时在这里倾听你')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 15 })
          Text('分享你的想法，我会用心回应')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 6 })
        }
        .layoutWeight(1)

        Button('开始聊天')
          .width(200)
          .height(48)
          .backgroundColor('#4A90D9')
          .borderRadius(24)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 80 })
          .shadow({
            radius: 12,
            color: 'rgba(74,144,217,0.3)',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => router.pushUrl({ url: 'pages/Chat' }))
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  TreeHoleTab() {
    Column() {
      Text('私密树洞')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 15, bottom: 20 })

      Column() {
        Column() {
          Text('📮')
            .fontSize(70)
            .margin({ top: 60 })
          Text('写下你的心事')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 15 })
          Text('这里是你私密的空间')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 6 })
        }
        .layoutWeight(1)

        Button('创建树洞')
          .width(200)
          .height(48)
          .backgroundColor('#4CAF50')
          .borderRadius(24)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 80 })
          .shadow({
            radius: 12,
            color: 'rgba(76,175,80,0.3)',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => router.pushUrl({ url: 'pages/TreeHole' }))
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  VoiceTab() {
    Column() {
      Text('语音记录')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 15, bottom: 20 })

      Column() {
        Column() {
          Text('🎤')
            .fontSize(70)
            .margin({ top: 60 })
          Text('说出你的感受')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ top: 15 })
          Text('用声音记录此刻的心情')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 6 })
        }
        .layoutWeight(1)

        Button('开始录音')
          .width(200)
          .height(48)
          .backgroundColor('#FF6B6B')
          .borderRadius(24)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 80 })
          .shadow({
            radius: 12,
            color: 'rgba(255,107,107,0.3)',
            offsetX: 0,
            offsetY: 4
          })
          .onClick(() => router.pushUrl({ url: 'pages/VoiceRecord' }))
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')
    }
  }

  @Builder
  SettingsTab() {
    Column() {
      Text('设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .margin({ top: 15, bottom: 20 })

      List() {
        ListItem() {
          Row() {
            Text('👤')
              .fontSize(20)
              .margin({ right: 12 })
            Text('设备管理')
              .fontSize(16)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding(16)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 15, right: 15, bottom: 10 })

        ListItem() {
          Row() {
            Text('🔒')
              .fontSize(20)
              .margin({ right: 12 })
            Text('隐私设置')
              .fontSize(16)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding(16)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 15, right: 15, bottom: 10 })

        ListItem() {
          Row() {
            Text('ℹ️')
              .fontSize(20)
              .margin({ right: 12 })
            Text('关于我们')
              .fontSize(16)
              .fontColor('#333333')
            Blank()
            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .padding(16)
        }
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .margin({ left: 15, right: 15, bottom: 10 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F8F9FA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F8F9FA')
  }
}