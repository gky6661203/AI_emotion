import router from '@ohos.router';
import { EmotionReport, EmotionDistributionItem } from '../models/Types';
import { apiService } from '../services/ApiService';



interface RecentRecord {
  emotion?: string;
  content?: string;
  created_at?: string;
  intensity?: number;
  risk_detected?: boolean;
}

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
      // Header
      Row() {
        Text('<')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('情绪报告')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 10 })

        Blank()

        Button('刷新')
          .fontSize(13)
          .backgroundColor('#4A90D9')
          .borderRadius(14)
          .height(28)
          .margin({ right: 15 })
          .onClick(() => this.loadReport())
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: 'rgba(0,0,0,0.05)',
        offsetY: 2
      })

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#4A90D9')
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#F8F9FA')
      } else if (this.report) {
        Scroll() {
          Column() {
            this.SummaryCard()
            this.ReportSummaryCard()
            this.EmotionDistributionCard()
            this.RecentRecordsCard()
          }
          .padding(15)
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F8F9FA')
      } else {
        Column() {
          Column() {
            Text('📊')
              .fontSize(60)
              .margin({ top: 60 })
            Text('暂无报告数据')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ top: 15 })
            Button('创建匿名用户')
              .width(160)
              .height(44)
              .backgroundColor('#4A90D9')
              .borderRadius(22)
              .fontColor('#FFFFFF')
              .margin({ top: 25 })
              .onClick(() => this.initUser())
          }
          .layoutWeight(1)
        }
        .width('100%')
        .backgroundColor('#F8F9FA')
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
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      Row() {
        Column() {
          Text(this.getEmotionEmoji(this.report?.dominant_emotion || 'neutral'))
            .fontSize(32)
          Text(this.report?.dominant_emotion || 'neutral')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4A90D9')
            .margin({ top: 6 })
          Text('主要情绪')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })

        Column() {
          Text((this.report?.average_intensity || 0).toFixed(2))
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF9500')
          Text('平均强度')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })

        Column() {
          Text((this.report?.total_records || 0).toString())
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
          Text('记录数')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })
      }
      .width('100%')
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 3
    })
    .margin({ bottom: 15 })
  }

  @Builder
  ReportSummaryCard() {
    Column() {
      Text('支持性总结')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
      Text(this.report?.summary || '暂无总结')
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 10 })
        .width('100%')
      if (this.report?.keywords && this.report.keywords.length > 0) {
        Text(`关键词：${this.report.keywords.join('、')}`)
          .fontSize(13)
          .fontColor('#4A90D9')
          .margin({ top: 10 })
          .width('100%')
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 3
    })
    .margin({ bottom: 15 })
  }

  @Builder
  EmotionDistributionCard() {
    Column() {
      Text('情绪分布')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)

      if (this.report?.emotion_distribution && this.report.emotion_distribution.length > 0) {
        Column() {
          ForEach(this.report?.emotion_distribution || [], (item: EmotionDistributionItem) => {
            Row() {
              Text(this.getEmotionEmoji(item.emotion))
                .fontSize(18)
                .width(32)

              Text(item.emotion)
                .fontSize(14)
                .fontColor('#666666')
                .width(60)

              Column() {
                Row() {
                  Rect()
                    .width(Math.max(20, (item.count / (this.report?.total_records || 1)) * 180))
                    .height(8)
                    .fill(this.getEmotionColor(item.emotion))
                    .borderRadius(4)
                }
                .width('100%')
                .justifyContent(FlexAlign.Start)
              }
              .layoutWeight(1)
              .margin({ left: 10, right: 10 })

              Text(item.count.toString())
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .width(30)
              Text('次')
                .fontSize(12)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
          })
        }
        .width('100%')
        .margin({ top: 14 })
      } else {
        Text('暂无数据')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .margin({ top: 16, bottom: 16 })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 3
    })
    .margin({ bottom: 15 })
  }

  @Builder
  RecentRecordsCard() {
    Column() {
      Text('最近记录')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 12 })

      if (this.report?.recent_records && this.report.recent_records.length > 0) {
        ForEach(this.report.recent_records.slice(0, 5), (record: RecentRecord, index: number) => {
          Row() {
            Text(this.getEmotionEmoji(record.emotion || 'neutral'))
              .fontSize(22)
              .width(40)

            Column() {
              Text(record.emotion || 'unknown')
                .fontSize(14)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
              Text(record.created_at ? record.created_at.split('T')[0] : '')
                .fontSize(12)
                .fontColor('#999999')
                .margin({ top: 2 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            if (record.risk_detected) {
              Text('⚠️')
                .fontSize(18)
                .backgroundColor('#FFF3E0')
                .padding(6)
                .borderRadius(8)
            }
          }
          .width('100%')
          .padding({ top: 10, bottom: 10 })
          .border({
            width: { bottom: index < Math.min(this.report?.recent_records?.length || 0, 5) - 1 ? 1 : 0 },
            color: '#F5F5F5'
          })
        })
      } else {
        Text('暂无记录')
          .fontSize(14)
          .fontColor('#CCCCCC')
          .padding({ top: 16, bottom: 16 })
      }
    }
    .width('100%')
    .padding(18)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .shadow({
      radius: 10,
      color: 'rgba(0,0,0,0.06)',
      offsetX: 0,
      offsetY: 3
    })
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