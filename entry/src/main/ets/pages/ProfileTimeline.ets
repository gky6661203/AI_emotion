import router from '@ohos.router';
import { apiService } from '../services/ApiService';

interface TimelineStateVector {
  valence: number;
  arousal: number;
  dominance: number;
  social: number;
  cognitive: number;
}

interface TimelineCounts {
  emotion_records: number;
  posts: number;
  letters: number;
  voices: number;
}

interface TimelineItem {
  snapshot_date?: string;
  dominant_emotion: string;
  average_intensity: number;
  risk_rate: number;
  signal_summary: string;
  state_vector: TimelineStateVector;
  counts: TimelineCounts;
  created_at?: string;
}

@Entry
@Component
struct ProfileTimelinePage {
  @State timeline: TimelineItem[] = [];
  @State isLoading: boolean = true;
  @State days: number = 14;
  @State statusText: string = '画像趋势正在加载';

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    this.statusText = '正在生成画像快照';
    try {
      await apiService.ensureAnonymousUser();
      await apiService.createProfileSnapshot();
      const res = await apiService.getProfileTimeline(this.days);
      this.timeline = res.timeline || [];
      this.statusText = this.timeline.length > 0 ? '画像趋势已更新' : '暂无趋势数据';
    } catch (error) {
      console.error('Load profile timeline failed:', error);
      this.statusText = '趋势加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Text('画像趋势').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button('返回').onClick(() => router.back())
      }.width('100%').padding(16)

      Row() {
        Text(this.statusText).fontSize(12).fontColor('#888888')
        Blank()
        Text('7天').fontSize(11).fontColor(this.days === 7 ? '#FFF' : '#7B57FF').padding({ left: 8, right: 8, top: 4, bottom: 4 }).backgroundColor(this.days === 7 ? '#7B57FF' : '#F1ECFF').borderRadius(10).onClick(() => { this.days = 7; this.load(); })
        Text('14天').fontSize(11).fontColor(this.days === 14 ? '#FFF' : '#7B57FF').padding({ left: 8, right: 8, top: 4, bottom: 4 }).backgroundColor(this.days === 14 ? '#7B57FF' : '#F1ECFF').borderRadius(10).margin({ left: 8 }).onClick(() => { this.days = 14; this.load(); })
        Text('30天').fontSize(11).fontColor(this.days === 30 ? '#FFF' : '#7B57FF').padding({ left: 8, right: 8, top: 4, bottom: 4 }).backgroundColor(this.days === 30 ? '#7B57FF' : '#F1ECFF').borderRadius(10).margin({ left: 8 }).onClick(() => { this.days = 30; this.load(); })
      }.padding({ left: 16, right: 16, bottom: 8 }).width('100%')

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        Scroll() {
          Column() {
            if (this.timeline.length === 0) {
              Column() {
                Text('暂无画像快照').fontSize(15).fontColor('#888888')
                Button('生成一次快照').margin({ top: 12 }).onClick(() => this.load())
              }.padding(24).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16 })
            } else {
              ForEach(this.timeline, (item: TimelineItem) => {
                Column() {
                  Row() {
                    Text(item.snapshot_date || item.created_at?.split('T')[0] || '未知日期').fontSize(14).fontWeight(FontWeight.Bold)
                    Blank()
                    Text(item.dominant_emotion).fontSize(11).fontColor('#7B57FF')
                  }.width('100%')
                  Text(item.signal_summary).fontSize(13).fontColor('#666666').margin({ top: 8 })
                  Row() {
                    this.VectorMini('V', item.state_vector.valence)
                    this.VectorMini('A', item.state_vector.arousal)
                    this.VectorMini('D', item.state_vector.dominance)
                    this.VectorMini('S', item.state_vector.social)
                    this.VectorMini('C', item.state_vector.cognitive)
                  }.margin({ top: 10 })
                }
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .margin({ left: 16, right: 16, bottom: 12 })
              }, (item: TimelineItem) => item.snapshot_date || item.created_at || item.signal_summary)
            }
          }.width('100%').padding({ bottom: 20 })
        }.width('100%').layoutWeight(1).backgroundColor('#F7F4FF')
      }
    }.width('100%').height('100%').backgroundColor('#F7F4FF')
  }

  @Builder
  VectorMini(label: string, value: number) {
    Column() {
      Text(label).fontSize(9).fontColor('#9B96AC')
      Text(`${Math.round(value * 100)}`).fontSize(11).fontWeight(FontWeight.Bold).fontColor('#5B4C9B')
    }.padding({ left: 8, right: 8, top: 6, bottom: 6 }).backgroundColor('#FAF8FF').borderRadius(10).margin({ right: 6 })
  }
}
