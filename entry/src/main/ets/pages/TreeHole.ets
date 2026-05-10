import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PrivateLetter } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct TreeHole {
  @State letters: PrivateLetter[] = [];
  @State newTitle: string = '';
  @State newContent: string = '';
  @State isLoading: boolean = false;
  @State keyword: string = '';
  @State allowAiAnalysis: boolean = true;
  @State writeToProfile: boolean = true;
  @State statusText: string = '还没有树洞';

  aboutToAppear() {
    this.loadLetters();
  }

  async loadLetters() {
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.listLetters(this.keyword || undefined);
      this.letters = result.letters;
      this.statusText = this.letters.length > 0 ? `已加载 ${this.letters.length} 封树洞` : '还没有树洞';
    } catch (error) {
      this.statusText = '加载失败，请检查后端是否启动';
      console.error('Failed to load letters:', error);
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .rotate({ angle: 180 })
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('私密树洞')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 10 })

        Blank()

        Button('刷新')
          .height(32)
          .backgroundColor('#4A90D9')
          .fontColor('#FFFFFF')
          .borderRadius(16)
          .margin({ right: 15 })
          .onClick(() => {
            this.statusText = '正在刷新树洞...';
            this.loadLetters();
          })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .shadow({ radius: 4, color: 'rgba(0,0,0,0.05)', offsetY: 2 })

      Scroll() {
        Column() {
          Column() {
            Text('写下一点心事')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')

            TextInput({ placeholder: '标题（可选）', text: this.newTitle })
              .width('100%')
              .height(48)
              .backgroundColor('#F8F9FA')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .fontSize(15)
              .margin({ top: 16 })
              .onChange((value: string) => this.newTitle = value)

            TextArea({ placeholder: '在这里写下你的心事，我会用心倾听...', text: this.newContent })
              .width('100%')
              .height(180)
              .backgroundColor('#F8F9FA')
              .borderRadius(12)
              .padding(16)
              .fontSize(15)
              .margin({ top: 12 })
              .onChange((value: string) => {
                this.newContent = value;
                this.statusText = `正在编辑，字数 ${this.newContent.length}`;
              })

            Row() {
              Text('允许 AI 分析')
                .fontSize(13)
                .fontColor('#666666')
              Toggle({ type: ToggleType.Switch, isOn: this.allowAiAnalysis })
                .onChange((isOn: boolean) => this.allowAiAnalysis = isOn)
              Blank()
              Text('写入情绪报告')
                .fontSize(13)
                .fontColor('#666666')
              Toggle({ type: ToggleType.Switch, isOn: this.writeToProfile })
                .onChange((isOn: boolean) => this.writeToProfile = isOn)
            }
            .width('100%')
            .margin({ top: 12 })

            Text(`内容字数：${this.newContent.length}`)
              .fontSize(12)
              .fontColor('#888888')
              .margin({ top: 12 })

            Button(this.isLoading ? '发布中...' : '发布')
              .width('100%')
              .height(48)
              .backgroundColor(this.newContent.trim().length > 0 ? '#4CAF50' : '#CCCCCC')
              .fontColor('#FFFFFF')
              .fontSize(15)
              .fontWeight(FontWeight.Medium)
              .borderRadius(24)
              .margin({ top: 14 })
              .enabled(this.newContent.trim().length > 0 && !this.isLoading)
              .onClick(() => this.createLetter())

            Text(this.statusText)
              .fontSize(12)
              .fontColor('#888888')
              .margin({ top: 10 })
          }
          .width('100%')
          .padding({ left: 15, right: 15, top: 16, bottom: 12 })
          .backgroundColor('#FFFFFF')
          .borderRadius(16)
          .shadow({ radius: 8, color: 'rgba(0,0,0,0.04)', offsetY: 2 })

          if (this.letters.length === 0) {
            Column() {
              Text('📮')
                .fontSize(60)
                .margin({ top: 18 })
              Text('还没有树洞')
                .fontSize(18)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 10 })
              Text('写下你的第一个心事吧')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .width('100%')
            .padding({ top: 24, bottom: 18 })
          } else {
            Column() {
              ForEach(this.letters, (letter: PrivateLetter) => {
                this.LetterCard(letter)
              })
            }
            .width('100%')
            .margin({ top: 12 })
          }
        }
        .width('100%')
        .padding({ left: 15, right: 15, top: 12, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F8F9FA')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  LetterCard(letter: PrivateLetter) {
    Column() {
      Row() {
        Column() {
          if (letter.title) {
            Text(letter.title)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }

          Text(letter.content)
            .fontSize(14)
            .fontColor('#666666')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: letter.title ? 6 : 0 })
        }
        .layoutWeight(1)
      }

      Row() {
        if (letter.emotion) {
          Row() {
            Text(this.getEmotionEmoji(letter.emotion))
              .fontSize(12)
            Text(letter.emotion)
              .fontSize(12)
              .fontColor('#666666')
              .margin({ left: 4 })
          }
          .backgroundColor(this.getEmotionColor(letter.emotion) + '20')
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .borderRadius(10)
        }

        Blank()

        Text(letter.created_at.split('T')[0])
          .fontSize(12)
          .fontColor('#999999')

        Text('删除')
          .fontSize(12)
          .fontColor('#F44336')
          .margin({ left: 12 })
          .onClick(() => this.deleteLetter(letter.id))
      }
      .margin({ top: 12 })
      .width('100%')
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(14)
    .shadow({ radius: 8, color: 'rgba(0,0,0,0.06)', offsetX: 0, offsetY: 2 })
    .margin({ bottom: 12 })
  }

  async createLetter() {
    if (!this.newContent.trim()) {
      this.statusText = '请输入内容后再发布';
      promptAction.showToast({ message: '请输入内容' });
      return;
    }

    this.isLoading = true;
    this.statusText = '正在准备发布...';

    try {
      await apiService.ensureAnonymousUser();
      this.statusText = '正在发布...';
      let result = await apiService.createLetter(this.newContent, this.newTitle || undefined, this.allowAiAnalysis, this.writeToProfile);
      this.letters.unshift(result.letter);
      this.newTitle = '';
      this.newContent = '';
      this.statusText = '发布成功';
      promptAction.showToast({ message: '树洞已发布' });
    } catch (error) {
      this.statusText = '发布失败，请检查后端连接';
      promptAction.showToast({ message: '发布失败' });
      console.error('Failed to create letter:', error);
    } finally {
      this.isLoading = false;
    }
  }

  async deleteLetter(id: string) {
    try {
      await apiService.deleteLetter(id);
      this.letters = this.letters.filter((letter: PrivateLetter) => letter.id !== id);
    } catch (error) {
      console.error('Failed to delete letter:', error);
    }
  }

  getEmotionEmoji(emotion: string): string {
    let emojiMap: Record<string, string> = {
      'happy': '😊', 'sad': '😢', 'angry': '😠',
      'anxious': '😰', 'lonely': '😔', 'neutral': '😐'
    };
    return emojiMap[emotion] || '😐';
  }

  getEmotionColor(emotion: string): string {
    let colorMap: Record<string, string> = {
      'happy': '#4CAF50', 'sad': '#2196F3', 'angry': '#F44336',
      'anxious': '#FF9800', 'lonely': '#9C27B0', 'neutral': '#9E9E9E'
    };
    return colorMap[emotion] || '#9E9E9E';
  }
}
