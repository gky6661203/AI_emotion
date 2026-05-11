import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { PrivateLetter } from '../models/Types';

@Entry
@Component
struct TreeHoleDetail {
  @State letterId: string = '';
  @State letter: PrivateLetter | null = null;
  @State title: string = '';
  @State content: string = '';
  @State allowAiAnalysis: boolean = true;
  @State writeToProfile: boolean = true;
  @State isEditing: boolean = false;
  @State isLoading: boolean = true;
  @State statusText: string = '加载中';
  @State detailHint: string = '这里是只给自己看的安全空间';

  aboutToAppear() {
    interface LetterParams {
      letterId?: string;
    }
    try {
      const params = router.getParams() as LetterParams;
      this.letterId = params?.letterId || '';
    } catch (err) {
      console.error('getParams failed', err);
      this.letterId = '';
    }
    this.load();
  }

  async load() {
    if (!this.letterId) {
      this.isLoading = false;
      this.statusText = '未找到树洞';
      return;
    }
    try {
      await apiService.ensureAnonymousUser();
      const res = await apiService.listLetters();
      this.letter = (res.letters || []).find((item) => item.id === this.letterId) || null;
      if (this.letter) {
        this.title = this.letter.title || '';
        this.content = this.letter.content;
        this.allowAiAnalysis = this.letter.allow_ai_analysis;
        this.writeToProfile = this.letter.write_to_emotion_profile;
        this.statusText = this.letter.is_public ? '公开状态' : '私密状态';
        this.detailHint = this.letter.emotion ? `已识别到 ${this.letter.emotion}` : '尚未识别到情绪';
      } else {
        this.statusText = '树洞不存在或已删除';
      }
    } catch (error) {
      console.error('Load letter detail failed:', error);
      this.statusText = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async save() {
    if (!this.content.trim()) {
      try {
        promptAction.showToast({ message: '请输入内容' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }
    try {
      await apiService.updateLetter(this.letterId, this.content.trim(), this.title || undefined, this.allowAiAnalysis, this.writeToProfile);
      try {
        promptAction.showToast({ message: '树洞已保存' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      await this.load();
      this.isEditing = false;
    } catch (error) {
      console.error('Save letter failed:', error);
      try {
        promptAction.showToast({ message: '保存失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  async remove() {
    try {
      await apiService.deleteLetter(this.letterId);
      try {
        promptAction.showToast({ message: '树洞已删除' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      try {
        router.back();
      } catch (err) {
        console.error('back failed', err);
      }
    } catch (error) {
      console.error('Delete letter failed:', error);
      try {
        promptAction.showToast({ message: '删除失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  build() {
    Column() {
      Row() {
        Text('树洞详情').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button('返回').onClick(() => {
          try {
            router.back();
          } catch (err) {
            console.error('back failed', err);
          }
        })
      }.width('100%').padding(16)

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else if (this.letter) {
        Scroll() {
          Column() {
            Column() {
              Row() {
                Text(this.isEditing ? '编辑模式' : '查看模式').fontSize(12).fontColor('#7B57FF')
                Blank()
                Text(this.statusText).fontSize(11).fontColor('#888888')
              }.width('100%')

              Text(this.detailHint).fontSize(11).fontColor('#8B849B').margin({ top: 8 })

              TextInput({ placeholder: '标题（可选）', text: this.title })
                .height(44)
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .margin({ top: 14 })
                .enabled(this.isEditing)
                .onChange((v: string) => this.title = v)

              TextArea({ placeholder: '树洞内容', text: this.content })
                .height(180)
                .backgroundColor('#F5F5F5')
                .borderRadius(12)
                .margin({ top: 12 })
                .enabled(this.isEditing)
                .onChange((v: string) => this.content = v)

              Row() {
                Text('允许 AI 分析').fontSize(12)
                Toggle({ type: ToggleType.Switch, isOn: this.allowAiAnalysis })
                  .enabled(this.isEditing)
                  .onChange((isOn: boolean) => this.allowAiAnalysis = isOn)
                Blank()
                Text('写入情绪画像').fontSize(12)
                Toggle({ type: ToggleType.Switch, isOn: this.writeToProfile })
                  .enabled(this.isEditing)
                  .onChange((isOn: boolean) => this.writeToProfile = isOn)
              }.margin({ top: 12 })

              Row() {
                Button(this.isEditing ? '保存修改' : '进入编辑')
                  .layoutWeight(1)
                  .onClick(() => {
                    if (this.isEditing) {
                      this.save();
                    } else {
                      this.isEditing = true;
                    }
                  })
                Button('删除')
                  .layoutWeight(1)
                  .margin({ left: 10 })
                  .fontColor('#C94E4E')
                  .onClick(() => this.remove())
              }.margin({ top: 16 }).width('100%')

              Row() {
                Text(`创建时间：${this.letter.created_at}`).fontSize(11).fontColor('#888888')
                Blank()
                if (this.letter.emotion) {
                  Text(`${this.getEmotionEmoji(this.letter.emotion)} ${this.letter.emotion}`).fontSize(11).fontColor('#7B57FF')
                }
              }.width('100%').margin({ top: 12 })
            }
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ left: 16, right: 16 })

            if (this.letter.emotion_analysis) {
              Column() {
                Text('AI 分析').fontSize(14).fontWeight(FontWeight.Bold)
                Text(this.letter.emotion_analysis.summary || '暂无分析内容')
                  .fontSize(13)
                  .fontColor('#666666')
                  .margin({ top: 8 })
                if (this.letter.emotion_analysis.keywords && this.letter.emotion_analysis.keywords.length > 0) {
                  Text(`关键词：${this.letter.emotion_analysis.keywords.join('、')}`)
                    .fontSize(12)
                    .fontColor('#7B57FF')
                    .margin({ top: 8 })
                }
              }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16, top: 12 })
            }
          }
          .width('100%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .backgroundColor('#F4F1FF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }

  getEmotionEmoji(emotion: string): string {
    let emojiMap: Record<string, string> = {
      'happy': '😊', 'sad': '😢', 'angry': '😠',
      'anxious': '😰', 'lonely': '😔', 'neutral': '😐'
    };
    return emojiMap[emotion] || '😐';
  }
}
