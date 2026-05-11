import router from '@ohos.router';
import promptAction from '@ohos.promptAction';
import { PublicPost } from '../models/Types';
import { apiService } from '../services/ApiService';

@Entry
@Component
struct Plaza {
  @State posts: PublicPost[] = [];
  @State isLoading: boolean = false;
  @State showCreateDialog: boolean = false;
  @State newTitle: string = '';
  @State newContent: string = '';
  @State allowComments: boolean = true;
  @State searchText: string = '';
  @State statusText: string = '匿名广场';
  @State reportPostId: string = '';
  @State reportReason: string = '内容举报';
  @State reportDescription: string = '';
  @State showReportDialog: boolean = false;
  @State quickHint: string = '先发声，再回应，再看见被回应';
  @State localDraftPosts: PublicPost[] = [];

  aboutToAppear() {
    this.loadPosts();
  }

  private safeText(value?: string): string {
    return value && value.trim().length > 0 ? value : '';
  }

  private safeDateText(value?: string): string {
    if (!value) {
      return '刚刚';
    }
    let time = new Date(value).getTime();
    if (isNaN(time)) {
      return '刚刚';
    }
    return value.substring(0, 16).replace('T', ' ');
  }

  private isLocalPost(post: PublicPost): boolean {
    return post.id.indexOf('local-') === 0;
  }

  private createLocalPost(content: string, title?: string): PublicPost {
    const now = new Date().toISOString();
    return {
      id: `local-${new Date().getTime()}`,
      user_id: 'local-user',
      title: title,
      content: content,
      allow_comments: this.allowComments,
      link_match_request: false,
      risk_level: 'low',
      moderation_status: 'approved',
      author_display_name: '匿名同学',
      created_at: now,
      updated_at: now
    };
  }

  private mergePosts(remotePosts: PublicPost[]): PublicPost[] {
    let ids: string[] = [];
    let merged: PublicPost[] = [];
    remotePosts.forEach((post: PublicPost) => {
      if (post && post.id) {
        ids.push(post.id);
        merged.push(post);
      }
    });
    this.localDraftPosts.forEach((post: PublicPost) => {
      if (post && post.id && ids.indexOf(post.id) < 0) {
        merged.unshift(post);
      }
    });
    return merged;
  }

  private getFilteredPosts(): PublicPost[] {
    const keyword = this.searchText.trim().toLowerCase();
    if (!keyword) {
      return this.posts;
    }
    return this.posts.filter((post: PublicPost) => {
      return (post.content || '').toLowerCase().indexOf(keyword) >= 0 || (post.title || '').toLowerCase().indexOf(keyword) >= 0;
    });
  }

  async loadPosts() {
    this.isLoading = true;
    try {
      await apiService.ensureAnonymousUser();
      let res = await apiService.listPosts(50);
      this.posts = this.mergePosts(res.posts || []);
      this.statusText = this.posts.length > 0 ? `已加载 ${this.posts.length} 条匿名内容` : '还没有匿名帖子';
      this.quickHint = this.posts.length > 0 ? `最近有 ${this.posts.length} 条匿名表达` : '还没有人发声，先发第一条吧';
    } catch (e) {
      this.posts = this.mergePosts([]);
      this.statusText = this.posts.length > 0 ? '已显示本地刚发布的帖子，后端连接失败' : '加载失败，请检查后端是否启动';
      this.quickHint = this.posts.length > 0 ? '网络恢复后可刷新同步广场' : '还没有人发声，先发第一条吧';
      console.error('Failed to load posts', e);
    } finally {
      this.isLoading = false;
    }
  }

  async publishPost() {
    const content = this.newContent.trim();
    const title = this.newTitle.trim();
    if (!content) {
      try {
        promptAction.showToast({ message: '请输入内容' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }

    let optimisticPost = this.createLocalPost(content, title || undefined);
    this.localDraftPosts = [optimisticPost].concat(this.localDraftPosts);
    this.posts = this.mergePosts(this.posts);
    this.showCreateDialog = false;
    this.newTitle = '';
    this.newContent = '';
    this.allowComments = true;
    this.statusText = '匿名帖子已发布';
    this.quickHint = '帖子已发出，可以等回应，也可以继续看广场';

    try {
      promptAction.showToast({ message: '匿名帖子已发布' });
    } catch (err) {
      console.error('showToast failed', err);
    }

    try {
      let res = await apiService.createPost(content, title || undefined, optimisticPost.allow_comments);
      this.localDraftPosts = this.localDraftPosts.filter((post: PublicPost) => post.id !== optimisticPost.id);
      this.posts = this.posts.filter((post: PublicPost) => post.id !== optimisticPost.id);
      this.posts = [res.post].concat(this.posts);
      this.statusText = '帖子已同步到广场';
      this.quickHint = '帖子已同步，可以等回应，也可以继续看广场';
    } catch (e) {
      this.statusText = '帖子已先显示在本地，后端同步失败';
      this.quickHint = '网络恢复后点击刷新重新同步';
      console.error('Publish error:', e);
    }
  }

  async react(postId: string, type: string) {
    if (postId.indexOf('local-') === 0) {
      try {
        promptAction.showToast({ message: '本地帖子同步后可互动' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }
    try {
      await apiService.addReaction(postId, type);
      this.quickHint = '回应已送出，看看别人怎么回你';
      try {
        promptAction.showToast({ message: '已回应' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    } catch (e) {
      console.error('React error:', e);
    }
  }

  async deletePost(post: PublicPost) {
    if (this.isLocalPost(post)) {
      this.localDraftPosts = this.localDraftPosts.filter((item: PublicPost) => item.id !== post.id);
      this.posts = this.posts.filter((item: PublicPost) => item.id !== post.id);
      try {
        promptAction.showToast({ message: '本地草稿已移除' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }
    try {
      await apiService.deletePost(post.id);
      this.posts = this.posts.filter((item: PublicPost) => item.id !== post.id);
      try {
        promptAction.showToast({ message: '帖子已删除' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    } catch (e) {
      console.error('Delete post error:', e);
      try {
        promptAction.showToast({ message: '删除失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  async submitReport() {
    if (!this.reportPostId || !this.reportReason.trim()) {
      return;
    }
    if (this.reportPostId.indexOf('local-') === 0) {
      this.showReportDialog = false;
      try {
        promptAction.showToast({ message: '本地帖子无需举报' });
      } catch (err) {
        console.error('showToast failed', err);
      }
      return;
    }
    try {
      await apiService.reportPost(this.reportPostId, this.reportReason.trim(), this.reportDescription.trim() || undefined);
      this.showReportDialog = false;
      this.reportDescription = '';
      this.reportPostId = '';
      this.quickHint = '举报已提交，系统会继续帮你守住安全边界';
      try {
        promptAction.showToast({ message: '举报已提交' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    } catch (e) {
      console.error('Report post error:', e);
      try {
        promptAction.showToast({ message: '举报失败' });
      } catch (err) {
        console.error('showToast failed', err);
      }
    }
  }

  build() {
    Stack() {
      Column() {
        this.Header()
        this.SearchBar()
        Text(this.quickHint).fontSize(11).fontColor('#7B57FF').padding({ left: 16, right: 16, bottom: 6 }).width('100%')
        this.PostListArea()
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F4F1FF')

      if (this.showReportDialog) {
        this.ReportDialog()
      }

      if (this.showCreateDialog) {
        this.CreateDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F4F1FF')
  }

  @Builder
  Header() {
    Row() {
      Image($r('app.media.avatar1'))
        .width(36)
        .height(36)
        .borderRadius(18)
      Column() {
        Text('匿名广场')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.color_text_primary'))
        Text(this.statusText)
          .fontSize(11)
          .fontColor('#8B849B')
          .margin({ top: 2 })
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })
      Blank()
      Button('发帖')
        .fontSize(14)
        .backgroundColor($r('app.color.color_primary'))
        .fontColor($r('app.color.color_white'))
        .height(34)
        .borderRadius(17)
        .onClick(() => { this.showCreateDialog = true; })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_white'))
  }

  @Builder
  SearchBar() {
    Row() {
      TextInput({ placeholder: '搜索匿名内容', text: this.searchText })
        .layoutWeight(1)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((v: string) => { this.searchText = v; })
      Button('刷新')
        .height(36)
        .fontSize(13)
        .backgroundColor('#F0E9FF')
        .fontColor('#7B57FF')
        .borderRadius(18)
        .margin({ left: 10 })
        .onClick(() => this.loadPosts())
    }
    .padding({ left: 16, right: 16, bottom: 8 })
    .backgroundColor($r('app.color.color_white'))
  }

  @Builder
  PostListArea() {
    if (this.isLoading && this.posts.length === 0) {
      Column() {
        LoadingProgress().width(48).height(48).color('#7B57FF')
        Text('正在加载匿名广场').fontSize(13).fontColor('#8B849B').margin({ top: 12 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else if (this.getFilteredPosts().length === 0) {
      Column() {
        Text(this.posts.length === 0 ? '还没有匿名帖子' : '没有匹配的帖子')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#201B34')
        Text(this.posts.length === 0 ? '先发第一条匿名表达吧' : '换个关键词试试看')
          .fontSize(13)
          .fontColor('#888888')
          .margin({ top: 8 })
        Button('发布匿名帖子')
          .height(38)
          .fontSize(13)
          .backgroundColor('#7B57FF')
          .fontColor('#FFFFFF')
          .borderRadius(19)
          .margin({ top: 18 })
          .onClick(() => { this.showCreateDialog = true; })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      List({ space: 16 }) {
        ForEach(this.getFilteredPosts(), (post: PublicPost) => {
          ListItem() {
            this.PostCard(post)
          }
        }, (item: PublicPost) => item.id)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })
    }
  }

  @Builder
  CreateDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Rect()
        .width('100%')
        .height('100%')
        .fill('#00000066')
        .onClick(() => { this.showCreateDialog = false; })

      Column() {
        Text('发布匿名帖子')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
        Text('请确认内容中没有真实姓名、手机号、宿舍号、微信号等隐私信息。')
          .fontSize(12)
          .fontColor('#8B849B')
          .margin({ bottom: 12 })

        TextInput({ placeholder: '标题（可选）', text: this.newTitle })
          .height(42)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 10 })
          .onChange((v: string) => this.newTitle = v)

        TextArea({ placeholder: '分享你的情绪或倾诉...', text: this.newContent })
          .height(120)
          .onChange((v: string) => this.newContent = v)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 14 })

        Row() {
          Text('允许评论')
            .fontSize(13)
            .fontColor('#666666')
          Toggle({ type: ToggleType.Switch, isOn: this.allowComments })
            .onChange((isOn: boolean) => this.allowComments = isOn)
          Blank()
          Button('取消')
            .backgroundColor('#F5F5F5')
            .fontColor($r('app.color.color_unselected'))
            .onClick(() => { this.showCreateDialog = false; })
          Button('发布')
            .backgroundColor($r('app.color.color_primary'))
            .fontColor($r('app.color.color_white'))
            .margin({ left: 10 })
            .onClick(() => this.publishPost())
        }
        .width('100%')
      }
      .width('86%')
      .backgroundColor($r('app.color.color_white'))
      .borderRadius(16)
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .zIndex(999)
  }

  @Builder
  ReportDialog() {
    Stack({ alignContent: Alignment.Center }) {
      Rect()
        .width('100%')
        .height('100%')
        .fill('#00000066')
        .onClick(() => { this.showReportDialog = false; })

      Column() {
        Text('举报帖子')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })
        Text('请尽量提供简短、明确的原因。')
          .fontSize(12)
          .fontColor('#8B849B')
          .margin({ bottom: 12 })

        TextInput({ placeholder: '举报原因', text: this.reportReason })
          .height(42)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 10 })
          .onChange((v: string) => this.reportReason = v)

        TextArea({ placeholder: '补充说明（可选）', text: this.reportDescription })
          .height(100)
          .backgroundColor('#F5F5F5')
          .borderRadius(8)
          .margin({ bottom: 14 })
          .onChange((v: string) => this.reportDescription = v)

        Row() {
          Blank()
          Button('取消')
            .backgroundColor('#F5F5F5')
            .fontColor($r('app.color.color_unselected'))
            .onClick(() => { this.showReportDialog = false; })
          Button('提交')
            .backgroundColor($r('app.color.color_primary'))
            .fontColor($r('app.color.color_white'))
            .margin({ left: 10 })
            .onClick(() => this.submitReport())
        }
        .width('100%')
      }
      .width('86%')
      .backgroundColor($r('app.color.color_white'))
      .borderRadius(16)
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .zIndex(1000)
  }

  @Builder
  PostCard(post: PublicPost) {
    Column() {
      Row() {
        Image($r('app.media.avatar1')).width(32).height(32).borderRadius(16)
        Column() {
          Text(this.safeText(post.author_display_name) || '匿名同学')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.color_text_primary'))
          Row() {
            Text(this.safeDateText(post.created_at))
              .fontSize(10)
              .fontColor($r('app.color.color_unselected'))
            if (post.topic) {
              Text(` · ${post.topic}`).fontSize(10).fontColor('#7B57FF')
            }
          }.margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })
      }
      .width('100%')

      if (post.title) {
        Text(post.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.color_text_primary'))
          .margin({ top: 12 })
          .width('100%')
      }

      Text(post.content || '')
        .fontSize(15)
        .fontColor($r('app.color.color_text_primary'))
        .lineHeight(22)
        .margin({ top: post.title ? 8 : 12, bottom: 16 })
        .width('100%')

      Row() {
        this.ReactionBtn('抱抱', (): void => { this.react(post.id, 'hug'); })
        this.ReactionBtn('我懂你', (): void => { this.react(post.id, 'understand'); })
        this.ReactionBtn('评论', (): void => {
          if (this.isLocalPost(post)) {
            try {
              promptAction.showToast({ message: '本地帖子同步后可评论' });
            } catch (err) {
              console.error('showToast failed', err);
            }
            return;
          }
          try {
            router.pushUrl({ url: 'pages/PostDetail', params: { postId: post.id } });
          } catch (err) {
            console.error('pushUrl failed', err);
          }
        })
        this.ReactionBtn('举报', (): void => {
          this.reportPostId = post.id;
          this.showReportDialog = true;
        })
      }
      .width('100%')

      Row() {
        Text(post.allow_comments ? '可评论' : '评论已关闭').fontSize(11).fontColor('#7B57FF')
        Blank()
        Text(this.isLocalPost(post) ? '本地待同步' : (post.moderation_status === 'approved' ? '已通过审核' : '审核中'))
          .fontSize(11)
          .fontColor(this.isLocalPost(post) ? '#E18B71' : '#888888')
      }.margin({ top: 10 }).width('100%')

      Row() {
        Blank()
        Button(this.isLocalPost(post) ? '移除本地草稿' : '删除自己的帖子')
          .fontSize(12)
          .height(28)
          .backgroundColor('#FFF1F1')
          .fontColor('#C94E4E')
          .borderRadius(14)
          .onClick(() => this.deletePost(post))
      }
      .width('100%')
      .margin({ top: 10 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor($r('app.color.color_white'))
    .borderRadius(16)
    .shadow({ radius: 8, color: '#0000000D', offsetY: 4 })
  }

  @Builder
  ReactionBtn(label: string, action: () => void) {
    Button(label)
      .fontSize(12)
      .height(28)
      .backgroundColor('#F0E9FF')
      .fontColor($r('app.color.color_primary'))
      .borderRadius(14)
      .margin({ right: 8 })
      .onClick(action)
  }
}
