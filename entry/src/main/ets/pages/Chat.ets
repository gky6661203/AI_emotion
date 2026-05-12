import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import mediaquery from '@ohos.mediaquery';
import { ChatMessage } from '../models/Types';
import { apiService } from '../services/ApiService';
import { CommonTabBar } from '../components/CommonTabBar';

interface EmotionDetails {
  risk_level?: string;
  emotion?: string;
  summary?: string;
  response?: string;
}

interface EmotionAnalysisCarrier {
  emotion_analysis?: EmotionDetails;
}

@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State lastRiskLevel: string = 'low';
  @State emotionLabel: string = '平静';
  @State emotionHint: string = '你可以从一句“我今天有点累”开始。';
  @State showSafetyHelp: boolean = false;
  @State safetyMessage: string = '如果你现在很难受，请优先联系现实中的可信任支持者。';
  @State isAssistantTyping: boolean = false;
  @State isWatchLayout: boolean = false;
  private watchQuery: mediaquery.MediaQueryListener | null = null;
  scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.setupWatchQuery();
    this.initAndLoadMessages();
  }

  aboutToDisappear() {
    if (this.watchQuery) {
      this.watchQuery.off('change');
      this.watchQuery = null;
    }
  }

  private setupWatchQuery(): void {
    try {
      this.watchQuery = mediaquery.matchMediaSync('(max-width: 240vp)');
      this.isWatchLayout = this.watchQuery.matches;
      this.watchQuery.on('change', (result: mediaquery.MediaQueryResult) => {
        this.isWatchLayout = result.matches;
      });
    } catch (err) {
      console.error('setup watch media query failed', err);
      this.isWatchLayout = false;
    }
  }

  async initAndLoadMessages() {
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.listMessages(50);
      this.messages = result.messages;
      if (this.messages.length === 0) {
        this.messages = [this.createChatMessage('assistant', '你好，我在这里。你可以从一句“我今天有点累”开始。')];
      }
    } catch (error) {
      console.error('Failed to load messages:', error);
    }
  }

  private safeEmotionLabel(emotion: string): string {
    switch (emotion) {
      case 'happy': return '愉悦';
      case 'sad': return '低落';
      case 'angry': return '烦躁';
      case 'anxious': return '焦虑';
      case 'lonely': return '孤独';
      default: return '平静';
    }
  }

  private updateAnalysis(response: EmotionAnalysisCarrier): void {
    if (response.emotion_analysis) {
      this.lastRiskLevel = response.emotion_analysis.risk_level || 'low';
      this.emotionLabel = this.safeEmotionLabel(response.emotion_analysis.emotion || 'neutral');
      this.emotionHint = response.emotion_analysis.summary || response.emotion_analysis.response || this.emotionHint;
      if (this.lastRiskLevel === 'critical' || this.lastRiskLevel === 'high') {
        this.showSafetyHelp = true;
      }
    }
  }

  build() {
    if (this.isWatchLayout) {
      this.WatchChatPage()
    } else {
      Column() {
      // Header
      Row() {
        Image($r('app.media.arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .rotate({ angle: 180 })
          .margin({ left: 15 })
          .onClick(() => {
            try {
              router.back();
            } catch (err) {
              console.error('back failed', err);
            }
          })

        Text('AI 陪伴')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 10 })

        Blank()

        Row() {
          Circle()
            .width(8)
            .height(8)
            .fill('#4CAF50')
          Text('在线')
            .fontSize(12)
            .fontColor('#4CAF50')
            .margin({ left: 4 })
        }
        .backgroundColor('#E8F5E9')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
        .borderRadius(12)
        .margin({ right: 15 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: 'rgba(0,0,0,0.05)',
        offsetY: 2
      })

      Column() {
        Row() {
          Column() {
            Text('当前情绪').fontSize(11).fontColor('#8B849B')
            Text(this.emotionLabel).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#201B34')
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Text(`风险：${this.lastRiskLevel}`).fontSize(11).fontColor('#FF7A59')
        }.width('100%')
        Text(this.emotionHint).fontSize(12).fontColor('#7E788F').margin({ top: 6 }).width('100%')
      }.width('100%').padding(14).backgroundColor('#FFF').borderRadius(14)
        .margin({ left: 12, right: 12, top: 10 })

      // Messages List
      List({ scroller: this.scroller }) {
        ForEach(this.messages, (msg: ChatMessage) => {
          ListItem() {
            if (msg.role === 'user') {
              this.UserMessage(msg.content)
            } else {
              this.AIMessage(msg.content)
            }
          }
        })

        if (this.isAssistantTyping) {
          ListItem() {
            this.TypingIndicator()
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 10 })
      .backgroundColor('#F8F9FA')

      if (this.isAssistantTyping) {
        Row() {
          this.TypingIndicator()
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 4 })
        .backgroundColor('#F8F9FA')
      }

      Row() {
        this.QuickEmotion('有点累')
        this.QuickEmotion('很焦虑')
        this.QuickEmotion('想被听见')
        this.QuickEmotion('还不错')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8 })
      .backgroundColor('#FFFFFF')

      if (this.lastRiskLevel === 'medium' || this.lastRiskLevel === 'high' || this.lastRiskLevel === 'critical') {
        Column() {
          Text('如果你正处在危险中，请优先联系身边可信任的人或当地紧急求助资源。')
            .fontSize(12)
            .fontColor('#D9534F')
          Row() {
            Button('写入树洞').onClick(() => {
              try {
                router.pushUrl({ url: 'pages/TreeHole' });
              } catch (err) {
                console.error('pushUrl failed', err);
              }
            })
            Button('安全帮助').margin({ left: 8 }).onClick(() => this.openSafetyHelp())
          }.margin({ top: 8 })
          Text(this.safetyMessage).fontSize(12).fontColor('#B94A48').margin({ top: 8 })
        }.width('100%').padding(10).backgroundColor('#FFF3F3')
      }

      // Input Area
      Column() {
        Row() {
          TextInput({ placeholder: '消息', text: this.inputText })
            .layoutWeight(1)
            .height(42)
            .backgroundColor('#F5F2FF')
            .borderRadius(21)
            .padding({ left: 14, right: 14 })
            .fontSize(14)
            .fontColor('#201B34')
            .placeholderColor('#9A93AA')
            .onChange((value: string) => {
              this.inputText = value;
            })

          Button() {
            if (this.isLoading) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color('#FFFFFF')
            } else {
              Text('发')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
            }
          }
          .width(42)
          .height(42)
          .backgroundColor(this.inputText.trim().length > 0 ? '#7658F6' : '#C9C2D8')
          .borderRadius(21)
          .margin({ left: 8 })
          .shadow({ radius: this.inputText.trim().length > 0 ? 10 : 0, color: '#7658F644', offsetY: 4 })
          .enabled(this.inputText.trim().length > 0 && !this.isLoading)
          .onClick(() => this.sendMessage())
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 8, bottom: 10 })
        .backgroundColor('#FFFFFF')
        Blank()
        CommonTabBar()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
  }
}

  @Builder
  WatchChatPage() {
    Column() {
      Row() {
        Text('‹').fontSize(24).fontColor('#201B34').onClick(() => {
          try {
            router.back();
          } catch (err) {
            console.error('back failed', err);
          }
        })
        Text(this.emotionLabel).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ left: 8 })
        Blank()
        Circle().width(8).height(8).fill('#4CAF50')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 6 })

      List({ scroller: this.scroller }) {
        ForEach(this.messages.slice(-6), (msg: ChatMessage) => {
          ListItem() {
            if (msg.role === 'user') {
              this.WatchUserMessage(msg.content)
            } else {
              this.WatchAIMessage(msg.content)
            }
          }
        })
        if (this.isAssistantTyping) {
          ListItem() {
            Text('AI 正在想...').fontSize(12).fontColor('#7B57FF').padding(10)
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12 })

      Row() {
        TextInput({ placeholder: '消息', text: this.inputText })
          .layoutWeight(1)
          .height(38)
          .fontSize(13)
          .backgroundColor('#F5F2FF')
          .borderRadius(19)
          .padding({ left: 12, right: 12 })
          .onChange((value: string) => { this.inputText = value; })
        Button('发')
          .width(38)
          .height(38)
          .fontSize(13)
          .fontColor('#FFFFFF')
          .backgroundColor(this.inputText.trim().length > 0 ? '#7658F6' : '#C9C2D8')
          .borderRadius(19)
          .margin({ left: 6 })
          .enabled(this.inputText.trim().length > 0 && !this.isLoading)
          .onClick(() => this.sendMessage())
      }
      .width('100%')
      .padding({ left: 10, right: 10, bottom: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FAF8FF')
  }

  @Builder
  WatchUserMessage(content: string) {
    Row() {
      Blank()
      Text(content)
        .fontSize(13)
        .fontColor('#FFFFFF')
        .lineHeight(18)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#7658F6')
        .borderRadius(14)
        .constraintSize({ maxWidth: 128 })
    }.width('100%').margin({ bottom: 6 })
  }

  @Builder
  WatchAIMessage(content: string) {
    Row() {
      Text(this.compactMessage(content))
        .fontSize(13)
        .fontColor('#201B34')
        .lineHeight(18)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .constraintSize({ maxWidth: 136 })
    }.width('100%').margin({ bottom: 6 })
  }

  private compactMessage(content: string): string {
    const value = (content || '').replace(/\n+/g, ' ');
    return value.length > 80 ? `${value.substring(0, 80)}...` : value;
  }

  @Builder
  QuickEmotion(text: string) {
    Text(text)
      .fontSize(12)
      .fontColor('#4A90D9')
      .backgroundColor('#E8F4FD')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .borderRadius(14)
      .margin({ right: 8 })
      .onClick(() => {
        this.inputText = text;
        this.sendMessage();
      })
  }

  @Builder
  UserMessage(content: string) {
    Row() {
      Blank()
      Column() {
        Text(content)
          .fontSize(15)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Normal)
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      }
      .backgroundColor('#4A90D9')
      .borderRadius(18)
      .borderRadius({
        topLeft: 18,
        topRight: 4,
        bottomLeft: 18,
        bottomRight: 18
      })
      .constraintSize({ maxWidth: '280vp' })
      .margin({ left: 50, bottom: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  AIMessage(content: string) {
    Row() {
      Column() {
        Text('🤖')
          .fontSize(24)
          .margin({ right: 8 })
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .shadow({
        radius: 6,
        color: 'rgba(0,0,0,0.08)',
        offsetX: 0,
        offsetY: 2
      })
      .alignItems(HorizontalAlign.Center)

      Column() {
        ForEach(this.splitMessage(content), (line: string) => {
          Text(line)
            .fontSize(15)
            .fontColor('#333333')
            .lineHeight(22)
            .padding({ bottom: 4 })
            .width('100%')
        })
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .borderRadius({
        topLeft: 4,
        topRight: 18,
        bottomLeft: 18,
        bottomRight: 18
      })
      .constraintSize({ maxWidth: '280vp' })
      .padding({ left: 14, right: 14, top: 10, bottom: 8 })
      .shadow({
        radius: 8,
        color: 'rgba(0,0,0,0.06)',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ left: 8, bottom: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Top)
  }

  private openSafetyHelp() {
    this.showSafetyHelp = true;
    apiService.getSafetyResources().then((resources) => {
      if (resources.message) {
        this.safetyMessage = resources.message;
        this.emotionHint = resources.message;
        try {
          promptAction.showToast({ message: resources.message });
        } catch (err) {
          console.error('showToast failed', err);
        }
      } else {
        this.safetyMessage = '已为你准备安全帮助资源';
        try {
          promptAction.showToast({ message: '已为你准备安全帮助资源' });
        } catch (err) {
          console.error('showToast failed', err);
        }
      }
    }).catch(() => {
      this.safetyMessage = '请优先联系现实中的可信任支持者';
      try {
        promptAction.showToast({ message: '请优先联系现实中的可信任支持者' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    });
  }

  private createChatMessage(role: string, content: string): ChatMessage {
    return {
      id: '',
      user_id: '',
      role: role,
      content: content,
      content_type: 'text',
      created_at: new Date().toISOString()
    };
  }

  async sendMessage() {
    if (!this.inputText.trim() || this.isLoading) return;

    let userMessage: ChatMessage = {
      id: '',
      user_id: '',
      role: 'user',
      content: this.inputText,
      content_type: 'text',
      created_at: new Date().toISOString()
    };

    this.messages.push(userMessage);
    let text = this.inputText;
    this.inputText = '';
    this.isLoading = true;
    this.isAssistantTyping = true;

    try {
      let response = await apiService.sendMessage(text);
      this.updateAnalysis(response as EmotionAnalysisCarrier);
      let aiContent = response.ai_response?.content || response.message.content || '谢谢你愿意和我说这些。';
      this.messages.push(this.createChatMessage('assistant', aiContent));
    } catch (error) {
      this.messages.push(this.createChatMessage('assistant', '抱歉，AI 服务暂时不可用。请稍后再试。'));
    } finally {
      this.isLoading = false;
      this.isAssistantTyping = false;
      this.scroller.scrollToIndex(this.messages.length - 1);
    }
  }

  @Builder
  TypingIndicator() {
    Row() {
      Column() {
        Text('🤖')
          .fontSize(24)
      }
      .width(40)
      .height(40)
      .backgroundColor('#FFFFFF')
      .borderRadius(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({
        radius: 6,
        color: 'rgba(0,0,0,0.08)',
        offsetX: 0,
        offsetY: 2
      })

      Row() {
        Text('正在思考')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ right: 8 })
        LoadingProgress().width(18).height(18)
      }
      .backgroundColor('#FFFFFF')
      .borderRadius(18)
      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
      .margin({ left: 8, bottom: 6 })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
  }

  private splitMessage(content: string): string[] {
    return (content || '').split(/\n+/).filter((line: string) => line.trim().length > 0);
  }
}
