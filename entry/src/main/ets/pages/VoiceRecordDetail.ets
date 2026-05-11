import router from '@ohos.router';
import { VoiceRecord } from '../models/Types';

@Entry
@Component
struct VoiceRecordDetail {
  @State record: VoiceRecord | null = null;
  @State isPlaying: boolean = false;
  @State playProgress: number = 0;
  @State playHint: string = '可在这里演示播放状态';

  aboutToAppear() {
    const params = router.getParams() as Record<string, VoiceRecord>;
    this.record = params?.record || null;
  }

  build() {
    Column() {
      Row() {
        Text('录音详情').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button('返回').onClick(() => router.back())
      }.width('100%').padding(16)

      if (this.record) {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text('🎤').fontSize(24)
                Column() {
                  Text(`录音 ${this.formatDuration(this.record.duration_seconds || 0)}`)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  Text(this.record.created_at.split('T')[0]).fontSize(12).fontColor('#888888').margin({ top: 4 })
                }.alignItems(HorizontalAlign.Start).margin({ left: 10 })
              }.width('100%')

              Row() {
                this.StateBadge('转写', this.record.transcription_status || '待处理')
                this.StateBadge('分析', this.record.analysis_status || '待处理')
                if (this.record.emotion) {
                  Text(`${this.record.emotion} ${this.record.emotion_intensity ? `· ${Math.round(this.record.emotion_intensity * 100)}%` : ''}`)
                    .fontSize(12)
                    .fontColor('#7B57FF')
                    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
                    .backgroundColor('#F1ECFF')
                    .borderRadius(12)
                    .margin({ left: 8 })
                }
              }.width('100%').margin({ top: 14 })

              Row() {
                Button(this.isPlaying ? '暂停演示播放' : '播放演示录音')
                  .fontSize(12)
                  .height(32)
                  .backgroundColor('#7B57FF')
                  .fontColor('#FFFFFF')
                  .borderRadius(16)
                  .onClick(() => this.togglePlay())
                Text(this.playHint).fontSize(11).fontColor('#8B849B').margin({ left: 12 })
              }.margin({ top: 14 }).width('100%')

              if (this.isPlaying) {
                Text(`播放进度：${this.playProgress}%`).fontSize(11).fontColor('#7B57FF').margin({ top: 8 })
              }
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)

            if (this.record.transcript) {
              Column() {
                Text('转写内容').fontSize(14).fontWeight(FontWeight.Bold)
                Text(this.record.transcript).fontSize(13).fontColor('#555555').margin({ top: 8 })
              }.margin({ top: 16 }).padding(14).backgroundColor('#FAFAFA').borderRadius(12)
            }

            Column() {
              Text('演示说明').fontSize(14).fontWeight(FontWeight.Bold)
              Text('当前语音页使用的是演示型录音适配层，后续会替换为真机麦克风录音。')
                .fontSize(11)
                .fontColor('#8B849B')
                .margin({ top: 8 })
            }.margin({ top: 16 }).padding(14).backgroundColor('#FFFFFF').borderRadius(12)
          }
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }

  @Builder
  StateBadge(title: string, value: string) {
    Row() {
      Text(title).fontSize(11).fontColor('#888888')
      Text(value).fontSize(11).fontColor('#7B57FF').margin({ left: 6 })
    }.padding({ left: 10, right: 10, top: 5, bottom: 5 }).backgroundColor('#FAF8FF').borderRadius(12).margin({ right: 8 })
  }

  togglePlay() {
    this.isPlaying = !this.isPlaying;
    this.playHint = this.isPlaying ? '正在演示播放录音...' : '可在这里演示播放状态';
    if (this.isPlaying) {
      this.playProgress = 0;
      const timer = setInterval(() => {
        if (!this.isPlaying) {
          clearInterval(timer);
          return;
        }
        this.playProgress = Math.min(100, this.playProgress + 12);
        if (this.playProgress >= 100) {
          this.isPlaying = false;
          this.playHint = '演示播放完成';
          clearInterval(timer);
        }
      }, 250);
    }
  }

  formatDuration(seconds: number): string {
    let mins = Math.floor(seconds / 60);
    let secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
}
