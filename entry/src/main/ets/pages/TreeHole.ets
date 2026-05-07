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

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('私密树洞')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 10 })

        Blank()

        Button('写一封')
          .fontSize(14)
          .backgroundColor('#4CAF50')
          .borderRadius(15)
          .height(32)
          .margin({ right: 15 })
          .onClick(() => this.showCreateDialog = true)
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')

      if (this.letters.length === 0) {
        Column() {
          Text('📮')
            .fontSize(60)
            .margin({ top: 100 })
          Text('还没有树洞')
            .fontSize(18)
            .fontColor('#666666')
            .margin({ top: 20 })
          Text('写下你的第一个心事吧')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
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
        .padding(10)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

    if (this.showCreateDialog) {
      Column() {
        Column() {
          Row() {
            Text('写树洞')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
            Blank()
            Text('X')
              .fontSize(20)
              .onClick(() => this.showCreateDialog = false)
          }
          .width('100%')
          .padding(15)

          TextInput({ placeholder: '标题（可选）' })
            .width('100%')
            .height(40)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ top: 10 })
            .onChange((value: string) => this.newTitle = value)

          TextArea({ placeholder: '在这里写下你的心事...' })
            .width('100%')
            .height(200)
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .margin({ top: 10 })
            .onChange((value: string) => this.newContent = value)

          Row() {
            Button('取消')
              .width('45%')
              .height(40)
              .backgroundColor('#E0E0E0')
              .fontColor('#666666')
              .borderRadius(20)
              .onClick(() => this.showCreateDialog = false)

            Button('发布')
              .width('45%')
              .height(40)
              .backgroundColor('#4CAF50')
              .fontColor('#FFFFFF')
              .borderRadius(20)
              .margin({ left: '10%' })
              .enabled(this.newContent.length > 0 && !this.isLoading)
              .onClick(() => this.createLetter())
          }
          .width('100%')
          .margin({ top: 20 })
        }
        .width('90%')
        .backgroundColor('#FFFFFF')
        .borderRadius(15)
        .padding(20)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#80000000')
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
  }

  @Builder
  LetterCard(letter: PrivateLetter) {
    Column() {
      if (letter.title) {
        Text(letter.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Text(letter.content)
        .fontSize(14)
        .fontColor('#666666')
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: letter.title ? 8 : 0 })

      Row() {
        if (letter.emotion) {
          Text(this.getEmotionEmoji(letter.emotion))
            .fontSize(12)
          Text(letter.emotion)
            .fontSize(12)
            .fontColor('#666666')
            .margin({ left: 4 })
        }

        Blank()

        Text(letter.created_at.split('T')[0])
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ top: 10 })
      .width('100%')
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#FFFFFF')
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  async createLetter() {
    if (!this.newContent.trim()) return;

    this.isLoading = true;

    try {
      let result = await apiService.createLetter(this.newContent, this.newTitle || undefined);
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

  getEmotionEmoji(emotion: string): string {
    let emojiMap: Record<string, string> = {
      'happy': '😊',
      'sad': '😢',
      'angry': '😠',
      'anxious': '😰',
      'lonely': '😔',
      'neutral': '😐'
    };
    return emojiMap[emotion] || '😐';
  }
}