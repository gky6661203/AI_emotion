import router from '@ohos.router';
import { PrivateLetter } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct TreeHole {
  @State letters: PrivateLetter[] = [];
  @State showCreateDialog: boolean = false;
  @State newTitle: string = '';
  @State newContent: string = '';
  @State isLoading: boolean = false;
  @State keyword: string = '';
  @State allowAiAnalysis: boolean = true;
  @State writeToProfile: boolean = true;

  aboutToAppear() {
    this.loadLetters();
  }

  async loadLetters() {
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.listLetters(this.keyword || undefined);
      this.letters = result.letters;
    } catch (error) {
      console.error('Failed to load letters:', error);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column() {
        // Header
        Row() {
          Text('<')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
            .margin({ left: 15 })
            .onClick(() => router.back())

          Text('私密树洞')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
            .margin({ left: 10 })

          Blank()

          Button('写一封')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#4CAF50')
            .borderRadius(16)
            .height(32)
            .margin({ right: 8 })
            .onClick(() => this.showCreateDialog = true)

          Button('刷新')
            .fontSize(14)
            .backgroundColor('#4A90D9')
            .borderRadius(16)
            .height(32)
            .margin({ right: 15 })
            .onClick(() => this.loadLetters())
        }
        .width('100%')
        .height(56)
        .backgroundColor('#FFFFFF')
        .shadow({
          radius: 4,
          color: 'rgba(0,0,0,0.05)',
          offsetY: 2
        })

        if (this.letters.length === 0) {
          Column() {
            Column() {
              Text('📮')
                .fontSize(70)
                .margin({ top: 80 })
              Text('还没有树洞')
                .fontSize(18)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)
                .margin({ top: 20 })
              Text('写下你的第一个心事吧')
                .fontSize(14)
                .fontColor('#999999')
                .margin({ top: 8 })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .backgroundColor('#F8F9FA')
        } else {
          List() {
            ForEach(this.letters, (letter: PrivateLetter) => {
              ListItem() {
                this.LetterCard(letter)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
          .padding({ left: 15, right: 15, top: 12 })
          .backgroundColor('#F8F9FA')
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFFFFF')

      if (this.showCreateDialog) {
        Column() {
          Column() {
            Row() {
              Text('写树洞')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
              Blank()
              Text('✕')
                .fontSize(20)
                .fontColor('#999999')
                .onClick(() => this.showCreateDialog = false)
            }
            .width('100%')
            .padding(20)
            .border({
              width: { bottom: 1 },
              color: '#F0F0F0'
            })

            TextInput({ placeholder: '标题（可选）' })
              .width('100%')
              .height(48)
              .backgroundColor('#F8F9FA')
              .borderRadius(12)
              .padding({ left: 16, right: 16 })
              .fontSize(15)
              .margin({ top: 16 })
              .onChange((value: string) => this.newTitle = value)

            TextArea({ placeholder: '在这里写下你的心事，我会用心倾听...' })
              .width('100%')
              .height(180)
              .backgroundColor('#F8F9FA')
              .borderRadius(12)
              .padding(16)
              .fontSize(15)
              .margin({ top: 12 })
              .onChange((value: string) => this.newContent = value)

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

            Row() {
              Button('取消')
                .width('45%')
                .height(48)
                .backgroundColor('#F5F5F5')
                .fontColor('#666666')
                .fontSize(15)
                .borderRadius(24)
                .onClick(() => this.showCreateDialog = false)

              Button('发布')
                .width('45%')
                .height(48)
                .backgroundColor(this.newContent.length > 0 ? '#4CAF50' : '#CCCCCC')
                .fontColor('#FFFFFF')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .borderRadius(24)
                .margin({ left: '10%' })
                .enabled(this.newContent.length > 0 && !this.isLoading)
                .onClick(() => this.createLetter())
            }
            .width('100%')
            .margin({ top: 20 })
          }
          .width('92%')
          .backgroundColor('#FFFFFF')
          .borderRadius(20)
        }
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.5)')
        .justifyContent(FlexAlign.Center)
      }
    }
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
    .shadow({
      radius: 8,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 2
    })
    .margin({ bottom: 12 })
  }

  async createLetter() {
    if (!this.newContent.trim()) return;

    this.isLoading = true;

    try {
      let result = await apiService.createLetter(this.newContent, this.newTitle || undefined, this.allowAiAnalysis, this.writeToProfile);
      this.letters.unshift(result.letter);
      this.showCreateDialog = false;
      this.newTitle = '';
      this.newContent = '';
    } catch (error) {
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