import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { AnonymousProfile, UserPrivacySettings } from '../models/Types';

const DEFAULT_API_BASE_URL = 'http://10.16.106.237:8080';

@Entry
@Component
struct AccountSettings {
  @State account: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State campus: string = '';
  @State apiBaseUrl: string = DEFAULT_API_BASE_URL;
  @State status: string = '温暖治愈，陪伴每一刻';
  @State profileName: string = '匿名同学';
  @State profileBio: string = '';
  @State allowChatAnalysis: boolean = true;
  @State allowLetterAnalysis: boolean = true;
  @State allowVoiceAnalysis: boolean = true;
  @State allowProfileUpdate: boolean = true;
  @State allowRecommendationUse: boolean = true;
  @State allowVoiceTextRetention: boolean = true;
  @State allowMultiDeviceSync: boolean = false;
  @State allowEmotionReminders: boolean = false;
  @State showLoginForm: boolean = false;
  @State isLoading: boolean = false;
  @State isPressed: boolean = false;

  aboutToAppear() {
    this.syncBaseUrl();
    this.load();
  }

  syncBaseUrl() {
    apiService.setBaseUrl(this.apiBaseUrl);
  }

  async load() {
    try {
      this.isLoading = true;
      this.syncBaseUrl();

      try {
        let me = await apiService.getMe();
        this.profileName = me.user.nickname || '用户';
        this.nickname = this.profileName;
        this.status = '已登录账号';
      } catch {
        this.profileName = '未登录';
        this.nickname = '';
        this.status = '请先登录账号';
      }

      try {
        let profileResp = await apiService.getAnonymousProfile();
        this.applyProfile(profileResp.profile);
      } catch {
        // If there is no anonymous profile yet, keep the current name.
      }
      try {
        let privacyResp = await apiService.getPrivacySettings();
        this.applyPrivacy(privacyResp.settings);
      } catch {
        // If privacy settings are unavailable, keep local defaults.
      }
    } catch (err) {
      this.status = '暂时无法同步设置';
      promptAction.showToast({ message: this.getErrorMessage(err, '设置加载失败') });
      console.error('account settings load failed', err);
    } finally {
      this.isLoading = false;
    }
  }

  applyProfile(profile: AnonymousProfile) {
    this.profileName = profile.display_name || '匿名同学';
    this.nickname = this.profileName;
    this.profileBio = profile.bio || '';
    this.campus = profile.campus || '';
  }

  applyPrivacy(settings: UserPrivacySettings) {
    this.allowChatAnalysis = settings.allow_chat_analysis;
    this.allowLetterAnalysis = settings.allow_letter_analysis;
    this.allowVoiceAnalysis = settings.allow_voice_analysis;
    this.allowProfileUpdate = settings.allow_profile_update;
    this.allowRecommendationUse = settings.allow_recommendation_use;
    this.allowVoiceTextRetention = settings.allow_voice_text_retention;
    this.allowMultiDeviceSync = settings.allow_multi_device_sync;
    this.allowEmotionReminders = settings.allow_emotion_reminders;
  }

  async login() {
    try {
      this.isLoading = true;
      this.syncBaseUrl();
      if (!this.account.trim()) {
        this.status = '请输入用户名';
        promptAction.showToast({ message: '请输入用户名' });
        return;
      }
      let result = await apiService.login(this.account.trim(), this.password);
      apiService.setToken(result.token);
      this.status = '登录成功';
      promptAction.showToast({ message: '登录成功' });
      await this.load();
      router.replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      this.status = '登录失败，请检查用户名和密码';
      promptAction.showToast({ message: this.getErrorMessage(err, '登录失败') });
      console.error('login failed', err);
    } finally {
      this.isLoading = false;
    }
  }

  async register() {
    try {
      this.isLoading = true;
      this.syncBaseUrl();
      if (!this.account.trim()) {
        this.status = '注册请填写用户名';
        promptAction.showToast({ message: '注册请填写用户名' });
        return;
      }
      let result = await apiService.register(this.account.trim(), this.password, this.nickname, this.campus);
      apiService.setToken(result.token);
      this.status = '注册成功，已自动登录';
      promptAction.showToast({ message: '注册成功' });
      await this.load();
      router.replaceUrl({ url: 'pages/Index' });
    } catch (err) {
      const message = this.getErrorMessage(err, '注册失败');
      if (message.includes('409') || message.includes('已被注册') || message.includes('duplicate')) {
        this.status = '这个用户名已经注册过了，请换一个再试';
      } else {
        this.status = '注册失败：用户名已存在，密码至少 8 位且含字母和数字';
      }
      promptAction.showToast({ message: this.status });
      console.error('register failed', err);
    } finally {
      this.isLoading = false;
    }
  }

  async saveProfile() {
    try {
      this.syncBaseUrl();
      let resp = await apiService.updateAnonymousProfile(this.nickname || this.profileName, this.profileBio, this.campus);
      this.applyProfile(resp.profile);
      this.status = '匿名身份已保存';
      promptAction.showToast({ message: '匿名身份已保存' });
    } catch (err) {
      this.status = '保存匿名身份失败';
      promptAction.showToast({ message: this.getErrorMessage(err, '保存匿名身份失败') });
      console.error('save profile failed', err);
    }
  }

  async randomProfile() {
    try {
      this.syncBaseUrl();
      let resp = await apiService.randomizeAnonymousProfile();
      this.applyProfile(resp.profile);
      this.status = '已随机生成新的匿名身份';
      promptAction.showToast({ message: '已随机生成新的匿名身份' });
    } catch (err) {
      this.status = '随机身份生成失败';
      promptAction.showToast({ message: this.getErrorMessage(err, '随机身份生成失败') });
      console.error('random profile failed', err);
    }
  }

  async savePrivacy() {
    try {
      this.syncBaseUrl();
      let resp = await apiService.updatePrivacySettings({
        allow_chat_analysis: this.allowChatAnalysis,
        allow_letter_analysis: this.allowLetterAnalysis,
        allow_voice_analysis: this.allowVoiceAnalysis,
        allow_profile_update: this.allowProfileUpdate,
        allow_recommendation_use: this.allowRecommendationUse,
        allow_voice_text_retention: this.allowVoiceTextRetention,
        allow_multi_device_sync: this.allowMultiDeviceSync,
        allow_emotion_reminders: this.allowEmotionReminders
      });
      this.applyPrivacy(resp.settings);
      this.status = '隐私设置已保存';
      promptAction.showToast({ message: '隐私设置已保存' });
    } catch (err) {
      this.status = '保存隐私设置失败';
      promptAction.showToast({ message: this.getErrorMessage(err, '保存隐私设置失败') });
      console.error('save privacy failed', err);
    }
  }

  async logout() {
    try {
      await apiService.logout();
      this.status = '已退出登录';
      promptAction.showToast({ message: '已退出登录' });
      router.replaceUrl({ url: 'pages/LoginPage' });
    } catch (err) {
      promptAction.showToast({ message: this.getErrorMessage(err, '退出失败') });
    }
  }

  getErrorMessage(err: Error | string | number | boolean | null | undefined, fallback: string): string {
    if (err instanceof Error && err.message) {
      return err.message;
    }
    if (typeof err === 'string' && err) {
      return err;
    }
    if (typeof err === 'number' || typeof err === 'boolean') {
      return String(err);
    }
    return fallback;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('‹').fontSize(30).fontColor('#7658F6').onClick(() => router.back())
        Text('账号与设置').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ left: 8 })
        Blank()
      }.width('100%').height(56).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          // Hero Section
          Column() {
            Text('🌿').fontSize(48)
            Text('树洞').fontSize(32).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ top: 12 })
            Text(this.status).fontSize(13).fontColor('#8B849B').margin({ top: 8 })
            TextInput({ text: this.apiBaseUrl, placeholder: '后端地址' })
              .height(42)
              .fontSize(14)
              .fontColor('#201B34')
              .backgroundColor('#F7F4FF')
              .borderRadius(12)
              .padding({ left: 14, right: 14 })
              .margin({ top: 14 })
              .onChange((value: string) => {
                this.apiBaseUrl = value;
                this.syncBaseUrl();
              })
          }
          .width('100%')
          .padding({ top: 32, bottom: 32 })
          .alignItems(HorizontalAlign.Center)

          // Main Action Card
          Column() {
            Button(this.isLoading ? '进入中...' : '直接开始匿名体验')
              .width('100%')
              .height(52)
              .fontSize(17)
              .fontColor('#FFF')
              .borderRadius(26)
              .linearGradient({
                angle: 135,
                colors: this.isPressed ? [['#6A4AE8', 0], ['#5A3ED0', 1]] : [['#7658F6', 0], ['#7B59FF', 1]]
              })
              .shadow({ radius: 16, color: '#7658F640', offsetY: 6 })
              .scale({ x: this.isPressed ? 0.97 : 1, y: this.isPressed ? 0.97 : 1 })
              .animation({ duration: 150, curve: Curve.EaseInOut })
              .onTouch((event: TouchEvent) => {
                if (event.type === TouchType.Down) { this.isPressed = true; }
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) { this.isPressed = false; }
              })
              .onClick(async () => {
                try {
                  this.isLoading = true;
                  let result = await apiService.createAnonymous();
                  apiService.setToken(result.token);
                  this.status = '已匿名进入';
                  promptAction.showToast({ message: '匿名体验已开启' });
                  router.replaceUrl({ url: 'pages/Index' });
                } catch (err) {
                  this.status = '匿名体验失败';
                  promptAction.showToast({ message: this.getErrorMessage(err, '匿名体验失败') });
                } finally {
                  this.isLoading = false;
                }
              })

            Text('登录已有账号')
              .fontSize(14)
              .fontColor('#8B849B')
              .margin({ top: 20 })
              .onClick(() => { animateTo({ duration: 200 }, () => { this.showLoginForm = !this.showLoginForm; }); })
          }
          .width('100%')
          .padding(24)
          .backgroundColor('#FFF')
          .borderRadius(24)
          .shadow({ radius: 20, color: '#8B7ED620', offsetY: 6 })
          .margin({ left: 18, right: 18 })

          // Expandable Login Form
          if (this.showLoginForm) {
            Column() {
              Text('账号密码登录').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#201B34').width('100%')

              this.MinimalInput('账号', this.account, (v: string) => { this.account = v; })
              this.MinimalInput('密码', this.password, (v: string) => { this.password = v; })
              this.MinimalInput('后端地址', this.apiBaseUrl, (v: string) => { this.apiBaseUrl = v; this.syncBaseUrl(); })

              Row() {
                Button('登录')
                  .layoutWeight(1).height(46)
                  .fontSize(15).fontColor('#FFF')
                  .backgroundColor('#7658F6')
                  .borderRadius(23)
                  .onClick(() => this.login())

                Button('注册')
                  .layoutWeight(1).height(46)
                  .fontSize(15).fontColor('#7658F6')
                  .backgroundColor('#EEE8FF')
                  .borderRadius(23)
                  .margin({ left: 12 })
                  .onClick(() => this.register())
              }.width('100%').margin({ top: 16 })
            }
            .width('100%')
            .padding(20)
            .backgroundColor('#FFF')
            .borderRadius(20)
            .margin({ left: 18, right: 18, top: 16 })
            .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: -10 } })
          }

          // Privacy controls
          Column() {
            Text('隐私设置').fontSize(16).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ bottom: 10 })
            this.SwitchRow('允许 AI 分析聊天', this.allowChatAnalysis, (v: boolean) => { this.allowChatAnalysis = v; })
            this.SwitchRow('允许 AI 分析树洞', this.allowLetterAnalysis, (v: boolean) => { this.allowLetterAnalysis = v; })
            this.SwitchRow('允许写入长期画像', this.allowProfileUpdate, (v: boolean) => { this.allowProfileUpdate = v; })
            this.SwitchRow('允许推荐使用近期状态', this.allowRecommendationUse, (v: boolean) => { this.allowRecommendationUse = v; })
            this.SwitchRow('允许保留语音转写', this.allowVoiceTextRetention, (v: boolean) => { this.allowVoiceTextRetention = v; })
            this.SwitchRow('允许多设备同步', this.allowMultiDeviceSync, (v: boolean) => { this.allowMultiDeviceSync = v; })
            this.SwitchRow('接收情绪提醒', this.allowEmotionReminders, (v: boolean) => { this.allowEmotionReminders = v; })
            Button('保存隐私设置').width('100%').height(46).backgroundColor('#7658F6').fontColor('#FFF').borderRadius(23)
              .margin({ top: 12 }).onClick(() => this.savePrivacy())
          }
          .width('100%')
          .padding(20)
          .backgroundColor('#FFF')
          .borderRadius(20)
          .margin({ left: 18, right: 18, top: 16 })

          Row() {
            Text('登录即表示同意')
              .fontSize(11)
              .fontColor('#B9B5C8')
            Text('《隐私政策》')
              .fontSize(11)
              .fontColor('#7658F6')
          }
          .margin({ top: 18 })
          .padding({ bottom: 32 })
        }
        .width('100%')
        .constraintSize({ maxWidth: 720 })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }

  @Builder MinimalInput(label: string, value: string, onChange: (v: string) => void) {
    Column() {
      TextInput({ text: value, placeholder: label })
        .height(48)
        .fontSize(15)
        .fontColor('#201B34')
        .placeholderColor('#B9B5C8')
        .backgroundColor('#F7F4FF')
        .borderRadius(14)
        .onChange(onChange)
    }
    .width('100%')
    .margin({ top: 12 })
  }

  @Builder SwitchRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(13).fontColor('#4A435B')
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value }).onChange(onChange)
    }.width('100%').height(40)
  }
}
