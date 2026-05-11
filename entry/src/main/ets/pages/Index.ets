import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { User, Recommendation, EmotionReport, ProfileStateVector } from '../models/Types';

interface EmotionReportResult extends EmotionReport {
  risk_level?: string;
}

interface FeatureEntry {
  title: string;
  desc: string;
  icon: string;
  tint: string;
  url: string;
  featureName: string;
}

interface FutureAction {
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

@Entry
@Component
struct Index {
  @State tab: number = 0;
  @State emotion: string = '平静';
  @State care: string = '检测到你最近有些疲惫，要不要试试放松一下？';
  @State guestLimitText: string = '游客模式无法保存记录，登录账号可解锁完整树洞功能';
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
  @State isHeroPressed: boolean = false;
  @State selectedOrb: number = 0;
  @State cardLift: boolean = false;
  @State glowPhase: number = 0;
  @State featureEntries: FeatureEntry[] = [
    { title: '无压力倾诉', desc: '安心表达', icon: '♥', tint: '#FF7DB7', url: 'pages/Chat', featureName: '倾诉' },
    { title: 'AI共情陪伴', desc: '温暖回应', icon: '✦', tint: '#6F62FF', url: 'pages/Chat', featureName: '倾诉' },
    { title: '隐私安全', desc: '严格保护', icon: '▣', tint: '#31C96A', url: 'pages/SafetyHelp', featureName: '安全帮助' }
  ];
  @State recentActions: FutureAction[] = [
    { title: '去树洞记录', desc: '把刚刚的情绪放进安全空间', url: 'pages/TreeHole' },
    { title: '查看搭子匹配', desc: '看看当前画像适合怎样的搭子', url: 'pages/MatchPage' },
    { title: '打开安全帮助', desc: '当需要稳住当下时先来这里', url: 'pages/SafetyHelp' }
  ];

  aboutToAppear() {
    this.load();
    try {
      animateTo({ duration: 1500, curve: Curve.EaseInOut, iterations: -1, playMode: PlayMode.Alternate }, () => {
        this.glowPhase = 1;
        this.cardLift = true;
      });
    } catch (err) {
      console.error('animateTo failed', err);
    }
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
        this.profileSignalsText = profile.preference_signals.prefersVoice ? '更偏好语音表达' :
          profile.preference_signals.prefersPrivateWriting ? '更偏好私密写作' :
            profile.preference_signals.prefersDirectAdvice ? '更偏好直接建议' :
              profile.preference_signals.openToPublicInteraction ? '愿意公开互动' : '画像偏好待观察';
        this.care = profile.preference_signals.prefersVoice ? '你更适合语音表达，先说出来会更轻松。' :
          profile.preference_signals.prefersPrivateWriting ? '你更适合先写下来，再慢慢整理。' :
            profile.preference_signals.prefersDirectAdvice ? '你最近更需要直接一点的建议。' : this.care;
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
      try {
        animateTo({ duration: 520, curve: Curve.Friction }, () => {
          this.isLoading = false;
        });
      } catch (err) {
        this.isLoading = false;
      }
    }
  }

  private requireAuth(actionName: string): boolean {
    if (!this.isGuest) {
      return true;
    }
    let toastOptions: ToastOptions = { message: `${actionName}需要先登录或选择匿名体验` };
    try {
      promptAction.showToast(toastOptions);
    } catch (err) {
      console.error('showToast failed', err);
    }
    try {
      router.pushUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      console.error('pushUrl failed', err);
    }
    return false;
  }

  private openFeature(url: string, featureName: string): void {
    if (featureName && !this.requireAuth(featureName)) {
      return;
    }
    try {
      router.pushUrl({ url: url } as PushUrlOptions);
    } catch (err) {
      console.error('pushUrl failed', err);
    }
  }

  private refreshCurrentState(): void {
    try {
      animateTo({ duration: 380, curve: Curve.EaseOut }, () => {
        this.cardLift = !this.cardLift;
        this.glowPhase = this.glowPhase === 0 ? 1 : 0;
      });
    } catch (err) {
      console.error('animateTo failed', err);
    }
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
      try {
        promptAction.showToast({ message: '已退出登录' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      try {
        router.replaceUrl({ url: 'pages/LoginPage' });
      } catch (err) {
        console.error('replaceUrl failed', err);
      }
    }
  }

  build() {
    Stack() {
      this.FluidBackground()
      if (this.isLoading) {
        this.LoadingView()
      } else {
        Tabs({ barPosition: BarPosition.End }) {
          TabContent() { this.Home() }.tabBar(this.Tab('首页', $r('app.media.home'), 0))
          TabContent() { this.FeaturePage('树洞', '登录树洞，发现更多美好', '进入树洞', 'pages/TreeHole', '树洞') }.tabBar(this.Tab('树洞', $r('app.media.message'), 1))
          TabContent() { this.FeaturePage('倾诉', '今天想说点什么吗？', '开始今日倾诉', 'pages/Chat', '倾诉') }.tabBar(this.CenterTab())
          TabContent() { this.FeaturePage('广场', '匿名共鸣，连接真实的你', '进入广场', 'pages/Plaza', '广场') }.tabBar(this.Tab('广场', $r('app.media.community'), 3))
          TabContent() { this.ProfilePage() }.tabBar(this.Tab('我的', $r('app.media.profile'), 4))
        }
        .barHeight(82)
        .barBackgroundColor('#FFFFFFD9')
        .backgroundColor(Color.Transparent)
        .onChange((i: number) => {
          try {
            animateTo({ duration: 320, curve: Curve.EaseOut }, () => {
              this.tab = i;
            });
          } catch (err) {
            console.error('animateTo failed', err);
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F3FF')
  }

  @Builder
  FluidBackground() {
    Stack() {
      Rect().width('100%').height('100%').fill('#FAF8FF')
      Circle().width(this.glowPhase === 0 ? 330 : 390).height(this.glowPhase === 0 ? 330 : 390).fill('#DDD1FF').opacity(0.92).blur(42).position({ x: -118, y: -74 })
      Circle().width(this.glowPhase === 0 ? 250 : 310).height(this.glowPhase === 0 ? 250 : 310).fill('#BDA7FF').opacity(0.42).blur(54).position({ x: '58%', y: 34 })
      Circle().width(this.glowPhase === 0 ? 210 : 260).height(this.glowPhase === 0 ? 210 : 260).fill('#F8CBE8').opacity(0.42).blur(60).position({ x: '66%', y: '50%' })
      Circle().width(260).height(260).fill('#EAF9F0').opacity(0.68).blur(70).position({ x: -72, y: '62%' })
      this.SoftLeaf(22, 148, 46, '#D8C4FF')
      this.SoftLeaf(326, 92, 58, '#C0A8FF')
      this.SoftLeaf(380, 166, 42, '#D9C7FF')
      Row() {
        Circle().width(4).height(4).fill('#FFFFFF')
        Circle().width(4).height(4).fill('#FFFFFF').margin({ left: 8 })
        Circle().width(4).height(4).fill('#FFFFFF').margin({ left: 8 })
        Circle().width(4).height(4).fill('#FFFFFF').margin({ left: 8 })
      }.position({ x: 42, y: 222 }).opacity(0.8)
      Rect().width('100%').height(96).fill('#F3E8FF66').borderRadius({ topLeft: 60, topRight: 120 }).position({ x: 0, y: '88%' }).blur(3)
    }.width('100%').height('100%')
  }

  @Builder
  SoftLeaf(x: number, y: number, size: number, color: string) {
    Ellipse().width(size).height(size * 1.75).fill(color).opacity(0.56).rotate({ angle: -28 }).blur(1).position({ x: x, y: y })
  }

  @Builder
  LoadingView() {
    Column() {
      Stack() {
        Circle().width(78).height(78).fill('#FFFFFFA8').backdropBlur(24)
        Circle().width(this.glowPhase === 0 ? 38 : 52).height(this.glowPhase === 0 ? 38 : 52).fill('#7C55FF').opacity(0.72).blur(4)
      }
      Text('正在同步树洞情绪').fontSize(14).fontColor('#7D7392').margin({ top: 16 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder
  Home() {
    Scroll() {
      Column() {
        this.StatusBarMock()
        this.HomeHeader()
        this.MascotHero()
        this.ChatEntrance()
        this.FeatureEntryGrid()
        this.StatusCareGrid()
        this.RecommendCards()
        Text('陪伴而不诊断 · 引导而不治疗').fontSize(11).fontColor('#A29AAF').letterSpacing(1).margin({ top: 18, bottom: 110 })
      }
      .width('100%')
      .constraintSize({ maxWidth: 760 })
      .padding({ left: 22, right: 22, top: 10 })
      .alignItems(HorizontalAlign.Center)
    }.width('100%').height('100%').backgroundColor(Color.Transparent)
  }

  @Builder
  StatusBarMock() {
    Row() {
      Text('10:34').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#141326')
      Blank()
      Text('◐  ⌁⌁  Wi‑Fi  100').fontSize(12).fontWeight(FontWeight.Medium).fontColor('#141326')
    }.width('100%').height(28)
  }

  @Builder
  HomeHeader() {
    Row() {
      Column() {
        Text('早上好  👋').fontSize(14).fontColor('#4D4960')
        Text('欢迎回来').fontSize(30).fontWeight(FontWeight.Bold).fontColor('#19172C').margin({ top: 10 })
        Text(this.isGuest ? '登录树洞，发现更多美好' : '很高兴再次见到你')
          .fontSize(14).fontColor('#7F788E').margin({ top: 10 })
      }.alignItems(HorizontalAlign.Start)
      Blank()
      Column() {
        Row() {
          Text('▣').fontSize(14).fontColor('#332F45')
          Text(' 多设备已连接  ›').fontSize(13).fontColor('#332F45')
        }
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .backgroundColor('#FFFFFF8C')
        .borderRadius(16)
        .backdropBlur(18)
        .onClick(() => this.openFeature('pages/ProfileTimeline', '设备管理'))
        Row() {
          Text('🛡').fontSize(14)
          Text(this.isGuest ? ' 未登录' : ' 已登录账号').fontSize(12).fontColor('#5A526A')
        }.margin({ top: 20 })
      }.alignItems(HorizontalAlign.End)
    }.width('100%').margin({ top: 12 })
  }

  @Builder
  MascotHero() {
    Stack() {
      Circle().width(94).height(94).fill('#BCA4FF').opacity(this.glowPhase === 0 ? 0.72 : 0.92).blur(1).position({ x: '61%', y: 18 })
      Ellipse().width(114).height(36).fill('#A48CFF').opacity(0.45).rotate({ angle: -16 }).position({ x: '55%', y: 54 })
      Circle().width(70).height(70).fill('#F9F6FF').shadow({ radius: 18, color: '#9D84FF44', offsetY: 8 }).position({ x: '66%', y: 88 })
      Text('⌣').fontSize(26).fontColor('#332D52').position({ x: '72%', y: 112 })
      this.Sparkle(36, 70)
      this.Sparkle(306, 28)
    }.width('100%').height(170).margin({ top: -8 })
  }

  @Builder
  Sparkle(x: number, y: number) {
    Text('✦').fontSize(this.glowPhase === 0 ? 12 : 18).fontColor('#FFFFFF').opacity(0.88).position({ x: x, y: y })
  }

  @Builder
  ChatEntrance() {
    Stack() {
      Circle().width(132).height(132).fill('#ECE5FF').opacity(0.78).position({ x: '73%', y: 24 })
      Circle().width(112).height(84).fill('#DFD5FF').opacity(0.76).position({ x: '70%', y: 64 })
      Circle().width(12).height(12).fill('#8A6CFF').position({ x: '76%', y: 74 })
      Circle().width(12).height(12).fill('#A48EFF').position({ x: '83%', y: 74 })
      Circle().width(12).height(12).fill('#C0B0FF').position({ x: '90%', y: 74 })
      Column() {
        Text('今天想说点什么吗？').fontSize(20).fontWeight(FontWeight.Bold).fontColor('#201D35')
        Text('倾诉一下，让心情更轻松').fontSize(14).fontColor('#8A8398').margin({ top: 8 })
        Button('开始今日倾诉   ›')
          .height(44)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#7655F6')
          .borderRadius(16)
          .margin({ top: 20 })
          .shadow({ radius: this.cardLift ? 24 : 14, color: '#7655F666', offsetY: this.cardLift ? 10 : 6 })
          .sharedTransition('chat-entrance')
          .onClick(() => this.openFeature('pages/Chat', '倾诉'))
      }
      .width('62%')
      .alignItems(HorizontalAlign.Start)
      .position({ x: 24, y: 28 })
    }
    .width('100%')
    .height(156)
    .margin({ top: 2 })
    .backgroundColor('#FFFFFFCC')
    .border({ width: 1, color: '#FFFFFF' })
    .borderRadius(24)
    .backdropBlur(28)
    .clip(true)
    .scale({ x: this.isHeroPressed ? 0.985 : 1, y: this.isHeroPressed ? 0.985 : 1 })
    .shadow({ radius: 28, color: '#8B7AFF1F', offsetY: 12 })
    .gesture(LongPressGesture({ repeat: false }).onAction(() => {
      try {
        animateTo({ duration: 160, curve: Curve.EaseOut }, () => { this.isHeroPressed = true; });
        animateTo({ duration: 260, curve: Curve.EaseOut }, () => { this.isHeroPressed = false; });
      } catch (err) {
        console.error('animateTo failed', err);
      }
    }))
  }

  @Builder
  FeatureEntryGrid() {
    GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
      ForEach(this.featureEntries, (item: FeatureEntry) => {
        GridCol({ span: { xs: 4, sm: 4, md: 4, lg: 4 } }) {
          this.MiniFeatureCard(item)
        }
      }, (item: FeatureEntry) => item.title)
    }.width('100%').margin({ top: 16 })
  }

  @Builder
  MiniFeatureCard(item: FeatureEntry) {
    Column() {
      Stack() {
        Circle().width(42).height(42).fill(item.tint).opacity(0.14)
        Text(item.icon).fontSize(23).fontColor(item.tint)
      }.width(48).height(48)
      Text(item.title).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#27243A').maxLines(1).margin({ top: 8 })
      Text(item.desc).fontSize(11).fontColor('#918A9F').margin({ top: 4 })
    }
    .height(112)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFFD9')
    .border({ width: 1, color: '#FFFFFF' })
    .borderRadius(18)
    .backdropBlur(22)
    .shadow({ radius: 18, color: `${item.tint}20`, offsetY: 8 })
    .onClick(() => this.openFeature(item.url, item.featureName))
  }

  @Builder
  StatusCareGrid() {
    GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
      GridCol({ span: { xs: 6, sm: 6, md: 6, lg: 6 } }) { this.CurrentStatusCard() }
      GridCol({ span: { xs: 6, sm: 6, md: 6, lg: 6 } }) { this.DailyCareCard() }
    }.width('100%').margin({ top: 16 })
  }

  @Builder
  CurrentStatusCard() {
    Column() {
      Row() {
        Text('当前状态').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#232037')
        Text(' 更新于 09:30').fontSize(10).fontColor('#A7A0B3').margin({ left: 8 })
      }.width('100%')
      Row() {
        Column() {
          Text('☺').fontSize(45).textAlign(TextAlign.Center).width(68).height(68).backgroundColor('#FFF6D7').borderRadius(34)
          Text('情绪').fontSize(11).fontColor('#A7A0B3').margin({ top: 8 })
          Text(`${this.emotion}  ${Math.round(this.emotionIntensity * 100)}分`).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#28243A').margin({ top: 3 })
        }.width('48%')
        Divider().vertical(true).height(112).color('#EEEAF4')
        Column() {
          this.StatusLine('⌂', '场景', this.isAnonymous ? '匿名' : '居家')
          this.StatusLine('▯', '能量值', this.riskLevel === 'low' ? '82%' : this.riskLevel)
        }.layoutWeight(1).padding({ left: 12 }).alignItems(HorizontalAlign.Start)
      }.width('100%').margin({ top: 14 })
      Row() {
        Text('专注度').fontSize(12).fontColor('#8F879A')
        Progress({ value: 68, total: 100, type: ProgressType.Linear }).layoutWeight(1).height(6).color('#8061F8').backgroundColor('#EDE8F5').margin({ left: 10, right: 10 })
        Text('68%').fontSize(13).fontWeight(FontWeight.Bold).fontColor('#29253A')
      }.width('100%').margin({ top: 12 })
    }
    .height(226)
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFFD9')
    .border({ width: 1, color: '#FFFFFF' })
    .borderRadius(22)
    .backdropBlur(24)
    .shadow({ radius: 24, color: '#8B7AFF18', offsetY: 10 })
  }

  @Builder
  StatusLine(icon: string, label: string, value: string) {
    Row() {
      Text(icon).fontSize(20).fontColor('#8061F8').width(36).height(36).textAlign(TextAlign.Center).backgroundColor('#F0ECFF').borderRadius(12)
      Column() {
        Text(label).fontSize(10).fontColor('#A7A0B3')
        Text(value).fontSize(14).fontWeight(FontWeight.Bold).fontColor('#28243A').margin({ top: 3 })
      }.alignItems(HorizontalAlign.Start).margin({ left: 10 })
    }.margin({ bottom: 14 })
  }

  @Builder
  DailyCareCard() {
    Stack() {
      Column() {
        Text('每日关怀').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#232037')
        Text(`“${this.care}”`).fontSize(13).fontColor('#746D82').lineHeight(21).margin({ top: 18 }).maxLines(3)
        Text('去放松一下  ›').fontSize(13).fontColor('#7655F6').margin({ top: 16 }).onClick(() => this.openFeature('pages/Chat', '倾诉'))
      }.width('100%').height('100%').padding(18).alignItems(HorizontalAlign.Start)
      Ellipse().width(70).height(120).fill('#A9D69B').rotate({ angle: 28 }).opacity(0.92).position({ x: '61%', y: 118 })
      Rect().width(56).height(44).fill('#F6EFD6').borderRadius(10).position({ x: '75%', y: 152 })
      Rect().width(58).height(22).fill('#FFFFFF').borderRadius(11).position({ x: '57%', y: 178 })
    }
    .height(226)
    .width('100%')
    .backgroundColor('#FFFFFFC9')
    .border({ width: 1, color: '#FFFFFF' })
    .borderRadius(22)
    .backdropBlur(24)
    .clip(true)
    .shadow({ radius: 24, color: '#8B7AFF16', offsetY: 10 })
  }

  @Builder
  RecommendCards() {
    Column() {
      Row() {
        Text('为你推荐').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#242138')
        Blank()
        Text('换一换  ↻').fontSize(12).fontColor('#7B7489').onClick(() => this.refreshCurrentState())
      }.width('100%').margin({ bottom: 12 })
      GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
        if (this.recommendations.length > 0) {
          ForEach(this.recommendations.slice(0, 4), (item: Recommendation, index: number) => {
            GridCol({ span: { xs: 3, sm: 3, md: 3, lg: 3 } }) {
              this.MediaCard(item.title, `${Math.max(8, (index + 1) * 4)} 分钟`, this.recColor(index))
            }
          }, (item: Recommendation) => item.title)
        } else {
          GridCol({ span: { xs: 3, sm: 3, md: 3, lg: 3 } }) { this.MediaCard('晨间放松', '8 分钟', '#BFE4BF') }
          GridCol({ span: { xs: 3, sm: 3, md: 3, lg: 3 } }) { this.MediaCard('海边冥想', '12 分钟', '#F0B7A5') }
          GridCol({ span: { xs: 3, sm: 3, md: 3, lg: 3 } }) { this.MediaCard('情绪日记', '15 分钟', '#D8BCA8') }
          GridCol({ span: { xs: 3, sm: 3, md: 3, lg: 3 } }) { this.MediaCard('助眠音乐', '20 分钟', '#5E72B8') }
        }
      }.width('100%')
    }.width('100%').margin({ top: 22 })
  }

  @Builder
  MediaCard(title: string, time: string, color: string) {
    Column() {
      Stack() {
        Rect().width('100%').height(80).fill(color).opacity(0.72)
        Circle().width(30).height(30).fill('#FFFFFFD9')
        Text('▶').fontSize(13).fontColor('#6B6178')
      }.width('100%').height(80).borderRadius({ topLeft: 16, topRight: 16 }).clip(true)
      Text(title).fontSize(13).fontWeight(FontWeight.Bold).fontColor('#2B273B').maxLines(1).margin({ top: 10 })
      Text(time).fontSize(11).fontColor('#9B93A7').margin({ top: 4 })
    }
    .height(152)
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .backgroundColor('#FFFFFFC9')
    .borderRadius(16)
    .clip(true)
    .shadow({ radius: 16, color: '#7564BB14', offsetY: 8 })
    .onClick(() => this.openFeature('pages/RecommendationPage', '发现'))
  }

  @Builder
  FeaturePage(title: string, sub: string, btn: string, url: string, featureName: string) {
    Column() {
      Stack() {
        Circle().width(130).height(130).fill('#BDA7FF').opacity(0.82).blur(4)
        Circle().width(82).height(82).fill('#FFFFFFD9').shadow({ radius: 18, color: '#9D84FF44', offsetY: 8 })
        Text('⌣').fontSize(28).fontColor('#332D52')
      }.width(160).height(150).sharedTransition(featureName === '倾诉' ? 'chat-entrance' : 'feature-card')
      Text(title).fontSize(36).fontWeight(FontWeight.Bold).fontColor('#19172C').margin({ top: 16 })
      Text(sub).fontSize(15).fontColor('#80788F').textAlign(TextAlign.Center).margin({ top: 10 })
      Button(btn).height(50).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF').backgroundColor('#7655F6').borderRadius(25).margin({ top: 28 })
        .onClick(() => this.openFeature(url, featureName))
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).padding(32)
  }

  @Builder
  ProfilePage() {
    Scroll() {
      Column() {
        this.ProfileOrb()
        Text(this.currentUser?.nickname || (this.isAnonymous ? '匿名同学' : '校园同学'))
          .fontSize(30)
          .fontWeight(FontWeight.Bold)
          .fontColor('#19172C')
          .margin({ top: 14 })
        Text(this.isGuest ? '未登录' : (this.isAnonymous ? '匿名体验账号' : '正式校园账号'))
          .fontSize(13)
          .fontColor('#7655F6')
          .padding({ left: 14, right: 14, top: 7, bottom: 7 })
          .backgroundColor('#EFE9FF')
          .borderRadius(16)
          .margin({ top: 8 })
        this.ProfileInfoCard()
        this.ProfileStatsGrid()
        this.ProfilePrivacyCard()
        Row() {
          Button('画像趋势')
            .layoutWeight(1)
            .height(46)
            .fontColor('#7655F6')
            .backgroundColor('#FFFFFFD9')
            .borderRadius(23)
            .onClick(() => this.openFeature('pages/ProfileTimeline', '画像趋势'))
          Button(this.isGuest ? '去登录' : '退出登录')
            .layoutWeight(1)
            .height(46)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isGuest ? '#7655F6' : '#D9534F')
            .borderRadius(23)
            .margin({ left: 12 })
            .onClick(() => {
              if (this.isGuest) {
                try {
                  router.pushUrl({ url: 'pages/LoginPage' });
                } catch (err) {
                  console.error('pushUrl failed', err);
                }
              } else {
                this.doLogout();
              }
            })
        }
        .width('100%')
        .margin({ top: 18, bottom: 110 })
      }
      .width('100%')
      .constraintSize({ maxWidth: 760 })
      .padding({ left: 22, right: 22, top: 42 })
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  ProfileInfoCard() {
    Column() {
      Row() {
        Text('基本信息').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#242138')
        Blank()
        Text(this.profileOverviewReady ? '已同步' : '待同步').fontSize(12).fontColor('#7B7489')
      }.width('100%').margin({ bottom: 14 })
      this.InfoRow('账号 ID', this.currentUser?.id || '暂无')
      this.InfoRow('昵称', this.currentUser?.nickname || (this.isAnonymous ? '匿名同学' : '未设置'))
      this.InfoRow('校园', this.currentUser?.campus || '未填写')
      this.InfoRow('入学年份', this.currentUser?.enrollment_year ? `${this.currentUser?.enrollment_year}` : '未填写')
      this.InfoRow('账号状态', this.currentUser?.account_status || (this.isGuest ? 'guest' : 'active'))
      this.InfoRow('风险等级', this.riskLevel)
    }
    .width('100%')
    .padding(18)
    .margin({ top: 18 })
    .backgroundColor('#FFFFFFD9')
    .border({ width: 1, color: '#FFFFFF' })
    .borderRadius(24)
    .backdropBlur(24)
    .shadow({ radius: 24, color: '#8B7AFF18', offsetY: 10 })
  }

  @Builder
  InfoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor('#8F879A')
      Blank()
      Text(value).fontSize(13).fontWeight(FontWeight.Medium).fontColor('#29253A').maxLines(1)
    }.width('100%').padding({ top: 8, bottom: 8 })
  }

  @Builder
  ProfileStatsGrid() {
    GridRow({ columns: 12, gutter: { x: 12, y: 12 } }) {
      GridCol({ span: { xs: 6, sm: 3, md: 3, lg: 3 } }) { this.ProfileStatCard('互动', `${this.currentUser?.total_interactions || 0}`, '#7655F6') }
      GridCol({ span: { xs: 6, sm: 3, md: 3, lg: 3 } }) { this.ProfileStatCard('情绪', this.emotion, '#FF7DB7') }
      GridCol({ span: { xs: 6, sm: 3, md: 3, lg: 3 } }) { this.ProfileStatCard('强度', `${Math.round(this.emotionIntensity * 100)}分`, '#31C96A') }
      GridCol({ span: { xs: 6, sm: 3, md: 3, lg: 3 } }) { this.ProfileStatCard('搭子', this.profileSignalsText, '#E18B71') }
    }.width('100%').margin({ top: 14 })
  }

  @Builder
  ProfileStatCard(label: string, value: string, color: string) {
    Column() {
      Circle().width(10).height(10).fill(color)
      Text(value).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#242138').maxLines(1).margin({ top: 10 })
      Text(label).fontSize(12).fontColor('#8F879A').margin({ top: 5 })
    }
    .height(108)
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#FFFFFFD9')
    .borderRadius(20)
    .shadow({ radius: 18, color: `${color}18`, offsetY: 8 })
  }

  @Builder
  ProfilePrivacyCard() {
    Column() {
      Row() {
        Text('画像与隐私').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#242138')
        Blank()
        Text('OpenHarmony 多设备协同').fontSize(11).fontColor('#7655F6')
      }.width('100%')
      Text(this.profileOverviewText)
        .fontSize(13)
        .fontColor('#746D82')
        .lineHeight(21)
        .margin({ top: 12 })
        .width('100%')
      Text(this.profileSignalsText)
        .fontSize(13)
        .fontColor('#746D82')
        .margin({ top: 8 })
        .width('100%')
    }
    .width('100%')
    .padding(18)
    .margin({ top: 14 })
    .backgroundColor('#FFFFFFCC')
    .borderRadius(24)
    .backdropBlur(24)
  }

  @Builder
  ProfileOrb() {
    Stack() {
      Circle().width(150).height(150).fill('#E4DCFF').backdropBlur(24)
      Circle().width(this.glowPhase === 0 ? 88 : 104).height(this.glowPhase === 0 ? 88 : 104).fill('#8B6CFF').opacity(0.72).blur(5)
      Text(this.emotion).fontSize(24).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
    }.width(170).height(170).sharedTransition('emotion-orb')
  }

  @Builder
  Tab(t: string, icon: Resource, n: number) {
    Column() {
      Image(icon).width(24).height(24).fillColor(this.tab === n ? '#7655F6' : '#9994A6')
      Text(t).fontSize(10).fontColor(this.tab === n ? '#7655F6' : '#9994A6').fontWeight(this.tab === n ? FontWeight.Bold : FontWeight.Regular).margin({ top: 4 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  @Builder
  CenterTab() {
    Column() {
      Stack() {
        Circle().width(62).height(62).fill('#7655F6').shadow({ radius: 24, color: '#7655F666', offsetY: 8 })
        Circle().width(this.glowPhase === 0 ? 38 : 48).height(this.glowPhase === 0 ? 38 : 48).fill('#9B82FF').opacity(0.7)
        Image($r('app.media.voice')).width(27).height(27).fillColor('#FFFFFF')
      }.sharedTransition('chat-entrance')
      Text('倾诉').fontSize(10).fontColor('#7655F6').fontWeight(FontWeight.Bold).margin({ top: 2 })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }

  recColor(index: number): string {
    const colors = ['#BFE4BF', '#F0B7A5', '#D8BCA8', '#5E72B8'];
    return colors[index % colors.length];
  }
}
