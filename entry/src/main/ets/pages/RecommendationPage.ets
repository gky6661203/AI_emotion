import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { Recommendation } from '../models/Types';

@Entry
@Component
struct RecommendationPage {
  @State recommendations: Recommendation[] = [];
  @State isLoading: boolean = true;
  @State statusText: string = '正在加载推荐';
  @State dominantEmotion: string = '';
  @State averageIntensity: number = 0;
  @State riskLevel: string = 'low';
  @State feedbackTargetType: string = '';
  @State feedbackTargetTitle: string = '';
  @State feedbackText: string = '';
  @State showFeedbackDialog: boolean = false;

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      const res = await apiService.getRecommendations(10);
      this.recommendations = res.recommendations || [];
      this.dominantEmotion = res.dominant_emotion || '';
      this.averageIntensity = res.average_intensity || 0;
      this.riskLevel = res.risk_level || 'low';
      this.statusText = this.recommendations.length > 0 ? '推荐已更新' : '暂无推荐';
    } catch (error) {
      console.error('Load recommendations failed:', error);
      this.statusText = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async submitFeedback() {
    if (!this.feedbackTargetType || !this.feedbackText.trim()) {
      promptAction.showToast({ message: '请先选择推荐并填写反馈' });
      return;
    }
    try {
      await apiService.sendRecommendationFeedback(
        this.feedbackTargetType,
        this.feedbackText.trim(),
        this.feedbackTargetTitle || undefined,
        undefined,
        `dominant=${this.dominantEmotion};risk=${this.riskLevel}`
      );
      this.showFeedbackDialog = false;
      this.feedbackText = '';
      promptAction.showToast({ message: '反馈已记录' });
    } catch (error) {
      console.error('Submit recommendation feedback failed:', error);
      promptAction.showToast({ message: '反馈提交失败' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('推荐页').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button('返回').onClick(() => router.back())
      }.width('100%').padding(16)

      Row() {
        Text(this.statusText).fontSize(12).fontColor('#888888')
        Blank()
        Button('刷新').onClick(() => this.load())
      }.padding({ left: 16, right: 16, bottom: 8 }).width('100%')

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        Scroll() {
          Column() {
            Column() {
              Text('当前建议状态').fontSize(16).fontWeight(FontWeight.Bold)
              Text(this.dominantEmotion ? `主要情绪：${this.dominantEmotion}` : '主要情绪：暂无').fontSize(13).margin({ top: 8 })
              Text(`平均强度：${this.averageIntensity.toFixed(2)}`).fontSize(13).margin({ top: 4 })
              Text(`风险等级：${this.riskLevel}`).fontSize(13).margin({ top: 4 })
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16 })

            Image($r('app.media.forest'))
              .width('100%')
              .height(160)
              .objectFit(ImageFit.Cover)
              .margin({ left: 16, right: 16, top: 14 })
              .borderRadius(16)

            Text('为你推荐').fontSize(16).fontWeight(FontWeight.Bold).margin({ left: 16, top: 16, bottom: 8 })
            ForEach(this.recommendations, (item: Recommendation) => {
              Column() {
                Row() {
                  Text(item.title).fontSize(15).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(`#${item.priority}`).fontSize(11).fontColor('#7B57FF')
                }.width('100%')
                Text(item.description || '温和陪伴和下一步建议').fontSize(13).fontColor('#666666').margin({ top: 8 })
                Row() {
                  Text(item.recommendation_type).fontSize(11).fontColor('#888888')
                  Blank()
                  Button('反馈').fontSize(11).height(28).onClick(() => {
                    this.feedbackTargetType = item.recommendation_type;
                    this.feedbackTargetTitle = item.title;
                    this.showFeedbackDialog = true;
                  })
                }.margin({ top: 10 }).width('100%')
              }
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(16)
              .margin({ left: 16, right: 16, bottom: 12 })
            }, (item: Recommendation) => `${item.title}-${item.priority}`)
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F7F4FF')
      }

      if (this.showFeedbackDialog) {
        Stack({ alignContent: Alignment.Center }) {
          Rect().width('100%').height('100%').fill('rgba(0,0,0,0.4)').onClick(() => { this.showFeedbackDialog = false; })
          Column() {
            Text('推荐反馈').fontSize(18).fontWeight(FontWeight.Bold)
            Text(this.feedbackTargetTitle).fontSize(12).fontColor('#7B57FF').margin({ top: 8 })
            TextArea({ placeholder: '这条推荐是否有帮助？哪里需要改进？', text: this.feedbackText })
              .height(110)
              .backgroundColor('#F5F5F5')
              .borderRadius(12)
              .margin({ top: 12 })
              .onChange((v: string) => this.feedbackText = v)
            Row() {
              Button('取消').backgroundColor('transparent').onClick(() => { this.showFeedbackDialog = false; })
              Blank()
              Button('提交').onClick(() => this.submitFeedback())
            }.margin({ top: 12 }).width('100%')
          }.width('85%').padding(20).backgroundColor('#FFFFFF').borderRadius(16)
        }.width('100%').height('100%').position({ x: 0, y: 0 }).zIndex(1000)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }
}
