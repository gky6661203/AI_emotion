import router from '@ohos.router';

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @State userNickname: string = '新用户';
  @State recentEmotion: string = 'neutral';

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        this.HomeTab()
      }
      .tabBar('首页')

      TabContent() {
        this.ChatTab()
      }
      .tabBar('聊天')

      TabContent() {
        this.TreeHoleTab()
      }
      .tabBar('树洞')

      TabContent() {
        this.VoiceTab()
      }
      .tabBar('语音')

      TabContent() {
        this.SettingsTab()
      }
      .tabBar('设置')
    }
    .barHeight(60)
    .onChange((index) => {
      this.currentTab = index;
    })
  }

  @Builder
  HomeTab() {
    Column() {
      Row() {
        Text('校园树洞')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 20, top: 20 })
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)

      Column() {
        Column() {
          Text(`你好，${this.userNickname}`)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 10 })

          Text('今天感觉怎么样？')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .padding(20)
        .backgroundColor('#F5F5F5')
        .borderRadius(15)
        .margin({ top: 20, left: 15, right: 15 })
      }

      Column() {
        Text('快捷入口')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 20, bottom: 15 })

        Row() {
          this.QuickEntry('AI 聊天', '💬', () => router.pushUrl({ url: 'pages/Chat' }))
          this.QuickEntry('私密树洞', '📮', () => router.pushUrl({ url: 'pages/TreeHole' }))
          this.QuickEntry('语音记录', '🎤', () => router.pushUrl({ url: 'pages/VoiceRecord' }))
          this.QuickEntry('情绪报告', '📊', () => router.pushUrl({ url: 'pages/EmotionReport' }))
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  QuickEntry(title: string, emoji: string, callback: () => void) {
    Column() {
      Text(emoji)
        .fontSize(28)
      Text(title)
        .fontSize(12)
        .margin({ top: 5 })
    }
    .width(70)
    .height(70)
    .backgroundColor('#F0F0F0')
    .borderRadius(12)
    .justifyContent(FlexAlign.Center)
    .onClick(callback)
  }

  @Builder
  ChatTab() {
    Column() {
      Text('AI 陪伴')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })

      Column() {
        Text('💬')
          .fontSize(60)
          .margin({ top: 50 })
        Text('随时在这里倾听你')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 15 })
        Button('开始聊天')
          .margin({ top: 30 })
          .width(200)
          .height(45)
          .backgroundColor('#4A90D9')
          .borderRadius(22)
          .fontColor('#FFFFFF')
          .onClick(() => router.pushUrl({ url: 'pages/Chat' }))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  TreeHoleTab() {
    Column() {
      Text('私密树洞')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })

      Column() {
        Text('📮')
          .fontSize(60)
          .margin({ top: 50 })
        Text('写下你的心事')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 15 })
        Button('创建树洞')
          .margin({ top: 30 })
          .width(200)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(22)
          .fontColor('#FFFFFF')
          .onClick(() => router.pushUrl({ url: 'pages/TreeHole' }))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  VoiceTab() {
    Column() {
      Text('语音记录')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })

      Column() {
        Text('🎤')
          .fontSize(60)
          .margin({ top: 50 })
        Text('说出你的感受')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ top: 15 })
        Button('开始录音')
          .margin({ top: 30 })
          .width(200)
          .height(45)
          .backgroundColor('#FF6B6B')
          .borderRadius(22)
          .fontColor('#FFFFFF')
          .onClick(() => router.pushUrl({ url: 'pages/VoiceRecord' }))
      }
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SettingsTab() {
    Column() {
      Text('设置')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 15, bottom: 15 })

      List() {
        ListItem() {
          Row() {
            Text('设备管理')
              .fontSize(16)
            Blank()
            Text('>')
              .fontColor('#999999')
          }
          .width('100%')
          .padding(15)
        }

        ListItem() {
          Row() {
            Text('隐私设置')
              .fontSize(16)
            Blank()
            Text('>')
              .fontColor('#999999')
          }
          .width('100%')
          .padding(15)
        }

        ListItem() {
          Row() {
            Text('关于我们')
              .fontSize(16)
            Blank()
            Text('>')
              .fontColor('#999999')
          }
          .width('100%')
          .padding(15)
        }
      }
      .width('100%')
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .margin({ left: 15, right: 15 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}