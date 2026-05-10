import router from '@ohos.router';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct Index {
  @State tab: number = 0;
  @State emotion: string = '平静';
  @State care: string = '检测到你最近有些疲惫，要不要试试放松一下？';
  @State tag: number = 0;

  aboutToAppear() { this.load(); }

  async load() {
    try {
      await apiService.ensureAnonymousUser();
      let e = (await apiService.getTodayEmotion()).dominant_emotion || 'neutral';
      this.emotion = e === 'happy' || e === 'joy' ? '愉悦' : e === 'sad' ? '低落' : e === 'anxious' || e === 'fear' ? '焦虑' : e === 'angry' ? '烦躁' : '平静';
    } catch (err) { console.error('home load failed', err); }
  }

  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() { this.Home() }.tabBar(this.Tab('首页', $r('app.media.home'), 0))
      TabContent() { this.Page('树洞', '这里是只属于你的私密空间', '进入树洞', 'pages/TreeHole') }.tabBar(this.Tab('树洞', $r('app.media.message'), 1))
      TabContent() { this.Page('倾诉', '选择一种舒服的方式,把此刻说出来', '开始 AI 陪伴', 'pages/Chat') }.tabBar(this.MidTab())
      TabContent() { this.Page('发现', '情绪报告、成长记录和个性化推荐', '查看报告', 'pages/EmotionReport') }.tabBar(this.Tab('发现', $r('app.media.community'), 3))
      TabContent() { this.Me() }.tabBar(this.Tab('我的', $r('app.media.profile'), 4))
    }.barHeight(68).barBackgroundColor('#FFFFFF').backgroundColor('#F7F4FF').onChange((i: number) => { this.tab = i; })
  }

  @Builder Tab(t: string, icon: Resource, n: number) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .fillColor(this.tab === n ? '#7658F6' : '#8B8A99')
        .margin({ bottom: 4 })
      Text(t)
        .fontSize(10)
        .fontColor(this.tab === n ? '#7658F6' : '#8B8A99')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  @Builder MidTab() {
    Column() {
      Column() {
        Image($r('app.media.voice'))
          .width(28)
          .height(28)
          .fillColor('#FFF')
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor('#7B57FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({ radius: 18, color: '#7B57FF55', offsetY: 6 })
      Text('倾诉')
        .fontSize(10)
        .fontColor('#7658F6')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder Home() {
    Scroll() { Column() { this.Head(); this.Hero(); this.Status(); this.Recommend(); this.Buddies(); this.Device(); Text('陪伴而不诊断，引导而不治疗').fontSize(11).fontColor('#B9B5C8').margin({ top: 16, bottom: 18 }) }.width('100%').constraintSize({ maxWidth: 760 }).padding({ left: 12, right: 12, top: 8 }).alignItems(HorizontalAlign.Center) }.width('100%').height('100%').backgroundColor('#F7F4FF')
  }

  @Builder Head() {
    Column() {
      Row() {
        Text('09:30').fontSize(12)
        Blank()
        Row() {
          Image($r('app.media.devices'))
            .width(16)
            .height(16)
            .fillColor('#2C2940')
          Text(' 多设备已连接').fontSize(12).fontColor('#2C2940')
          Text('  ⌕').fontSize(12).fontColor('#2C2940')
        }
      }.width('100%').height(18)
      Row() {
        Stack() {
          Circle().width(42).height(42).fill('#7A62FF')
          Circle().width(18).height(18).fill('#FFFFFF99')
        }.width(46)
        Column() {
          Text('树洞').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#19162B')
          Text('OpenHarmony').fontSize(8).fontColor('#FFF').padding({ left: 6, right: 6 }).backgroundColor('#7D8DFF').borderRadius(7)
        }.alignItems(HorizontalAlign.Start)
        Blank()
        Text('首页').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#171329').padding({ bottom: 6 }).border({ width: { bottom: 3 }, color: '#7762F4' })
        Blank()
      }.width('100%').height(62).alignItems(VerticalAlign.Center)
    }.width('100%')
  }

  @Builder Hero() {
    Stack() {
      Row() {
        Column() {
          Text('Hi~ 这里是你的树洞🌿').fontSize(24).fontWeight(FontWeight.Bold).fontColor('#17112D').maxLines(1)
          Text('倾听你的情绪，陪伴你的每一刻').fontSize(13).fontColor('#77708B').margin({ top: 8 })
          Row() {
            this.Pill('无压力倾诉')
            this.Pill('AI共情陪伴')
            this.Pill('隐私安全守护')
          }.margin({ top: 14 })
          Row() {
            Image($r('app.media.comment'))
              .width(20)
              .height(20)
              .fillColor('#FFF')
              .margin({ right: 8 })
            Column() {
              Text('想说点什么吗？').fontSize(14).fontColor('#FFF').fontWeight(FontWeight.Bold)
              Text('点击开始倾诉...').fontSize(10).fontColor('#E7DEFF')
            }.alignItems(HorizontalAlign.Start)
            Blank()
            Image($r('app.media.arrow_right'))
              .width(20)
              .height(20)
              .fillColor('#FFF')
          }
          .height(58)
          .width('90%')
          .padding({ left: 14, right: 12 })
          .backgroundColor('#8061F8')
          .borderRadius(16)
          .margin({ top: 18 })
          .onClick(() => router.pushUrl({ url: 'pages/Chat' }))
          Button('直接开始匿名体验')
            .width('90%')
            .height(42)
            .fontSize(14)
            .fontColor('#7658F6')
            .backgroundColor('#F2ECFF')
            .borderRadius(14)
            .margin({ top: 10 })
            .onClick(() => router.pushUrl({ url: 'pages/AccountSettings' }))
        }
        .width('60%')
        .padding({ left: 24, top: 26 })
        .alignItems(HorizontalAlign.Start)
        Blank()
        this.Tree()
      }.height('100%')
      Text('我在这里\n一直陪着你')
        .fontSize(11)
        .fontColor('#FFF')
        .textAlign(TextAlign.Center)
        .padding(10)
        .backgroundColor('#5A436688')
        .borderRadius(18)
        .position({ x: '76%', y: 52 })
    }
    .height(258)
    .width('100%')
    .backgroundColor('#ECE7FF')
    .borderRadius(18)
    .clip(true)
    .shadow({ radius: 14, color: '#9B8FEA22', offsetY: 6 })
  }

  @Builder Pill(t: string) { Text(t).fontSize(10).fontColor('#837A9A').padding({ left: 10, right: 10, top: 6, bottom: 6 }).backgroundColor('#F5F1FF').borderRadius(12).margin({ right: 7 }) }
  @Builder Tree() { Stack() { Rect().width('100%').height('100%').fill('#A6B4FF'); Circle().width(150).height(108).fill('#285F50').position({ x: 20, y: 20 }); Circle().width(112).height(92).fill('#2F735C').position({ x: 88, y: 42 }); Rect().width(54).height(132).fill('#725034').borderRadius(28).position({ x: 82, y: 106 }); Circle().width(82).height(82).fill('#FFF2B8').position({ x: 68, y: 110 }); Text('⌒  ⌒').fontSize(16).fontColor('#5B4C36').position({ x: 90, y: 142 }); Circle().width(7).height(7).fill('#FFE978').position({ x: 36, y: 92 }); Circle().width(6).height(6).fill('#FFE978').position({ x: 166, y: 62 }) }.width('40%').height('100%').clip(true) }

  @Builder Status() { GridRow({ columns: 12, gutter: { x: 10, y: 10 } }) { GridCol({ span: { xs: 12, sm: 8 } }) { this.StateCard() }; GridCol({ span: { xs: 12, sm: 4 } }) { this.Care() } }.width('100%').margin({ top: 12 }) }
  @Builder StateCard() { Column() { Row() { Text('✺ 当前状态').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#2D2840'); Text(' · 更新于 09:30').fontSize(10).fontColor('#9B96AC'); Blank() }.width('100%'); Row() { this.Metric('☺', '情绪', this.emotion, '76分', '#FFE6A7'); this.Line(); this.Metric('⌂', '场景', '居家', '晚上', '#DED9FF'); this.Line(); this.Focus(); this.Line(); this.Metric('▯', '能量值', '82%', '', '#DDF7E3') }.height(104).width('100%') }.padding(14).width('100%').backgroundColor('#FFF').borderRadius(18).shadow({ radius: 12, color: '#8B7ED622', offsetY: 4 }) }
  @Builder Metric(i: string, l: string, t: string, s: string, c: string) { Column() { Text(i).fontSize(28).fontColor('#6C5CE7').width(42).height(42).textAlign(TextAlign.Center).backgroundColor(c).borderRadius(21); Text(l).fontSize(10).fontColor('#918AA3'); Text(t).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#19162B'); Text(s).fontSize(13).fontColor('#7C768D') }.layoutWeight(1).alignItems(HorizontalAlign.Center) }
  @Builder Focus() { Column() { Text('专注度').fontSize(10).fontColor('#918AA3'); Stack() { Progress({ value: 68, total: 100, type: ProgressType.Ring }).width(54).height(54).color('#7FD9AE').backgroundColor('#EEEAF8'); Text('68%').fontSize(13).fontColor('#776F88') }.margin({ top: 7 }) }.layoutWeight(1).alignItems(HorizontalAlign.Center) }
  @Builder Line() { Divider().vertical(true).height(72).color('#EEEAF8').strokeWidth(1) }
  @Builder Care() { Stack({ alignContent: Alignment.BottomEnd }) { Column() { Row() { Text('✈ 主动关怀').fontSize(14).fontWeight(FontWeight.Bold).fontColor('#30294B'); Text('NEW').fontSize(8).fontColor('#FFF').padding({ left: 5, right: 5 }).backgroundColor('#7B59FF').borderRadius(8).margin({ left: 6 }); Blank() }; Text(this.care).fontSize(11).fontColor('#60596F').lineHeight(18).width('72%').margin({ top: 12 }); Button('聊一聊').width(84).height(28).fontSize(11).fontColor('#7860E9').backgroundColor('#FFF').borderRadius(14).margin({ top: 10 }).onClick(() => { this.care = '我在这里，先做三次深呼吸，再慢慢告诉我发生了什么。'; }) }.padding(14).width('100%').height('100%').alignItems(HorizontalAlign.Start); Stack() { Circle().width(84).height(84).fill('#E2D9FF'); Rect().width(46).height(30).fill('#111B35').borderRadius(16); Text('• •').fontSize(16).fontColor('#5CF5FF') }.width(96).height(96).margin({ right: 2, bottom: 4 }) }.height(156).width('100%').backgroundColor('#F0E9FF').borderRadius(18).clip(true) }

  @Builder Recommend() {
    Column() {
      Row() {
        Text('为你推荐').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#201B34')
        Blank()
        Row() {
          Image($r('app.media.refresh'))
            .width(16)
            .height(16)
            .fillColor('#756F86')
          Text(' 换一换').fontSize(11).fontColor('#756F86')
        }
        .onClick(() => { this.tag = (this.tag + 1) % 4; })
      }.margin({ top: 18, bottom: 10 }).width('100%')
      Row() {
        this.Tag('治愈时刻', 0)
        this.Tag('学习提升', 1)
        this.Tag('轻松娱乐', 2)
        this.Tag('成长记录', 3)
      }.justifyContent(FlexAlign.Center).margin({ bottom: 10 }).width('100%')
      GridRow({ columns: 12, gutter: { x: 10, y: 10 } }) {
        GridCol({ span: { xs: 6, sm: 3 } }) { this.Rec('深呼吸 · 森林白噪音', '放松身心，回归平静', '08:45', '#7FA36B') }
        GridCol({ span: { xs: 6, sm: 3 } }) { this.Rec('专注学习计时器', '番茄钟 · 提升专注力', '25:00', '#C8B28C') }
        GridCol({ span: { xs: 6, sm: 3 } }) { this.Rec('今日快乐小视频', '治愈瞬间，好心情', '05:12', '#C9A391') }
        GridCol({ span: { xs: 6, sm: 3 } }) { this.Rec('睡前减压冥想', '释放压力，安然入眠', '03:21', '#6D74B8') }
      }.width('100%')
    }.width('100%')
  }
  @Builder Tag(t: string, i: number) { Text(t).fontSize(11).fontColor(this.tag === i ? '#7B60EA' : '#8F89A0').padding({ left: 12, right: 12, top: 6, bottom: 6 }).backgroundColor(this.tag === i ? '#EEE8FF' : '#F7F4FF').borderRadius(13).margin({ right: 8 }).onClick(() => { this.tag = i; }) }
  @Builder Rec(t: string, d: string, time: string, c: string) { Column() { Stack() { Rect().width('100%').height(92).fill(c).opacity(0.28); Circle().width(90).height(90).fill(c).opacity(0.45); Text('▶').fontSize(24).fontColor('#FFF'); Text(time).fontSize(9).fontColor('#FFF').backgroundColor('#00000066').borderRadius(5).padding({ left: 5, right: 5 }).position({ x: '66%', y: 72 }) }.height(92).width('100%'); Column() { Text(t).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#272137').maxLines(1); Text(d).fontSize(9).fontColor('#8C8597').maxLines(1).margin({ top: 4 }); Text('治愈').fontSize(9).fontColor(c).margin({ top: 8 }) }.padding(9).alignItems(HorizontalAlign.Start) }.height(170).width('100%').backgroundColor('#FFF').borderRadius(12).clip(true).shadow({ radius: 10, color: '#8B7ED618', offsetY: 4 }) }

  @Builder Buddies() {
    Column() {
      Row() {
        Text('为你推荐搭子').fontSize(17).fontWeight(FontWeight.Bold).fontColor('#201B34')
        Blank()
        Image($r('app.media.arrow_right'))
          .width(20)
          .height(20)
          .fillColor('#7E778E')
      }.width('100%').margin({ top: 18, bottom: 10 })
      Row() {
        this.Buddy('小夏同学', '4.9', '#F5CFCF')
        this.Buddy('阿杰', '4.8', '#D5C6AE')
        this.Buddy('鹿鹿酱', '4.9', '#F6D8E7')
        this.Buddy('星星', '4.7', '#DCD2FF')
      }.width('100%')
    }.width('100%')
  }
  @Builder Buddy(n: string, s: string, c: string) { Column() { Circle().width(48).height(48).fill(c); Text(n).fontSize(12).fontWeight(FontWeight.Bold).fontColor('#2A2439'); Text(`★ ${s}`).fontSize(10).fontColor('#D9AA35'); Button('去认识').height(28).width('82%').fontSize(11).fontColor('#FFF').backgroundColor('#7658F6').borderRadius(14).margin({ top: 8 }) }.layoutWeight(1).height(128).backgroundColor('#FFF').borderRadius(13).padding({ top: 10, left: 5, right: 5 }).alignItems(HorizontalAlign.Center).margin({ right: 8 }) }
  @Builder Device() {
    Column() {
      Row() {
        Image($r('app.media.devices'))
          .width(20)
          .height(20)
          .fillColor('#7658F6')
          .margin({ right: 8 })
        Text('多设备同步').fontSize(15).fontWeight(FontWeight.Bold).fontColor('#201B34')
      }
      Text('手机树洞内容已同步至平板、手表、智慧屏等设备').fontSize(11).fontColor('#7E788F').margin({ top: 10 })
      Row() {
        Text('查看设备')
          .fontSize(11)
          .fontColor('#7257E8')
        Image($r('app.media.arrow_right'))
          .width(14)
          .height(14)
          .fillColor('#7257E8')
          .margin({ left: 4 })
      }
      .height(30)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#F6F2FF')
      .borderRadius(15)
      .margin({ top: 12 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFF')
    .borderRadius(18)
    .margin({ top: 10 })
    .shadow({ radius: 12, color: '#8B7ED622', offsetY: 4 })
  }

  @Builder Page(t: string, d: string, b: string, u: string) { Column() { Text(t).fontSize(22).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ top: 38, bottom: 20 }); Text(d).fontSize(13).fontColor('#8B849B'); Button(b).width(210).height(48).fontSize(16).fontColor('#FFF').backgroundColor('#7658F6').borderRadius(24).margin({ top: 40 }).onClick(() => router.pushUrl({ url: u })) }.width('100%').height('100%').backgroundColor('#F7F4FF').alignItems(HorizontalAlign.Center) }
  @Builder Me() {
    Column() {
      Text('我的').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ top: 38, bottom: 20 })
      Button('去登录 / 账号设置')
        .width('100%')
        .height(48)
        .fontSize(16)
        .fontColor('#FFF')
        .backgroundColor('#7658F6')
        .borderRadius(16)
        .margin({ bottom: 14 })
        .onClick(() => router.pushUrl({ url: 'pages/AccountSettings' }))
      this.Setting('账号与隐私', $r('app.media.profile'), 'pages/AccountSettings')
      this.Setting('多设备管理', $r('app.media.devices'))
      this.Setting('关于树洞', $r('app.media.comment'))
    }
    .width('100%')
    .height('100%')
    .padding({ left: 18, right: 18 })
    .backgroundColor('#F7F4FF')
  }
  @Builder Setting(t: string, icon: Resource, url?: string) {
    Row() {
      Image(icon)
        .width(22)
        .height(22)
        .fillColor('#7658F6')
        .margin({ right: 12 })
      Text(t).fontSize(16).fontColor('#30294B')
      Blank()
      Image($r('app.media.arrow_right'))
        .width(18)
        .height(18)
        .fillColor('#A9A2B8')
    }
    .width('100%')
    .height(58)
    .padding({ left: 16, right: 16 })
    .backgroundColor('#FFF')
    .borderRadius(16)
    .margin({ bottom: 12 })
    .onClick(() => {
      if (url) {
        router.pushUrl({ url: url })
      }
    })
  }
}
