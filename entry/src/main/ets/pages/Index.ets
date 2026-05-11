import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { User, Recommendation, EmotionReport, ProfileStateVector } from '../models/Types';

interface EmotionReportResult extends EmotionReport {
  risk_level?: string;
}

interface GeneratedTypeLiteralInterface_2 {
  title: string;
  desc: string;
  url: string;
}

interface ToastOptions {
  message: string;
}

interface PushUrlOptions {
  url: string;
}

interface ProfilePreferences {
  prefersDirectAdvice: boolean;
  prefersVoice: boolean;
  prefersPrivateWriting: boolean;
  openToPublicInteraction: boolean;
  safetySensitive: boolean;
}


@Entry
@Component
struct Index {
  @State tab: number = 0;
  @State emotion: string = '平静';
  @State care: string = '检测到你最近有些疲惫，要不要试试放松一下？';
  @State guestLimitText: string = '游客模式无法保存记录，登录账号可解锁完整树洞功能';
  @State deviceAlertText: string = '多设备已连接，建议立即管理设备，避免账号风险';
  @State currentStatusHint: string = '暂无情绪记录，点击下方开始倾诉吧';
  @State tag: number = 0;
  @State currentUser: User | null = null;
  @State isAnonymous: boolean = false;
  @State isGuest: boolean = true;
  @State isLoading: boolean = true;
  @State recommendations: Recommendation[] = [];
  @State emotionSummary: string = '今天先慢一点，也没关系';
  @State riskLevel: string = 'low';
  @State emotionIntensity: number = 0;
  @State emotionTrendLabel: string = '近期状态稳定';
  @State profileOverviewText: string = '画像正在生成';
  @State profileOverviewReady: boolean = false;
  @State profileStateVector: ProfileStateVector = {
    valence: 0,
    arousal: 0,
    dominance: 0,
    social: 0,
    cognitive: 0
  };
  @State profileSignalsText: string = '偏好信号正在计算';
  @State recentActions: Array<GeneratedTypeLiteralInterface_2> = [
    { title: '去树洞记录', desc: '把刚刚的情绪放进安全空间', url: 'pages/TreeHole' },
    { title: '查看搭子匹配', desc: '看看当前画像适合怎样的搭子', url: 'pages/MatchPage' },
    { title: '打开安全帮助', desc: '当需要稳住当下时先来这里', url: 'pages/SafetyHelp' }
  ];

  aboutToAppear() {
    this.load();
  }

  async load() {
    try {
      let me = await apiService.getMe();
      this.currentUser = me.user;
      this.isAnonymous = me.user.is_anonymous || me.user.role === 'anonymous';
      this.isGuest = false;
      try {
        let today = await apiService.getTodayEmotion();
        let e = today.dominant_emotion || 'neutral';
        this.emotion = e === 'happy' || e === 'joy' ? '愉悦' :
          e === 'sad' ? '低落' : e === 'anxious' || e === 'fear' ? '焦虑' : e === 'angry' ? '烦躁' : '平静';
        this.emotionSummary = today.summary || this.emotionSummary;
        this.emotionIntensity = today.average_intensity || 0;
        this.emotionTrendLabel = today.risk_events_count > 0 ? '最近需要更多照顾' :
          (today.total_records > 0 ? '近期状态有记录' : '暂无今日记录');
        let maybeRisk = (today as EmotionReportResult).risk_level;
        if (maybeRisk) {
          this.riskLevel = maybeRisk;
        }
      } catch (emotionErr) {
        console.error('load emotion failed', emotionErr);
      }
      try {
        let profile = await apiService.getProfileOverview();
        this.profileOverviewReady = true;
        this.profileOverviewText = profile.signal_summary || '画像已更新';
        this.profileStateVector = {
          valence: profile.state_vector.valence,
          arousal: profile.state_vector.arousal,
          dominance: profile.state_vector.dominance,
          social: profile.state_vector.social,
          cognitive: profile.state_vector.cognitive
        };
        this.profileSignalsText = profile.preference_signals.prefersVoice
          ? '更偏好语音表达'
          : profile.preference_signals.prefersPrivateWriting
            ? '更偏好私密写作'
            : profile.preference_signals.prefersDirectAdvice
              ? '更偏好直接建议'
              : profile.preference_signals.openToPublicInteraction
                ? '愿意公开互动'
                : '画像偏好待观察';
        this.emotionTrendLabel = profile.preferred_day ? `更常在${profile.preferred_day}记录` : this.emotionTrendLabel;
        this.care = profile.preference_signals.prefersVoice
          ? '你更适合语音表达，先说出来会更轻松。'
          : profile.preference_signals.prefersPrivateWriting
            ? '你更适合先写下来，再慢慢整理。'
            : profile.preference_signals.prefersDirectAdvice
              ? '你最近更需要直接一点的建议。'
              : this.care;
        this.recommendations = this.recommendations.map((item: Recommendation, index: number) => {
          if (index === 0 && profile.preference_signals.prefersVoice) {
            item.title = '先用语音说出来';
            item.description = '从最自然的表达方式开始';
          }
          if (index === 0 && profile.preference_signals.prefersPrivateWriting) {
            item.title = '先写进树洞';
            item.description = '让情绪先有一个安全出口';
          }
          return item;
        });
      } catch (profileErr) {
        console.error('load profile overview failed', profileErr);
      }
      try {
        let rec = await apiService.getRecommendations(4);
        this.recommendations = rec.recommendations || [];
      } catch (recommendErr) {
        console.error('load recommendations failed', recommendErr);
      }
    } catch (err) {
      this.currentUser = null;
      this.isAnonymous = false;
      this.isGuest = true;
      try {
        let anonymous = await apiService.ensureAnonymousUser();
        this.currentUser = anonymous;
        this.isGuest = false;
        this.isAnonymous = true;
      } catch (guestErr) {
        console.error('anonymous fallback failed', guestErr);
      }
    } finally {
      this.isLoading = false;
    }
  }

  private requireAuth(actionName: string): boolean {
    if (!this.isGuest) {
      return true;
    }
    let toastOptions: ToastOptions = { message: `${actionName}需要先登录或选择匿名体验` };
    let loginOptions: PushUrlOptions = { url: 'pages/LoginPage' };
    promptAction.showToast(toastOptions);
    router.pushUrl(loginOptions);
    return false;
  }

  private openFeature(url: string, featureName: string): void {
    if (featureName && !this.requireAuth(featureName)) {
      return;
    }
    let pushOptions: PushUrlOptions = { url: url };
    router.pushUrl(pushOptions);
  }

  private refreshCurrentState(): void {
    this.isLoading = true;
    this.load();
  }

  async doLogout(): Promise<void> {
    try {
      await apiService.logout();
    } catch (err) {
      console.error('logout failed', err);
    } finally {
      apiService.setToken('');
      this.currentUser = null;
      this.isAnonymous = false;
      this.isGuest = true;
      let logoutToast: ToastOptions = { message: '已退出登录' };
      let replaceOptions: PushUrlOptions = { url: 'pages/LoginPage' };
      promptAction.showToast(logoutToast);
      router.replaceUrl(replaceOptions);
    }
  }

  build() {
    Stack() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(48).height(48).color('#7658F6')
          Text('加载中...').fontSize(14).fontColor('#8B849B').margin({ top: 12 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor('#F7F4FF')
      } else {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() {
            this.Home()
          }.tabBar(this.Tab('首页', $r('app.media.home'), 0))

          TabContent() {
            this.Page('树洞', '这里是只属于你的私密空间', '进入树洞', 'pages/TreeHole', '树洞')
          }.tabBar(this.Tab('树洞', $r('app.media.message'), 1))

          TabContent() {
            this.Page('倾诉', '选择一种舒服的方式,把此刻说出来', '开始 AI 陪伴', 'pages/Chat', '倾诉')
          }.tabBar(this.MidTab())

          TabContent() {
            this.Page('广场', '匿名表达与温和共鸣', '进入广场', 'pages/Plaza', '广场')
          }.tabBar(this.Tab('广场', $r('app.media.community'), 3))

          TabContent() {
            this.Page('发现', '情绪报告、成长记录和个性化推荐', '查看报告', 'pages/EmotionReport', '发现')
          }.tabBar(this.Tab('发现', $r('app.media.community'), 4))

          TabContent() {
            this.Me()
          }.tabBar(this.Tab('我的', $r('app.media.profile'), 5))
        }.barHeight(68).barBackgroundColor('#FFFFFF').backgroundColor('#F7F4FF').onChange((i: number) => {
          this.tab = i;
        })
      }
    }
    .width('100%').height('100%')
  }

  @Builder
  Tab(t: string, icon: Resource, n: number) {
    Column() {
      Image(icon).width(24).height(24)
        .fillColor(this.tab === n ? '#7658F6' : '#8B8A99').margin({ bottom: 4 })
      Text(t).fontSize(10).fontColor(this.tab === n ? '#7658F6' : '#8B8A99')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  MidTab() {
    Column() {
      Column() {
        Image($r('app.media.voice')).width(28).height(28).fillColor('#FFF')
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor('#7B57FF')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .shadow({ radius: 18, color: '#7B57FF55', offsetY: 6 })

      Text('倾诉').fontSize(10).fontColor('#7658F6').fontWeight(FontWeight.Bold)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  Home() {
    Scroll() {
      Column() {
        this.Head()
        this.Hero()
        this.Status()
        this.Recommend()
        this.QuickLoop()
        this.EntryGrid()
        this.Device()
        Text('陪伴而不诊断，引导而不治疗').fontSize(11).fontColor('#B9B5C8').margin({ top: 16, bottom: 18 })
      }
      .width('100%')
      .constraintSize({ maxWidth: 760 })
      .padding({ left: 12, right: 12, top: 8 })
      .margin({ bottom: 18 })
      .alignItems(HorizontalAlign.Center)
    }.width('100%').height('100%').backgroundColor('#F4F1FF')
  }

  @Builder
  Head() {
    Column() {
      Row() {
        Text('09:30').fontSize(12).fontColor('#6D6880')
        Blank()
        Row() {
          Text('!').fontSize(12).fontColor('#C53A4A').fontWeight(FontWeight.Bold)
          Text(' 多设备已连接').fontSize(11).fontColor('#C53A4A').fontWeight(FontWeight.Medium)
          Text(' 管理设备').fontSize(11).fontColor('#7B57FF').fontWeight(FontWeight.Medium)
        }
        .padding({
          left: 10,
          right: 10,
          top: 5,
          bottom: 5
        })
        .backgroundColor('#FFF0F2')
        .borderRadius(14)
        .onClick(() => this.openFeature('pages/ProfileTimeline', '设备管理'))
      }.width('100%').height(22)

      Row() {
        Text(`情绪：${this.emotion}`).fontSize(11).fontColor('#6E6781')
        Text(` · ${this.emotionSummary}`).fontSize(11).fontColor('#6E6781')
        Blank()
        Text(`风险 ${this.riskLevel}`)
          .fontSize(11)
          .fontColor(this.riskLevel === 'high' || this.riskLevel === 'critical' ? '#D9534F' : '#6E6781')
      }.width('100%').margin({ top: 6 })

      Text(this.profileOverviewText)
        .fontSize(11)
        .fontColor(this.profileOverviewReady ? '#7B57FF' : '#8B849B')
        .margin({ top: 6 })
      if (this.profileSignalsText) {
        Text(this.profileSignalsText)
          .fontSize(11)
          .fontColor('#8B849B')
          .margin({ top: 4 })
      }
      Row() {
        Image($r('app.media.avatar1')).width(42).height(42).borderRadius(21)
        Column() {
          Text(this.currentUser?.nickname || (this.isAnonymous ? '匿名同学' : '用户'))
            .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#19162B')
          Text(this.isGuest ? '未登录' : (this.isAnonymous ? '匿名模式' : '正式账号'))
            .fontSize(8)
            .fontColor('#FFF')
            .padding({ left: 6, right: 6 })
            .backgroundColor(this.isGuest ? '#B9B5C8' : (this.isAnonymous ? '#9B8FEA' : '#7D8DFF'))
            .borderRadius(7)
        }.alignItems(HorizontalAlign.Start).margin({ left: 10 })

        Blank()
        Text('首页')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor('#171329')
          .padding({ bottom: 6 })
          .border({ width: { bottom: 3 }, color: '#7762F4' })
        Blank()
      }.width('100%').height(62).alignItems(VerticalAlign.Center)
    }.width('100%')
  }

  @Builder
  Hero() {
    Stack() {
      Row() {
        Column() {
          Text(this.isGuest ? '👋 欢迎来到树洞' : (this.isAnonymous ? '👋 欢迎来到树洞' : '👋 欢迎回来'))
            .fontSize(24).fontWeight(FontWeight.Bold).fontColor('#17112D').maxLines(1)
          Text(this.isGuest ? '请先登录、注册或选择匿名体验' :
            (this.isAnonymous ? '在这里你可以放心倾诉' : '很高兴再次见到你'))
            .fontSize(14).fontColor('#77708B').margin({ top: 8 })
          if (this.isAnonymous) {
            Text(this.guestLimitText).fontSize(12).fontColor('#8E89A6').margin({ top: 6 })
          }
          Row() {
            this.Pill('无压力倾诉')
            this.Pill('AI共情陪伴')
            this.Pill('隐私安全守护')
          }.margin({ top: 14 })

          Row() {
            Image($r('app.media.comment')).width(20).height(20).fillColor('#FFF').margin({ right: 8 })
            Column() {
              Text('想说点什么吗？').fontSize(15).fontColor('#FFF').fontWeight(FontWeight.Medium)
              Text(this.isGuest ? '请先登录或选择匿名体验' : this.currentStatusHint).fontSize(12).fontColor('#E7DEFF')
            }.alignItems(HorizontalAlign.Start)

            Blank()
            Image($r('app.media.arrow_right')).width(20).height(20).fillColor('#FFF')
          }
          .height(58)
          .width('90%')
          .padding({ left: 16, right: 14 })
          .backgroundColor(this.isGuest ? '#AFA7D8' : (this.isAnonymous ? '#9B8FEA' : '#8061F8'))
          .borderRadius(16)
          .margin({ top: 18 })
          .onClick(() => this.openFeature('pages/Chat', '倾诉'))

          Button(this.isGuest ? '去登录或匿名体验' : (this.isAnonymous ? '登录解锁完整功能' : '开始今日倾诉'))
            .width('90%')
            .height(42)
            .fontSize(14)
            .fontColor(this.isGuest ? '#7658F6' : (this.isAnonymous ? '#7658F6' : '#FFF'))
            .backgroundColor(this.isGuest ? '#F2ECFF' : (this.isAnonymous ? '#F2ECFF' : '#7658F6'))
            .borderRadius(14)
            .margin({ top: 10 })
            .onClick(() => {
              if (this.isGuest) {
                router.pushUrl({ url: 'pages/LoginPage' });
              } else {
                this.openFeature('pages/Chat', '倾诉');
              }
            })
        }.width('60%').padding({ left: 24, top: 26 }).alignItems(HorizontalAlign.Start)

        Blank()
        this.Tree()
      }.height('100%')

      if (this.isGuest) {
        Text('👤 未登录')
          .fontSize(11)
          .fontColor('#FFF')
          .textAlign(TextAlign.Center)
          .padding(10)
          .backgroundColor('#8E89A6AA')
          .borderRadius(18)
          .position({ x: '76%', y: 52 })
      } else if (this.isAnonymous) {
        Text('🛡 游客模式')
          .fontSize(11)
          .fontColor('#FFF')
          .textAlign(TextAlign.Center)
          .padding(10)
          .backgroundColor('#5A436688')
          .borderRadius(18)
          .position({ x: '76%', y: 52 })
      } else {
        Text('🛡 已登录账号')
          .fontSize(11)
          .fontColor('#FFF')
          .textAlign(TextAlign.Center)
          .padding(10)
          .backgroundColor('#5A436688')
          .borderRadius(18)
          .position({ x: '76%', y: 52 })
      }
    }
    .height(272)
    .width('100%')
    .backgroundColor('#ECE7FF')
    .borderRadius(18)
    .clip(true)
    .shadow({ radius: 14, color: '#9B8FEA22', offsetY: 6 })
  }

  @Builder
  Pill(t: string) {
    Text(t)
      .fontSize(10)
      .fontColor('#837A9A')
      .padding({
        left: 10,
        right: 10,
        top: 6,
        bottom: 6
      })
      .backgroundColor('#F5F1FF')
      .borderRadius(12)
      .margin({ right: 7 })
  }

  @Builder
  Tree() {
    Image($r('app.media.tree'))
      .width('40%')
      .height('100%')
      .objectFit(ImageFit.Cover)
  }

  @Builder
  Status() {
    GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
      GridCol({ span: { xs: 12, sm: 6 } }) {
        this.StateCard()
      }

      GridCol({ span: { xs: 12, sm: 6 } }) {
        this.Care()
      }
    }.width('100%').margin({ top: 16 })
  }

  @Builder
  StateCard() {
    Column() {
      Row() {
        Text('✺ 当前状态').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#2D2840')
        Text(` · ${this.emotionTrendLabel}`).fontSize(12).fontColor('#9B96AC')
        Blank()
      }.width('100%')

      Row() {
        this.Metric('☺', '情绪', this.emotion, `${Math.round(this.emotionIntensity * 100)}分`, '#FFE6A7')
        this.Line()
        Column() {
          this.Metric('⌂', '场景', this.isAnonymous ? '匿名体验' : '真实账号', this.isGuest ? '未登录' : '在线',
            '#DED9FF')
        }.width('100%')

        this.Line()
        Column() {
          this.Focus()
        }.width('100%')

        this.Line()
        this.Metric('▯', '能量值', this.riskLevel === 'high' || this.riskLevel === 'critical' ? '需要关注' : '稳定',
          this.riskLevel, '#DDF7E3')
      }.height(116).width('100%')
    }
    .padding(20)
    .width('100%')
    .backgroundColor('#FFF')
    .borderRadius(18)
    .shadow({ radius: 12, color: '#8B7ED622', offsetY: 4 })
  }

  @Builder
  Metric(i: string, l: string, t: string, s: string, c: string) {
    Column() {
      Text(i)
        .fontSize(26)
        .fontColor('#6C5CE7')
        .width(42)
        .height(42)
        .textAlign(TextAlign.Center)
        .backgroundColor(c)
        .borderRadius(21)
      Text(l).fontSize(12).fontColor('#918AA3')
      Text(t).fontSize(15).fontWeight(FontWeight.Medium).fontColor('#19162B')
      Text(s).fontSize(12).fontColor('#7C768D')
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  Focus() {
    Column() {
      Text('专注度').fontSize(12).fontColor('#918AA3')
      Stack() {
        Progress({ value: 68, total: 100, type: ProgressType.Ring }).width(54).height(54)
          .color('#7FD9AE').backgroundColor('#EEEAF8')
        Text('68%').fontSize(12).fontColor('#776F88')
      }.margin({ top: 7 })
    }.layoutWeight(1).alignItems(HorizontalAlign.Center)
  }

  @Builder
  Line() {
    Divider().vertical(true).height(72).color('#EEEAF8').strokeWidth(1)
  }

  @Builder
  Care() {
    Stack({ alignContent: Alignment.BottomEnd }) {
      Column() {
        Row() {
          Text('✈ 主动关怀').fontSize(16).fontWeight(FontWeight.Medium).fontColor('#30294B')
          Text('关怀中')
            .fontSize(10)
            .fontColor('#7B57FF')
            .padding({
              left: 7,
              right: 7,
              top: 3,
              bottom: 3
            })
            .backgroundColor('#EEE8FF')
            .borderRadius(10)
            .margin({ left: 6 })
          Blank()
        }

        Text(this.care)
          .fontSize(12)
          .fontColor('#60596F')
          .lineHeight(18)
          .width('100%')
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 10 })
        if (this.profileStateVector) {
          Row() {
            this.VectorChip('V', this.profileStateVector.valence)
            this.VectorChip('A', this.profileStateVector.arousal)
            this.VectorChip('D', this.profileStateVector.dominance)
            this.VectorChip('S', this.profileStateVector.social)
            this.VectorChip('C', this.profileStateVector.cognitive)
          }.margin({ top: 10 })
        }
        Row() {
          Button('聊一聊')
            .width(84)
            .height(28)
            .fontSize(11)
            .fontColor('#FFF')
            .backgroundColor('#7658F6')
            .borderRadius(14)
            .onClick(() => this.openFeature('pages/Chat', '倾诉'))
          Button('写树洞')
            .width(84)
            .height(28)
            .fontSize(11)
            .fontColor('#7658F6')
            .backgroundColor('#FFF')
            .borderRadius(14)
            .margin({ left: 8 })
            .onClick(() => this.openFeature('pages/TreeHole', '树洞'))
        }.margin({ top: 10 })
      }.padding(20).width('100%').height('100%').alignItems(HorizontalAlign.Start)

      Image($r('app.media.avatar1'))
        .width(96)
        .height(96)
        .margin({ right: 2, bottom: 4 })
    }
    .height(168)
    .width('100%')
    .backgroundColor('#F0E9FF')
    .borderRadius(18)
    .clip(true)
  }

  @Builder
  VectorChip(label: string, value: number) {
    Column() {
      Text(label).fontSize(9).fontColor('#9B96AC')
      Text(`${Math.round(value * 100)}`).fontSize(11).fontWeight(FontWeight.Bold).fontColor('#5B4C9B')
    }
    .padding({
      left: 8,
      right: 8,
      top: 6,
      bottom: 6
    })
    .backgroundColor('#FFF')
    .borderRadius(10)
    .margin({ right: 6 })
  }

  @Builder
  Recommend() {
    Column() {
      Row() {
        Text('为你推荐').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#201B34')
        Blank()
        Row() {
          Image($r('app.media.refresh')).width(18).height(18).fillColor('#7658F6')
        }.padding(8).backgroundColor('#F3ECFF').borderRadius(999)
        .onClick(() => {
          this.refreshCurrentState();
        })
      }.margin({ top: 24, bottom: 14 }).width('100%')

      Row() {
        this.Tag('治愈时刻', 0)
        this.Tag('学习提升', 1)
        this.Tag('轻松娱乐', 2)
        this.Tag('成长记录', 3)
      }.justifyContent(FlexAlign.Center).margin({ bottom: 14 }).width('100%')

      GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
        if (this.recommendations.length > 0) {
          ForEach(this.recommendations.slice(0, 4), (item: Recommendation, index: number) => {
            GridCol({ span: { xs: 6, sm: 3 } }) {
              this.Rec(item.title, item.description || '温和陪伴和下一步建议', `${item.priority}`, this.recColor(index))
            }
          }, (item: Recommendation) => item.title)
        } else {
          GridCol({ span: { xs: 6, sm: 3 } }) {
            this.Rec('写进树洞', '把心情先放下来', '建议', '#7FA36B')
          }

          GridCol({ span: { xs: 6, sm: 3 } }) {
            this.Rec('做一次呼吸', '先让自己慢一点', '建议', '#C8B28C')
          }

          GridCol({ span: { xs: 6, sm: 3 } }) {
            this.Rec('去广场看看', '找一点共鸣', '建议', '#C9A391')
          }

          GridCol({ span: { xs: 6, sm: 3 } }) {
            this.Rec('看情绪报告', '回顾最近状态', '建议', '#6D74B8')
          }
        }
      }.width('100%')

      Row() {
        this.QuickAction('呼吸练习', 'pages/Chat', '倾诉')
        this.QuickAction('写入树洞', 'pages/TreeHole', '树洞')
        this.QuickAction('去广场', 'pages/Plaza', '广场')
        this.QuickAction('看推荐', 'pages/RecommendationPage', '发现')
      }.margin({ top: 10 }).width('100%')

      Row() {
        Button('刷新首页状态')
          .height(30)
          .fontSize(11)
          .backgroundColor('#F3ECFF')
          .fontColor('#7658F6')
          .borderRadius(15)
          .onClick(() => this.refreshCurrentState())
        Button('去推荐页')
          .height(30)
          .fontSize(11)
          .backgroundColor('#F6F2FF')
          .fontColor('#7658F6')
          .borderRadius(15)
          .margin({ left: 8 })
          .onClick(() => router.pushUrl({ url: 'pages/RecommendationPage' }))
        Button('画像趋势')
          .height(30)
          .fontSize(11)
          .backgroundColor('#EEF8FF')
          .fontColor('#3A7BBF')
          .borderRadius(15)
          .margin({ left: 8 })
          .onClick(() => router.pushUrl({ url: 'pages/ProfileTimeline' }))
        Button('搭子匹配')
          .height(30)
          .fontSize(11)
          .backgroundColor('#F0F7ED')
          .fontColor('#5A8A4E')
          .borderRadius(15)
          .margin({ left: 8 })
          .onClick(() => router.pushUrl({ url: 'pages/MatchPage' }))
      }.margin({ top: 12 }).width('100%')
    }.width('100%')
  }

  @Builder
  QuickAction(title: string, url: string, featureName: string) {
    Column() {
      Text(title).fontSize(12).fontColor('#5A526A').fontWeight(FontWeight.Medium)
      Button('打开')
        .fontSize(10)
        .height(28)
        .margin({ top: 8 })
        .backgroundColor('#FFFFFF')
        .fontColor('#7658F6')
        .borderRadius(14)
        .onClick(() => this.openFeature(url, featureName))
    }
    .layoutWeight(1)
    .padding(14)
    .backgroundColor('#FFF')
    .borderRadius(14)
    .margin({ right: 8 })
  }

  @Builder
  EntryGrid() {
    GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
      GridCol({ span: { xs: 6, sm: 3 } }) {
        this.EntryCard('AI 聊天', '倾诉和陪伴', '#8B6FF7', 'pages/Chat', '倾诉')
      }

      GridCol({ span: { xs: 6, sm: 3 } }) {
        this.EntryCard('私密树洞', '只给自己看', '#6DAA90', 'pages/TreeHole', '树洞')
      }

      GridCol({ span: { xs: 6, sm: 3 } }) {
        this.EntryCard('匿名广场', '匿名表达', '#E18B71', 'pages/Plaza', '广场')
      }

      GridCol({ span: { xs: 6, sm: 3 } }) {
        this.EntryCard('情绪报告', '查看趋势', '#5F7DDB', 'pages/EmotionReport', '发现')
      }

      GridCol({ span: { xs: 6, sm: 3 } }) {
        this.EntryCard('推荐页', '个性化建议', '#7B57FF', 'pages/RecommendationPage', '发现')
      }
    }.width('100%').margin({ top: 12 })
  }

  @Builder
  Tag(t: string, i: number) {
    Text(t)
      .fontSize(11)
      .fontColor(this.tag === i ? '#FFF' : '#8F89A0')
      .padding({
        left: 12,
        right: 12,
        top: 6,
        bottom: 6
      })
      .backgroundColor(this.tag === i ? '#7658F6' : '#F7F4FF')
      .borderRadius(13)
      .margin({ right: 8 })
      .onClick(() => {
        this.tag = i;
      })
  }

  @Builder
  Rec(t: string, d: string, time: string, c: string) {
    Column() {
      Stack() {
        Rect().width('100%').height(92).fill(c).opacity(0.22)
        Circle().width(90).height(90).fill(c).opacity(0.4)
        Text(time)
          .fontSize(9)
          .fontColor('#FFF')
          .backgroundColor('#00000055')
          .borderRadius(5)
          .padding({ left: 5, right: 5 })
          .position({ x: '66%', y: 72 })
      }.height(92).width('100%')

      Column() {
        Text(t).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#272137').maxLines(1)
        Text(d).fontSize(11).fontColor('#8C8597').maxLines(1).margin({ top: 4 })
        Text('建议').fontSize(10).fontColor(c).margin({ top: 8 })
      }.padding(10).alignItems(HorizontalAlign.Start)
    }
    .height(174)
    .width('100%')
    .backgroundColor('#FFF')
    .borderRadius(12)
    .clip(true)
  }

  @Builder
  Device() {
    Column() {
      Row() {
        Text('最近动态').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#201B34')
        Blank()
        Text('闭环入口').fontSize(11).fontColor('#7B57FF')
      }.width('100%').margin({ bottom: 10 })

      ForEach(this.recentActions, (item: GeneratedTypeLiteralInterface_2) => {
        Row() {
          Column() {
            Text(item.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#272137')
            Text(item.desc).fontSize(11).fontColor('#8C8597').margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start)

          Blank()
          Button('去')
            .fontSize(11)
            .height(28)
            .backgroundColor('#F3ECFF')
            .fontColor('#7658F6')
            .borderRadius(14)
            .onClick(() => this.openFeature(item.url, item.title))
        }
        .width('100%')
        .padding(14)
        .backgroundColor('#FFFFFF')
        .borderRadius(14)
        .margin({ bottom: 8 })
      })
    }.width('100%').margin({ top: 16 })
  }

  @Builder
  QuickLoop() {
    Column() {
      Row() {
        Text('快速闭环').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#201B34')
        Blank()
        Text('一键回到行动').fontSize(11).fontColor('#8B849B')
      }.width('100%').margin({ bottom: 10 })

      Row() {
        this.QuickAction('树洞记录', 'pages/TreeHole', '树洞')
        this.QuickAction('查看搭子', 'pages/MatchPage', '广场')
        this.QuickAction('安全帮助', 'pages/SafetyHelp', '广场')
      }.width('100%')
    }.width('100%').margin({ top: 14 })
  }

  @Builder
  Me() {
    Column() {
      Text('我的').fontSize(18).fontWeight(FontWeight.Bold)
      Button('退出登录').margin({ top: 20 }).onClick(() => this.doLogout())
    }.width('100%').padding(20)
  }

  @Builder
  Page(title: string, sub: string, btn: string, url: string, featureName: string) {
    Column() {
      Text(title).fontSize(22).fontWeight(FontWeight.Bold)
      Text(sub).fontSize(13).fontColor('#8B849B').margin({ top: 8 })
      Button(btn).margin({ top: 20 }).onClick(() => this.openFeature(url, featureName))
    }.width('100%').padding(20)
  }

  @Builder
  EntryCard(title: string, desc: string, color: string, url: string, featureName: string) {
    Column() {
      Text(title).fontSize(14).fontWeight(FontWeight.Bold)
      Text(desc).fontSize(11).fontColor('#8C8597').margin({ top: 6 })
      Button('打开')
        .fontSize(10)
        .height(28)
        .margin({ top: 10 })
        .backgroundColor(color)
        .fontColor('#FFF')
        .borderRadius(14)
        .onClick(() => this.openFeature(url, featureName))
    }.padding(12).backgroundColor('#FFF').borderRadius(14)
  }

  recColor(index: number): string {
    const colors = ['#7B57FF', '#6DAA90', '#E18B71', '#5F7DDB'];
    return colors[index % colors.length];
  }
}
