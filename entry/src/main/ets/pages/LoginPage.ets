import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { apiService } from '../services/ApiService';

interface ErrorRecord {
  message?: string;
  error?: string;
  detail?: string;
}

@Entry
@Component
struct LoginPage {
  @State account: string = '';
  @State password: string = '';
  @State nickname: string = '';
  @State confirmPassword: string = '';
  @State backendUrl: string = 'http://10.16.106.237:8080';
  @State isRegisterMode: boolean = false;
  @State isLoading: boolean = false;
  @State isPressed: boolean = false;
  @State showPassword: boolean = false;
  @State passwordStrength: number = 0;
  @State errorMsg: string = '';

  aboutToAppear() {
    // Always start from the login entry page so the user can choose login/register/anonymous
    this.isRegisterMode = false;
    this.errorMsg = '';
    apiService.setBaseUrl(this.backendUrl);
  }

  checkPasswordStrength(pwd: string): number {
    if (!pwd) return 0;
    let strength = 0;
    if (pwd.length >= 8) strength++;
    if (/[A-Za-z]/.test(pwd) && /\d/.test(pwd)) strength++;
    if (pwd.length >= 12) strength++;
    if (/[!@#$%^&*]/.test(pwd)) strength++;
    return strength;
  }

  formatError(err: Error | string | ErrorRecord, fallback: string): string {
    if (err instanceof Error && err.message) {
      return err.message;
    }
    if (typeof err === 'string' && err) {
      return err;
    }
    let record = err as ErrorRecord;
    if (typeof record.message === 'string' && record.message) {
      return record.message;
    }
    if (typeof record.error === 'string' && record.error) {
      return record.error;
    }
    if (typeof record.detail === 'string' && record.detail) {
      return record.detail;
    }
    return fallback;
  }

  async doLogin() {
    if (!this.account || !this.password) {
      this.errorMsg = '请输入用户名和密码';
      return;
    }
    this.errorMsg = '';
    this.isLoading = true;
    try {
      const healthOk = await apiService.healthCheck();
      if (!healthOk) {
        this.errorMsg = '后端服务暂时不可用，请先检查后端是否已启动';
        return;
      }
      let result = await apiService.login(this.account.trim(), this.password);
      apiService.setToken(result.token);
      await apiService.getMe();
      try {
        router.replaceUrl({ url: 'pages/Index' });
      } catch (err) {
        console.error('replaceUrl failed', err);
      }
    } catch (err) {
      this.errorMsg = this.formatError(err as Error | string | object, '登录失败，请检查用户名和密码');
    } finally {
      this.isLoading = false;
    }
  }

  async doRegister() {
    if (!this.account || !this.password) {
      this.errorMsg = '请输入用户名和密码';
      return;
    }
    if (this.password !== this.confirmPassword) {
      this.errorMsg = '两次密码输入不一致';
      return;
    }
    if (this.passwordStrength < 2) {
      this.errorMsg = '密码强度不足，至少8位且包含字母和数字';
      return;
    }
    this.errorMsg = '';
    this.isLoading = true;
    try {
      const healthOk = await apiService.healthCheck();
      if (!healthOk) {
        this.errorMsg = '后端服务暂时不可用，请先检查后端是否已启动';
        return;
      }
      let result = await apiService.register(this.account.trim(), this.password, this.nickname);
      apiService.setToken(result.token);
      await apiService.getMe();
      try {
        router.replaceUrl({ url: 'pages/Index' });
      } catch (err) {
        console.error('replaceUrl failed', err);
      }
    } catch (err) {
      const message = this.formatError(err as Error | string | object, '注册失败');
      if (message.includes('409') || message.includes('已被注册') || message.includes('duplicate')) {
        this.errorMsg = '这个用户名已经注册过了，请换一个再试';
      } else {
        this.errorMsg = message || '注册失败';
      }
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      Row() {
        if (this.isRegisterMode) {
          Text('‹').fontSize(30).fontColor('#7658F6').onClick(() => { this.isRegisterMode = false; })
        }
        Text(this.isRegisterMode ? '注册' : '登录')
          .fontSize(22).fontWeight(FontWeight.Bold).fontColor('#201B34')
          .margin({ left: this.isRegisterMode ? 8 : 0 })
        Blank()
      }
      .width('100%').height(56).alignItems(VerticalAlign.Center)

      Scroll() {
        Column() {
          Column() {
            Text('🌿').fontSize(56)
            Text('树洞').fontSize(36).fontWeight(FontWeight.Bold).fontColor('#201B34').margin({ top: 8 })
            Text(this.isRegisterMode ? '创建你的用户名' : '欢迎回来').fontSize(14).fontColor('#8B849B').margin({ top: 6 })
            TextInput({ text: this.backendUrl, placeholder: '后端地址' })
              .height(42)
              .fontSize(14)
              .fontColor('#201B34')
              .backgroundColor('#F7F4FF')
              .borderRadius(12)
              .padding({ left: 14, right: 14 })
              .margin({ top: 14 })
              .onChange((value: string) => {
                this.backendUrl = value;
                apiService.setBaseUrl(value);
              })
          }.width('100%').padding({ top: 40, bottom: 32 }).alignItems(HorizontalAlign.Center)

          if (this.errorMsg) {
            Text(this.errorMsg).fontSize(12).fontColor('#FF6B6B').width('100%')
              .padding(12).backgroundColor('#FFE8E8').borderRadius(12).margin({ bottom: 16 })
          }

          Column() {
            if (this.isRegisterMode) {
              this.formInput('设置昵称（选填）', this.nickname, (v: string) => { this.nickname = v; })
            }
            this.formInput('用户名', this.account, (v: string) => { this.account = v; })

            Row() {
              TextInput({ text: this.password, placeholder: '密码' })
                .height(50).fontSize(16).fontColor('#201B34')
                .placeholderColor('#B9B5C8').backgroundColor('#F7F4FF').borderRadius(14)
                .type(this.showPassword ? InputType.Normal : InputType.Password)
                .onChange((v: string) => {
                  this.password = v;
                  this.passwordStrength = this.checkPasswordStrength(v);
                })
              Text('👁').fontSize(18).fontColor('#B9B5C8')
                .onClick(() => { this.showPassword = !this.showPassword; })
            }.width('100%').margin({ top: 14 })

            if (this.isRegisterMode && this.password) {
              Row() {
                ForEach([1, 2, 3, 4], (level: number) => {
                  Rect().width('22%').height(4)
                    .fill(this.passwordStrength >= level ? (level <= 2 ? '#FF6B6B' : level === 3 ? '#FFB347' : '#4CAF50') : '#E0E0E0')
                    .borderRadius(2)
                })
              }.width('100%').margin({ top: 8 })
            }

            if (this.isRegisterMode) {
              this.formInput('确认密码', this.confirmPassword, (v: string) => { this.confirmPassword = v; })
            }

            Button(this.isLoading ? (this.isRegisterMode ? '注册中...' : '登录中...') : (this.isRegisterMode ? '注册' : '登录'))
              .width('100%').height(52).fontSize(17).fontColor('#FFF').borderRadius(26)
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
              .onClick(() => { this.isRegisterMode ? this.doRegister() : this.doLogin() })
              .margin({ top: 24 })

            Text(this.isRegisterMode ? '已有账号？去登录' : '没有账号？去注册')
              .fontSize(14).fontColor('#7658F6').margin({ top: 20 })
              .onClick(() => { this.isRegisterMode = !this.isRegisterMode; this.errorMsg = ''; })

            if (!this.isRegisterMode) {
              Text('直接匿名体验').fontSize(13).fontColor('#B9B5C8').margin({ top: 12 })
                .onClick(async () => {
                  this.isLoading = true;
                  this.errorMsg = '';
                  try {
                    let result = await apiService.createAnonymous();
                    apiService.setToken(result.token);
                    try {
                      promptAction.showToast({ message: '已进入匿名体验' });
                    } catch (err) {
                      console.error('showToast failed', err);
                    }
                    try {
                      router.replaceUrl({ url: 'pages/Index' });
                    } catch (err) {
                      console.error('replaceUrl failed', err);
                    }
                  } catch (err) {
                    this.errorMsg = this.formatError(err as Error | string | object, '匿名体验失败');
                  } finally {
                    this.isLoading = false;
                  }
                })
            }
          }
          .width('100%').padding(24).backgroundColor('#FFF').borderRadius(24)
            .shadow({ radius: 20, color: '#8B7ED620', offsetY: 6 }).margin({ left: 18, right: 18 })
        }.width('100%')
      }.width('100%').layoutWeight(1)
    }.width('100%').height('100%').backgroundColor('#F7F4FF')
  }

  @Builder formInput(placeholder: string, value: string, onChange: (v: string) => void) {
    TextInput({ text: value, placeholder: placeholder })
      .height(50).fontSize(16).fontColor('#201B34')
      .placeholderColor('#B9B5C8').backgroundColor('#F7F4FF').borderRadius(14)
      .onChange(onChange)
    .width('100%').margin({ top: 14 })
  }
}
