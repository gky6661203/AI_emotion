import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';

interface MatchSuggestion {
  user_id: string;
  dominant_emotion: string;
  signal_summary: string;
  score: number;
  reason: string;
}

interface MatchRequestItem {
  id: string;
  match_type: string;
  note?: string;
  status: string;
  created_at: string;
}

@Entry
@Component
struct MatchPage {
  @State suggestions: MatchSuggestion[] = [];
  @State requests: MatchRequestItem[] = [];
  @State isLoading: boolean = true;
  @State statusText: string = '正在加载搭子建议';
  @State matchType: string = 'companion';
  @State note: string = '希望找到一个稳定、轻松、能互相支持的搭子。';
  @State showRequestPanel: boolean = true;
  @State loopHint: string = '从建议到请求，再到状态沉淀';

  aboutToAppear() {
    this.load();
  }

  async load() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      const suggestionRes = await apiService.getMatchSuggestions(10);
      const requestRes = await apiService.listMatchRequests();
      this.suggestions = suggestionRes.suggestions || [];
      this.requests = requestRes.requests || [];
      this.statusText = this.suggestions.length > 0 ? '已生成匹配建议' : '暂无匹配建议';
      this.loopHint = this.requests.length > 0 ? `当前有 ${this.requests.length} 个搭子请求在沉淀` : '还没有发起过搭子请求';
    } catch (error) {
      console.error('Load match suggestions failed:', error);
      this.statusText = '加载失败';
    } finally {
      this.isLoading = false;
    }
  }

  async requestMatch() {
    if (!this.note.trim()) {
      promptAction.showToast({ message: '请先写一点你的需求' });
      return;
    }
    try {
      const res = await apiService.createMatchRequest(this.matchType, this.note.trim());
      this.requests.unshift({
        id: res.request_id || `${Date.now()}`,
        match_type: this.matchType,
        note: this.note,
        status: 'open',
        created_at: new Date().toISOString()
      });
      this.showRequestPanel = false;
      this.loopHint = '请求已提交，可以继续看建议或刷新状态';
      promptAction.showToast({ message: '搭子请求已提交' });
    } catch (error) {
      console.error('Create match request failed:', error);
      promptAction.showToast({ message: '提交失败' });
    }
  }

  build() {
    Column() {
      Row() {
        Text('搭子匹配').fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button('返回').onClick(() => router.back())
      }.width('100%').padding(16)

      Row() {
        Text(this.statusText).fontSize(12).fontColor('#888888')
        Blank()
        Button('刷新建议').onClick(() => this.load())
      }.padding({ left: 16, right: 16, top: 8, bottom: 4 }).width('100%')

      Text(this.loopHint).fontSize(11).fontColor('#7B57FF').padding({ left: 16, right: 16, bottom: 8 })

      Row() {
        Button(this.showRequestPanel ? '收起请求面板' : '发起搭子请求')
          .layoutWeight(1)
          .height(38)
          .backgroundColor('#F3ECFF')
          .fontColor('#7658F6')
          .borderRadius(18)
          .onClick(() => { this.showRequestPanel = !this.showRequestPanel; })
        Button('刷新请求状态')
          .layoutWeight(1)
          .height(38)
          .margin({ left: 10 })
          .backgroundColor('#EEF8F1')
          .fontColor('#4F8A5B')
          .borderRadius(18)
          .onClick(() => this.load())
      }.padding({ left: 16, right: 16, bottom: 8 }).width('100%')

      if (this.showRequestPanel) {
        Column() {
          Row() {
            Text('发起一个搭子请求').fontSize(16).fontWeight(FontWeight.Bold)
            Blank()
            Text('先提交，再等待匹配').fontSize(11).fontColor('#8B849B')
          }.width('100%')
          TextInput({ placeholder: '匹配类型，比如 companion / study / exercise', text: this.matchType })
            .margin({ top: 10 })
            .height(44)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .onChange((v: string) => this.matchType = v)
          TextArea({ placeholder: '简单描述你想要的搭子', text: this.note })
            .margin({ top: 10 })
            .height(100)
            .backgroundColor('#F5F5F5')
            .borderRadius(12)
            .onChange((v: string) => this.note = v)
          Row() {
            Button('提交搭子请求').margin({ top: 12 }).onClick(() => this.requestMatch())
            Blank()
            Button('先看看建议').margin({ top: 12 }).onClick(() => { this.showRequestPanel = false; })
          }.width('100%')
        }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16 })
      }

      if (this.requests.length > 0) {
        Column() {
          Row() {
            Text('我的搭子请求').fontSize(16).fontWeight(FontWeight.Bold)
            Blank()
            Text(`${this.requests.length} 条`).fontSize(11).fontColor('#999999')
          }.width('100%').padding({ left: 16, right: 16, top: 16, bottom: 8 })
          ForEach(this.requests, (item: MatchRequestItem) => {
            Column() {
              Row() {
                Text(item.match_type).fontSize(14).fontWeight(FontWeight.Bold)
                Blank()
                Text(item.status).fontSize(11).fontColor('#7B57FF')
              }.width('100%')
              Text(item.note || '').fontSize(12).fontColor('#666666').margin({ top: 8 })
              Row() {
                Text(item.created_at.split('T')[0]).fontSize(11).fontColor('#999999')
                Blank()
                if (item.status !== 'closed') {
                  Button('结束请求').fontSize(10).height(26).onClick(async () => {
                    await apiService.closeMatchRequest(item.id);
                    await this.load();
                  })
                }
              }.width('100%').margin({ top: 6 })
            }.padding(14).backgroundColor('#FFFFFF').borderRadius(14).margin({ left: 16, right: 16, bottom: 10 })
          }, (item: MatchRequestItem) => item.id)
        }
      }

      if (this.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 40 })
      } else {
        Scroll() {
          Column() {
            Text('画像建议').fontSize(16).fontWeight(FontWeight.Bold).margin({ left: 16, top: 16, bottom: 8 })
            ForEach(this.suggestions, (item: MatchSuggestion) => {
              Column() {
                Row() {
                  Text(item.dominant_emotion).fontSize(15).fontWeight(FontWeight.Bold)
                  Blank()
                  Text(`${Math.round(item.score * 100)}%`).fontSize(11).fontColor('#7B57FF')
                }.width('100%')
                Text(item.signal_summary).fontSize(13).fontColor('#666666').margin({ top: 8 })
                Text(item.reason).fontSize(12).fontColor('#888888').margin({ top: 6 })
                Button('用这个搭子风格').fontSize(11).height(28).margin({ top: 10 }).onClick(() => {
                  this.matchType = item.dominant_emotion || 'companion';
                  this.note = `我想要一个和我当前状态更匹配的搭子，参考画像：${item.reason}`;
                  this.showRequestPanel = true;
                })
              }.padding(16).backgroundColor('#FFFFFF').borderRadius(16).margin({ left: 16, right: 16, bottom: 12 })
            }, (item: MatchSuggestion) => item.user_id)
          }.width('100%').padding({ bottom: 20 })
        }.width('100%').layoutWeight(1).backgroundColor('#F7F4FF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F1FF')
  }
}
