import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { ChatMessage } from '../models/Types';
import { apiService } from '../services/ApiService';

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
  scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.initAndLoadMessages();
  }

  async initAndLoadMessages() {
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.listMessages(50);
      this.messages = result.messages;
      if (this.messages.length === 0) {
        this.messages = [{
          id: '',
          user_id: '',
          role: 'assistant',
          content: '你好，我在这里。你可以从一句“我今天有点累”开始。',
          content_type: 'text',
          created_at: new Date().toISOString()
        }];
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
    Column() {
      // Header
      Row() {
        Image($r('app.media.arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .rotate({ angle: 180 })
          .margin({ left: 15 })
          .onClick(() => router.back())

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
        ForEach(this.messages, (msg: ChatMessage, index: number) => {
          ListItem() {
            if (msg.role === 'user') {
              this.UserMessage(msg.content)
            } else {
              this.AIMessage(msg.content)
            }
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 12, right: 12, top: 10 })
      .backgroundColor('#F8F9FA')

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
            Button('写入树洞').onClick(() => router.pushUrl({ url: 'pages/TreeHole' }))
            Button('安全帮助').margin({ left: 8 }).onClick(async () => {
              this.showSafetyHelp = true;
              try {
                const resources = await apiService.getSafetyResources();
                if (resources.message) {
                  this.safetyMessage = resources.message;
                  this.emotionHint = resources.message;
                  promptAction.showToast({ message: resources.message });
                } else {
                  this.safetyMessage = '已为你准备安全帮助资源';
                  promptAction.showToast({ message: '已为你准备安全帮助资源' });
                }
              } catch {
                this.safetyMessage = '请优先联系现实中的可信任支持者';
                promptAction.showToast({ message: '请优先联系现实中的可信任支持者' });
              }
            })
          }.margin({ top: 8 })
          Text(this.safetyMessage).fontSize(12).fontColor('#B94A48').margin({ top: 8 })
        }.width('100%').padding(10).backgroundColor('#FFF3F3')
      }

      // Input Area
      Column() {
        Row() {
          TextInput({ placeholder: '输入消息...', text: this.inputText })
            .width('100%')
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(22)
            .padding({ left: 18, right: 18 })
            .fontSize(15)
            .placeholderColor('#999999')
            .onChange((value: string) => {
              this.inputText = value;
            })

          Button() {
            if (this.isLoading) {
              LoadingProgress()
                .width(22)
                .height(22)
                .color('#FFFFFF')
            } else {
              Text('发送')
                .fontSize(13)
                .fontColor('#FFFFFF')
            }
          }
          .width(44)
          .height(44)
          .backgroundColor(this.inputText.length > 0 ? '#4A90D9' : '#CCCCCC')
          .borderRadius(22)
          .margin({ left: 10 })
          .enabled(this.inputText.length > 0 && !this.isLoading)
          .onClick(() => this.sendMessage())
        }
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
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
        Text(content)
          .fontSize(15)
          .fontColor('#333333')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
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

    let aiMessage: ChatMessage = {
      id: '',
      user_id: '',
      role: 'assistant',
      content: '思考中...',
      content_type: 'text',
      created_at: new Date().toISOString()
    };
    this.messages.push(aiMessage);

    try {
      let response = await apiService.sendMessage(text);
      this.updateAnalysis(response as EmotionAnalysisCarrier);
      let lastIndex = this.messages.length - 1;
      if (lastIndex >= 0 && this.messages[lastIndex].role === 'assistant') {
        if (response.ai_response) {
          this.messages[lastIndex] = response.ai_response;
        } else {
          this.messages[lastIndex].content = response.message.content;
        }
      }
    } catch (error) {
      let lastIndex = this.messages.length - 1;
      if (lastIndex >= 0 && this.messages[lastIndex].role === 'assistant') {
        this.messages[lastIndex].content = '抱歉，AI 服务暂时不可用。请稍后再试。';
      }
    } finally {
      this.isLoading = false;
      this.scroller.scrollToIndex(this.messages.length - 1);
    }
  }
}