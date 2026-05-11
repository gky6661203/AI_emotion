import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';

interface SafetyResourceItem {
  title: string;
  description?: string;
  url?: string;
}

interface SafetyResourcesResponse {
  resources?: SafetyResourceItem[];
  message?: string;
}

@Entry
@Component
struct SafetyHelp {
  @State isLoading: boolean = true;
  @State message: string = '如果你现在不太安全，请先把自己放到更安全的地方。';
  @State resources: SafetyResourceItem[] = [];
  @State emergencyTips: string[] = [
    '先把自己移动到更安全、有人在的地方',
    '把手机放在手边，联系一个可信任的人',
    '先不要一个人硬扛，允许自己求助'
  ];
  @State showQuickCall: boolean = false;
  @State actionStatus: string = '先稳住当下，再做下一步';

  aboutToAppear() {
    this.loadResources();
  }

  async loadResources() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      let result = await apiService.getSafetyResources() as SafetyResourcesResponse;
      this.resources = result.resources || [];
      this.message = result.message || this.message;
      this.actionStatus = this.resources.length > 0 ? '已准备好可执行资源' : this.actionStatus;
    } catch (error) {
      console.error('Load safety resources failed:', error);
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.arrow_right'))
          .width(24)
          .height(24)
          .fillColor('#333333')
          .rotate({ angle: 180 })
          .onClick(() => router.back())

        Text('安全帮助')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ left: 10 })

        Blank()

        Button('刷新')
          .height(30)
          .fontSize(12)
          .backgroundColor('#EDE7FF')
          .fontColor('#7658F6')
          .borderRadius(15)
          .onClick(() => this.loadResources())
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Scroll() {
        Column() {
          Column() {
            Text('先保证此刻安全')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#201B34')
              .width('100%')
            Text(this.message)
              .fontSize(14)
              .fontColor('#666666')
              .lineHeight(22)
              .margin({ top: 10 })
            Text('先稳住自己，再决定下一步。').fontSize(12).fontColor('#8B849B').margin({ top: 8 })
            Text(this.actionStatus).fontSize(11).fontColor('#7B57FF').margin({ top: 8 })
          }
          .padding(16)
          .backgroundColor('#FFF6F6')
          .borderRadius(18)

          Button('联系身边可信任的人')
            .width('100%')
            .height(48)
            .margin({ top: 16 })
            .backgroundColor('#7658F6')
            .fontColor('#FFFFFF')
            .borderRadius(16)
            .onClick(() => {
              this.showQuickCall = true;
              this.actionStatus = '先联系一个你信任的人';
              promptAction.showToast({ message: '请优先联系家人、朋友、辅导员或室友' });
            })

          Row() {
            Button('去安全资源')
              .layoutWeight(1)
              .height(44)
              .backgroundColor('#F3ECFF')
              .fontColor('#7658F6')
              .borderRadius(16)
              .onClick(() => {
                this.actionStatus = this.resources.length > 0 ? '正在查看可执行资源' : '先做三件事，再看资源';
                promptAction.showToast({ message: '先做三件事' });
              })
            Button('返回首页')
              .layoutWeight(1)
              .height(44)
              .margin({ left: 10 })
              .backgroundColor('#FFF1F1')
              .fontColor('#C94E4E')
              .borderRadius(16)
              .onClick(() => router.replaceUrl({ url: 'pages/Index' }))
          }.width('100%').margin({ top: 10 })

          if (this.showQuickCall) {
            Column() {
              Text('现在可以做的三件事').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 10 })
              ForEach(this.emergencyTips, (tip: string, index: number) => {
                Row() {
                  Text(`${index + 1}`).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#7658F6')
                  Text(tip)
                    .fontSize(13)
                    .fontColor('#666666')
                    .lineHeight(20)
                    .margin({ left: 10 })
                    .width('100%')
                }
                .width('100%')
                .padding(16)
                .backgroundColor('#FFFFFF')
                .borderRadius(16)
                .margin({ bottom: 12 })
              })
            }.padding(16).backgroundColor('#FFFFFF').borderRadius(18).margin({ top: 16 })
          }

          Text('可先做的事')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#201B34')
            .margin({ top: 24, bottom: 10 })
            .width('100%')

          ForEach(this.emergencyTips, (tip: string, index: number) => {
            Row() {
              Text(`${index + 1}`).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#7658F6')
              Text(tip)
                .fontSize(13)
                .fontColor('#666666')
                .lineHeight(20)
                .margin({ left: 10 })
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ bottom: 12 })
          })

          ForEach(this.resources, (item: SafetyResourceItem) => {
            Column() {
              Text(item.title)
                .fontSize(15)
                .fontWeight(FontWeight.Medium)
                .fontColor('#201B34')
                .width('100%')
              Text(item.description || '')
                .fontSize(13)
                .fontColor('#666666')
                .lineHeight(20)
                .margin({ top: 6 })
                .width('100%')
              if (item.url) {
                Text(item.url)
                  .fontSize(11)
                  .fontColor('#7B57FF')
                  .margin({ top: 8 })
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor('#FFFFFF')
            .borderRadius(16)
            .margin({ bottom: 12 })
          })
        }
        .width('100%')
        .padding(16)
      }
      .layoutWeight(1)
      .backgroundColor('#F4F1FF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }
}
