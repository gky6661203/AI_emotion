import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { VoiceRecord } from '../models/Types';
import { apiService } from '../services/ApiService';
import { VoiceRecorder } from '../services/VoiceRecorder';

@Entry
@Component
struct VoiceRecordPage {
  @State isRecording: boolean = false;
  @State recordingDuration: number = 0;
  @State voiceRecords: VoiceRecord[] = [];
  @State currentTranscript: string = '';
  @State currentEmotion: string = '';
  @State statusText: string = '点击开始录音';
  @State currentUploadState: string = '';
  @State isBusy: boolean = false;
  @State hasPermissionHint: boolean = false;
  @State recordHint: string = '按下中间按钮，开始记录此刻';
  @State pulseScale: number = 1;
  @State pulseOpacity: number = 0.14;
  private timerId: number = -1;
  private pulseTimerId: number = -1;
  private recorder: VoiceRecorder = new VoiceRecorder();

  aboutToAppear() {
    this.loadVoiceRecords();
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    if (this.pulseTimerId !== -1) {
      clearInterval(this.pulseTimerId);
      this.pulseTimerId = -1;
    }
  }

  async loadVoiceRecords() {
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.listVoiceRecords(50);
      this.voiceRecords = result.voice_records;
    } catch (error) {
      console.error('Failed to load voice records:', error);
    }
  }

  build() {
    Column() {
      // Header
      Row() {
        Image($r('app.media.arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .rotate({ angle: 180 })
          .margin({ left: 15 })
          .onClick(() => router.back())

        Column() {
          Text('语音记录')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text('适合不想打字的时候，先说出来')
            .fontSize(11)
            .fontColor('#999999')
            .margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 10 })
        
        Blank()

        Button('刷新')
          .height(30)
          .fontSize(11)
          .backgroundColor('#F1ECFF')
          .fontColor('#7B57FF')
          .borderRadius(15)
          .margin({ right: 15 })
          .onClick(() => this.loadVoiceRecords())
      }
      .width('100%')
      .height(64)
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
            .fontWeight(FontWeight.Lighter)
            .fontColor(this.isRecording ? '#FF6B6B' : '#333333')

          Text(this.statusText)
            .fontSize(14)
            .fontColor(this.isRecording ? '#FF6B6B' : '#999999')
            .margin({ top: 10 })
          Text(this.recordHint)
            .fontSize(11)
            .fontColor('#8B849B')
            .margin({ top: 6 })
          if (this.currentUploadState) {
            Text(this.currentUploadState)
              .fontSize(12)
              .fontColor('#7B57FF')
              .margin({ top: 6 })
          }
          if (this.hasPermissionHint) {
            Text('提示：正式录音接入后，这里会申请麦克风权限并生成真实文件。')
              .fontSize(11)
              .fontColor('#8B849B')
              .margin({ top: 6 })
              .width('80%')
          }
        }
        .margin({ top: 32 })

        // Record button
        Stack({ alignContent: Alignment.Center }) {
          if (this.isRecording) {
            Circle()
              .width(106 * this.pulseScale)
              .height(106 * this.pulseScale)
              .fill('#FF6B6B')
              .opacity(this.pulseOpacity)

            Circle()
              .width(90)
              .height(90)
              .fill('#FF6B6B')

            Column() {
              Rect()
                .width(24)
                .height(24)
                .fill('#FFFFFF')
                .borderRadius(4)
            }
            .onClick(() => this.stopRecording())
          } else {
            Circle()
              .width(106)
              .height(106)
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
        .margin({ top: 34 })

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
                  Text(this.getEmotionLabel(this.currentEmotion))
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
          .margin({ top: 24 })
        }

        // History section
        if (this.voiceRecords.length > 0) {
          Column() {
            Row() {
              Text('历史录音')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
              Blank()
              Text(`${this.voiceRecords.length} 条`).fontSize(11).fontColor('#999999')
            }
            .width('92%')
            .margin({ top: 24, bottom: 12 })

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

        Row() {
          Text(record.created_at.split('T')[0])
            .fontSize(12)
            .fontColor('#999999')
          if (record.emotion) {
            Text(` · ${this.getEmotionLabel(record.emotion)}`)
              .fontSize(12)
              .fontColor('#7B57FF')
          }
        }
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
        Button('详情')
          .fontSize(10)
          .height(26)
          .margin({ top: 8 })
          .onClick(() => router.pushUrl({ url: 'pages/VoiceRecordDetail', params: { record } }))
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
    if (this.isBusy) {
      return;
    }
    this.isRecording = true;
    this.recordingDuration = 0;
    this.currentTranscript = '';
    this.currentEmotion = '';
    this.currentUploadState = '';
    this.statusText = '录音中...';
    this.recordHint = '录音结束后会自动上传、转写和分析';
    this.hasPermissionHint = true;
    this.recorder.start().catch((error: Error) => {
      console.error('Start recorder failed:', error);
      this.statusText = '录音初始化失败';
      this.isRecording = false;
      this.hasPermissionHint = false;
      promptAction.showToast({ message: '无法启动录音' });
    });

    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
    if (this.pulseTimerId !== -1) {
      clearInterval(this.pulseTimerId);
    }
    this.pulseTimerId = setInterval(() => {
      if (!this.isRecording) {
        this.pulseScale = 1;
        this.pulseOpacity = 0.14;
        return;
      }
      this.pulseScale = this.pulseScale >= 1.08 ? 1 : this.pulseScale + 0.02;
      this.pulseOpacity = this.pulseOpacity >= 0.26 ? 0.12 : this.pulseOpacity + 0.02;
    }, 160);
    this.timerId = setInterval(() => {
      if (this.isRecording) {
        this.recordingDuration++;
      }
    }, 1000);
  }

  stopRecording() {
    if (!this.isRecording || this.isBusy) {
      return;
    }
    this.isRecording = false;
    this.isBusy = true;
    this.pulseScale = 1;
    this.pulseOpacity = 0.14;
    this.hasPermissionHint = false;
    this.recordHint = '正在保存这段语音';

    this.recorder.stop().then((voiceResult) => {
      const mockUrl = voiceResult.fileUrl;
      const duration = voiceResult.durationSeconds;
      this.currentUploadState = '正在上传录音...';

      return apiService.uploadVoiceRecord(mockUrl, duration).then((result) => {
        let record = result.voice_record;
        this.voiceRecords.unshift(record);
        this.currentUploadState = '录音已保存，正在转写...';

        if (record.id) {
          return apiService.transcribeVoice(record.id).then((transcribeResult) => {
            this.currentTranscript = transcribeResult.transcript;
            let index = this.voiceRecords.findIndex(r => r.id === record.id);
            if (index >= 0) {
              this.voiceRecords[index] = transcribeResult.voice_record;
            }
            this.currentUploadState = '转写完成，正在分析情绪...';
            this.analyzeRecord(record.id);
          }).catch((error: Error) => {
            console.error('Failed to transcribe voice:', error);
            this.currentUploadState = '转写失败，仍可继续分析';
            this.analyzeRecord(record.id);
          });
        }

        return undefined;
      });
    }).catch((error: Error) => {
      console.error('Stop recorder failed:', error);
      this.currentUploadState = '保存录音失败';
      this.recordHint = '可以重试一次，或者先回到首页整理心情';
      promptAction.showToast({ message: '保存失败' });
    }).finally(() => {
      this.isBusy = false;
    });

  }

  analyzeRecord(recordId: string) {
    apiService.analyzeVoice(recordId).then((result) => {
      this.currentEmotion = result.emotion;
      this.currentUploadState = `分析完成：${this.getEmotionLabel(result.emotion)}`;

      let index = this.voiceRecords.findIndex(r => r.id === recordId);
      if (index >= 0) {
        this.voiceRecords[index] = result.voice_record;
      }
    }).catch((error: Error) => {
      console.error('Failed to analyze voice:', error);
      this.currentUploadState = '分析失败';
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

  getEmotionLabel(emotion: string): string {
    let labelMap: Record<string, string> = {
      'happy': '愉悦', 'sad': '低落', 'angry': '烦躁',
      'anxious': '焦虑', 'lonely': '孤独', 'neutral': '平静'
    };
    return labelMap[emotion] || emotion || '未知';
  }
}