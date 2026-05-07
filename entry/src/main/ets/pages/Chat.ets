import router from '@ohos.router';
import { ChatMessage } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct Chat {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State scroller: Scroller = new Scroller();

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('AI 陪伴')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 10 })

        Blank()

        Text('AI')
          .fontSize(14)
          .fontColor('#4A90D9')
          .backgroundColor('#E8F4FD')
          .padding({ left: 10, right: 10, top: 3, bottom: 3 })
          .borderRadius(10)
          .margin({ right: 15 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 2, color: '#10000000' })

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
      .padding(10)
      .backgroundColor('#F5F5F5')

      Column() {
        Row() {
          TextInput({ placeholder: '输入消息...', text: this.inputText })
            .width('80%')
            .height(40)
            .backgroundColor('#FFFFFF')
            .borderRadius(20)
            .padding({ left: 15 })
            .onChange((value: string) => {
              this.inputText = value;
            })

          Button('发送')
            .width('18%')
            .height(40)
            .backgroundColor(this.inputText.length > 0 ? '#4A90D9' : '#CCCCCC')
            .borderRadius(20)
            .fontColor('#FFFFFF')
            .margin({ left: 10 })
            .enabled(this.inputText.length > 0 && !this.isLoading)
            .onClick(() => this.sendMessage())
        }
        .padding(10)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  UserMessage(content: string) {
    Row() {
      Blank()
      Text(content)
        .fontSize(16)
        .padding(12)
        .backgroundColor('#4A90D9')
        .foregroundColor('#FFFFFF')
        .borderRadius(15)
        .margin({ left: 60, bottom: 5 })
    }
    .width('100%')
    .justifyContent(FlexAlign.End)
  }

  @Builder
  AIMessage(content: string) {
    Row() {
      Text('🤖')
        .fontSize(20)
        .margin({ right: 8 })

      Text(content)
        .fontSize(16)
        .padding(12)
        .backgroundColor('#FFFFFF')
        .foregroundColor('#333333')
        .borderRadius(15)
        .shadow({ radius: 2, color: '#10000000' })
    }
    .width('100%')
    .justifyContent(FlexAlign.Start)
    .margin({ bottom: 5 })
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