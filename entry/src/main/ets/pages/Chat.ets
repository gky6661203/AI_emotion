import router from '@ohos.router';
import { ChatMessage } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State lastRiskLevel: string = 'low';
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
        Text('如果你正处在危险中，请优先联系身边可信任的人或当地紧急求助资源。')
          .fontSize(12)
          .fontColor('#D9534F')
          .backgroundColor('#FFF3F3')
          .padding(10)
          .width('100%')
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
              Image($r('app.media.voice'))
                .width(22)
                .height(22)
                .fillColor('#FFFFFF')
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
      if (response.emotion_analysis) {
        this.lastRiskLevel = response.emotion_analysis.risk_level;
      }
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