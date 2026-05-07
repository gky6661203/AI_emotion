import router from '@ohos.router';
import { EmotionReport } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct EmotionReportPage {
  @State report: EmotionReport | null = null;
  @State isLoading: boolean = true;

  aboutToAppear() {
    this.loadReport();
  }

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('情绪报告')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 10 })

        Blank()

        Button('刷新')
          .fontSize(14)
          .backgroundColor('#4A90D9')
          .borderRadius(15)
          .height(32)
          .margin({ right: 15 })
          .onClick(() => this.loadReport())
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.report) {
        Scroll() {
          Column() {
            this.SummaryCard()

            this.EmotionDistributionCard()

            this.RecentRecordsCard()
          }
          .padding(15)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F5F5F5')
      } else {
        Column() {
          Text('暂无报告数据')
            .fontSize(16)
            .fontColor('#666666')

          Button('创建匿名用户')
            .margin({ top: 20 })
            .onClick(() => this.initUser())
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  SummaryCard() {
    Column() {
      Text('本周情绪概况')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)

      Row() {
        Column() {
          Text(this.report?.dominant_emotion || 'neutral')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')
          Text('主要情绪')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Column() {
          Text((this.report?.average_intensity || 0).toFixed(2))
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9500')
          Text('平均强度')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)

        Column() {
          Text((this.report?.total_records || 0).toString())
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('记录数')
            .fontSize(12)
            .fontColor('#666666')
        }
        .layoutWeight(1)
      }
      .margin({ top: 20 })
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .margin({ bottom: 15 })
  }

  @Builder
  EmotionDistributionCard() {
    Column() {
      Text('情绪分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 15 })

      if (this.report?.emotion_distribution) {
        ForEach(this.report?.emotion_distribution || [], (item: { emotion: string, count: number }) => {
          Row() {
            Text(this.getEmotionEmoji(item.emotion))
              .fontSize(16)
            Text(item.emotion)
              .fontSize(14)
              .margin({ left: 8 })
            Blank()
            Text(item.count.toString())
              .fontSize(14)
              .fontColor('#4A90D9')
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        })
      } else {
        Text('暂无数据')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .margin({ bottom: 15 })
  }

  @Builder
  RecentRecordsCard() {
    Column() {
      Text('最近记录')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 15 })

      if (this.report?.recent_records && this.report.recent_records.length > 0) {
        ForEach(this.report.recent_records.slice(0, 5), (record: any) => {
          Row() {
            Text(this.getEmotionEmoji(record.emotion))
              .fontSize(16)
            Column() {
              Text(record.emotion)
                .fontSize(14)
                .fontColor('#333333')
              Text(record.created_at.split('T')[0])
                .fontSize(12)
                .fontColor('#999999')
            }
            .margin({ left: 8 })
            .alignItems(HorizontalAlign.Start)
            Blank()
            if (record.risk_detected) {
              Text('⚠️')
                .fontSize(16)
            }
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        })
      } else {
        Text('暂无记录')
          .fontSize(14)
          .fontColor('#999999')
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor('#FFFFFF')
    .borderRadius(15)
    .margin({ bottom: 15 })
  }

  async loadReport() {
    this.isLoading = true;

    try {
      this.report = await apiService.getEmotionReport(7);
    } catch (error) {
      console.error('Failed to load report:', error);
      this.report = null;
    } finally {
      this.isLoading = false;
    }
  }

  async initUser() {
    try {
      await apiService.createAnonymous();
      this.loadReport();
    } catch (error) {
      console.error('Failed to create anonymous user:', error);
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