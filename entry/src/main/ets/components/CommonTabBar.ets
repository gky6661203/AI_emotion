import mediaquery from '@ohos.mediaquery';
import router from '@ohos.router';

@Component
export struct CommonTabBar {
  @State currentTab: number = 0;
  @State isWatchLayout: boolean = false;
  private watchQuery: mediaquery.MediaQueryListener | null = null;

  aboutToAppear(): void {
    this.setupWatchQuery();
  }

  aboutToDisappear(): void {
    if (this.watchQuery) {
      this.watchQuery.off('change');
      this.watchQuery = null;
    }
  }

  private setupWatchQuery(): void {
    try {
      this.watchQuery = mediaquery.matchMediaSync('(max-width: 240vp)');
      this.isWatchLayout = this.watchQuery.matches;
      this.watchQuery.on('change', (result: mediaquery.MediaQueryResult) => {
        this.isWatchLayout = result.matches;
      });
    } catch (err) {
      this.isWatchLayout = false;
    }
  }

  private navigateTo(index: number): void {
    if (index === this.currentTab) {
      return;
    }
    this.currentTab = index;
    let url = '';
    switch (index) {
      case 0: url = 'pages/Index'; break;
      case 1: url = 'pages/Index'; break;
      case 2: url = 'pages/Chat'; break;
      case 3: url = 'pages/Index'; break;
      case 4: url = 'pages/Index'; break;
      default: url = 'pages/Index'; break;
    }
    try {
      router.replaceUrl({ url: url });
    } catch (err) {
      console.error('CommonTabBar router failed', err);
    }
  }

  @Builder
  TabItem(icon: Resource, label: string, n: number, isCenter: boolean = false) {
    Column() {
      if (isCenter) {
        Stack() {
          Circle().width(62).height(62).fill('#7655F6').shadow({ radius: 24, color: '#7655F666', offsetY: 8 })
          Circle().width(38).height(38).fill('#9B82FF').opacity(0.7)
          Image(icon).width(27).height(27).fillColor('#FFFFFF')
        }
        Text(label).fontSize(10).fontColor('#7655F6').fontWeight(FontWeight.Bold).margin({ top: 2 })
      } else {
        Image(icon).width(24).height(24).fillColor(this.currentTab === n ? '#7655F6' : '#9994A6')
        Text(label).fontSize(10).fontColor(this.currentTab === n ? '#7655F6' : '#9994A6')
          .fontWeight(this.currentTab === n ? FontWeight.Bold : FontWeight.Regular).margin({ top: 4 })
      }
    }
    .width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  build() {
    if (this.isWatchLayout) {
      Row() {
        Text('首页').fontSize(11).fontColor(this.currentTab === 0 ? '#FFFFFF' : '#9994A6')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 }).borderRadius(10)
          .backgroundColor(this.currentTab === 0 ? '#7655F6' : 'transparent')
          .onClick(() => this.navigateTo(0))
        Text('树洞').fontSize(11).fontColor(this.currentTab === 1 ? '#FFFFFF' : '#9994A6')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 }).borderRadius(10)
          .backgroundColor(this.currentTab === 1 ? '#7655F6' : 'transparent')
          .onClick(() => this.navigateTo(1))
        Text('倾诉').fontSize(11).fontColor(this.currentTab === 2 ? '#FFFFFF' : '#9994A6')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 }).borderRadius(10)
          .backgroundColor(this.currentTab === 2 ? '#7655F6' : 'transparent')
          .onClick(() => this.navigateTo(2))
        Text('广场').fontSize(11).fontColor(this.currentTab === 3 ? '#FFFFFF' : '#9994A6')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 }).borderRadius(10)
          .backgroundColor(this.currentTab === 3 ? '#7655F6' : 'transparent')
          .onClick(() => this.navigateTo(3))
        Text('我的').fontSize(11).fontColor(this.currentTab === 4 ? '#FFFFFF' : '#9994A6')
          .padding({ left: 8, right: 8, top: 5, bottom: 5 }).borderRadius(10)
          .backgroundColor(this.currentTab === 4 ? '#7655F6' : 'transparent')
          .onClick(() => this.navigateTo(4))
      }
      .width('100%').height(48).justifyContent(FlexAlign.SpaceEvenly).alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFFD9').padding({ left: 4, right: 4 })
    } else {
      Row() {
        this.TabItem($r('app.media.home'), '首页', 0)
        this.TabItem($r('app.media.message'), '树洞', 1)
        this.TabItem($r('app.media.voice'), '倾诉', 2, true)
        this.TabItem($r('app.media.community'), '广场', 3)
        this.TabItem($r('app.media.profile'), '我的', 4)
      }
      .width('100%').height(82).justifyContent(FlexAlign.SpaceAround).alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFFD9')
    }
  }
}