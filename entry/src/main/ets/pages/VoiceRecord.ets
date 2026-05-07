import router from '@ohos.router';
import { VoiceRecord } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct VoiceRecordPage {
  @State isRecording: boolean = false;
  @State recordingDuration: number = 0;
  @State voiceRecords: VoiceRecord[] = [];
  @State currentTranscript: string = '';
  @State currentEmotion: string = '';

  build() {
    Column() {
      Row() {
        Text('<')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('语音记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ left: 10 })
      }
      .width('100%')
      .height(50)
      .backgroundColor('#FFFFFF')

      Column() {
        Column() {
          Text(this.formatDuration(this.recordingDuration))
            .fontSize(48)
            .fontWeight(FontWeight.Light)
            .fontColor(this.isRecording ? '#FF6B6B' : '#333333')

          Text(this.isRecording ? '录音中...' : '点击开始录音')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ top: 10 })

          Row() {
            if (this.isRecording) {
              Circle()
                .width(80)
                .height(80)
                .fill('#FF6B6B')
                .onClick(() => this.stopRecording())
            } else {
              Circle()
                .width(80)
                .height(80)
                .fill('#4A90D9')
                .onClick(() => this.startRecording())
            }
          }
          .margin({ top: 40 })

          if (this.currentTranscript) {
            Column() {
              Text('转写结果')
                .fontSize(14)
                .fontColor('#666666')
                .alignSelf(ItemAlign.Start)
                .margin({ bottom: 8 })

              Text(this.currentTranscript)
                .fontSize(14)
                .fontColor('#333333')
                .width('100%')

              if (this.currentEmotion) {
                Row() {
                  Text('情绪: ')
                    .fontSize(12)
                    .fontColor('#666666')
                  Text(this.currentEmotion)
                    .fontSize(12)
                    .fontColor('#4A90D9')
                }
                .margin({ top: 10 })
                .alignSelf(ItemAlign.Start)
              }
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#F5F5F5')
            .borderRadius(10)
            .margin({ top: 30 })
          }
        }
        .padding(20)

        if (this.voiceRecords.length > 0) {
          Column() {
            Text('历史记录')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)
              .margin({ left: 15, bottom: 10 })

            List() {
              ForEach(this.voiceRecords, (record: VoiceRecord) => {
                ListItem() {
                  this.VoiceRecordItem(record)
                }
              })
            }
            .width('100%')
            .layoutWeight(1)
          }
        } else {
          Column() {
            Text('暂无录音记录')
              .fontSize(14)
              .fontColor('#999999')
          }
          .layoutWeight(1)
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder
  VoiceRecordItem(record: VoiceRecord) {
    Row() {
      Column() {
        Text(`录音 ${this.formatDuration(record.duration_seconds || 0)}`)
          .fontSize(14)
          .fontColor('#333333')

        Text(record.created_at.split('T')[0])
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }

      Blank()

      if (record.emotion) {
        Text(this.getEmotionEmoji(record.emotion))
          .fontSize(20)
      }

      Text(record.transcription_status === 'completed' ? '已转写' : '转写中')
        .fontSize(12)
        .fontColor(record.transcription_status === 'completed' ? '#4CAF50' : '#FFA500')
        .margin({ left: 10 })
    }
    .width('100%')
    .padding(15)
    .backgroundColor('#F5F5F5')
    .borderRadius(10)
    .margin({ bottom: 10 })
  }

  startRecording() {
    this.isRecording = true;
    this.recordingDuration = 0;

    let timer = setInterval(() => {
      this.recordingDuration++;
      if (!this.isRecording) {
        clearInterval(timer);
      }
    }, 1000);
  }

  stopRecording() {
    this.isRecording = false;

    let mockUrl = `file://temp/voice_${Date.now()}.m4a`;

    apiService.uploadVoiceRecord(mockUrl, this.recordingDuration).then(result => {
      this.voiceRecords.unshift(result.voice_record);

      this.currentTranscript = '这是一段模拟的语音转文字内容。';

      if (result.voice_record.id) {
        this.analyzeRecord(result.voice_record.id);
      }
    }).catch(error => {
      console.error('Failed to upload voice record:', error);
    });
  }

  analyzeRecord(recordId: string) {
    apiService.analyzeVoice(recordId).then(result => {
      this.currentEmotion = result.emotion;

      let index = this.voiceRecords.findIndex(r => r.id === recordId);
      if (index >= 0) {
        this.voiceRecords[index].emotion = result.emotion;
      }
    }).catch(error => {
      console.error('Failed to analyze voice:', error);
    });
  }

  formatDuration(seconds: number): string {
    let mins = Math.floor(seconds / 60);
    let secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
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