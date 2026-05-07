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
      // Header
      Row() {
        Text('<')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ left: 15 })
          .onClick(() => router.back())

        Text('语音记录')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 10 })
      }
      .width('100%')
      .height(56)
      .backgroundColor('#FFFFFF')
      .shadow({
        radius: 4,
        color: 'rgba(0,0,0,0.05)',
        offsetY: 2
      })

      Column() {
        // Timer display
        Column() {
          Text(this.formatDuration(this.recordingDuration))
            .fontSize(56)
            .fontWeight(FontWeight.Light)
            .fontColor(this.isRecording ? '#FF6B6B' : '#333333')

          Text(this.isRecording ? '录音中...' : '点击下方按钮开始录音')
            .fontSize(14)
            .fontColor(this.isRecording ? '#FF6B6B' : '#999999')
            .margin({ top: 10 })
        }
        .margin({ top: 40 })

        // Record button
        Stack({ alignContent: Alignment.Center }) {
          if (this.isRecording) {
            // Recording state - pulsing circle
            Circle()
              .width(90)
              .height(90)
              .fill('#FF6B6B')
              .opacity(0.2)

            Circle()
              .width(76)
              .height(76)
              .fill('#FF6B6B')

            Column() {
              Rectangle()
                .width(24)
                .height(24)
                .fill('#FFFFFF')
                .borderRadius(4)
            }
            .onClick(() => this.stopRecording())
          } else {
            // Idle state
            Circle()
              .width(90)
              .height(90)
              .fill('#4A90D9')
              .shadow({
                radius: 16,
                color: 'rgba(74,144,217,0.35)',
                offsetX: 0,
                offsetY: 6
              })

            Column() {
              Circle()
                .width(32)
                .height(32)
                .fill('#FFFFFF')
            }
            .onClick(() => this.startRecording())
          }
        }
        .margin({ top: 40 })

        // Transcript result
        if (this.currentTranscript) {
          Column() {
            Row() {
              Text('转写结果')
                .fontSize(14)
                .fontColor('#666666')
                .fontWeight(FontWeight.Medium)

              Blank()

              if (this.currentEmotion) {
                Row() {
                  Text(this.getEmotionEmoji(this.currentEmotion))
                    .fontSize(14)
                  Text(this.currentEmotion)
                    .fontSize(13)
                    .fontColor('#4A90D9')
                    .margin({ left: 4 })
                }
                .backgroundColor('#E8F4FD')
                .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                .borderRadius(12)
              }
            }
            .width('100%')

            Text(this.currentTranscript)
              .fontSize(14)
              .fontColor('#333333')
              .width('100%')
              .margin({ top: 12 })
          }
          .width('92%')
          .padding(16)
          .backgroundColor('#FFFFFF')
          .borderRadius(14)
          .shadow({
            radius: 8,
            color: 'rgba(0,0,0,0.06)',
            offsetX: 0,
            offsetY: 2
          })
          .margin({ top: 30 })
        }

        // History section
        if (this.voiceRecords.length > 0) {
          Column() {
            Text('历史录音')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .alignSelf(ItemAlign.Start)
              .margin({ left: 15, bottom: 12, top: 30 })

            List() {
              ForEach(this.voiceRecords, (record: VoiceRecord) => {
                ListItem() {
                  this.VoiceRecordItem(record)
                }
              })
            }
            .width('92%')
            .layoutWeight(1)
          }
        } else {
          Column() {
            Text('暂无录音记录')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .margin({ top: 60 })
          }
          .layoutWeight(1)
        }
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
  VoiceRecordItem(record: VoiceRecord) {
    Row() {
      Column() {
        Row() {
          Text('🎤')
            .fontSize(18)
          Text(`录音 ${this.formatDuration(record.duration_seconds || 0)}`)
            .fontSize(14)
            .fontColor('#333333')
            .margin({ left: 8 })
        }

        Text(record.created_at.split('T')[0])
          .fontSize(12)
          .fontColor('#999999')
          .margin({ left: 26, top: 4 })
      }

      Blank()

      if (record.emotion) {
        Text(this.getEmotionEmoji(record.emotion))
          .fontSize(24)
      }

      Column() {
        if (record.transcription_status === 'completed') {
          Text('已转写')
            .fontSize(12)
            .fontColor('#4CAF50')
        } else if (record.transcription_status === 'processing') {
          Text('转写中')
            .fontSize(12)
            .fontColor('#FFA500')
        } else {
          Text('待处理')
            .fontSize(12)
            .fontColor('#999999')
        }
      }
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 6,
      color: 'rgba(0,0,0,0.04)',
      offsetX: 0,
      offsetY: 1
    })
    .margin({ bottom: 10 })
  }

  startRecording() {
    this.isRecording = true;
    this.recordingDuration = 0;

    setInterval(() => {
      if (this.isRecording) {
        this.recordingDuration++;
      }
    }, 1000);
  }

  stopRecording() {
    this.isRecording = false;

    let mockUrl = `file://temp/voice_${Date.now()}.m4a`;

    apiService.uploadVoiceRecord(mockUrl, this.recordingDuration).then(result => {
      this.voiceRecords.unshift(result.voice_record);
      this.currentTranscript = '这是一段语音转文字的内容。';

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
      'happy': '😊', 'sad': '😢', 'angry': '😠',
      'anxious': '😰', 'lonely': '😔', 'neutral': '😐'
    };
    return emojiMap[emotion] || '😐';
  }
}