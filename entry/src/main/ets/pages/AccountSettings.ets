import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';
import { AnonymousProfile, UserPrivacySettings } from '../models/Types';

const DEFAULT_API_BASE_URL = 'http://192.168.1.100:8080';

@Entry
@Component
struct AccountSettings {
  @State account: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State campus: string = '';
  @State apiBaseUrl: string = DEFAULT_API_BASE_URL;
  @State status: string = '可直接进入匿名体验，或登录正式账号';
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

  aboutToAppear() {
    this.syncBaseUrl();
    this.load();
  }

  syncBaseUrl() {
    apiService.setBaseUrl(this.apiBaseUrl);
  }

  async load() {
    try {
      this.syncBaseUrl();
      await apiService.ensureAnonymousUser();
      let profileResp = await apiService.getAnonymousProfile();
      this.applyProfile(profileResp.profile);
      let privacyResp = await apiService.getPrivacySettings();
      this.applyPrivacy(privacyResp.settings);
      this.status = '已进入匿名体验，账号与隐私设置已同步';
      promptAction.showToast({ message: '已进入匿名体验' });
    } catch (err) {
      this.status = '暂时无法同步设置，请确认后端服务已启动';
      promptAction.showToast({ message: this.getErrorMessage(err, '匿名体验进入失败') });
      console.error('account settings load failed', err);
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
      this.syncBaseUrl();
      await apiService.login(this.account, this.password);
      this.status = '登录成功';
      promptAction.showToast({ message: '登录成功' });
      await this.load();
    } catch (err) {
      this.status = '登录失败，请检查账号和密码';
      promptAction.showToast({ message: this.getErrorMessage(err, '登录失败') });
      console.error('login failed', err);
    }
  }

  async register() {
    try {
      this.syncBaseUrl();
      await apiService.register(this.account, this.password, this.nickname, this.campus);
      this.status = '注册成功，已自动登录';
      promptAction.showToast({ message: '注册成功' });
      await this.load();
    } catch (err) {
      this.status = '注册失败：账号至少 2 位，密码至少 8 位';
      promptAction.showToast({ message: this.getErrorMessage(err, '注册失败') });
      console.error('register failed', err);
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
    Scroll() {
      Column() {
        Row() {
          Text('‹').fontSize(30).fontColor('#7658F6').onClick(() => router.back())
          Text('账号与隐私').fontSize(22).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ left: 8 })
          Blank()
        }.width('100%').height(56).alignItems(VerticalAlign.Center)

        Text(this.status).fontSize(12).fontColor('#7E788F').width('100%').margin({ bottom: 14 })

        Button('直接开始匿名体验')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontColor('#FFF')
          .backgroundColor('#7658F6')
          .borderRadius(24)
          .onClick(() => this.load())

        this.SectionTitle('正式账号（可选）')
        this.Input('账号', this.account, (v: string) => { this.account = v; })
        this.Input('密码', this.password, (v: string) => { this.password = v; })
        this.Input('后端地址', this.apiBaseUrl, (v: string) => { this.apiBaseUrl = v; this.syncBaseUrl(); })
        Row() {
          Button('登录').layoutWeight(1).height(42).fontColor('#FFF').backgroundColor('#7658F6').borderRadius(21).onClick(() => this.login())
          Button('注册').layoutWeight(1).height(42).fontColor('#7658F6').backgroundColor('#EEE8FF').borderRadius(21).margin({ left: 10 }).onClick(() => this.register())
        }.width('100%').margin({ top: 8, bottom: 18 })

        this.SectionTitle('匿名身份')
        this.Input('匿名昵称', this.nickname, (v: string) => { this.nickname = v; })
        this.Input('个性签名', this.profileBio, (v: string) => { this.profileBio = v; })
        this.Input('校区', this.campus, (v: string) => { this.campus = v; })
        Row() {
          Button('保存身份').layoutWeight(1).height(42).fontColor('#FFF').backgroundColor('#7658F6').borderRadius(21).onClick(() => this.saveProfile())
          Button('随机身份').layoutWeight(1).height(42).fontColor('#7658F6').backgroundColor('#EEE8FF').borderRadius(21).margin({ left: 10 }).onClick(() => this.randomProfile())
        }.width('100%').margin({ top: 8, bottom: 18 })

        this.SectionTitle('隐私设置')
        this.SwitchRow('允许分析聊天内容', this.allowChatAnalysis, (v: boolean) => { this.allowChatAnalysis = v; })
        this.SwitchRow('允许分析私密树洞', this.allowLetterAnalysis, (v: boolean) => { this.allowLetterAnalysis = v; })
        this.SwitchRow('允许分析语音记录', this.allowVoiceAnalysis, (v: boolean) => { this.allowVoiceAnalysis = v; })
        this.SwitchRow('允许写入长期画像', this.allowProfileUpdate, (v: boolean) => { this.allowProfileUpdate = v; })
        this.SwitchRow('允许用于推荐优化', this.allowRecommendationUse, (v: boolean) => { this.allowRecommendationUse = v; })
        this.SwitchRow('保留语音转写文本', this.allowVoiceTextRetention, (v: boolean) => { this.allowVoiceTextRetention = v; })
        this.SwitchRow('开启多设备同步', this.allowMultiDeviceSync, (v: boolean) => { this.allowMultiDeviceSync = v; })
        this.SwitchRow('接收情绪提醒', this.allowEmotionReminders, (v: boolean) => { this.allowEmotionReminders = v; })
        Button('保存隐私设置').width('100%').height(46).fontColor('#FFF').backgroundColor('#7658F6').borderRadius(23).margin({ top: 12, bottom: 24 }).onClick(() => this.savePrivacy())
      }
      .width('100%')
      .constraintSize({ maxWidth: 720 })
      .padding({ left: 18, right: 18, top: 10 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F4FF')
  }

  @Builder SectionTitle(title: string) {
    Text(title).fontSize(17).fontWeight(FontWeight.Bold).fontColor('#201B34').width('100%').margin({ top: 8, bottom: 10 })
  }

  @Builder Input(label: string, value: string, onChange: (v: string) => void) {
    Column() {
      Text(label).fontSize(12).fontColor('#7E788F').width('100%')
      TextInput({ text: value, placeholder: label })
        .height(44)
        .fontSize(14)
        .backgroundColor('#FFF')
        .borderRadius(14)
        .margin({ top: 6 })
        .onChange(onChange)
    }.width('100%').margin({ bottom: 10 })
  }

  @Builder SwitchRow(label: string, value: boolean, onChange: (v: boolean) => void) {
    Row() {
      Text(label).fontSize(15).fontColor('#30294B')
      Blank()
      Toggle({ type: ToggleType.Switch, isOn: value }).onChange(onChange)
    }
    .width('100%')
    .height(54)
    .padding({ left: 14, right: 14 })
    .backgroundColor('#FFF')
    .borderRadius(16)
    .margin({ bottom: 9 })
  }
}
